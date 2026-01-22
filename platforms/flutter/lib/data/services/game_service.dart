import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';

/// 遊戲行動類型
enum ActionType {
  query,
  rebut,
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
        if (targetId != null) 'targetId': targetId,
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
    return RoomInfo(
      roomId: json['roomId'] ?? '',
      roomCode: json['roomCode'] ?? '',
      player: json['player'] as Map<String, dynamic>?,
    );
  }
}

/// 遊戲服務
class GameService {
  final SocketService _socketService;

  // 事件流控制器
  final _roomCreatedController = StreamController<RoomInfo>.broadcast();
  final _roomJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerReadyChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _phaseChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStateUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _actionResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _voteReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameEndedController = StreamController<Map<String, dynamic>>.broadcast();

  // 事件流
  Stream<RoomInfo> get onRoomCreated => _roomCreatedController.stream;
  Stream<Map<String, dynamic>> get onRoomJoined => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get onPlayerJoined => _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get onPlayerLeft => _playerLeftController.stream;
  Stream<Map<String, dynamic>> get onPlayerReadyChanged => _playerReadyChangedController.stream;
  Stream<Map<String, dynamic>> get onGameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onPhaseChanged => _phaseChangedController.stream;
  Stream<Map<String, dynamic>> get onGameStateUpdate => _gameStateUpdateController.stream;
  Stream<Map<String, dynamic>> get onActionResult => _actionResultController.stream;
  Stream<Map<String, dynamic>> get onMessageReceived => _messageReceivedController.stream;
  Stream<Map<String, dynamic>> get onVoteReceived => _voteReceivedController.stream;
  Stream<Map<String, dynamic>> get onGameEnded => _gameEndedController.stream;

  GameService(this._socketService) {
    _setupEventListeners();
  }

  /// 設置事件監聽
  void _setupEventListeners() {
    _socketService.on(SocketEvents.roomCreated, (data) {
      debugPrint('Room created: $data');
      if (data is Map<String, dynamic>) {
        _roomCreatedController.add(RoomInfo.fromJson(data));
      }
    });

    _socketService.on(SocketEvents.roomJoined, (data) {
      debugPrint('Room joined: $data');
      if (data is Map<String, dynamic>) {
        _roomJoinedController.add(data);
      }
    });

    _socketService.on(SocketEvents.playerJoined, (data) {
      debugPrint('Player joined: $data');
      if (data is Map<String, dynamic>) {
        _playerJoinedController.add(data);
      }
    });

    _socketService.on(SocketEvents.playerLeft, (data) {
      debugPrint('Player left: $data');
      if (data is Map<String, dynamic>) {
        _playerLeftController.add(data);
      }
    });

    _socketService.on(SocketEvents.playerReadyChanged, (data) {
      debugPrint('Player ready changed: $data');
      if (data is Map<String, dynamic>) {
        _playerReadyChangedController.add(data);
      }
    });

    _socketService.on(SocketEvents.gameStarted, (data) {
      debugPrint('Game started: $data');
      if (data is Map<String, dynamic>) {
        _gameStartedController.add(data);
      }
    });

    _socketService.on(SocketEvents.phaseChanged, (data) {
      debugPrint('Phase changed: $data');
      if (data is Map<String, dynamic>) {
        _phaseChangedController.add(data);
      }
    });

    _socketService.on(SocketEvents.gameStateUpdate, (data) {
      // debugPrint('Game state update: $data'); // 太頻繁，不打印
      if (data is Map<String, dynamic>) {
        _gameStateUpdateController.add(data);
      }
    });

    _socketService.on(SocketEvents.actionResult, (data) {
      debugPrint('Action result: $data');
      if (data is Map<String, dynamic>) {
        _actionResultController.add(data);
      }
    });

    _socketService.on(SocketEvents.messageReceived, (data) {
      debugPrint('Message received: $data');
      if (data is Map<String, dynamic>) {
        _messageReceivedController.add(data);
      }
    });

    _socketService.on(SocketEvents.voteReceived, (data) {
      debugPrint('Vote received: $data');
      if (data is Map<String, dynamic>) {
        _voteReceivedController.add(data);
      }
    });

    _socketService.on(SocketEvents.gameEnded, (data) {
      debugPrint('Game ended: $data');
      if (data is Map<String, dynamic>) {
        _gameEndedController.add(data);
      }
    });
  }

