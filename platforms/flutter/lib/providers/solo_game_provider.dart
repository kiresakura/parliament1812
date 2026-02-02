// 1812 國會風雲 - 單人遊戲狀態管理
//
// 使用 Riverpod 管理單人遊戲的所有狀態，包括：
// - 遊戲房間狀態
// - 人類玩家與 AI 玩家
// - 遊戲階段與計時
// - 遊戲事件日誌

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../domain/models/models.dart';
import '../domain/services/services.dart';

// ============================================================
// 遊戲事件類型
// ============================================================

/// 遊戲事件類型
enum GameEventType {
  gameStarted,       // 遊戲開始
  phaseChanged,      // 階段變更
  playerAction,      // 玩家動作
  aiAction,          // AI 動作
  damage,            // 造成傷害
  heal,              // 恢復聲望
  allianceFormed,    // 結盟
  allianceBroken,    // 背叛
  skillUsed,         // 使用技能
  voteSubmitted,     // 投票
  voteResult,        // 投票結果
  playerEliminated,  // 玩家出局
  gameEnded,         // 遊戲結束
  systemMessage,     // 系統訊息
}

/// 遊戲事件
class GameEvent {
  /// 事件 ID
  final String id;

  /// 事件類型
  final GameEventType type;

  /// 事件時間
  final DateTime timestamp;

  /// 事件描述
  final String message;

  /// 相關玩家 ID
  final String? playerId;

  /// 目標玩家 ID
  final String? targetId;

  /// 額外資料
  final Map<String, dynamic> data;

  const GameEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.message,
    this.playerId,
    this.targetId,
    this.data = const {},
  });

  factory GameEvent.create({
    required GameEventType type,
    required String message,
    String? playerId,
    String? targetId,
    Map<String, dynamic> data = const {},
  }) {
    return GameEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      message: message,
      playerId: playerId,
      targetId: targetId,
      data: data,
    );
  }
}

// ============================================================
// 單人遊戲狀態
// ============================================================

/// 單人遊戲狀態
class SoloGameState {
  /// 遊戲房間
  final SoloGameRoom? gameRoom;

  /// 當前階段
  final GamePhase currentPhase;

  /// 階段剩餘時間（秒）
  final int phaseTimeRemaining;

  /// 人類玩家
  final Player? humanPlayer;

  /// AI 玩家列表
  final List<AIPlayer> aiPlayers;

  /// 遊戲事件日誌
  final List<GameEvent> gameLog;

  /// 遊戲是否結束
  final bool isGameOver;

  /// 獲勝者（角色 ID 或陣營名稱）
  final String? winner;

  /// 當前回合
  final int currentRound;

  /// 總回合數
  final int totalRounds;

  /// 是否暫停
  final bool isPaused;

  /// 當前發言者 ID
  final String? currentSpeakerId;

  /// 發言順序
  final List<String> speakingOrder;

  /// 當前議案
  final Bill? currentBill;

  /// 投票記錄
  final Map<String, String> votes;

  /// 是否正在處理 AI 回合
  final bool isProcessingAI;

  /// 錯誤訊息
  final String? error;

  // ===== 回合制辯論狀態 =====

  /// 當前辯論回合（1 開始）
  final int debateRound;

  /// 辯論最大回合數
  final int maxDebateRounds;

  /// 當前回合中的發言順序索引
  final int debateTurnIndex;

  /// 當前回合剩餘時間（秒）
  final int turnTimeRemaining;

  /// 當前玩家是否已行動
  final bool hasActedThisTurn;

  // ===== 突發事件狀態 =====

  /// 當前觸發的突發事件
  final RandomEvent? currentRandomEvent;

  /// 是否正在等待玩家對事件做出選擇
  final bool awaitingEventChoice;

  /// 受事件影響的玩家 ID（如報紙號外的目標）
  final String? eventTargetPlayerId;

  /// 玩家對法國威脅事件的選擇（playerId -> choiceId）
  final Map<String, String> frenchThreatChoices;

  /// 特殊效果狀態（如皇室關注的發言權重加成）
  final Map<String, double> speechWeightModifiers;

  /// 是否為人類玩家的回合
  bool get isHumanTurn {
    if (currentPhase != GamePhase.debate) return false;
    if (speakingOrder.isEmpty) return false;
    if (debateTurnIndex >= speakingOrder.length) return false;
    return speakingOrder[debateTurnIndex] == humanPlayer?.id;
  }

  /// 當前行動者 ID
  String? get currentActorId {
    if (speakingOrder.isEmpty || debateTurnIndex >= speakingOrder.length) {
      return null;
    }
    return speakingOrder[debateTurnIndex];
  }

  /// 當前行動者
  Player? get currentActor {
    final actorId = currentActorId;
    if (actorId == null) return null;
    if (actorId == humanPlayer?.id) return humanPlayer;
    return aiPlayers
        .where((ai) => ai.id == actorId)
        .map((ai) => ai.player)
        .firstOrNull;
  }

  const SoloGameState({
    this.gameRoom,
    this.currentPhase = GamePhase.waiting,
    this.phaseTimeRemaining = 0,
    this.humanPlayer,
    this.aiPlayers = const [],
    this.gameLog = const [],
    this.isGameOver = false,
    this.winner,
    this.currentRound = 0,
    this.totalRounds = 3,
    this.isPaused = false,
    this.currentSpeakerId,
    this.speakingOrder = const [],
    this.currentBill,
    this.votes = const {},
    this.isProcessingAI = false,
    this.error,
    // 回合制辯論
    this.debateRound = 0,
    this.maxDebateRounds = 3,
    this.debateTurnIndex = 0,
    this.turnTimeRemaining = 0,
    this.hasActedThisTurn = false,
    // 突發事件
    this.currentRandomEvent,
    this.awaitingEventChoice = false,
    this.eventTargetPlayerId,
    this.frenchThreatChoices = const {},
    this.speechWeightModifiers = const {},
  });

  /// 初始狀態
  static const SoloGameState initial = SoloGameState();

  /// 是否遊戲進行中
  bool get isGameInProgress =>
      gameRoom != null &&
      currentPhase != GamePhase.waiting &&
      !isGameOver;

  /// 所有玩家（人類 + AI）
  List<Player> get allPlayers {
    if (humanPlayer == null) return [];
    return [humanPlayer!, ...aiPlayers.map((ai) => ai.player)];
  }

  /// 存活玩家數
  int get alivePlayerCount => allPlayers.where((p) => p.isAlive).length;

  /// 人類玩家是否存活
  bool get isHumanAlive => humanPlayer?.isAlive ?? false;

  /// 當前階段名稱
  String get phaseName {
    switch (currentPhase) {
      case GamePhase.waiting:
        return '準備中';
      case GamePhase.preparing:
        return '準備階段';
      case GamePhase.conspiracy:
        return '密謀階段';
      case GamePhase.debate:
        return '辯論階段';
      case GamePhase.event:
        return '突發事件';
      case GamePhase.voting:
        return '投票階段';
      case GamePhase.result:
        return '結算階段';
    }
  }

