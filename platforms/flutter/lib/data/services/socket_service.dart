import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../core/constants/api_constants.dart';
import 'auth_service.dart';

/// Socket 連接狀態
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket 服務 - 單例模式
/// 使用原生 WebSocket 與 Rust 後端通訊
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _connectionTimeoutSeconds = 20;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastPongTime;
  StreamSubscription? _subscription;

  // 連接狀態監聽器
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  ConnectionState get connectionState => _connectionState;

  // 錯誤監聽器
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  // 訊息監聽器 (原始 JSON)
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // 事件監聽器映射
  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  /// 測試伺服器健康狀態
  Future<bool> _checkServerHealth() async {
    try {
      final healthUrl = '${ApiConstants.baseUrl}/health';
      debugPrint('Checking server health: $healthUrl');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (cert, host, port) => true; // 允許自簽名證書（開發用）

      final request = await client.getUrl(Uri.parse(healthUrl));
      request.headers.set('Accept', 'application/json');

      final response = await request.close().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('❌ Server health check timeout');
          throw TimeoutException('Health check timeout');
        },
      );

      client.close(force: true);

      if (response.statusCode == 200) {
        debugPrint('✅ Server health check passed');
        return true;
      } else {
        debugPrint('❌ Server health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Server health check error: $e');
      // 健康檢查失敗時仍然嘗試連接 WebSocket
      // 因為某些網路環境可能阻擋 HTTP 但允許 WebSocket
      debugPrint('⚠️ Will still try WebSocket connection despite health check failure');
      return true; // 返回 true 讓它繼續嘗試 WebSocket
    }
  }

  /// 連接到伺服器
  Future<bool> connect({String? token}) async {
    if (_connectionState == ConnectionState.connected) {
      debugPrint('WebSocket already connected');
      return true;
    }

    _setConnectionState(ConnectionState.connecting);

    // 先檢查伺服器是否可達
    final isHealthy = await _checkServerHealth();
    if (!isHealthy) {
      debugPrint('❌ Server not reachable, aborting WebSocket connection');
      _setConnectionState(ConnectionState.error);
      _errorController.add('伺服器無法連接');
      return false;
    }

    // 如果沒有提供 token，自動取得認證
    if (token == null || token.isEmpty) {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        debugPrint('AuthService: Initializing authentication...');
        final authResult = await authService.initialize();
        if (!authResult.success) {
          debugPrint('❌ Failed to authenticate');
          _setConnectionState(ConnectionState.error);
          _errorController.add('認證失敗');
          return false;
        }
      }
      token = authService.accessToken;
    }

    try {
      // 構建 WebSocket URL
      String wsUrl = ApiConstants.wsUrl;
      if (!wsUrl.endsWith('/ws')) {
        wsUrl = '$wsUrl/ws';
      }

      // 加入 token 到 query string
      if (token != null && token.isNotEmpty) {
        wsUrl = '$wsUrl?token=$token';
      }

      debugPrint('Connecting to WebSocket: $wsUrl');

      // 建立 WebSocket 連接
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 30),
      );

      // 設定超時
      final completer = Completer<bool>();
      Timer? timeout;

      timeout = Timer(const Duration(seconds: _connectionTimeoutSeconds), () {
        if (!completer.isCompleted) {
          debugPrint('WebSocket connection timeout');
          completer.complete(false);
          _setConnectionState(ConnectionState.error);
          _errorController.add('連接超時');
        }
      });

      // 監聯訊息
      _subscription = _channel!.stream.listen(
        (data) {
          // 第一條訊息表示連接成功
          if (!completer.isCompleted) {
            timeout?.cancel();
            completer.complete(true);
            _reconnectAttempts = 0;
            _lastPongTime = DateTime.now();
            _setConnectionState(ConnectionState.connected);
            _startHeartbeat();
            debugPrint('✅ WebSocket connected successfully');
          }

          // 處理訊息
          _handleMessage(data);
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          if (!completer.isCompleted) {
            timeout?.cancel();
            completer.complete(false);
          }
          _setConnectionState(ConnectionState.error);
          _errorController.add('WebSocket 錯誤: $error');
          _attemptReconnect();
        },
        onDone: () {
          debugPrint('⚠️ WebSocket connection closed');
          if (!completer.isCompleted) {
            timeout?.cancel();
            completer.complete(false);
          }
          _stopHeartbeat();
          _setConnectionState(ConnectionState.disconnected);
          _attemptReconnect();
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('WebSocket connect exception: $e');
      _setConnectionState(ConnectionState.error);
      _errorController.add('連接異常: $e');
      return false;
    }
  }

  /// 處理收到的訊息
  void _handleMessage(dynamic data) {
    try {
      final String jsonStr = data is String ? data : utf8.decode(data);
      final Map<String, dynamic> message = json.decode(jsonStr);

      debugPrint('📩 Received: ${message['type']}');

      // 發送到訊息流
      _messageController.add(message);

      // 處理特定訊息類型
      final String? messageType = message['type'];
      if (messageType != null) {
        // 更新心跳時間
        if (messageType == 'pong') {
          _lastPongTime = DateTime.now();
        }

        // 觸發事件監聽器
        _triggerEvent(messageType, message);
      }
    } catch (e) {
      debugPrint('❌ Failed to parse message: $e');
    }
  }

  /// 觸發事件監聽器
  void _triggerEvent(String event, dynamic data) {
    final listeners = _eventListeners[event];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(data);
        } catch (e) {
          debugPrint('Event listener error for $event: $e');
        }
      }
    }
  }

  /// 斷開連接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _setConnectionState(ConnectionState.disconnected);
    debugPrint('WebSocket disconnected manually');
  }

  /// 開始心跳檢測
  void _startHeartbeat() {
    _stopHeartbeat();
    _lastPongTime = DateTime.now();

    // 每 25 秒發送心跳
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_channel == null || _connectionState != ConnectionState.connected) {
        _stopHeartbeat();
        return;
      }

      // 檢查上次 pong 時間
      if (_lastPongTime != null) {
        final elapsed = DateTime.now().difference(_lastPongTime!);
        if (elapsed.inSeconds > 60) {
          debugPrint('❌ Heartbeat timeout - no pong received in ${elapsed.inSeconds}s');
          _stopHeartbeat();
          _setConnectionState(ConnectionState.error);
          _errorController.add('連接超時');
          _attemptReconnect();
          return;
        }
      }

      debugPrint('💓 Sending heartbeat ping');
      send({'type': 'ping'});
    });
  }

  /// 停止心跳檢測
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 發送訊息
  void send(Map<String, dynamic> message) {
    if (_channel == null || _connectionState != ConnectionState.connected) {
      debugPrint('Cannot send: WebSocket not connected');
      _errorController.add('未連接到伺服器');
      return;
    }
    final jsonStr = json.encode(message);
    debugPrint('📤 Sending: ${message['type']}');
    _channel!.sink.add(jsonStr);
  }

  /// 發送並等待回應（使用訊息類型匹配）
  Future<Map<String, dynamic>?> sendAndWait(
    Map<String, dynamic> message, {
    String? expectedResponseType,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_channel == null || _connectionState != ConnectionState.connected) {
      debugPrint('Cannot send: WebSocket not connected');
      _errorController.add('未連接到伺服器');
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();

    // 監聽回應
    late StreamSubscription subscription;
    subscription = messageStream.listen((response) {
      if (expectedResponseType == null ||
          response['type'] == expectedResponseType ||
          response['type'] == 'error') {
        if (!completer.isCompleted) {
          completer.complete(response);
          subscription.cancel();
        }
      }
    });

    // 發送訊息
    send(message);

    // 超時處理
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        subscription.cancel();
        debugPrint('Send and wait timeout: ${message['type']}');
        return null;
      },
    );
  }

  // ============================================================
  // 便捷方法 - 對應後端 ClientMessage 類型
  // ============================================================

  /// 加入房間
  void joinRoom(String roomCode, String playerName) {
    send({
      'type': 'join_room',
      'room_code': roomCode,
      'player_name': playerName,
    });
  }

  /// 離開房間
  void leaveRoom() {
    send({'type': 'leave_room'});
  }

  /// 選擇角色
  void selectCharacter(String character) {
    send({
      'type': 'select_character',
      'character': character,
    });
  }

  /// 準備
  void ready() {
    send({'type': 'ready'});
  }

  /// 取消準備
  void unready() {
    send({'type': 'unready'});
  }

  /// 開始遊戲
  void startGame() {
    send({'type': 'start_game'});
  }

  /// 發送公開聊天
  void sendChat(String content) {
    send({
      'type': 'send_chat',
      'content': content,
    });
  }

  /// 發送私訊
  void sendPrivateChat(String targetId, String content) {
    send({
      'type': 'send_private_chat',
      'target_id': targetId,
      'content': content,
    });
  }

  /// 質詢（攻擊）
  void challenge(String targetId) {
    send({
      'type': 'challenge',
      'target_id': targetId,
    });
  }

  /// 反駁（防禦）
  void counter() {
    send({'type': 'counter'});
  }

  /// 使用技能
  void useSkill({String? targetId}) {
    send({
      'type': 'use_skill',
      if (targetId != null) 'target_id': targetId,
    });
  }

  /// 投票
  void vote(String choice) {
    send({
      'type': 'vote',
      'choice': choice,
    });
  }

  // ============================================================
  // 事件監聽
  // ============================================================

  /// 監聽事件
  void on(String event, Function(dynamic) callback) {
    _eventListeners.putIfAbsent(event, () => []);
    _eventListeners[event]!.add(callback);
  }

  /// 監聽事件（只觸發一次）
  void once(String event, Function(dynamic) callback) {
    late Function(dynamic) wrapper;
    wrapper = (data) {
      callback(data);
      off(event, wrapper);
    };
    on(event, wrapper);
  }

  /// 取消監聽事件
  void off(String event, [Function(dynamic)? callback]) {
    if (callback == null) {
      _eventListeners.remove(event);
    } else {
      _eventListeners[event]?.remove(callback);
    }
  }

  /// 取消所有監聽
  void offAll() {
    _eventListeners.clear();
  }

  /// 設置連接狀態
  void _setConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  /// 嘗試重連
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _setConnectionState(ConnectionState.error);
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (_reconnectAttempts + 1) * 2);
    _reconnectAttempts++;

    debugPrint('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _setConnectionState(ConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      if (_connectionState != ConnectionState.connected) {
        connect();
      }
    });
  }

  /// 手動重連
  Future<bool> reconnect() async {
    _reconnectAttempts = 0;
    disconnect();
    return connect();
  }

  /// 是否已連接
  bool get isConnected => _connectionState == ConnectionState.connected;

  /// 清理資源
  void dispose() {
    _stopHeartbeat();
    disconnect();
    _connectionStateController.close();
    _errorController.close();
    _messageController.close();
  }
}
