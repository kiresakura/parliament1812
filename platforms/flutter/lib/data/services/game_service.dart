import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';
import '../../core/constants/api_constants.dart';

/// 遊戲行動類型
enum ActionType {
  challenge,
  counter,
  skill,
  pass,
}

/// 遊戲行動
class GameAction {
  final ActionType type;
  final String? targetId;
  final Map<String, dynamic>? params;

  GameAction({
    required this.type,
    this.targetId,
    this.params,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (targetId != null) 'target_id': targetId,
        if (params != null) 'params': params,
      };
}

/// 房間資訊
class RoomInfo {
  final String roomId;
  final String roomCode;
  final Map<String, dynamic>? player;

  RoomInfo({
    required this.roomId,
    required this.roomCode,
    this.player,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>?;
    return RoomInfo(
      roomId: room?['id'] ?? json['room_id'] ?? '',
      roomCode: room?['code'] ?? json['room_code'] ?? '',
      player: json['player'] as Map<String, dynamic>?,
    );
  }
}

/// 伺服器訊息類型常數（對應 Rust 後端）
class ServerMessageTypes {
  static const String connected = 'connected';
  static const String error = 'error';
  static const String roomState = 'room_state';
  static const String playerJoined = 'player_joined';
  static const String playerLeft = 'player_left';
  static const String playerSelectedCharacter = 'player_selected_character';
  static const String playerReady = 'player_ready';
  static const String playerUnready = 'player_unready';
  static const String gameStarted = 'game_started';
  static const String phaseChanged = 'phase_changed';
  static const String chatMessage = 'chat_message';
  static const String challengeEvent = 'challenge_event';
  static const String counterEvent = 'counter_event';
  static const String skillUsed = 'skill_used';
  static const String reputationChanged = 'reputation_changed';
  static const String goldChanged = 'gold_changed';
  static const String voteReceived = 'vote_received';
  static const String voteResult = 'vote_result';
  static const String gameResult = 'game_result';
  static const String playerPoliticalDeath = 'player_political_death';
  static const String systemMessage = 'system_message';
  static const String pong = 'pong';
  static const String timerUpdate = 'timer_update';
  // 卡牌相關
  static const String cardUsed = 'card_used';
  static const String cardDrawn = 'card_drawn';
  static const String handUpdated = 'hand_updated';
  static const String playerHandCountChanged = 'player_hand_count_changed';
}

/// 遊戲服務
class GameService {
  final SocketService _socketService;

  // 事件流控制器
  final _connectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _roomStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerSelectedCharacterController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerReadyController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _phaseChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _challengeEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _counterEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _skillUsedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reputationChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _voteReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _voteResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _systemMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<Map<String, dynamic>>.broadcast();
  // 卡牌相關
  final _cardUsedController = StreamController<Map<String, dynamic>>.broadcast();
  final _cardDrawnController = StreamController<Map<String, dynamic>>.broadcast();
  final _handUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerHandCountChangedController = StreamController<Map<String, dynamic>>.broadcast();

  // 事件流
  Stream<Map<String, dynamic>> get onConnected => _connectedController.stream;
  Stream<Map<String, dynamic>> get onRoomState => _roomStateController.stream;
  Stream<Map<String, dynamic>> get onPlayerJoined => _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get onPlayerLeft => _playerLeftController.stream;
  Stream<Map<String, dynamic>> get onPlayerSelectedCharacter => _playerSelectedCharacterController.stream;
  Stream<Map<String, dynamic>> get onPlayerReady => _playerReadyController.stream;
  Stream<Map<String, dynamic>> get onGameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onPhaseChanged => _phaseChangedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onChallengeEvent => _challengeEventController.stream;
  Stream<Map<String, dynamic>> get onCounterEvent => _counterEventController.stream;
  Stream<Map<String, dynamic>> get onSkillUsed => _skillUsedController.stream;
  Stream<Map<String, dynamic>> get onReputationChanged => _reputationChangedController.stream;
  Stream<Map<String, dynamic>> get onVoteReceived => _voteReceivedController.stream;
  Stream<Map<String, dynamic>> get onVoteResult => _voteResultController.stream;
  Stream<Map<String, dynamic>> get onGameResult => _gameResultController.stream;
  Stream<Map<String, dynamic>> get onSystemMessage => _systemMessageController.stream;
  Stream<Map<String, dynamic>> get onError => _errorController.stream;
  // 卡牌相關事件流
  Stream<Map<String, dynamic>> get onCardUsed => _cardUsedController.stream;
  Stream<Map<String, dynamic>> get onCardDrawn => _cardDrawnController.stream;
  Stream<Map<String, dynamic>> get onHandUpdated => _handUpdatedController.stream;
  Stream<Map<String, dynamic>> get onPlayerHandCountChanged => _playerHandCountChangedController.stream;