  /// 格式化剩餘時間
  String get formattedTimeRemaining {
    final minutes = phaseTimeRemaining ~/ 60;
    final seconds = phaseTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  SoloGameState copyWith({
    SoloGameRoom? gameRoom,
    GamePhase? currentPhase,
    int? phaseTimeRemaining,
    Player? humanPlayer,
    List<AIPlayer>? aiPlayers,
    List<GameEvent>? gameLog,
    bool? isGameOver,
    String? winner,
    int? currentRound,
    int? totalRounds,
    bool? isPaused,
    String? currentSpeakerId,
    List<String>? speakingOrder,
    Bill? currentBill,
    Map<String, String>? votes,
    bool? isProcessingAI,
    String? error,
    // 回合制辯論
    int? debateRound,
    int? maxDebateRounds,
    int? debateTurnIndex,
    int? turnTimeRemaining,
    bool? hasActedThisTurn,
    // 突發事件
    RandomEvent? currentRandomEvent,
    bool? awaitingEventChoice,
    String? eventTargetPlayerId,
    Map<String, String>? frenchThreatChoices,
    Map<String, double>? speechWeightModifiers,
    bool clearRandomEvent = false,
  }) {
    return SoloGameState(
      gameRoom: gameRoom ?? this.gameRoom,
      currentPhase: currentPhase ?? this.currentPhase,
      phaseTimeRemaining: phaseTimeRemaining ?? this.phaseTimeRemaining,
      humanPlayer: humanPlayer ?? this.humanPlayer,
      aiPlayers: aiPlayers ?? this.aiPlayers,
      gameLog: gameLog ?? this.gameLog,
      isGameOver: isGameOver ?? this.isGameOver,
      winner: winner ?? this.winner,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isPaused: isPaused ?? this.isPaused,
      currentSpeakerId: currentSpeakerId ?? this.currentSpeakerId,
      speakingOrder: speakingOrder ?? this.speakingOrder,
      currentBill: currentBill ?? this.currentBill,
      votes: votes ?? this.votes,
      isProcessingAI: isProcessingAI ?? this.isProcessingAI,
      error: error,
      // 回合制辯論
      debateRound: debateRound ?? this.debateRound,
      maxDebateRounds: maxDebateRounds ?? this.maxDebateRounds,
      debateTurnIndex: debateTurnIndex ?? this.debateTurnIndex,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
      hasActedThisTurn: hasActedThisTurn ?? this.hasActedThisTurn,
      // 突發事件
      currentRandomEvent: clearRandomEvent ? null : (currentRandomEvent ?? this.currentRandomEvent),
      awaitingEventChoice: awaitingEventChoice ?? this.awaitingEventChoice,
      eventTargetPlayerId: eventTargetPlayerId ?? this.eventTargetPlayerId,
      frenchThreatChoices: frenchThreatChoices ?? this.frenchThreatChoices,
      speechWeightModifiers: speechWeightModifiers ?? this.speechWeightModifiers,
    );
  }
}

// ============================================================
// 單人遊戲 Notifier
// ============================================================

/// 單人遊戲狀態管理器
class SoloGameNotifier extends StateNotifier<SoloGameState> {
  /// AI 決策引擎
  final AIDecisionEngine _aiEngine;

  /// 突發事件系統
  final RandomEventSystem _eventSystem;

  /// 隨機數生成器
  final Random _random;

  /// 階段計時器
  Timer? _phaseTimer;

  /// 回合計時器（辯論階段）
  Timer? _turnTimer;

  /// AI 處理基礎延遲（毫秒）- 讓 AI 行動有間隔
  /// 實際延遲會根據難度調整
  static const int _baseAIActionDelay = 800;

  SoloGameNotifier({
    AIDecisionEngine? aiEngine,
    RandomEventSystem? eventSystem,
    Random? random,
  })  : _aiEngine = aiEngine ?? AIDecisionEngine(enableDebugLogging: kDebugMode),
        _eventSystem = eventSystem ?? RandomEventSystem(),
        _random = random ?? Random(),
        super(SoloGameState.initial);

  // ============================================================
  // 遊戲生命週期
  // ============================================================

  /// 開始新遊戲
  ///
  /// [difficulty] - AI 難度
  /// [humanCharacterId] - 人類玩家選擇的角色 ID
  /// [humanPlayerName] - 人類玩家名稱
  Future<bool> startNewGame({
    required AIDifficulty difficulty,
    required String humanCharacterId,
    String humanPlayerName = '玩家',
  }) async {
    try {
      // 1. 獲取人類選擇的角色
      final humanRole = RoleDatabase.getRoleById(humanCharacterId);
      if (humanRole == null) {
        state = state.copyWith(error: '無效的角色選擇');
        return false;
      }

      // 2. 創建人類玩家
      final humanPlayer = Player(
        id: 'human_player',
        name: humanPlayerName,
        roleId: humanCharacterId,
        reputation: humanRole.initialReputation,
        gold: humanRole.initialGold,
        intel: humanRole.initialIntel,
        favor: humanRole.initialFavor,
        defense: humanRole.baseDefense,
        isReady: true,
        isHost: true,
      );

      // 3. 分配 AI 角色（排除人類選的）- 使用全部 17 個角色
      final availableRoles = RoleDatabase.allRoles
          .where((r) => r.id != humanCharacterId)
          .toList();
      availableRoles.shuffle(_random);

      // 4. 創建 AI 玩家（3 個 AI）
      final aiPlayers = <AIPlayer>[];
      for (int i = 0; i < 3 && i < availableRoles.length; i++) {
        final role = availableRoles[i];
        final aiPlayer = AIPlayer.createRandom(
          id: 'ai_player_$i',
          name: role.name,
          difficulty: difficulty,
          avatarIndex: i,
          roleId: role.id,
          reputation: role.initialReputation,
        ).copyWith(
          player: Player(
            id: 'ai_player_$i',
            name: role.name,
            roleId: role.id,
            reputation: role.initialReputation,
            gold: role.initialGold,
            intel: role.initialIntel,
            favor: role.initialFavor,
            defense: role.baseDefense,
            isReady: true,
          ),
        );
        aiPlayers.add(aiPlayer);
      }

      // 5. 設置玩家角色映射給 AI 引擎
      final playerRoles = <String, Role?>{
        humanPlayer.id: humanRole,
        for (final ai in aiPlayers)
          ai.id: ai.roleId != null ? RoleDatabase.getRoleById(ai.roleId!) : null,
      };
      _aiEngine.setPlayerRoles(playerRoles);

      // 6. 創建遊戲房間
      final gameRoom = SoloGameRoom(
        id: 'solo_${DateTime.now().millisecondsSinceEpoch}',
        modeType: SoloModeType.practice,
        difficulty: difficulty,
        humanPlayer: humanPlayer,
        aiPlayers: aiPlayers,
        currentBill: BillDatabase.mvpBill,
      );

      // 7. 初始化遊戲狀態
      state = SoloGameState(
        gameRoom: gameRoom,
        currentPhase: GamePhase.preparing,
        phaseTimeRemaining: GameConstants.preparingDuration,
        humanPlayer: humanPlayer,
        aiPlayers: aiPlayers,
        currentRound: 1,
        totalRounds: 3,
        currentBill: BillDatabase.mvpBill,
        gameLog: [
          GameEvent.create(
            type: GameEventType.gameStarted,
            message: '遊戲開始！你扮演 ${humanRole.name}',
          ),
        ],
      );

      // 8. 開始計時
      _startPhaseTimer();

      _addGameEvent(
        GameEventType.phaseChanged,
        '進入準備階段，請熟悉你的角色',
      );

      return true;
    } catch (e) {
      debugPrint('SoloGameNotifier: Error starting game: $e');
      state = state.copyWith(error: '開始遊戲失敗: $e');
      return false;
    }
  }

