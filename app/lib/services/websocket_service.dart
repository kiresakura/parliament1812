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
  
  // 序列號追蹤
  int _expectedSeq = 1;
  int _latestSeq = 0;
  final _pendingMessages = <int, ServerMessage>{};
  
  // 自動重連配置
  static const _maxReconnectAttempts = 10;
  static const _baseReconnectDelay = Duration(seconds: 1);
  static const _maxReconnectDelay = Duration(seconds: 30);

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
      
      // 檢查是否為包裝消息（帶序列號）
      if (jsonData.containsKey('seq') && jsonData.containsKey('message')) {
        _handleWrappedMessage(jsonData);
        return;
      }
      
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
  
  void _handleWrappedMessage(Map<String, dynamic> jsonData) {
    try {
      final seq = jsonData['seq'] as int;
      final timestamp = jsonData['timestamp'] as int;
      final messageData = jsonData['message'] as Map<String, dynamic>;
      
      final message = ServerMessage.fromJson(messageData);
      
      // 更新最新序列號
      if (seq > _latestSeq) {
        _latestSeq = seq;
      }
      
      // 檢查序列號順序
      if (seq == _expectedSeq) {
        // 正確順序，直接處理
        _processMessage(message);
        _expectedSeq++;
        
        // 檢查是否有等待的後續消息
        _processPendingMessages();
      } else if (seq > _expectedSeq) {
        // 亂序消息，暫存
        _pendingMessages[seq] = message;
        print('Message out of order: expected $_expectedSeq, got $seq');
        
        // 如果積壓太多，請求重新同步
        if (_pendingMessages.length > 10) {
          _requestResync();
        }
      } else {
        // 重複或過期消息，忽略
        print('Duplicate or old message: seq $seq (expected $_expectedSeq)');
      }
    } catch (e) {
      print('Error handling wrapped message: $e');
    }
  }
  
  void _processPendingMessages() {
    while (_pendingMessages.containsKey(_expectedSeq)) {
      final message = _pendingMessages.remove(_expectedSeq)!;
      _processMessage(message);
      _expectedSeq++;
    }
  }
  
  void _processMessage(ServerMessage message) {
    print('Processing message: ${message.runtimeType}');
    _messageController.add(message);
  }
  
  void _requestResync() {
    print('Requesting resync due to too many out-of-order messages');
    // 清空待處理消息
    _pendingMessages.clear();
    // 重置序列號期望（將由重連或重新同步處理）
    _expectedSeq = _latestSeq + 1;
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
        _reconnectAttempts >= _maxReconnectAttempts ||
        _lastUrl == null) {
      return;
    }

    _reconnectAttempts++;
    
    // 指數退避：1s → 2s → 4s → 8s → ... → max 30s
    final delay = Duration(
      milliseconds: (_baseReconnectDelay.inMilliseconds * 
        (1 << (_reconnectAttempts - 1))).clamp(
          _baseReconnectDelay.inMilliseconds,
          _maxReconnectDelay.inMilliseconds,
        ),
    );
    
    print('WebSocket attempting reconnect $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s');
    
    _updateConnectionState(ConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      final success = await connect(customUrl: _lastUrl);
      
      if (success) {
        // 重連成功，請求完整狀態
        _requestReconnectData();
      } else if (_reconnectAttempts < _maxReconnectAttempts) {
        // 繼續嘗試重連
        _attemptReconnect();
      } else {
        // 達到最大重連次數，停止嘗試
        print('Max reconnect attempts reached, giving up');
        _updateConnectionState(ConnectionState.error);
      }
    });
  }
  
  void _requestReconnectData() {
    // 這裡可以發送一個請求以獲取完整的房間/遊戲狀態
    // 重置序列號追蹤
    _expectedSeq = 1;
    _latestSeq = 0;
    _pendingMessages.clear();
    print('Requesting reconnect data after successful reconnection');
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
  reconnecting,
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

  // 結束回合（回合制）
  const factory ClientMessage.endTurn() = EndTurnMessage;

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

class ProposeAllianceMessage extends ClientMessage {
  final String targetId;

  const ProposeAllianceMessage({required this.targetId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'propose_alliance',
    'target_id': targetId,
  };
}

class RespondToAllianceMessage extends ClientMessage {
  final String proposerId;
  final bool accept;

  const RespondToAllianceMessage({required this.proposerId, required this.accept});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'respond_to_alliance',
    'proposer_id': proposerId,
    'accept': accept,
  };
}

class ReactToMessageMessage extends ClientMessage {
  final int messageSeq;
  final String emoji;

  const ReactToMessageMessage({required this.messageSeq, required this.emoji});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'react_to_message',
    'message_seq': messageSeq,
    'emoji': emoji,
  };
}

