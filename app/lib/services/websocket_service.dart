import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../config/constants.dart';
import '../models/player.dart';
import '../models/room.dart';

/// WebSocket 連線管理服務
/// 負責與 Rust 後端的 WebSocket 通訊
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  String? _lastUrl;

  // 事件流控制器
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<ServerMessage>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // 公開的事件流
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<ServerMessage> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // 當前連線狀態
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  /// 連接到 WebSocket 伺服器
  Future<bool> connect({String? customUrl}) async {
    if (_isConnecting) return false;

    final url = customUrl ?? AppConstants.websocketUrl;
    _lastUrl = url;

    try {
      _isConnecting = true;
      _updateConnectionState(ConnectionState.connecting);

      print('WebSocket connecting to: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 監聽訊息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      // 等待連接建立（簡單的超時檢查）
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_channel?.closeCode == null) {
        _updateConnectionState(ConnectionState.connected);
        _startHeartbeat();
        _resetReconnectAttempts();
        print('WebSocket connected successfully');
        return true;
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      print('WebSocket connection error: $e');
      _updateConnectionState(ConnectionState.error);
      _errorController.add('連接失敗: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// 斷開連接
  void disconnect() {
    print('WebSocket disconnecting...');
    _stopHeartbeat();
    _stopReconnecting();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _updateConnectionState(ConnectionState.disconnected);
  }

  /// 發送訊息到伺服器
  bool sendMessage(ClientMessage message) {
    if (_connectionState != ConnectionState.connected || _channel == null) {
      print('WebSocket not connected, cannot send message');
      return false;
    }

    try {
      final json = jsonEncode(message.toJson());
      _channel!.sink.add(json);
      print('WebSocket sent: ${message.runtimeType}');
      return true;
    } catch (e) {
      print('WebSocket send error: $e');
      _errorController.add('發送訊息失敗: $e');
      return false;
    }
  }

  /// 發送心跳
  void sendHeartbeat() {
    sendMessage(const ClientMessage.ping());
  }

  void _onMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ServerMessage.fromJson(jsonData);
      
      print('WebSocket received: ${message.runtimeType}');
      
      // 處理心跳回應
      if (message is ServerMessage && message.type == 'pong') {
        print('Heartbeat pong received');
        return;
      }
      
      _messageController.add(message);
    } catch (e) {
      print('WebSocket message parse error: $e');
      _errorController.add('訊息解析錯誤: $e');
    }
  }

  void _onError(dynamic error) {
    print('WebSocket error: $error');
    _updateConnectionState(ConnectionState.error);
    _errorController.add('連接錯誤: $error');
    _attemptReconnect();
  }

  void _onDisconnected() {
    print('WebSocket disconnected');
    _stopHeartbeat();
    
    if (_connectionState != ConnectionState.disconnected) {
      _updateConnectionState(ConnectionState.disconnected);
      _attemptReconnect();
    }
  }

  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      print('WebSocket state changed to: $newState');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      AppConstants.heartbeatInterval,
      (_) => sendHeartbeat(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _attemptReconnect() {
    if (_reconnectTimer != null || 
        _reconnectAttempts >= AppConstants.maxReconnectAttempts ||
        _lastUrl == null) {
      return;
    }

    _reconnectAttempts++;
    print('WebSocket attempting reconnect $_reconnectAttempts/${AppConstants.maxReconnectAttempts}');

    _reconnectTimer = Timer(AppConstants.reconnectDelay, () {
      _reconnectTimer = null;
      connect(customUrl: _lastUrl);
    });
  }

  void _stopReconnecting() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// 釋放資源
  void dispose() {
    _stopHeartbeat();
    _stopReconnecting();
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _errorController.close();
  }
}

/// 連線狀態列舉
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// 客戶端訊息基類
/// 對應 Rust 後端的 ClientMessage 列舉
sealed class ClientMessage {
  const ClientMessage();

  Map<String, dynamic> toJson();

  // 加入房間
  const factory ClientMessage.joinRoom({
    required String roomCode,
    required String playerName,
  }) = JoinRoomMessage;

  // 離開房間
  const factory ClientMessage.leaveRoom() = LeaveRoomMessage;

  // 選擇角色
  const factory ClientMessage.selectCharacter({
    required CharacterType character,
  }) = SelectCharacterMessage;

  // 準備
  const factory ClientMessage.ready() = ReadyMessage;

  // 取消準備
  const factory ClientMessage.unready() = UnreadyMessage;

  // 開始遊戲（僅房主）
  const factory ClientMessage.startGame() = StartGameMessage;

  // 發送公開聊天
  const factory ClientMessage.sendChat({
    required String content,
  }) = SendChatMessage;

  // 發送私訊
  const factory ClientMessage.sendPrivateChat({
    required String targetId,
    required String content,
  }) = SendPrivateChatMessage;

  // 質詢（攻擊）
  const factory ClientMessage.challenge({
    required String targetId,
  }) = ChallengeMessage;

  // 反駁（防禦）
  const factory ClientMessage.counter() = CounterMessage;

  // 使用技能
  const factory ClientMessage.useSkill({
    String? targetId,
  }) = UseSkillMessage;

  // 投票
  const factory ClientMessage.vote({
    required VoteChoice choice,
  }) = VoteMessage;

  // 使用卡牌
  const factory ClientMessage.useCard({
    required String cardId,
    String? targetId,
  }) = UseCardMessage;

  // 抽牌
  const factory ClientMessage.drawCard() = DrawCardMessage;

  // 棄牌
  const factory ClientMessage.discardCard({
    required String cardId,
  }) = DiscardCardMessage;

  // 心跳
  const factory ClientMessage.ping() = PingMessage;
}

// 具體實現類
class JoinRoomMessage extends ClientMessage {
  final String roomCode;
  final String playerName;

  const JoinRoomMessage({
    required this.roomCode,
    required this.playerName,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'join_room',
    'room_code': roomCode,
    'player_name': playerName,
  };
}

class LeaveRoomMessage extends ClientMessage {
  const LeaveRoomMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'leave_room'};
}

class SelectCharacterMessage extends ClientMessage {
  final CharacterType character;

  const SelectCharacterMessage({required this.character});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'select_character',
    'character': character.name,
  };
}

class ReadyMessage extends ClientMessage {
  const ReadyMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'ready'};
}