  /// 結束遊戲
  void endGame({String? winner}) {
    _stopPhaseTimer();

    final winnerName = winner ?? _determineWinner();

    state = state.copyWith(
      isGameOver: true,
      winner: winnerName,
      currentPhase: GamePhase.result,
    );

    _addGameEvent(
      GameEventType.gameEnded,
      winnerName != null ? '遊戲結束！$winnerName 獲勝' : '遊戲結束！',
    );
  }

  /// 重置遊戲
  void resetGame() {
    _stopPhaseTimer();
    state = SoloGameState.initial;
  }

  // ============================================================
  // 階段管理
  // ============================================================

  /// 進入下一階段
  Future<void> advancePhase() async {
    // 辯論階段結束後，嘗試觸發突發事件
    if (state.currentPhase == GamePhase.debate) {
      final triggeredEvent = _checkForRandomEvent();
      if (triggeredEvent != null) {
        await _startEventPhase(triggeredEvent);
        return;
      }
    }

    final nextPhase = _getNextPhase(state.currentPhase);

    // 如果是結算階段，結束遊戲
    if (nextPhase == GamePhase.result) {
      await _processVotingResult(clearVotes: false);
      endGame();
      return;
    }

    // 生成發言順序
    final speakingOrder = _generateSpeakingOrder();

    // 更新階段
    state = state.copyWith(
      currentPhase: nextPhase,
      phaseTimeRemaining: _getPhaseDuration(nextPhase),
      currentSpeakerId: speakingOrder.isNotEmpty ? speakingOrder[0] : null,
      speakingOrder: speakingOrder,
    );

    _addGameEvent(
      GameEventType.phaseChanged,
      '進入${_getPhaseName(nextPhase)}',
    );

    // 辯論階段使用回合制
    if (nextPhase == GamePhase.debate) {
      _startDebatePhase();
      return;
    }

    // 其他階段使用計時器
    _startPhaseTimer();

    // 在密謀階段觸發 AI 行動
    if (nextPhase == GamePhase.conspiracy) {
      Future.delayed(const Duration(seconds: 2), () {
        executeAITurn();
      });
    }
  }

  /// 開始辯論階段（回合制）
  void _startDebatePhase() {
    _stopPhaseTimer();

    // 初始化辯論狀態
    state = state.copyWith(
      debateRound: 1,
      maxDebateRounds: GameConstants.debateMaxRounds,
      debateTurnIndex: 0,
      turnTimeRemaining: GameConstants.debateTurnTimeout,
      hasActedThisTurn: false,
    );

    _addGameEvent(
      GameEventType.systemMessage,
      '辯論開始！第 1 回合，共 ${GameConstants.debateMaxRounds} 回合',
    );

    // 開始回合計時
    _startTurnTimer();

    // 如果第一個是 AI，執行 AI 回合
    _checkAndExecuteCurrentTurn();
  }

  /// 檢查並執行當前回合
  void _checkAndExecuteCurrentTurn() {
    if (state.currentPhase != GamePhase.debate) return;
    if (state.isGameOver) return;

    final currentActorId = state.currentActorId;
    if (currentActorId == null) {
      // 所有人都行動完畢，進入下一回合
      _advanceDebateRound();
      return;
    }

    // 更新當前發言者
    state = state.copyWith(currentSpeakerId: currentActorId);

    if (currentActorId != state.humanPlayer?.id) {
      // AI 的回合
      _executeCurrentAIDebateTurn();
    }
    // 如果是人類的回合，等待玩家操作
  }

  /// 執行當前 AI 的辯論回合
  Future<void> _executeCurrentAIDebateTurn() async {
    final currentActorId = state.currentActorId;
    if (currentActorId == null) return;

    final ai = state.aiPlayers.firstWhere(
      (a) => a.id == currentActorId,
      orElse: () => state.aiPlayers.first,
    );

    if (!ai.isAlive) {
      // AI 已死亡，跳過
      _advanceDebateTurn();
      return;
    }

    state = state.copyWith(isProcessingAI: true);

    try {
      // AI 思考延遲（2 秒）
      await Future.delayed(const Duration(seconds: 2));

      // 創建模擬的 GameState 給 AI 引擎
      final gameState = _createGameStateForAI();

      // AI 決策
      final decision = _aiEngine.decide(ai, gameState);

      // 執行 AI 決策
      await _executeAIDecision(ai, decision);

      // AI 行動完成，進入下一回合
      _advanceDebateTurn();
    } catch (e) {
      debugPrint('SoloGameNotifier: Error in AI debate turn: $e');
      _advanceDebateTurn();
    } finally {
      state = state.copyWith(isProcessingAI: false);
    }
  }

  /// 進入下一個玩家的回合
  void _advanceDebateTurn() {
    if (state.currentPhase != GamePhase.debate) return;

    final nextTurnIndex = state.debateTurnIndex + 1;

    if (nextTurnIndex >= state.speakingOrder.length) {
      // 當前回合所有人都行動完畢
      _advanceDebateRound();
      return;
    }

    // 更新到下一個玩家
    state = state.copyWith(
      debateTurnIndex: nextTurnIndex,
      turnTimeRemaining: GameConstants.debateTurnTimeout,
      hasActedThisTurn: false,
    );

    _addGameEvent(
      GameEventType.systemMessage,
      '輪到 ${state.currentActor?.name ?? "下一位"} 行動',
    );

    // 重置回合計時器
    _startTurnTimer();

    // 檢查並執行當前回合
    _checkAndExecuteCurrentTurn();
  }

  /// 進入下一個辯論回合
  void _advanceDebateRound() {
    if (state.currentPhase != GamePhase.debate) return;

    final nextRound = state.debateRound + 1;

    if (nextRound > state.maxDebateRounds) {
      // 辯論結束，進入投票階段
      _addGameEvent(
        GameEventType.systemMessage,
        '辯論結束！即將進入投票階段',
      );
      _stopTurnTimer();
      advancePhase();
      return;
    }

    // 重新生成發言順序
    final newSpeakingOrder = _generateSpeakingOrder();

    state = state.copyWith(
      debateRound: nextRound,
      debateTurnIndex: 0,
      speakingOrder: newSpeakingOrder,
      turnTimeRemaining: GameConstants.debateTurnTimeout,
      hasActedThisTurn: false,
    );

    _addGameEvent(
      GameEventType.systemMessage,
      '第 $nextRound 回合開始',
    );

    // 重置回合計時器
    _startTurnTimer();

    // 檢查並執行當前回合
    _checkAndExecuteCurrentTurn();
  }

  /// 人類玩家跳過回合
  void skipTurn() {
    if (!state.isHumanTurn) return;

    _addGameEvent(
      GameEventType.playerAction,
      '${state.humanPlayer?.name ?? "玩家"} 選擇跳過',
      playerId: state.humanPlayer?.id,
    );

    _advanceDebateTurn();
  }

  /// 暫停/繼續遊戲
  void togglePause() {
    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      _startPhaseTimer();
    } else {
      state = state.copyWith(isPaused: true);
      _stopPhaseTimer();
    }
  }

  // ============================================================
  // 人類玩家行動
  // ============================================================

