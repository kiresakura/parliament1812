import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/game_service.dart';
import '../domain/models/card.dart';
import 'socket_provider.dart';

/// 多人遊戲階段
enum MultiplayerPhase {
  lobby,        // 大廳
  conspiracy,   // 密謀
  debate,       // 辯論
  voting,       // 投票
  result,       // 結算
}

/// 質詢記錄
class ChallengeRecord {
  final String attackerId;
  final String attackerName;
  final String targetId;
  final String targetName;
  final int damage;
  final bool countered;
  final String? cardUsed;
  final DateTime timestamp;

  const ChallengeRecord({
    required this.attackerId,
    required this.attackerName,
    required this.targetId,
    required this.targetName,
    required this.damage,
    this.countered = false,
    this.cardUsed,
    required this.timestamp,
  });

  factory ChallengeRecord.fromJson(Map<String, dynamic> json) {
    return ChallengeRecord(
      attackerId: json['attacker_id'] as String,
      attackerName: json['attacker_name'] as String,
      targetId: json['target_id'] as String,
      targetName: json['target_name'] as String,
      damage: json['damage'] as int,
      countered: json['countered'] as bool? ?? false,
      cardUsed: json['card_used'] as String?,
      timestamp: DateTime.now(),
    );
  }
}

/// 聊天訊息
class ChatMessage {
  final String fromId;
  final String fromName;
  final String content;
  final bool isPrivate;
  final bool isSystem;
  final DateTime timestamp;

  const ChatMessage({
    required this.fromId,
    required this.fromName,
    required this.content,
    this.isPrivate = false,
    this.isSystem = false,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      fromId: json['from_id'] as String? ?? 'system',
      fromName: json['from_name'] as String? ?? '系統',
      content: json['content'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }
}

/// 投票狀態
class VotingState {
  final String billId;
  final String billTitle;
  final String optionADesc;
  final String optionBDesc;
  final String optionCDesc;
  final Map<String, String> votes; // playerId -> choice (A/B/C)
  final int timeRemaining;

  const VotingState({
    required this.billId,
    required this.billTitle,
    required this.optionADesc,
    required this.optionBDesc,
    required this.optionCDesc,
    this.votes = const {},
    this.timeRemaining = 120,
  });

  VotingState copyWith({
    Map<String, String>? votes,
    int? timeRemaining,
  }) {
    return VotingState(
      billId: billId,
      billTitle: billTitle,
      optionADesc: optionADesc,
      optionBDesc: optionBDesc,
      optionCDesc: optionCDesc,
      votes: votes ?? this.votes,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }
}

/// 多人玩家狀態
class MultiplayerPlayer {
  final String id;
  final String name;
  final String? characterId;
  final String? characterName;
  final int reputation;
  final int influence;
  final int gold;
  final int defense;
  final bool isAlive;
  final bool isReady;
  final bool isHost;
  final bool isLocal;

  const MultiplayerPlayer({
    required this.id,
    required this.name,
    this.characterId,
    this.characterName,
    this.reputation = 50,
    this.influence = 0,
    this.gold = 0,
    this.defense = 0,
    this.isAlive = true,
    this.isReady = false,
    this.isHost = false,
    this.isLocal = false,
  });

  MultiplayerPlayer copyWith({
    String? characterId,
    String? characterName,
    int? reputation,
    int? influence,
    int? gold,
    int? defense,
    bool? isAlive,
    bool? isReady,
    bool? isHost,
  }) {
    return MultiplayerPlayer(
      id: id,
      name: name,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      reputation: reputation ?? this.reputation,
      influence: influence ?? this.influence,
      gold: gold ?? this.gold,
      defense: defense ?? this.defense,
      isAlive: isAlive ?? this.isAlive,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      isLocal: isLocal,
    );
  }

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json, {bool isLocal = false}) {
    return MultiplayerPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      characterId: json['character_id'] as String?,
      characterName: json['character_name'] as String?,
      reputation: json['reputation'] as int? ?? 50,
      influence: json['influence'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      defense: json['defense'] as int? ?? 0,
      isAlive: json['is_alive'] as bool? ?? true,
      isReady: json['is_ready'] as bool? ?? false,
      isHost: json['is_host'] as bool? ?? false,
      isLocal: isLocal,
    );
  }
}

/// 多人遊戲狀態
class MultiplayerGameState {
  /// 房間代碼
  final String? roomCode;

  /// 本地玩家 ID
  final String? localPlayerId;

  /// 所有玩家
  final List<MultiplayerPlayer> players;

  /// 當前階段
  final MultiplayerPhase phase;

  /// 當前回合
  final int round;

  /// 階段剩餘時間（秒）
  final int timeRemaining;

  /// 本地玩家手牌
  final List<GameCard> hand;

  /// 投票狀態
  final VotingState? votingState;

  /// 聊天記錄
  final List<ChatMessage> chatMessages;

  /// 質詢記錄（當前回合）
  final List<ChallengeRecord> challengeRecords;

  /// 是否已連線
  final bool isConnected;

  /// 錯誤訊息
  final String? errorMessage;

  const MultiplayerGameState({
    this.roomCode,
    this.localPlayerId,
    this.players = const [],
    this.phase = MultiplayerPhase.lobby,
    this.round = 0,
    this.timeRemaining = 0,
    this.hand = const [],
    this.votingState,
    this.chatMessages = const [],
    this.challengeRecords = const [],
    this.isConnected = false,
    this.errorMessage,
  });

  /// 本地玩家
  MultiplayerPlayer? get localPlayer {
    if (localPlayerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == localPlayerId);
    } catch (_) {
      return null;
    }
  }

  /// 是否為房主
  bool get isHost => localPlayer?.isHost ?? false;

  /// 是否可以開始遊戲
  bool get canStartGame {
    return isHost &&
        players.length >= 2 &&
        players.every((p) => p.isReady || p.isHost) &&
        players.every((p) => p.characterId != null);
  }

  /// 存活玩家數
  int get alivePlayerCount => players.where((p) => p.isAlive).length;

  MultiplayerGameState copyWith({
    String? roomCode,
    String? localPlayerId,
    List<MultiplayerPlayer>? players,
    MultiplayerPhase? phase,
    int? round,
    int? timeRemaining,
    List<GameCard>? hand,
    VotingState? votingState,
    List<ChatMessage>? chatMessages,
    List<ChallengeRecord>? challengeRecords,
    bool? isConnected,
    String? errorMessage,
  }) {
    return MultiplayerGameState(
      roomCode: roomCode ?? this.roomCode,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      round: round ?? this.round,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      hand: hand ?? this.hand,
      votingState: votingState ?? this.votingState,
      chatMessages: chatMessages ?? this.chatMessages,
      challengeRecords: challengeRecords ?? this.challengeRecords,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
    );
  }
}

/// 多人遊戲 Notifier
class MultiplayerGameNotifier extends StateNotifier<MultiplayerGameState> {
  final GameService _gameService;
  // ignore: unused_field - 保留供未來擴展使用
  final Ref _ref;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _timer;