class EndTurnMessage extends ClientMessage {
  const EndTurnMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'end_turn'};
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
      case 'player_selected_character':
        return PlayerSelectedCharacterMessage.fromJson(json);
      case 'player_ready':
        return PlayerReadyMessage.fromJson(json);
      case 'player_unready':
        return PlayerUnreadyMessage.fromJson(json);
      case 'challenge_event':
        return ChallengeEventMessage.fromJson(json);
      case 'counter_event':
        return CounterEventMessage.fromJson(json);
      case 'skill_used':
        return SkillUsedMessage.fromJson(json);
      case 'reputation_changed':
        return ReputationChangedMessage.fromJson(json);
      case 'gold_changed':
        return GoldChangedMessage.fromJson(json);
      case 'card_used':
        return CardUsedMessage.fromJson(json);
      case 'card_drawn':
        return CardDrawnMessage.fromJson(json);
      case 'hand_updated':
        return HandUpdatedMessage.fromJson(json);
      case 'player_hand_count_changed':
        return PlayerHandCountChangedMessage.fromJson(json);
      case 'vote_received':
        return VoteReceivedMessage.fromJson(json);
      case 'vote_result':
        return VoteResultMessage.fromJson(json);
      case 'game_result':
        return GameResultMessage.fromJson(json);
      case 'player_political_death':
        return PlayerPoliticalDeathMessage.fromJson(json);
      case 'system_message':
        return SystemMessageMessage.fromJson(json);
      case 'timer_update':
        return TimerUpdateMessage.fromJson(json);
      case 'turn_changed':
        return TurnChangedMessage.fromJson(json);
      case 'alliance_proposed':
        return AllianceProposedMessage.fromJson(json);
      case 'alliance_accepted':
        return AllianceAcceptedMessage.fromJson(json);
      case 'alliance_rejected':
        return AllianceRejectedMessage.fromJson(json);
      case 'alliance_betrayed':
        return AllianceBetrayedMessage.fromJson(json);
      case 'message_reaction':
        return MessageReactionMessage.fromJson(json);
      case 'room_update':
        return RoomUpdateMessage.fromJson(json);
      case 'reconnect_data':
        return ReconnectDataMessage.fromJson(json);
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
  final List<String> turnOrder;

  const GameStartedMessage({
    required this.phase,
    required this.durationSecs,
    this.turnOrder = const [],
  }) : super('game_started');

  factory GameStartedMessage.fromJson(Map<String, dynamic> json) {
    return GameStartedMessage(
      phase: json['phase'] as String,
      durationSecs: json['duration_secs'] as int,
      turnOrder: (json['turn_order'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
  final int? messageSeq; // 用於表情反應的序列號

  const ChatMessageMessage({
    required this.fromId,
    required this.fromName,
    required this.content,
    required this.isPrivate,
    required this.timestamp,
    this.messageSeq,
  }) : super('chat_message');

  factory ChatMessageMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessageMessage(
      fromId: json['from_id'] as String,
      fromName: json['from_name'] as String,
      content: json['content'] as String,
      isPrivate: json['is_private'] as bool,
      timestamp: json['timestamp'] as int,
      messageSeq: json['message_seq'] as int?,
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

// 新增的 ServerMessage 類型
class PlayerSelectedCharacterMessage extends ServerMessage {
  final String playerId;
  final String character;

  const PlayerSelectedCharacterMessage({
    required this.playerId,
    required this.character,
  }) : super('player_selected_character');

  factory PlayerSelectedCharacterMessage.fromJson(Map<String, dynamic> json) {
    return PlayerSelectedCharacterMessage(
      playerId: json['player_id'] as String,
      character: json['character'] as String,
    );
  }
}

class PlayerReadyMessage extends ServerMessage {
  final String playerId;

  const PlayerReadyMessage({
    required this.playerId,
  }) : super('player_ready');

  factory PlayerReadyMessage.fromJson(Map<String, dynamic> json) {
    return PlayerReadyMessage(
      playerId: json['player_id'] as String,
    );
  }
}

class PlayerUnreadyMessage extends ServerMessage {
  final String playerId;

  const PlayerUnreadyMessage({
    required this.playerId,
  }) : super('player_unready');

  factory PlayerUnreadyMessage.fromJson(Map<String, dynamic> json) {
    return PlayerUnreadyMessage(
      playerId: json['player_id'] as String,
    );
  }
}

class ChallengeEventMessage extends ServerMessage {
  final String attackerId;
  final String attackerName;
  final String targetId;
  final String targetName;
  final int damage;
  final bool countered;

  const ChallengeEventMessage({
    required this.attackerId,
    required this.attackerName,
    required this.targetId,
    required this.targetName,
    required this.damage,
    required this.countered,
  }) : super('challenge_event');

  factory ChallengeEventMessage.fromJson(Map<String, dynamic> json) {
    return ChallengeEventMessage(
      attackerId: json['attacker_id'] as String,
      attackerName: json['attacker_name'] as String,
      targetId: json['target_id'] as String,
      targetName: json['target_name'] as String,
      damage: json['damage'] as int,
      countered: json['countered'] as bool,
    );
  }
}

class CounterEventMessage extends ServerMessage {
  final String defenderId;
  final String defenderName;
  final int damageBlocked;

  const CounterEventMessage({
    required this.defenderId,
    required this.defenderName,
    required this.damageBlocked,
  }) : super('counter_event');

  factory CounterEventMessage.fromJson(Map<String, dynamic> json) {
    return CounterEventMessage(
      defenderId: json['defender_id'] as String,
      defenderName: json['defender_name'] as String,
      damageBlocked: json['damage_blocked'] as int,
    );
  }
}

class SkillUsedMessage extends ServerMessage {
  final String playerId;
  final String playerName;
  final String skillName;
  final String? targetId;
  final String? targetName;
  final String effectDescription;

  const SkillUsedMessage({
    required this.playerId,
    required this.playerName,
    required this.skillName,
    this.targetId,
    this.targetName,
    required this.effectDescription,
  }) : super('skill_used');

  factory SkillUsedMessage.fromJson(Map<String, dynamic> json) {
    return SkillUsedMessage(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      skillName: json['skill_name'] as String,
      targetId: json['target_id'] as String?,
      targetName: json['target_name'] as String?,
      effectDescription: json['effect_description'] as String,
    );
  }
}

class ReputationChangedMessage extends ServerMessage {
  final String playerId;
  final int newReputation;
  final int change;
  final String reason;

  const ReputationChangedMessage({
    required this.playerId,
    required this.newReputation,
    required this.change,
    required this.reason,
  }) : super('reputation_changed');

  factory ReputationChangedMessage.fromJson(Map<String, dynamic> json) {
    return ReputationChangedMessage(
      playerId: json['player_id'] as String,
      newReputation: json['new_reputation'] as int,
      change: json['change'] as int,
      reason: json['reason'] as String,
    );
  }
}

class GoldChangedMessage extends ServerMessage {
  final String playerId;
  final int newGold;
  final int change;
  final String reason;

  const GoldChangedMessage({
    required this.playerId,
    required this.newGold,
    required this.change,
    required this.reason,
  }) : super('gold_changed');

  factory GoldChangedMessage.fromJson(Map<String, dynamic> json) {
    return GoldChangedMessage(
      playerId: json['player_id'] as String,
      newGold: json['new_gold'] as int,
      change: json['change'] as int,
      reason: json['reason'] as String,
    );
  }
}

class CardUsedMessage extends ServerMessage {
  final String playerId;
  final String playerName;
  final String cardId;
  final String cardName;
  final String? targetId;
  final String? targetName;
  final String effectDescription;
  final int value;

  const CardUsedMessage({
    required this.playerId,
    required this.playerName,
    required this.cardId,
    required this.cardName,
    this.targetId,
    this.targetName,
    required this.effectDescription,
    required this.value,
  }) : super('card_used');

  factory CardUsedMessage.fromJson(Map<String, dynamic> json) {
    return CardUsedMessage(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      cardId: json['card_id'] as String,
      cardName: json['card_name'] as String,
      targetId: json['target_id'] as String?,
      targetName: json['target_name'] as String?,
      effectDescription: json['effect_description'] as String,
      value: json['value'] as int,
    );
  }
}

class CardDrawnMessage extends ServerMessage {
  final String cardId;
  final String cardName;
  final String cardType;
  final String description;
  final int cost;

  const CardDrawnMessage({
    required this.cardId,
    required this.cardName,
    required this.cardType,
    required this.description,
    required this.cost,
  }) : super('card_drawn');

  factory CardDrawnMessage.fromJson(Map<String, dynamic> json) {
    return CardDrawnMessage(
      cardId: json['card_id'] as String,
      cardName: json['card_name'] as String,
      cardType: json['card_type'] as String,
      description: json['description'] as String,
      cost: json['cost'] as int,
    );
  }
}

class HandUpdatedMessage extends ServerMessage {
  final List<Map<String, dynamic>> cards;

  const HandUpdatedMessage({
    required this.cards,
  }) : super('hand_updated');

  factory HandUpdatedMessage.fromJson(Map<String, dynamic> json) {
    return HandUpdatedMessage(
      cards: (json['cards'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

class PlayerHandCountChangedMessage extends ServerMessage {
  final String playerId;
  final int cardCount;

  const PlayerHandCountChangedMessage({
    required this.playerId,
    required this.cardCount,
  }) : super('player_hand_count_changed');

  factory PlayerHandCountChangedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerHandCountChangedMessage(
      playerId: json['player_id'] as String,
      cardCount: json['card_count'] as int,
    );
  }
}

class VoteReceivedMessage extends ServerMessage {
  final String playerId;
  final int votesCount;
  final int totalPlayers;

  const VoteReceivedMessage({
    required this.playerId,
    required this.votesCount,
    required this.totalPlayers,
  }) : super('vote_received');

  factory VoteReceivedMessage.fromJson(Map<String, dynamic> json) {
    return VoteReceivedMessage(
      playerId: json['player_id'] as String,
      votesCount: json['votes_count'] as int,
      totalPlayers: json['total_players'] as int,
    );
  }
}

class VoteResultMessage extends ServerMessage {
  final Map<String, dynamic> votes;
  final String winner;

  const VoteResultMessage({
    required this.votes,
    required this.winner,
  }) : super('vote_result');

  factory VoteResultMessage.fromJson(Map<String, dynamic> json) {
    return VoteResultMessage(
      votes: json['votes'] as Map<String, dynamic>,
      winner: json['winner'] as String,
    );
  }
}

class GameResultMessage extends ServerMessage {
  final String winnerFaction;
  final Map<String, dynamic> votes;
  final List<Map<String, dynamic>> rankings;

  const GameResultMessage({
    required this.winnerFaction,
    required this.votes,
    required this.rankings,
  }) : super('game_result');

  factory GameResultMessage.fromJson(Map<String, dynamic> json) {
    return GameResultMessage(
      winnerFaction: json['winner_faction'] as String,
      votes: json['votes'] as Map<String, dynamic>,
      rankings: (json['rankings'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

class PlayerPoliticalDeathMessage extends ServerMessage {
  final String playerId;
  final String playerName;

  const PlayerPoliticalDeathMessage({
    required this.playerId,
    required this.playerName,
  }) : super('player_political_death');

  factory PlayerPoliticalDeathMessage.fromJson(Map<String, dynamic> json) {
    return PlayerPoliticalDeathMessage(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
    );
  }
}

class SystemMessageMessage extends ServerMessage {
  final String content;
  final String messageType;

  const SystemMessageMessage({
    required this.content,
    required this.messageType,
  }) : super('system_message');

  factory SystemMessageMessage.fromJson(Map<String, dynamic> json) {
    return SystemMessageMessage(
      content: json['content'] as String,
      messageType: json['message_type'] as String,
    );
  }
}

class TimerUpdateMessage extends ServerMessage {
  final int remainingSecs;

  const TimerUpdateMessage({
    required this.remainingSecs,
  }) : super('timer_update');

  factory TimerUpdateMessage.fromJson(Map<String, dynamic> json) {
    return TimerUpdateMessage(
      remainingSecs: json['remaining_secs'] as int,
    );
  }
}

/// 回合變更消息（回合制）
class TurnChangedMessage extends ServerMessage {
  final String currentPlayerId;
  final String currentPlayerName;
  final int actionPoints;
  final List<String> turnOrder;

  const TurnChangedMessage({
    required this.currentPlayerId,
    required this.currentPlayerName,
    required this.actionPoints,
    this.turnOrder = const [],
  }) : super('turn_changed');

  factory TurnChangedMessage.fromJson(Map<String, dynamic> json) {
    return TurnChangedMessage(
      currentPlayerId: json['current_player_id'] as String,
      currentPlayerName: json['current_player_name'] as String,
      actionPoints: json['action_points'] as int,
      turnOrder: (json['turn_order'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// 同盟相關消息
class AllianceProposedMessage extends ServerMessage {
  final String allianceId;
  final String proposerId;
  final String proposerName;
  final String targetId;
  final String targetName;

  const AllianceProposedMessage({
    required this.allianceId,
    required this.proposerId,
    required this.proposerName,
    required this.targetId,
    required this.targetName,
  }) : super('alliance_proposed');

  factory AllianceProposedMessage.fromJson(Map<String, dynamic> json) {
    return AllianceProposedMessage(
      allianceId: json['alliance_id'] as String,
      proposerId: json['proposer_id'] as String,
      proposerName: json['proposer_name'] as String,
      targetId: json['target_id'] as String,
      targetName: json['target_name'] as String,
    );
  }
}

class AllianceAcceptedMessage extends ServerMessage {
  final String allianceId;
  final List<String> members;
  final List<String> memberNames;

  const AllianceAcceptedMessage({
    required this.allianceId,
    required this.members,
    required this.memberNames,
  }) : super('alliance_accepted');

  factory AllianceAcceptedMessage.fromJson(Map<String, dynamic> json) {
    return AllianceAcceptedMessage(
      allianceId: json['alliance_id'] as String,
      members: List<String>.from(json['members'] as List),
      memberNames: List<String>.from(json['member_names'] as List),
    );
  }
}

class AllianceRejectedMessage extends ServerMessage {
  final String proposerId;
  final String proposerName;
  final String rejecterId;
  final String rejecterName;

  const AllianceRejectedMessage({
    required this.proposerId,
    required this.proposerName,
    required this.rejecterId,
    required this.rejecterName,
  }) : super('alliance_rejected');

  factory AllianceRejectedMessage.fromJson(Map<String, dynamic> json) {
    return AllianceRejectedMessage(
      proposerId: json['proposer_id'] as String,
      proposerName: json['proposer_name'] as String,
      rejecterId: json['rejecter_id'] as String,
      rejecterName: json['rejecter_name'] as String,
    );
  }
}

class AllianceBetrayedMessage extends ServerMessage {
  final String allianceId;
  final String betrayerId;
  final String betrayerName;
  final String victimId;
  final String victimName;

  const AllianceBetrayedMessage({
    required this.allianceId,
    required this.betrayerId,
    required this.betrayerName,
    required this.victimId,
    required this.victimName,
  }) : super('alliance_betrayed');

  factory AllianceBetrayedMessage.fromJson(Map<String, dynamic> json) {
    return AllianceBetrayedMessage(
      allianceId: json['alliance_id'] as String,
      betrayerId: json['betrayer_id'] as String,
      betrayerName: json['betrayer_name'] as String,
      victimId: json['victim_id'] as String,
      victimName: json['victim_name'] as String,
    );
  }
}

// 表情反應消息
class MessageReactionMessage extends ServerMessage {
  final String fromId;
  final String fromName;
  final int targetMessageSeq;
  final String emoji;
  final int timestamp;

  const MessageReactionMessage({
    required this.fromId,
    required this.fromName,
    required this.targetMessageSeq,
    required this.emoji,
    required this.timestamp,
  }) : super('message_reaction');

  factory MessageReactionMessage.fromJson(Map<String, dynamic> json) {
    return MessageReactionMessage(
      fromId: json['from_id'] as String,
      fromName: json['from_name'] as String,
      targetMessageSeq: json['target_message_seq'] as int,
      emoji: json['emoji'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

// 房間更新消息
class RoomUpdateMessage extends ServerMessage {
  final Room room;
  final List<Player> players;
  final String updateType;
  final String? relatedPlayerId;

  const RoomUpdateMessage({
    required this.room,
    required this.players,
    required this.updateType,
    this.relatedPlayerId,
  }) : super('room_update');

  factory RoomUpdateMessage.fromJson(Map<String, dynamic> json) {
    return RoomUpdateMessage(
      room: Room.fromJson(json['room'] as Map<String, dynamic>),
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      updateType: json['update_type'] as String,
      relatedPlayerId: json['related_player_id'] as String?,
    );
  }
}

// 重連數據消息
class ReconnectDataMessage extends ServerMessage {
  final Room room;
  final List<Player> players;
  final Map<String, dynamic>? gameState;
  final int latestSeq;

  const ReconnectDataMessage({
    required this.room,
    required this.players,
    this.gameState,
    required this.latestSeq,
  }) : super('reconnect_data');

  factory ReconnectDataMessage.fromJson(Map<String, dynamic> json) {
    return ReconnectDataMessage(
      room: Room.fromJson(json['room'] as Map<String, dynamic>),
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      gameState: json['game_state'] as Map<String, dynamic>?,
      latestSeq: json['latest_seq'] as int,
    );
  }
}