  /// 執行人類玩家行動
  Future<bool> executeHumanAction(GameAction action) async {
    if (state.humanPlayer == null || !state.isHumanAlive) {
      return false;
    }

    // 辯論階段檢查是否輪到人類
    if (state.currentPhase == GamePhase.debate && !state.isHumanTurn) {
      return false;
    }

    try {
      bool success = false;

      // 根據動作類型處理
      switch (action.type) {
        case ActionType.query:
          success = await _executeQueryAction(action as QueryAction, isHuman: true);
          break;
        case ActionType.rebut:
          success = await _executeRebutAction(action as RebutAction, isHuman: true);
          break;
        case ActionType.vote:
          success = await _executeVoteAction(action as VoteAction, isHuman: true);
          break;
        case ActionType.ally:
          success = await _executeAllyAction(action as AllyAction, isHuman: true);
          break;
        case ActionType.betray:
          success = await _executeBetrayAction(action as BetrayAction, isHuman: true);
          break;
        case ActionType.speak:
          success = await _executeSpeakAction(action as SpeakAction, isHuman: true);
          break;
        case ActionType.skill:
          success = await _executeSkillAction(action as SkillAction, isHuman: true);
          break;
        default:
          return false;
      }

      // 辯論階段行動後進入下一回合
      if (success && state.currentPhase == GamePhase.debate) {
        _advanceDebateTurn();
      }

      return success;
    } catch (e) {
      debugPrint('SoloGameNotifier: Error executing human action: $e');
      return false;
    }
  }

  /// 人類玩家投票
  Future<bool> submitVote(String option) async {
    if (state.humanPlayer == null || state.currentPhase != GamePhase.voting) {
      return false;
    }

    final voteAction = VoteAction(
      id: 'vote_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: state.humanPlayer!.id,
      timestamp: DateTime.now(),
      option: option,
      weight: state.humanPlayer!.voteWeight,
    );

    final success = await _executeVoteAction(voteAction, isHuman: true);

    if (success) {
      // 觸發 AI 投票
      await executeAITurn();

      // 檢查是否所有存活玩家都投票了
      final alivePlayersCount = state.allPlayers.where((p) => p.isAlive).length;
      if (state.votes.length >= alivePlayersCount) {
        // 停止計時器
        _stopPhaseTimer();
        // 處理投票結果（不清空投票記錄，因為遊戲即將結束）
        await _processVotingResult(clearVotes: false);
        // 結束遊戲，進入結算畫面
        endGame();
      }
    }

    return success;
  }

  // ============================================================
  // AI 回合處理
  // ============================================================

  /// 執行 AI 回合（非辯論階段用）
  ///
  /// 讓所有 AI 依序執行行動
  /// AI 行動延遲根據難度調整
  /// 注意：辯論階段使用回合制，不使用此方法
  Future<void> executeAITurn() async {
    // 辯論階段使用回合制，不在此執行
    if (state.currentPhase == GamePhase.debate) {
      return;
    }

    if (state.isProcessingAI || state.isGameOver || state.isPaused) {
      return;
    }

    state = state.copyWith(isProcessingAI: true);

    try {
      // 創建模擬的 GameState 給 AI 引擎
      final gameState = _createGameStateForAI();

      for (final ai in state.aiPlayers) {
        if (!ai.isAlive || state.isGameOver) continue;

        // 根據難度獲取 AI 反應時間
        final reactionTime = _aiEngine.getReactionTime(ai.difficulty);

        // AI 決策
        final decision = _aiEngine.decide(ai, gameState);

        // 轉換為遊戲動作並執行
        await _executeAIDecision(ai, decision);

        // 根據難度調整延遲
        final delay = _baseAIActionDelay + (reactionTime ~/ 2);
        await Future.delayed(Duration(milliseconds: delay));
      }
    } catch (e) {
      debugPrint('SoloGameNotifier: Error in AI turn: $e');
    } finally {
      state = state.copyWith(isProcessingAI: false);
    }
  }

  /// 執行 AI 決策
  ///
  /// AI 傷害根據難度修正
  Future<void> _executeAIDecision(AIPlayer ai, AIDecision decision) async {
    switch (decision.actionType) {
      case AIActionType.attack:
        if (decision.targetId != null) {
          // 根據難度計算實際傷害
          final damageModifier = _aiEngine.getDamageModifier(ai.difficulty);
          const baseDamage = GameConstants.queryBaseDamage;
          final actualDamage = (baseDamage * damageModifier).round();

          await _executeQueryAction(
            QueryAction(
              id: 'query_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
              actorId: ai.id,
              targetId: decision.targetId,
              timestamp: DateTime.now(),
              damage: baseDamage,
              actualDamage: actualDamage,
              reputationCost: GameConstants.queryCost,
            ),
            isHuman: false,
          );
        }
        break;

      case AIActionType.defend:
        await _executeRebutAction(
          RebutAction(
            id: 'rebut_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
            actorId: ai.id,
            timestamp: DateTime.now(),
            damageReduced: GameConstants.rebutBlock,
            reputationCost: GameConstants.rebutCost,
          ),
          isHuman: false,
        );
        break;

      case AIActionType.vote:
        final option = decision.parameters['option'] as String? ?? 'C';
        await _executeVoteAction(
          VoteAction(
            id: 'vote_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
            actorId: ai.id,
            timestamp: DateTime.now(),
            option: option,
            weight: ai.player.voteWeight,
          ),
          isHuman: false,
        );
        break;

      case AIActionType.ally:
        if (decision.targetId != null) {
          await _executeAllyAction(
            AllyAction(
              id: 'ally_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
              actorId: ai.id,
              targetId: decision.targetId,
              timestamp: DateTime.now(),
            ),
            isHuman: false,
          );
        }
        break;

      case AIActionType.betray:
        if (decision.targetId != null) {
          await _executeBetrayAction(
            BetrayAction(
              id: 'betray_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
              actorId: ai.id,
              targetId: decision.targetId,
              timestamp: DateTime.now(),
              bonusDamage: GameConstants.betrayBonusDamage,
              selfReputationLoss: GameConstants.betraySelfLoss,
            ),
            isHuman: false,
          );
        }
        break;

      case AIActionType.speak:
        // AI 發言（簡化處理）
        _addGameEvent(
          GameEventType.aiAction,
          '${ai.displayName} 發表了意見',
          playerId: ai.id,
        );
        break;

      case AIActionType.wait:
        // AI 等待，不做任何事
        break;

      default:
        break;
    }
  }

  // ============================================================
  // 行動執行
  // ============================================================

  /// 執行質詢動作
  Future<bool> _executeQueryAction(QueryAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);
    final target = _getPlayer(action.targetId);

    if (actor == null || target == null) return false;
    if (actor.reputation < action.reputationCost) return false;

    // 計算傷害
    final actualDamage = GameConstants.calculateDamage(
      baseDamage: action.damage,
      defenderDefense: target.defense,
    );

    // 更新攻擊者聲望（消耗）
    _updatePlayerReputation(action.actorId, -action.reputationCost);

    // 更新目標聲望（受傷）
    _updatePlayerReputation(action.targetId!, -actualDamage);

    _addGameEvent(
      isHuman ? GameEventType.playerAction : GameEventType.aiAction,
      '${actor.name} 質詢 ${target.name}，造成 $actualDamage 點傷害',
      playerId: action.actorId,
      targetId: action.targetId,
      data: {'damage': actualDamage},
    );