class UnreadyMessage extends ClientMessage {
  const UnreadyMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'unready'};
}

class StartGameMessage extends ClientMessage {
  const StartGameMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'start_game'};
}

class SendChatMessage extends ClientMessage {
  final String content;

  const SendChatMessage({required this.content});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'send_chat',
    'content': content,
  };
}

class SendPrivateChatMessage extends ClientMessage {
  final String targetId;
  final String content;

  const SendPrivateChatMessage({
    required this.targetId,
    required this.content,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'send_private_chat',
    'target_id': targetId,
    'content': content,
  };
}

class ChallengeMessage extends ClientMessage {
  final String targetId;

  const ChallengeMessage({required this.targetId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'challenge',
    'target_id': targetId,
  };
}

class CounterMessage extends ClientMessage {
  const CounterMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'counter'};
}

class UseSkillMessage extends ClientMessage {
  final String? targetId;

  const UseSkillMessage({this.targetId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'use_skill',
    if (targetId != null) 'target_id': targetId,
  };
}

class VoteMessage extends ClientMessage {
  final VoteChoice choice;

  const VoteMessage({required this.choice});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'vote',
    'choice': choice.name,
  };
}

class UseCardMessage extends ClientMessage {
  final String cardId;
  final String? targetId;

  const UseCardMessage({
    required this.cardId,
    this.targetId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'use_card',
    'card_id': cardId,
    if (targetId != null) 'target_id': targetId,
  };
}

class DrawCardMessage extends ClientMessage {
  const DrawCardMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'draw_card'};
}

class DiscardCardMessage extends ClientMessage {
  final String cardId;

  const DiscardCardMessage({required this.cardId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'discard_card',
    'card_id': cardId,
  };
}

class PingMessage extends ClientMessage {
  const PingMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'ping'};
}

/// 伺服器訊息基類
/// 對應 Rust 後端的 ServerMessage 列舉
sealed class ServerMessage {
  final String type;
  
