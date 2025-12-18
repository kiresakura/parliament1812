import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// WebSocket 事件類型
enum WSEventType {
  // 系統事件
  connected,
  disconnected,
  error,
  pong,

  // 玩家事件
  playerJoin,
  playerLeave,
  playerRoleAssigned,

  // 遊戲事件
  phaseChange,
  timerSync,
  timerStart,
  timerStop,

  // 私訊事件
  privateMessage,

  // 投票事件
  voteUpdate,
  voteResult,

  // 突發事件
  eventTrigger,

  // 揭曉事件
  secretRevealed,
}

/// WebSocket 服務
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  String? _roomCode;
  String? _playerId;

  bool _isConnected = false;
  bool _shouldReconnect = true;

  // 事件串流控制器
  final _eventController = StreamController<WSEvent>.broadcast();
  Stream<WSEvent> get eventStream => _eventController.stream;

  // 連線狀態串流
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// 連接 WebSocket
  Future<void> connect({
    required String roomCode,
    required String playerId,
  }) async {
    _roomCode = roomCode;
    _playerId = playerId;
    _shouldReconnect = true;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_roomCode == null || _playerId == null) return;

    try {
      final wsUrl = '${AppConfig.currentWsUrl}/ws/$_roomCode?player_id=$_playerId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _isConnected = true;
      _connectionController.add(true);
      _eventController.add(WSEvent(type: WSEventType.connected, data: {}));

      // 啟動心跳
      _startHeartbeat();

      // 監聽訊息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      _eventController.add(WSEvent(
        type: WSEventType.error,
        data: {'error': e.toString()},
      ));
      _scheduleReconnect();
    }
  }

  /// 斷開連線
  void disconnect() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
    _eventController.add(WSEvent(type: WSEventType.disconnected, data: {}));
  }

  /// 發送訊息
  void send(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;

    final message = jsonEncode({
      'type': type,
      'data': data,
    });
    _channel!.sink.add(message);
  }

  /// 發送私訊
  void sendPrivateMessage({
    required String toPlayerId,
    required String content,
  }) {
    send('send_message', {
      'to': toPlayerId,
      'content': content,
    });
  }

  /// 發送投票
  void sendVote({
    required int round,
    required String choice,
  }) {
    send('cast_vote', {
      'round': round,
      'choice': choice,
    });
  }

  /// 請求同步狀態
  void requestSync() {
    send('request_sync', {});
  }

  // ==================== 內部方法 ====================

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = _parseEventType(data['type']);
      final eventData = data['data'] as Map<String, dynamic>? ?? {};

      _eventController.add(WSEvent(type: type, data: eventData));
    } catch (e) {
      print('WebSocket 解析錯誤: $e');
    }
  }

  void _onError(dynamic error) {
    _isConnected = false;
    _connectionController.add(false);
    _eventController.add(WSEvent(
      type: WSEventType.error,
      data: {'error': error.toString()},
    ));
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _connectionController.add(false);
    _eventController.add(WSEvent(type: WSEventType.disconnected, data: {}));
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: AppConfig.wsHeartbeatInterval),
      (_) {
        if (_isConnected) {
          send('ping', {});
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: AppConfig.wsReconnectDelay),
      _doConnect,
    );
  }

  WSEventType _parseEventType(String? type) {
    switch (type) {
      case 'player_join':
        return WSEventType.playerJoin;
      case 'player_leave':
        return WSEventType.playerLeave;
      case 'player_role_assigned':
        return WSEventType.playerRoleAssigned;
      case 'phase_change':
        return WSEventType.phaseChange;
      case 'timer_sync':
        return WSEventType.timerSync;
      case 'timer_start':
        return WSEventType.timerStart;
      case 'timer_stop':
        return WSEventType.timerStop;
      case 'private_message':
        return WSEventType.privateMessage;
      case 'vote_update':
        return WSEventType.voteUpdate;
      case 'vote_result':
        return WSEventType.voteResult;
      case 'event_trigger':
        return WSEventType.eventTrigger;
      case 'secret_revealed':
        return WSEventType.secretRevealed;
      case 'pong':
        return WSEventType.pong;
      default:
        return WSEventType.error;
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}

/// WebSocket 事件
class WSEvent {
  final WSEventType type;
  final Map<String, dynamic> data;

  WSEvent({required this.type, required this.data});
}