    // 檢查目標是否出局
    _checkPlayerEliminated(action.targetId!);

    return true;
  }

  /// 執行反駁動作
  Future<bool> _executeRebutAction(RebutAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);

    if (actor == null) return false;
    if (actor.reputation < action.reputationCost) return false;

    // 更新聲望（消耗）
    _updatePlayerReputation(action.actorId, -action.reputationCost);

    _addGameEvent(
      isHuman ? GameEventType.playerAction : GameEventType.aiAction,
      '${actor.name} 進行反駁，增加防禦',
      playerId: action.actorId,
    );

    return true;
  }

  /// 執行投票動作
  Future<bool> _executeVoteAction(VoteAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);

    if (actor == null || !actor.isAlive) return false;

    // 記錄投票
    final newVotes = Map<String, String>.from(state.votes);
    newVotes[action.actorId] = action.option;

    state = state.copyWith(votes: newVotes);

    _addGameEvent(
      GameEventType.voteSubmitted,
      '${actor.name} 投出了選票',
      playerId: action.actorId,
      data: {'option': action.option, 'weight': action.weight},
    );

    return true;
  }

  /// 執行結盟動作
  Future<bool> _executeAllyAction(AllyAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);
    final target = _getPlayer(action.targetId);

    if (actor == null || target == null) return false;

    // 更新盟友關係
    _addAlly(action.actorId, action.targetId!);

    _addGameEvent(
      isHuman ? GameEventType.playerAction : GameEventType.aiAction,
      '${actor.name} 與 ${target.name} 結成同盟',
      playerId: action.actorId,
      targetId: action.targetId,
    );

    return true;
  }

  /// 執行背叛動作
  Future<bool> _executeBetrayAction(BetrayAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);
    final target = _getPlayer(action.targetId);

    if (actor == null || target == null) return false;

    // 移除盟友關係
    _removeAlly(action.actorId, action.targetId!);

    // 造成傷害
    _updatePlayerReputation(action.targetId!, -action.bonusDamage);

    // 自損聲望
    _updatePlayerReputation(action.actorId, -action.selfReputationLoss);

    _addGameEvent(
      GameEventType.allianceBroken,
      '${actor.name} 背叛了 ${target.name}！造成 ${action.bonusDamage} 點傷害',
      playerId: action.actorId,
      targetId: action.targetId,
      data: {'damage': action.bonusDamage},
    );

    // 檢查目標是否出局
    _checkPlayerEliminated(action.targetId!);

    return true;
  }

  /// 執行發言動作
  Future<bool> _executeSpeakAction(SpeakAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);

    if (actor == null) return false;

    _addGameEvent(
      isHuman ? GameEventType.playerAction : GameEventType.aiAction,
      '${actor.name}: ${action.content}',
      playerId: action.actorId,
    );

    return true;
  }

  /// 執行技能動作
  Future<bool> _executeSkillAction(SkillAction action, {required bool isHuman}) async {
    final actor = _getPlayer(action.actorId);
    if (actor == null) return false;

    final role = RoleDatabase.getRoleById(actor.roleId ?? '');
    if (role == null) return false;

    final skill = role.skills.firstWhere(
      (s) => s.id == action.skillId,
      orElse: () => role.skills.first,
    );

    // 檢查資源是否足夠
    if (actor.reputation < skill.reputationCost) return false;
    if (actor.gold < skill.goldCost) return false;
    if (actor.intel < skill.intelCost) return false;

    // 消耗資源
    if (skill.reputationCost > 0) {
      _updatePlayerReputation(action.actorId, -skill.reputationCost);
    }
    if (skill.goldCost > 0) {
      _updatePlayerGold(action.actorId, -skill.goldCost);
    }
    if (skill.intelCost > 0) {
      _updatePlayerIntel(action.actorId, -skill.intelCost);
    }

    // 根據技能 ID 執行不同效果
    switch (action.skillId) {
      case 'worker_solidarity':
        // 團結 - 被動技能，每有1名工人盟友，防禦+10
        // 這是被動技能，不需要手動執行
        break;

      case 'factory_bribe':
        // 收買 - 花費金幣使目標沉默1回合
        if (action.targetId != null) {
          final target = _getPlayer(action.targetId!);
          if (target != null) {
            _addGameEvent(
              GameEventType.skillUsed,
              '${actor.name} 使用「${skill.name}」收買了 ${target.name}！',
              playerId: action.actorId,
              targetId: action.targetId,
            );
          }
        }
        break;

      case 'reporter_expose':
        // 爆料 - 揭露目標的秘密（造成聲望傷害）
        if (action.targetId != null) {
          final target = _getPlayer(action.targetId!);
          if (target != null) {
            const exposeDamage = 20;
            _updatePlayerReputation(action.targetId!, -exposeDamage);
            _addGameEvent(
              GameEventType.skillUsed,
              '${actor.name} 使用「${skill.name}」揭露了 ${target.name} 的秘密！造成 $exposeDamage 點聲望傷害',
              playerId: action.actorId,
              targetId: action.targetId,
              data: {'damage': exposeDamage},
            );
            _checkPlayerEliminated(action.targetId!);
          }
        }
        break;

      case 'luddite_rage':
        // 怒火 - 造成雙倍傷害，但自己也扣聲望
        if (action.targetId != null) {
          final target = _getPlayer(action.targetId!);
          if (target != null) {
            const rageDamage = GameConstants.queryBaseDamage * 2;
            const selfDamage = 10;
            _updatePlayerReputation(action.targetId!, -rageDamage);
            _updatePlayerReputation(action.actorId, -selfDamage);
            _addGameEvent(
              GameEventType.skillUsed,
              '${actor.name} 爆發「${skill.name}」攻擊 ${target.name}！造成 $rageDamage 點傷害，自己損失 $selfDamage 聲望',
              playerId: action.actorId,
              targetId: action.targetId,
              data: {'damage': rageDamage, 'selfDamage': selfDamage},
            );
            _checkPlayerEliminated(action.targetId!);
            _checkPlayerEliminated(action.actorId);
          }
        }
        break;

      default:
        // 通用技能效果
        _addGameEvent(
          GameEventType.skillUsed,
          '${actor.name} 使用了「${skill.name}」',
          playerId: action.actorId,
          targetId: action.targetId,
        );
    }

    return true;
  }

  /// 更新玩家金幣
  void _updatePlayerGold(String playerId, int change) {
    if (playerId == state.humanPlayer?.id) {
      final newGold = (state.humanPlayer!.gold + change).clamp(0, 999);
      state = state.copyWith(
        humanPlayer: state.humanPlayer!.copyWith(gold: newGold),
      );
    } else {
      final newAiPlayers = state.aiPlayers.map((ai) {
        if (ai.id == playerId) {
          final newGold = (ai.player.gold + change).clamp(0, 999);
          return ai.updatePlayer((p) => p.copyWith(gold: newGold));
        }
        return ai;
      }).toList();
      state = state.copyWith(aiPlayers: newAiPlayers);
    }
  }

  /// 更新玩家情報
  void _updatePlayerIntel(String playerId, int change) {
    if (playerId == state.humanPlayer?.id) {
      final newIntel = (state.humanPlayer!.intel + change).clamp(0, 99);
      state = state.copyWith(
        humanPlayer: state.humanPlayer!.copyWith(intel: newIntel),
      );
    } else {
      final newAiPlayers = state.aiPlayers.map((ai) {
        if (ai.id == playerId) {
          final newIntel = (ai.player.intel + change).clamp(0, 99);
          return ai.updatePlayer((p) => p.copyWith(intel: newIntel));
        }
        return ai;
      }).toList();
      state = state.copyWith(aiPlayers: newAiPlayers);
    }
  }

  // ============================================================
  // 投票處理
  // ============================================================

  /// 處理投票結果
  /// [clearVotes] 是否清空投票記錄（遊戲結束時不清空）
  Future<void> _processVotingResult({bool clearVotes = true}) async {
    if (state.currentBill == null) return;

    final bill = state.currentBill!;
    final tally = <String, double>{'A': 0, 'B': 0, 'C': 0};

    // 計算加權票數
    for (final entry in state.votes.entries) {
      final player = _getPlayer(entry.key);
      if (player != null && player.isAlive) {
        final weight = player.voteWeight;
        tally[entry.value] = (tally[entry.value] ?? 0) + weight;
      }
    }

    // 決定獲勝選項
    String winningOption = 'C';
    double maxVotes = 0;
    for (final entry in tally.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winningOption = entry.key;
      }
    }

    final winningOptionData = bill.getOptionById(winningOption);

    _addGameEvent(
      GameEventType.voteResult,
      '投票結果：選項 $winningOption「${winningOptionData?.title ?? ''}」以 ${maxVotes.toStringAsFixed(1)} 票獲勝',
      data: {
        'option': winningOption,
        'tally': tally,
      },
    );

    // 更新當前回合（不清空投票如果遊戲即將結束）
    if (clearVotes && state.currentRound < state.totalRounds) {
      state = state.copyWith(
        currentRound: state.currentRound + 1,
        votes: {},
      );
    }
  }

  // ============================================================
  // 突發事件系統
  // ============================================================

  /// 檢查是否應觸發突發事件
  RandomEvent? _checkForRandomEvent() {
    return _eventSystem.checkAndTriggerEvent(
      currentRound: state.currentRound,
      players: state.allPlayers,
      aiPlayers: state.aiPlayers,
    );
  }

  /// 開始事件階段
  Future<void> _startEventPhase(RandomEvent event) async {
    _stopPhaseTimer();
    _stopTurnTimer();

    // 對於需要指定目標的事件（如報紙號外），先找出目標
    String? targetPlayerId;
    if (event.type == RandomEventType.newspaperExtra) {
      final alivePlayers = state.allPlayers.where((p) => p.isAlive).toList();
      if (alivePlayers.isNotEmpty) {
        alivePlayers.sort((a, b) => b.reputation.compareTo(a.reputation));
        targetPlayerId = alivePlayers.first.id;
      }
    }

    state = state.copyWith(
      currentPhase: GamePhase.event,
      phaseTimeRemaining: GameConstants.eventDuration,
      currentRandomEvent: event,
      awaitingEventChoice: event.requiresChoice,
      eventTargetPlayerId: targetPlayerId,
    );

    _addGameEvent(
      GameEventType.phaseChanged,
      '${event.emoji} 突發事件：${event.name}',
      data: {'eventId': event.id, 'eventType': event.type.name},
    );

    _addGameEvent(
      GameEventType.systemMessage,
      event.narrative,
    );

    // 如果是需要選擇的事件且目標是人類玩家，等待玩家選擇
    if (event.requiresChoice) {
      if (event.type == RandomEventType.newspaperExtra && 
          targetPlayerId == state.humanPlayer?.id) {
        // 人類玩家是報紙號外的目標，等待選擇
        _startPhaseTimer();
        return;
      } else if (event.type == RandomEventType.frenchThreat) {
        // 法國威脅需要所有人表態，先讓 AI 做出選擇
        await _processAIEventChoices(event);
        // 然後等待人類玩家選擇
        _startPhaseTimer();
        return;
      }
    }

    // 不需要選擇的事件，直接處理效果
    await _processEventEffects(event);
  }

  /// 處理 AI 對事件的選擇
  Future<void> _processAIEventChoices(RandomEvent event) async {
    if (event.type == RandomEventType.newspaperExtra) {
      // 報紙號外：AI 如果是目標，隨機選擇
      final targetId = state.eventTargetPlayerId;
      if (targetId != null && targetId != state.humanPlayer?.id) {
        // AI 是目標，隨機決定是否辯解
        final choice = _random.nextBool() ? 'defend' : 'silence';
        await submitEventChoice(choice, playerId: targetId);
      }
    } else if (event.type == RandomEventType.frenchThreat) {
      // 法國威脅：所有 AI 根據陣營傾向選擇
      final choices = Map<String, String>.from(state.frenchThreatChoices);
      
      for (final ai in state.aiPlayers) {
        if (!ai.isAlive) continue;
        
        // 根據 AI 角色陣營決定傾向
        final role = RoleDatabase.getRoleById(ai.roleId ?? '');
        String choice;
        
        if (role?.faction == Faction.royal) {
          // 皇室派傾向支持軍費
          choice = 'support_military';
        } else if (role?.faction == Faction.reform || role?.faction == Faction.worker) {
          // 改革派和勞工派傾向反對
          choice = 'oppose_military';
        } else {
          // 其他陣營隨機
          choice = _random.nextBool() ? 'support_military' : 'oppose_military';
        }
        
        choices[ai.id] = choice;
        
        final choiceText = choice == 'support_military' ? '支持增加軍費' : '反對增加軍費';
        _addGameEvent(
          GameEventType.aiAction,
          '${ai.displayName} 選擇：$choiceText',
          playerId: ai.id,
        );
      }
      
      state = state.copyWith(frenchThreatChoices: choices);
    }
  }

  /// 玩家提交事件選擇
  Future<bool> submitEventChoice(String choiceId, {String? playerId}) async {
    final event = state.currentRandomEvent;
    if (event == null) return false;

    final actorId = playerId ?? state.humanPlayer?.id;
    if (actorId == null) return false;

    final actor = _getPlayer(actorId);
    if (actor == null) return false;

    // 找出選擇的描述
    final choice = event.choices.firstWhere(
      (c) => c.id == choiceId,
      orElse: () => event.choices.first,
    );

    _addGameEvent(
      actorId == state.humanPlayer?.id ? GameEventType.playerAction : GameEventType.aiAction,
      '${actor.name} 選擇：${choice.title}',
      playerId: actorId,
      data: {'choiceId': choiceId},
    );

    // 根據事件類型處理選擇
    if (event.type == RandomEventType.newspaperExtra) {
      // 報紙號外：直接處理效果
      final results = _eventSystem.processNewspaperExtra(
        players: state.allPlayers,
        choiceId: choiceId,
      );
      _applyEventResults(results);
      
      // 結束事件階段
      await _finishEventPhase();
    } else if (event.type == RandomEventType.frenchThreat) {
      // 法國威脅：記錄人類玩家的選擇
      final choices = Map<String, String>.from(state.frenchThreatChoices);
      choices[actorId] = choiceId;
      state = state.copyWith(frenchThreatChoices: choices);

      // 如果是人類玩家的選擇，處理效果並結束
      if (actorId == state.humanPlayer?.id) {
        final results = _eventSystem.processFrenchThreat(
          players: state.allPlayers,
          playerChoices: choices,
        );
        _applyEventResults(results);
        await _finishEventPhase();
      }
    }

    return true;
  }

  /// 處理不需要選擇的事件效果
  Future<void> _processEventEffects(RandomEvent event) async {
    List<EventEffectResult> results = [];

    switch (event.type) {
      case RandomEventType.stockMarketCrash:
        results = _eventSystem.processStockMarketCrash(
          players: state.allPlayers,
          aiPlayers: state.aiPlayers,
        );
        break;

      case RandomEventType.factoryFire:
        results = _eventSystem.processFactoryFire(
          players: state.allPlayers,
          aiPlayers: state.aiPlayers,
        );
        break;

      case RandomEventType.royalAttention:
        results = _eventSystem.processRoyalAttention(
          players: state.allPlayers,
          aiPlayers: state.aiPlayers,
        );
        break;

      default:
        break;
    }

    _applyEventResults(results);

    // 短暫延遲後結束事件階段
    await Future.delayed(const Duration(seconds: 3));
    await _finishEventPhase();
  }

  /// 應用事件效果結果
  void _applyEventResults(List<EventEffectResult> results) {
    for (final result in results) {
      // 應用聲望變化
      if (result.playerId != null && result.reputationChange != 0) {
        _updatePlayerReputation(result.playerId!, result.reputationChange);
      }

      // 應用金幣變化
      if (result.playerId != null && result.goldChange != 0) {
        _updatePlayerGold(result.playerId!, result.goldChange);
      }

      // 記錄效果
      _addGameEvent(
        GameEventType.systemMessage,
        result.description,
        playerId: result.playerId,
        data: result.specialEffects,
      );

      // 處理特殊效果
      if (result.specialEffects.containsKey('speechWeight')) {
        final weight = result.specialEffects['speechWeight'] as double;
        final modifiers = Map<String, double>.from(state.speechWeightModifiers);
        modifiers[result.playerId!] = weight;
        state = state.copyWith(speechWeightModifiers: modifiers);
      }

      // 檢查玩家是否出局
      if (result.playerId != null) {
        _checkPlayerEliminated(result.playerId!);
      }
    }
  }

  /// 結束事件階段
  Future<void> _finishEventPhase() async {
    _stopPhaseTimer();

    // 清理事件狀態
    state = state.copyWith(
      clearRandomEvent: true,
      awaitingEventChoice: false,
      eventTargetPlayerId: null,
      frenchThreatChoices: {},
    );

    // 進入投票階段
    await advancePhase();
  }

  /// 跳過事件選擇（超時時自動選擇）
  void skipEventChoice() {
    final event = state.currentRandomEvent;
    if (event == null || !state.awaitingEventChoice) return;

    // 自動選擇第一個選項
    if (event.choices.isNotEmpty) {
      submitEventChoice(event.choices.first.id);
    }
  }

  // ============================================================
  // 輔助方法
  // ============================================================

  /// 開始階段計時
  void _startPhaseTimer() {
    _stopPhaseTimer();

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused || state.isGameOver) return;

      if (state.phaseTimeRemaining > 0) {
        state = state.copyWith(
          phaseTimeRemaining: state.phaseTimeRemaining - 1,
        );
      } else {
        // 時間到，自動進入下一階段
        advancePhase();
      }
    });
  }

  /// 停止階段計時
  void _stopPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  /// 開始回合計時（辯論階段用）
  void _startTurnTimer() {
    _stopTurnTimer();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused || state.isGameOver) return;
      if (state.currentPhase != GamePhase.debate) {
        _stopTurnTimer();
        return;
      }

      if (state.turnTimeRemaining > 0) {
        state = state.copyWith(
          turnTimeRemaining: state.turnTimeRemaining - 1,
        );
      } else {
        // 時間到，自動跳過
        if (state.isHumanTurn) {
          _addGameEvent(
            GameEventType.systemMessage,
            '時間到！自動跳過',
          );
        }
        _advanceDebateTurn();
      }
    });
  }

  /// 停止回合計時
  void _stopTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  /// 獲取下一階段
  GamePhase _getNextPhase(GamePhase current) {
    switch (current) {
      case GamePhase.waiting:
        return GamePhase.preparing;
      case GamePhase.preparing:
        return GamePhase.conspiracy;
      case GamePhase.conspiracy:
        return GamePhase.debate;
      case GamePhase.debate:
        return GamePhase.voting;
      case GamePhase.voting:
        return GamePhase.result;
      case GamePhase.event:
        return GamePhase.voting;
      case GamePhase.result:
        return GamePhase.result;
    }
  }

  /// 獲取階段持續時間
  int _getPhaseDuration(GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
        return 0;
      case GamePhase.preparing:
        return GameConstants.preparingDuration;
      case GamePhase.conspiracy:
        return GameConstants.conspiracyDuration;
      case GamePhase.debate:
        return GameConstants.debateDuration;
      case GamePhase.event:
        return GameConstants.eventDuration;
      case GamePhase.voting:
        return GameConstants.votingDuration;
      case GamePhase.result:
        return 0;
    }
  }

  /// 獲取階段名稱
  String _getPhaseName(GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
        return '等待中';
      case GamePhase.preparing:
        return '準備階段';
      case GamePhase.conspiracy:
        return '密謀階段';
      case GamePhase.debate:
        return '辯論階段';
      case GamePhase.event:
        return '突發事件';
      case GamePhase.voting:
        return '投票階段';
      case GamePhase.result:
        return '結算階段';
    }
  }

  /// 生成發言順序
  List<String> _generateSpeakingOrder() {
    final playerIds = state.allPlayers
        .where((p) => p.isAlive)
        .map((p) => p.id)
        .toList();
    playerIds.shuffle(_random);
    return playerIds;
  }

  /// 獲取玩家
  Player? _getPlayer(String? playerId) {
    if (playerId == null) return null;
    if (playerId == state.humanPlayer?.id) return state.humanPlayer;
    return state.aiPlayers
        .where((ai) => ai.id == playerId)
        .map((ai) => ai.player)
        .firstOrNull;
  }

  /// 更新玩家聲望
  void _updatePlayerReputation(String playerId, int change) {
    if (playerId == state.humanPlayer?.id) {
      final newReputation = (state.humanPlayer!.reputation + change).clamp(0, 100);
      state = state.copyWith(
        humanPlayer: state.humanPlayer!.copyWith(
          reputation: newReputation,
          isAlive: newReputation > 0,
        ),
      );
    } else {
      final newAiPlayers = state.aiPlayers.map((ai) {
        if (ai.id == playerId) {
          final newReputation = (ai.reputation + change).clamp(0, 100);
          return ai.updatePlayer((p) => p.copyWith(
                reputation: newReputation,
                isAlive: newReputation > 0,
              ));
        }
        return ai;
      }).toList();
      state = state.copyWith(aiPlayers: newAiPlayers);
    }
  }

  /// 添加盟友
  void _addAlly(String playerId, String allyId) {
    if (playerId == state.humanPlayer?.id) {
      state = state.copyWith(
        humanPlayer: state.humanPlayer!.copyWith(
          allies: [...state.humanPlayer!.allies, allyId],
        ),
      );
    } else {
      final newAiPlayers = state.aiPlayers.map((ai) {
        if (ai.id == playerId) {
          return ai.updatePlayer((p) => p.copyWith(
                allies: [...p.allies, allyId],
              ));
        }
        return ai;
      }).toList();
      state = state.copyWith(aiPlayers: newAiPlayers);
    }
  }

  /// 移除盟友
  void _removeAlly(String playerId, String allyId) {
    if (playerId == state.humanPlayer?.id) {
      state = state.copyWith(
        humanPlayer: state.humanPlayer!.copyWith(
          allies: state.humanPlayer!.allies.where((id) => id != allyId).toList(),
        ),
      );
    } else {
      final newAiPlayers = state.aiPlayers.map((ai) {
        if (ai.id == playerId) {
          return ai.updatePlayer((p) => p.copyWith(
                allies: p.allies.where((id) => id != allyId).toList(),
              ));
        }
        return ai;
      }).toList();
      state = state.copyWith(aiPlayers: newAiPlayers);
    }
  }

  /// 檢查玩家是否出局
  void _checkPlayerEliminated(String playerId) {
    final player = _getPlayer(playerId);
    if (player != null && !player.isAlive) {
      _addGameEvent(
        GameEventType.playerEliminated,
        '${player.name} 政治死亡！',
        playerId: playerId,
      );

      // 檢查是否只剩一人存活
      if (state.alivePlayerCount <= 1) {
        endGame();
      }
    }
  }

  /// 添加遊戲事件
  void _addGameEvent(
    GameEventType type,
    String message, {
    String? playerId,
    String? targetId,
    Map<String, dynamic> data = const {},
  }) {
    final event = GameEvent.create(
      type: type,
      message: message,
      playerId: playerId,
      targetId: targetId,
      data: data,
    );

    state = state.copyWith(
      gameLog: [...state.gameLog, event],
    );
  }

  /// 決定獲勝者
  String? _determineWinner() {
    // 如果只有一人存活，那人獲勝
    final alivePlayers = state.allPlayers.where((p) => p.isAlive).toList();
    if (alivePlayers.length == 1) {
      return alivePlayers.first.name;
    }

    // 否則根據聲望決定
    if (alivePlayers.isNotEmpty) {
      alivePlayers.sort((a, b) => b.reputation.compareTo(a.reputation));
      return alivePlayers.first.name;
    }

    return null;
  }

  /// 創建 GameState 給 AI 引擎使用
  GameState _createGameStateForAI() {
    return GameState(
      roomId: state.gameRoom?.id ?? '',
      roomCode: 'SOLO',
      phase: state.currentPhase,
      currentRound: state.currentRound,
      totalRounds: state.totalRounds,
      timeRemaining: state.phaseTimeRemaining,
      players: state.allPlayers,
      currentBill: state.currentBill,
      currentSpeakerId: state.currentSpeakerId,
      speakingOrder: state.speakingOrder,
    );
  }

  @override
  void dispose() {
    _stopPhaseTimer();
    _stopTurnTimer();
    super.dispose();
  }
}