  const ServerMessage(this.type);

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    
    switch (type) {
      case 'connected':
        return ConnectedMessage.fromJson(json);
      case 'error':
        return ErrorMessage.fromJson(json);
      case 'room_state':
        return RoomStateMessage.fromJson(json);
      case 'player_joined':
        return PlayerJoinedMessage.fromJson(json);
      case 'player_left':
        return PlayerLeftMessage.fromJson(json);
      case 'game_started':
        return GameStartedMessage.fromJson(json);
      case 'phase_changed':
        return PhaseChangedMessage.fromJson(json);
      case 'chat_message':
        return ChatMessageMessage.fromJson(json);
      case 'pong':
        return PongMessage.fromJson(json);
      default:
        throw Exception('Unknown server message type: $type');
    }
  }
}

// 具體的伺服器訊息實現類
class ConnectedMessage extends ServerMessage {
  final String? playerId;
  final String serverVersion;

  const ConnectedMessage({
    this.playerId,
    required this.serverVersion,
  }) : super('connected');

  factory ConnectedMessage.fromJson(Map<String, dynamic> json) {
    return ConnectedMessage(
      playerId: json['player_id'] as String?,
      serverVersion: json['server_version'] as String,
    );
  }
}

class ErrorMessage extends ServerMessage {
  final String code;
  final String message;

  const ErrorMessage({
    required this.code,
    required this.message,
  }) : super('error');

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

class RoomStateMessage extends ServerMessage {
  final Map<String, dynamic> roomData;
  final List<Map<String, dynamic>> playersData;

  const RoomStateMessage({
    required this.roomData,
    required this.playersData,
  }) : super('room_state');

  factory RoomStateMessage.fromJson(Map<String, dynamic> json) {
    return RoomStateMessage(
      roomData: json['room'] as Map<String, dynamic>,
      playersData: (json['players'] as List)
          .cast<Map<String, dynamic>>(),
    );
  }
}

class PlayerJoinedMessage extends ServerMessage {
  final Map<String, dynamic> playerData;

  const PlayerJoinedMessage({
    required this.playerData,
  }) : super('player_joined');

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerJoinedMessage(
      playerData: json['player'] as Map<String, dynamic>,
    );
  }
}

class PlayerLeftMessage extends ServerMessage {
  final String playerId;
  final String playerName;
  final bool wasHost;
  final String? newHostId;

  const PlayerLeftMessage({
    required this.playerId,
    required this.playerName,
    required this.wasHost,
    this.newHostId,
  }) : super('player_left');

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      wasHost: json['was_host'] as bool,
      newHostId: json['new_host_id'] as String?,
    );
  }
}

class GameStartedMessage extends ServerMessage {
  final String phase;
  final int durationSecs;

  const GameStartedMessage({
    required this.phase,
    required this.durationSecs,
  }) : super('game_started');

  factory GameStartedMessage.fromJson(Map<String, dynamic> json) {
    return GameStartedMessage(
      phase: json['phase'] as String,
      durationSecs: json['duration_secs'] as int,
    );
  }
}

class PhaseChangedMessage extends ServerMessage {
  final String phase;
  final int durationSecs;
  final int round;

  const PhaseChangedMessage({
    required this.phase,
    required this.durationSecs,
    required this.round,
  }) : super('phase_changed');

  factory PhaseChangedMessage.fromJson(Map<String, dynamic> json) {
    return PhaseChangedMessage(
      phase: json['phase'] as String,
      durationSecs: json['duration_secs'] as int,
      round: json['round'] as int,
    );
  }
}

class ChatMessageMessage extends ServerMessage {
  final String fromId;
  final String fromName;
  final String content;
  final bool isPrivate;
  final int timestamp;

  const ChatMessageMessage({
    required this.fromId,
    required this.fromName,
    required this.content,
    required this.isPrivate,
    required this.timestamp,
  }) : super('chat_message');

  factory ChatMessageMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessageMessage(
      fromId: json['from_id'] as String,
      fromName: json['from_name'] as String,
      content: json['content'] as String,
      isPrivate: json['is_private'] as bool,
      timestamp: json['timestamp'] as int,
    );
  }
}

class PongMessage extends ServerMessage {
  final int timestamp;

  const PongMessage({required this.timestamp}) : super('pong');

  factory PongMessage.fromJson(Map<String, dynamic> json) {
    return PongMessage(
      timestamp: json['timestamp'] as int,
    );
  }
}