  MultiplayerGameNotifier(this._gameService, this._ref)
      : super(const MultiplayerGameState()) {
    _setupListeners();
  }

  void _setupListeners() {
    // 連線成功
    _subscriptions.add(_gameService.onConnected.listen((data) {
      debugPrint('MultiplayerGame: Connected - $data');
      state = state.copyWith(isConnected: true);
    }));

    // 房間狀態
    _subscriptions.add(_gameService.onRoomState.listen((data) {
      debugPrint('MultiplayerGame: Room state - $data');
      _handleRoomState(data);
    }));

    // 玩家加入
    _subscriptions.add(_gameService.onPlayerJoined.listen((data) {
      debugPrint('MultiplayerGame: Player joined - $data');
      _handlePlayerJoined(data);
    }));

    // 玩家離開
    _subscriptions.add(_gameService.onPlayerLeft.listen((data) {
      debugPrint('MultiplayerGame: Player left - $data');
      _handlePlayerLeft(data);
    }));

    // 玩家準備
    _subscriptions.add(_gameService.onPlayerReady.listen((data) {
      debugPrint('MultiplayerGame: Player ready - $data');
      _handlePlayerReady(data);
    }));

    // 遊戲開始
    _subscriptions.add(_gameService.onGameStarted.listen((data) {
      debugPrint('MultiplayerGame: Game started - $data');
      _handleGameStarted(data);
    }));

    // 階段變更
    _subscriptions.add(_gameService.onPhaseChanged.listen((data) {
      debugPrint('MultiplayerGame: Phase changed - $data');
      _handlePhaseChanged(data);
    }));

    // 聊天訊息
    _subscriptions.add(_gameService.onChatMessage.listen((data) {
      debugPrint('MultiplayerGame: Chat message - $data');
      _handleChatMessage(data);
    }));

    // 質詢事件
    _subscriptions.add(_gameService.onChallengeEvent.listen((data) {
      debugPrint('MultiplayerGame: Challenge event - $data');
      _handleChallengeEvent(data);
    }));

    // 反駁事件
    _subscriptions.add(_gameService.onCounterEvent.listen((data) {
      debugPrint('MultiplayerGame: Counter event - $data');
      _handleCounterEvent(data);
    }));

    // 聲望變更
    _subscriptions.add(_gameService.onReputationChanged.listen((data) {
      debugPrint('MultiplayerGame: Reputation changed - $data');
      _handleReputationChanged(data);
    }));

    // 投票結果
    _subscriptions.add(_gameService.onVoteResult.listen((data) {
      debugPrint('MultiplayerGame: Vote result - $data');
      _handleVoteResult(data);
    }));

    // 遊戲結果
    _subscriptions.add(_gameService.onGameResult.listen((data) {
      debugPrint('MultiplayerGame: Game result - $data');
      _handleGameResult(data);
    }));

    // 錯誤
    _subscriptions.add(_gameService.onError.listen((data) {
      debugPrint('MultiplayerGame: Error - $data');
      state = state.copyWith(errorMessage: data['message'] as String?);
    }));
  }