// ============================================================
// Providers
// ============================================================

/// 單人遊戲狀態 Provider
final soloGameProvider =
    StateNotifierProvider<SoloGameNotifier, SoloGameState>((ref) {
  return SoloGameNotifier();
});

/// 當前階段 Provider
final soloCurrentPhaseProvider = Provider<GamePhase>((ref) {
  return ref.watch(soloGameProvider).currentPhase;
});

/// 階段剩餘時間 Provider
final soloPhaseTimeProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).phaseTimeRemaining;
});

/// 人類玩家 Provider
final soloHumanPlayerProvider = Provider<Player?>((ref) {
  return ref.watch(soloGameProvider).humanPlayer;
});

/// AI 玩家列表 Provider
final soloAIPlayersProvider = Provider<List<AIPlayer>>((ref) {
  return ref.watch(soloGameProvider).aiPlayers;
});

/// 所有玩家 Provider
final soloAllPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(soloGameProvider).allPlayers;
});

/// 遊戲日誌 Provider
final soloGameLogProvider = Provider<List<GameEvent>>((ref) {
  return ref.watch(soloGameProvider).gameLog;
});

/// 遊戲是否結束 Provider
final soloIsGameOverProvider = Provider<bool>((ref) {
  return ref.watch(soloGameProvider).isGameOver;
});

