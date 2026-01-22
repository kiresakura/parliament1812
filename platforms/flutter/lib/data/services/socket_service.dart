import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';

/// Socket 連接狀態
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Socket 事件常數
class SocketEvents {
  // Client → Server
  static const String createRoom = 'create_room';
  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String playerReady = 'player_ready';
  static const String startGame = 'start_game';
  static const String gameAction = 'game_action';
  static const String sendMessage = 'send_message';
  static const String vote = 'vote';

  // Server → Client
  static const String roomCreated = 'room_created';
  static const String roomJoined = 'room_joined';
  static const String playerJoined = 'player_joined';
  static const String playerLeft = 'player_left';
  static const String playerReadyChanged = 'player_ready_changed';
  static const String gameStarted = 'game_started';
  static const String phaseChanged = 'phase_changed';
  static const String gameStateUpdate = 'game_state_update';
  static const String actionResult = 'action_result';
  static const String messageReceived = 'message_received';
  static const String voteReceived = 'vote_received';
  static const String gameEnded = 'game_ended';
  static const String error = 'error';
}

/// Socket 服務 - 單例模式
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // 連接狀態監聽器
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  ConnectionState get connectionState => _connectionState;

  // 錯誤監聽器
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  /// 連接到伺服器
  Future<bool> connect({String? playerName}) async {
    if (_connectionState == ConnectionState.connected) {
      debugPrint('Socket already connected');
      return true;
    }

    _setConnectionState(ConnectionState.connecting);

    try {
      _socket = io.io(
        ApiConstants.wsUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setQuery(playerName != null ? {'playerName': playerName} : {})
            .build(),
      );

      // 連接事件
      _socket!.onConnect((_) {
        debugPrint('Socket connected');
        _reconnectAttempts = 0;
        _setConnectionState(ConnectionState.connected);
      });

      // 斷線事件
      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
        _setConnectionState(ConnectionState.disconnected);
      });

      // 連接錯誤
      _socket!.onConnectError((error) {
        debugPrint('Socket connect error: $error');
        _setConnectionState(ConnectionState.error);
        _errorController.add('連接失敗: $error');
        _attemptReconnect();
      });

      // 錯誤事件
      _socket!.onError((error) {
        debugPrint('Socket error: $error');
        _errorController.add('Socket 錯誤: $error');
      });

      // 重連事件
      _socket!.on('reconnect_attempt', (_) {
        debugPrint('Socket reconnecting...');
        _setConnectionState(ConnectionState.reconnecting);
      });

      _socket!.on('reconnect', (_) {
        debugPrint('Socket reconnected');
        _reconnectAttempts = 0;
        _setConnectionState(ConnectionState.connected);
      });

      _socket!.on('reconnect_failed', (_) {
        debugPrint('Socket reconnect failed');
        _setConnectionState(ConnectionState.error);
        _errorController.add('重連失敗');
      });

      // 伺服器錯誤
      _socket!.on(SocketEvents.error, (data) {
        final message = data is Map ? data['message'] ?? '未知錯誤' : data.toString();
        debugPrint('Server error: $message');
        _errorController.add(message);
      });

      _socket!.connect();

      // 等待連接完成
      final completer = Completer<bool>();
      Timer? timeout;

      void onConnect(_) {
        timeout?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }

      void onError(dynamic error) {
        timeout?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }

      _socket!.once('connect', onConnect);
      _socket!.once('connect_error', onError);

      timeout = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          _setConnectionState(ConnectionState.error);
          _errorController.add('連接超時');
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('Socket connect exception: $e');
      _setConnectionState(ConnectionState.error);
      _errorController.add('連接異常: $e');
      return false;
    }
  }

  /// 斷開連接
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setConnectionState(ConnectionState.disconnected);
    debugPrint('Socket disconnected manually');
  }

  /// 發送事件
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Cannot emit: socket not connected');
      _errorController.add('未連接到伺服器');
      return;
    }
    debugPrint('Emitting: $event -> $data');
    _socket!.emit(event, data);
  }

  /// 發送事件並等待回應
  Future<T?> emitWithAck<T>(String event, [dynamic data]) async {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Cannot emit: socket not connected');
      _errorController.add('未連接到伺服器');
      return null;
    }

    final completer = Completer<T?>();

    _socket!.emitWithAck(event, data, ack: (response) {
      if (!completer.isCompleted) {
        completer.complete(response as T?);
      }
    });

    // 超時處理
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Emit with ack timeout: $event');
        return null;
      },
    );
  }

  /// 監聽事件
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// 監聽事件（只觸發一次）
  void once(String event, Function(dynamic) callback) {
    _socket?.once(event, callback);
  }

  /// 取消監聽事件
  void off(String event, [Function(dynamic)? callback]) {
    _socket?.off(event, callback);
  }

  /// 取消所有監聽
  void offAll() {
    _socket?.clearListeners();
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
        _socket?.connect();
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
    disconnect();
    _connectionStateController.close();
    _errorController.close();
  }
}