  // ===== Event Handlers =====

  void _handleRoomState(Map<String, dynamic> data) {
    final roomData = data['room'] as Map<String, dynamic>?;
    final playersData = data['players'] as List<dynamic>?;

    if (roomData == null) return;

    final players = playersData?.map((p) {
      final playerMap = p as Map<String, dynamic>;
      return MultiplayerPlayer.fromJson(
        playerMap,
        isLocal: playerMap['id'] == state.localPlayerId,
      );
    }).toList() ?? [];

    state = state.copyWith(
      roomCode: roomData['code'] as String?,
      players: players,
    );
  }

  void _handlePlayerJoined(Map<String, dynamic> data) {
    final playerData = data['player'] as Map<String, dynamic>?;
    if (playerData == null) return;

    final newPlayer = MultiplayerPlayer.fromJson(playerData);
    if (!state.players.any((p) => p.id == newPlayer.id)) {
      state = state.copyWith(
        players: [...state.players, newPlayer],
      );
    }
  }

  void _handlePlayerLeft(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String?;
    final newHostId = data['new_host_id'] as String?;

    if (playerId == null) return;

    var players = state.players.where((p) => p.id != playerId).toList();

    // 更新新房主
    if (newHostId != null) {
      players = players.map((p) {
        if (p.id == newHostId) {
          return p.copyWith(isHost: true);
        }
        return p;
      }).toList();
    }

    state = state.copyWith(players: players);
  }