/// 遊戲是否進行中 Provider
final soloIsGameInProgressProvider = Provider<bool>((ref) {
  return ref.watch(soloGameProvider).isGameInProgress;
});

/// 當前議案 Provider
final soloCurrentBillProvider = Provider<Bill?>((ref) {
  return ref.watch(soloGameProvider).currentBill;
});

/// 投票記錄 Provider
final soloVotesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(soloGameProvider).votes;
});

/// 是否正在處理 AI Provider
final soloIsProcessingAIProvider = Provider<bool>((ref) {
  return ref.watch(soloGameProvider).isProcessingAI;
});

/// 格式化剩餘時間 Provider
final soloFormattedTimeProvider = Provider<String>((ref) {
  return ref.watch(soloGameProvider).formattedTimeRemaining;
});

/// 當前回合 Provider
final soloCurrentRoundProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).currentRound;
});

/// 總回合數 Provider
final soloTotalRoundsProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).totalRounds;
});

// ============================================================
// 回合制辯論 Providers
// ============================================================

/// 辯論回合數 Provider
final soloDebateRoundProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).debateRound;
});

/// 辯論最大回合數 Provider
final soloMaxDebateRoundsProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).maxDebateRounds;
});

/// 當前回合剩餘時間 Provider
final soloTurnTimeProvider = Provider<int>((ref) {
  return ref.watch(soloGameProvider).turnTimeRemaining;
});