  // 向後相容的別名
  Stream<Map<String, dynamic>> get onGameStateUpdate => _reputationChangedController.stream;
  Stream<Map<String, dynamic>> get onActionResult => _challengeEventController.stream;
  Stream<Map<String, dynamic>> get onMessageReceived => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onGameEnded => _gameResultController.stream;
  Stream<Map<String, dynamic>> get onPlayerReadyChanged => _playerReadyController.stream;

  GameService(this._socketService) {
    _setupEventListeners();
  }

  /// 設置事件監聽
  void _setupEventListeners() {
    _socketService.on(ServerMessageTypes.connected, (data) {
      debugPrint('Connected: $data');
      if (data is Map<String, dynamic>) {
        _connectedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.roomState, (data) {
      debugPrint('Room state: $data');
      if (data is Map<String, dynamic>) {
        _roomStateController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerJoined, (data) {
      debugPrint('Player joined: $data');
      if (data is Map<String, dynamic>) {
        _playerJoinedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerLeft, (data) {
      debugPrint('Player left: $data');
      if (data is Map<String, dynamic>) {
        _playerLeftController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerSelectedCharacter, (data) {
      debugPrint('Player selected character: $data');
      if (data is Map<String, dynamic>) {
        _playerSelectedCharacterController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerReady, (data) {
      debugPrint('Player ready: $data');
      if (data is Map<String, dynamic>) {
        _playerReadyController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerUnready, (data) {
      debugPrint('Player unready: $data');
      if (data is Map<String, dynamic>) {
        // 使用同一個 controller，但標記為 unready
        _playerReadyController.add({...data, 'ready': false});
      }
    });

    _socketService.on(ServerMessageTypes.gameStarted, (data) {
      debugPrint('Game started: $data');
      if (data is Map<String, dynamic>) {
        _gameStartedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.phaseChanged, (data) {
      debugPrint('Phase changed: $data');
      if (data is Map<String, dynamic>) {
        _phaseChangedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.chatMessage, (data) {
      debugPrint('Chat message: $data');
      if (data is Map<String, dynamic>) {
        _chatMessageController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.challengeEvent, (data) {
      debugPrint('Challenge event: $data');
      if (data is Map<String, dynamic>) {
        _challengeEventController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.counterEvent, (data) {
      debugPrint('Counter event: $data');
      if (data is Map<String, dynamic>) {
        _counterEventController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.skillUsed, (data) {
      debugPrint('Skill used: $data');
      if (data is Map<String, dynamic>) {
        _skillUsedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.reputationChanged, (data) {
      debugPrint('Reputation changed: $data');
      if (data is Map<String, dynamic>) {
        _reputationChangedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.voteReceived, (data) {
      debugPrint('Vote received: $data');
      if (data is Map<String, dynamic>) {
        _voteReceivedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.voteResult, (data) {
      debugPrint('Vote result: $data');
      if (data is Map<String, dynamic>) {
        _voteResultController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.gameResult, (data) {
      debugPrint('Game result: $data');
      if (data is Map<String, dynamic>) {
        _gameResultController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.systemMessage, (data) {
      debugPrint('System message: $data');
      if (data is Map<String, dynamic>) {
        _systemMessageController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.error, (data) {
      debugPrint('Error: $data');
      if (data is Map<String, dynamic>) {
        _errorController.add(data);
      }
    });

    // 卡牌相關事件
    _socketService.on(ServerMessageTypes.cardUsed, (data) {
      debugPrint('Card used: $data');
      if (data is Map<String, dynamic>) {
        _cardUsedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.cardDrawn, (data) {
      debugPrint('Card drawn: $data');
      if (data is Map<String, dynamic>) {
        _cardDrawnController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.handUpdated, (data) {
      debugPrint('Hand updated: $data');
      if (data is Map<String, dynamic>) {
        _handUpdatedController.add(data);
      }
    });

    _socketService.on(ServerMessageTypes.playerHandCountChanged, (data) {
      debugPrint('Player hand count changed: $data');
      if (data is Map<String, dynamic>) {
        _playerHandCountChangedController.add(data);
      }
    });
  }

  /// 連接到伺服器
  Future<bool> connect({String? token}) async {
    return await _socketService.connect(token: token);
  }

  /// 創建房間（透過 HTTP API）
  Future<RoomInfo?> createRoom(String playerName) async {
    try {
      final url = '${ApiConstants.baseUrl}/api/rooms';
      debugPrint('Creating room: $url');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(json.encode({'host_name': playerName}));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(body) as Map<String, dynamic>;
        debugPrint('Room created: $data');

        // 連接並加入房間
        if (!_socketService.isConnected) {
          await _socketService.connect();
        }

        final roomCode = data['code'] ?? data['room_code'] ?? '';
        if (roomCode.isNotEmpty) {
          _socketService.joinRoom(roomCode, playerName);
        }

        return RoomInfo.fromJson(data);
      } else {
        debugPrint('Create room failed: ${response.statusCode} - $body');
        return null;
      }
    } catch (e) {
      debugPrint('Create room error: $e');
      return null;
    }
  }

  /// 加入房間
  Future<Map<String, dynamic>?> joinRoom(String roomCode, String playerName) async {
    // 確保已連接
    if (!_socketService.isConnected) {
      final connected = await _socketService.connect();
      if (!connected) {
        debugPrint('Failed to connect');
        return null;
      }
    }

    // 發送並等待回應
    _socketService.joinRoom(roomCode, playerName);

    final completer = Completer<Map<String, dynamic>?>();

    void onRoomState(dynamic data) {
      if (data is Map<String, dynamic> && !completer.isCompleted) {
        completer.complete(data);
      }
    }

    void onError(dynamic data) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    _socketService.once(ServerMessageTypes.roomState, onRoomState);
    _socketService.once(ServerMessageTypes.error, onError);

    // 超時處理
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _socketService.off(ServerMessageTypes.roomState);
        _socketService.off(ServerMessageTypes.error);
        debugPrint('Join room timeout');
        return null;
      },
    );
  }

  /// 離開房間
  void leaveRoom() {
    _socketService.leaveRoom();
  }

  /// 選擇角色
  void selectCharacter(String character) {
    _socketService.selectCharacter(character);
  }

  /// 設置準備狀態
  void setReady(bool ready) {
    if (ready) {
      _socketService.ready();
    } else {
      _socketService.unready();
    }
  }

  /// 開始遊戲
  void startGame() {
    _socketService.startGame();
  }

  /// 發送質詢（攻擊）
  void sendChallenge(String targetId) {
    _socketService.challenge(targetId);
  }

  /// 發送質詢（別名，向後相容）
  void sendQuery(String targetId) {
    sendChallenge(targetId);
  }

  /// 發送反駁（防禦）
  void sendCounter() {
    _socketService.counter();
  }

  /// 發送反駁（別名，向後相容）
  void sendRebut() {
    sendCounter();
  }

  /// 使用技能
  void sendSkill({String? targetId}) {
    _socketService.useSkill(targetId: targetId);
  }

  /// 發送公開訊息
  void sendMessage(String content) {
    _socketService.sendChat(content);
  }

  /// 發送私訊
  void sendPrivateMessage(String targetId, String content) {
    _socketService.sendPrivateChat(targetId, content);
  }

  /// 投票
  void vote(String choice) {
    _socketService.vote(choice);
  }

  /// 使用卡牌
  void useCard(String cardId, {String? targetId}) {
    _socketService.send({
      'type': 'use_card',
      'card_id': cardId,
      'target_id': targetId,
    });
  }

  /// 抽牌
  void drawCard() {
    _socketService.send({
      'type': 'draw_card',
    });
  }

  /// 棄牌
  void discardCard(String cardId) {
    _socketService.send({
      'type': 'discard_card',
      'card_id': cardId,
    });
  }

  /// 是否已連接
  bool get isConnected => _socketService.isConnected;

  /// 清理資源
  void dispose() {
    _connectedController.close();
    _roomStateController.close();
    _playerJoinedController.close();
    _playerLeftController.close();
    _playerSelectedCharacterController.close();
    _playerReadyController.close();
    _gameStartedController.close();
    _phaseChangedController.close();
    _chatMessageController.close();
    _challengeEventController.close();
    _counterEventController.close();
    _skillUsedController.close();
    _reputationChangedController.close();
    _voteReceivedController.close();
    _voteResultController.close();
    _gameResultController.close();
    _systemMessageController.close();
    _errorController.close();
    // 卡牌相關
    _cardUsedController.close();
    _cardDrawnController.close();
    _handUpdatedController.close();
    _playerHandCountChangedController.close();
  }
}