  /// 創建房間
  Future<RoomInfo?> createRoom(String playerName) async {
    // 確保已連接
    if (!_socketService.isConnected) {
      final connected = await _socketService.connect(playerName: playerName);
      if (!connected) {
        debugPrint('Failed to connect');
        return null;
      }
    }

    final completer = Completer<RoomInfo?>();

    void onRoomCreated(dynamic data) {
      debugPrint('Create room callback: $data');
      if (data is Map<String, dynamic> && !completer.isCompleted) {
        completer.complete(RoomInfo.fromJson(data));
      }
    }

    void onError(dynamic data) {
      debugPrint('Create room error: $data');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    _socketService.once(SocketEvents.roomCreated, onRoomCreated);
    _socketService.once(SocketEvents.error, onError);

    _socketService.emit(SocketEvents.createRoom, {'playerName': playerName});

    // 超時處理
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _socketService.off(SocketEvents.roomCreated, onRoomCreated);
        _socketService.off(SocketEvents.error, onError);
        debugPrint('Create room timeout');
        return null;
      },
    );
  }

  /// 加入房間
  Future<Map<String, dynamic>?> joinRoom(String roomCode, String playerName) async {
    // 確保已連接
    if (!_socketService.isConnected) {
      final connected = await _socketService.connect(playerName: playerName);
      if (!connected) {
        debugPrint('Failed to connect');
        return null;
      }
    }

    final completer = Completer<Map<String, dynamic>?>();

    void onRoomJoined(dynamic data) {
      debugPrint('Join room callback: $data');
      if (data is Map<String, dynamic> && !completer.isCompleted) {
        completer.complete(data);
      }
    }

    void onError(dynamic data) {
      debugPrint('Join room error: $data');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    _socketService.once(SocketEvents.roomJoined, onRoomJoined);
    _socketService.once(SocketEvents.error, onError);

    _socketService.emit(SocketEvents.joinRoom, {
      'roomCode': roomCode,
      'playerName': playerName,
    });

    // 超時處理
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _socketService.off(SocketEvents.roomJoined, onRoomJoined);
        _socketService.off(SocketEvents.error, onError);
        debugPrint('Join room timeout');
        return null;
      },
    );
  }

  /// 離開房間
  void leaveRoom() {
    _socketService.emit(SocketEvents.leaveRoom);
  }

  /// 設置準備狀態
  void setReady(bool ready) {
    _socketService.emit(SocketEvents.playerReady, {'ready': ready});
  }

  /// 開始遊戲
  void startGame() {
    _socketService.emit(SocketEvents.startGame);
  }

  /// 發送遊戲行動
  void sendAction(GameAction action) {
    _socketService.emit(SocketEvents.gameAction, action.toJson());
  }

  /// 發送質詢
  void sendQuery(String targetId) {
    sendAction(GameAction(type: ActionType.query, targetId: targetId));
  }

  /// 發送反駁
  void sendRebut() {
    sendAction(GameAction(type: ActionType.rebut));
  }

  /// 發送技能
  void sendSkill({String? targetId, Map<String, dynamic>? params}) {
    sendAction(GameAction(type: ActionType.skill, targetId: targetId, params: params));
  }

  /// 跳過
  void sendPass() {
    sendAction(GameAction(type: ActionType.pass));
  }

  /// 發送訊息
  void sendMessage(String content, {String? targetId, String? type}) {
    _socketService.emit(SocketEvents.sendMessage, {
      'content': content,
      if (targetId != null) 'targetId': targetId,
      if (type != null) 'type': type,
    });
  }

  /// 投票
  void vote(String optionId) {
    _socketService.emit(SocketEvents.vote, {'optionId': optionId});
  }

  /// 清理資源
  void dispose() {
    _roomCreatedController.close();
    _roomJoinedController.close();
    _playerJoinedController.close();
    _playerLeftController.close();
    _playerReadyChangedController.close();
    _gameStartedController.close();
    _phaseChangedController.close();
    _gameStateUpdateController.close();
    _actionResultController.close();
    _messageReceivedController.close();
    _voteReceivedController.close();
    _gameEndedController.close();
  }
}