  void _handlePlayerReady(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String?;
    final isReady = data['is_ready'] as bool? ?? true;

    if (playerId == null) return;

    final players = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(isReady: isReady);
      }
      return p;
    }).toList();

    state = state.copyWith(players: players);
  }

  void _handleGameStarted(Map<String, dynamic> data) {
    final duration = data['duration_secs'] as int? ?? 120;

    state = state.copyWith(
      phase: MultiplayerPhase.conspiracy,
      round: 1,
      timeRemaining: duration,
      challengeRecords: [],
    );

    _startTimer(duration);
  }

  void _handlePhaseChanged(Map<String, dynamic> data) {
    final phaseStr = data['phase'] as String?;
    final duration = data['duration_secs'] as int? ?? 120;
    final round = data['round'] as int? ?? state.round;

    MultiplayerPhase phase;
    switch (phaseStr) {
      case 'conspiracy':
        phase = MultiplayerPhase.conspiracy;
        break;
      case 'debate':
        phase = MultiplayerPhase.debate;
        break;
      case 'voting':
        phase = MultiplayerPhase.voting;
        break;
      case 'result':
        phase = MultiplayerPhase.result;
        break;
      default:
        phase = MultiplayerPhase.lobby;
    }

    state = state.copyWith(
      phase: phase,
      round: round,
      timeRemaining: duration,
      challengeRecords: phase == MultiplayerPhase.debate ? [] : state.challengeRecords,
    );

    _startTimer(duration);
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    final message = ChatMessage.fromJson(data);
    state = state.copyWith(
      chatMessages: [...state.chatMessages, message].take(100).toList(),
    );
  }

  void _handleChallengeEvent(Map<String, dynamic> data) {
    final record = ChallengeRecord.fromJson(data);
    state = state.copyWith(
      challengeRecords: [...state.challengeRecords, record],
    );

    // 更新目標玩家的聲望
    _updatePlayerReputation(
      record.targetId,
      record.countered ? 0 : -record.damage,
    );
  }

  void _handleCounterEvent(Map<String, dynamic> data) {
    // 反駁成功，更新最後一個質詢記錄
    if (state.challengeRecords.isNotEmpty) {
      final records = List<ChallengeRecord>.from(state.challengeRecords);
      final last = records.last;
      records[records.length - 1] = ChallengeRecord(
        attackerId: last.attackerId,
        attackerName: last.attackerName,
        targetId: last.targetId,
        targetName: last.targetName,
        damage: last.damage,
        countered: true,
        cardUsed: last.cardUsed,
        timestamp: last.timestamp,
      );
      state = state.copyWith(challengeRecords: records);
    }
  }

  void _handleReputationChanged(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String?;
    final newReputation = data['new_reputation'] as int?;

    if (playerId == null || newReputation == null) return;

    _updatePlayerReputation(playerId, null, absolute: newReputation);
  }

  void _handleVoteResult(Map<String, dynamic> data) {
    // 處理投票結果
    debugPrint('Vote result: $data');
  }

  void _handleGameResult(Map<String, dynamic> data) {
    state = state.copyWith(phase: MultiplayerPhase.result);
    _timer?.cancel();
  }

  void _updatePlayerReputation(String playerId, int? change, {int? absolute}) {
    final players = state.players.map((p) {
      if (p.id == playerId) {
        final newRep = absolute ?? (p.reputation + (change ?? 0));
        return p.copyWith(reputation: newRep.clamp(0, 100));
      }
      return p;
    }).toList();

    state = state.copyWith(players: players);
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(timeRemaining: seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        timer.cancel();
      }
    });
  }

  // ===== Public Actions =====

  /// 創建房間
  Future<bool> createRoom(String playerName) async {
    try {
      final result = await _gameService.createRoom(playerName);
      if (result != null) {
        state = state.copyWith(
          roomCode: result.roomCode,
          localPlayerId: result.player?['id'] as String?,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('MultiplayerGame: Create room failed - $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// 加入房間
  Future<bool> joinRoom(String roomCode, String playerName) async {
    try {
      await _gameService.joinRoom(roomCode, playerName);
      state = state.copyWith(roomCode: roomCode);
      return true;
    } catch (e) {
      debugPrint('MultiplayerGame: Join room failed - $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// 選擇角色
  void selectCharacter(String characterId) {
    _gameService.selectCharacter(characterId);
  }

  /// 準備
  void setReady(bool ready) {
    _gameService.setReady(ready);
  }

  /// 開始遊戲
  void startGame() {
    if (state.canStartGame) {
      _gameService.startGame();
    }
  }

  /// 發送聊天
  void sendChat(String content) {
    _gameService.sendMessage(content);
  }

  /// 發送私訊
  void sendPrivateChat(String targetId, String content) {
    _gameService.sendPrivateMessage(targetId, content);
  }

  /// 質詢
  void challenge(String targetId) {
    _gameService.sendChallenge(targetId);
  }

  /// 反駁
  void counter() {
    _gameService.sendCounter();
  }

  /// 使用技能
  void useSkill({String? targetId}) {
    _gameService.sendSkill(targetId: targetId);
  }

  /// 投票
  void vote(String choice) {
    _gameService.vote(choice);
  }

  /// 使用卡牌
  void useCard(GameCard card, {String? targetId}) {
    // 發送卡牌使用訊息到伺服器
    // TODO: 實作卡牌使用的 WebSocket 訊息
    _gameService.sendMessage('use_card:${card.id}:${targetId ?? ""}');

    // 更新本地手牌
    final newHand = state.hand.where((c) => c.id != card.id).toList();
    state = state.copyWith(hand: newHand);
  }

  /// 離開房間
  void leaveRoom() {
    _gameService.leaveRoom();
    _timer?.cancel();
    state = const MultiplayerGameState();
  }

  /// 清除錯誤
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

// ===== Riverpod Providers =====

/// 多人遊戲 Provider
final multiplayerGameProvider =
    StateNotifierProvider<MultiplayerGameNotifier, MultiplayerGameState>((ref) {
  final gameService = ref.watch(gameServiceProvider);
  return MultiplayerGameNotifier(gameService, ref);
});

/// 當前房間代碼 Provider
final currentRoomCodeProvider = Provider<String?>((ref) {
  return ref.watch(multiplayerGameProvider).roomCode;
});

/// 多人遊戲玩家列表 Provider
final multiplayerPlayersProvider = Provider<List<MultiplayerPlayer>>((ref) {
  return ref.watch(multiplayerGameProvider).players;
});

/// 多人遊戲階段 Provider
final multiplayerPhaseProvider = Provider<MultiplayerPhase>((ref) {
  return ref.watch(multiplayerGameProvider).phase;
});

/// 多人遊戲剩餘時間 Provider
final multiplayerTimeRemainingProvider = Provider<int>((ref) {
  return ref.watch(multiplayerGameProvider).timeRemaining;
});

/// 本地玩家 Provider
final localPlayerProvider = Provider<MultiplayerPlayer?>((ref) {
  return ref.watch(multiplayerGameProvider).localPlayer;
});

/// 是否為房主 Provider
final isHostProvider = Provider<bool>((ref) {
  return ref.watch(multiplayerGameProvider).isHost;
});

/// 可以開始遊戲 Provider
final canStartGameProvider = Provider<bool>((ref) {
  return ref.watch(multiplayerGameProvider).canStartGame;
});

/// 聊天訊息列表 Provider
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(multiplayerGameProvider).chatMessages;
});

/// 質詢記錄 Provider
final challengeRecordsProvider = Provider<List<ChallengeRecord>>((ref) {
  return ref.watch(multiplayerGameProvider).challengeRecords;
});