/// 是否為人類回合 Provider
final soloIsHumanTurnProvider = Provider<bool>((ref) {
  return ref.watch(soloGameProvider).isHumanTurn;
});

/// 當前行動者 Provider
final soloCurrentActorProvider = Provider<Player?>((ref) {
  return ref.watch(soloGameProvider).currentActor;
});

/// 格式化回合時間 Provider
final soloFormattedTurnTimeProvider = Provider<String>((ref) {
  final seconds = ref.watch(soloTurnTimeProvider);
  return seconds.toString().padLeft(2, '0');
});

// ============================================================
// 突發事件 Providers
// ============================================================

/// 當前突發事件 Provider
final soloCurrentRandomEventProvider = Provider<RandomEvent?>((ref) {
  return ref.watch(soloGameProvider).currentRandomEvent;
});

/// 是否正在等待事件選擇 Provider
final soloAwaitingEventChoiceProvider = Provider<bool>((ref) {
  return ref.watch(soloGameProvider).awaitingEventChoice;
});

/// 事件目標玩家 ID Provider
final soloEventTargetPlayerIdProvider = Provider<String?>((ref) {
  return ref.watch(soloGameProvider).eventTargetPlayerId;
});

/// 事件目標玩家 Provider
final soloEventTargetPlayerProvider = Provider<Player?>((ref) {
  final targetId = ref.watch(soloEventTargetPlayerIdProvider);
  if (targetId == null) return null;
  
  final allPlayers = ref.watch(soloAllPlayersProvider);
  try {
    return allPlayers.firstWhere((p) => p.id == targetId);
  } catch (e) {
    return null;
  }
});

/// 是否為突發事件階段 Provider
final soloIsEventPhaseProvider = Provider<bool>((ref) {
  return ref.watch(soloCurrentPhaseProvider) == GamePhase.event;
});

/// 發言權重修正 Provider
final soloSpeechWeightModifiersProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(soloGameProvider).speechWeightModifiers;
});
