// 1812 國會風雲 - 單人遊戲控制器
//
// 這個控制器負責單人遊戲的核心流程控制，包括：
// 1. 遊戲初始化
// 2. 階段管理和計時
// 3. AI 行為執行
// 4. 結果計算

import 'dart:async';
import 'dart:math';

import '../models/models.dart';
import '../../core/constants/game_constants.dart';
import 'ai_decision_engine.dart';

// ============================================================
// 遊戲事件系統
// ============================================================

/// 遊戲事件類型
enum GameEventType {
  // 系統事件
  gameStart,            // 遊戲開始
  gameEnd,              // 遊戲結束
  phaseChange,          // 階段變更
  roundStart,           // 回合開始
  roundEnd,             // 回合結束
  timerTick,            // 計時器滴答
  turnChange,           // 回合變更（輪到某人行動）

  // AI 狀態
  aiThinking,           // AI 正在思考
  aiDecided,            // AI 已做出決策

  // 玩家動作
  playerSpeak,          // 玩家發言
  playerQuery,          // 玩家質詢
  playerRebut,          // 玩家反駁
  playerSkill,          // 玩家使用技能
  playerVote,           // 玩家投票
  playerSilenced,       // 玩家被沉默

  // 社交動作
  allianceRequest,      // 結盟請求
  allianceAccepted,     // 結盟接受
  allianceRejected,     // 結盟拒絕
  betrayal,             // 背叛
  privateMessage,       // 私訊

  // 狀態變化
  reputationChange,     // 聲望變化
  resourceChange,       // 資源變化
  playerEliminated,     // 玩家政治死亡
  defenseActivated,     // 防禦生效

  // 技能相關
  skillActivated,       // 技能激活
  skillEffect,          // 技能效果觸發

  // 投票相關
  voteSubmitted,        // 提交投票
  voteResult,           // 投票結果
}

/// 遊戲事件 - 記錄遊戲中發生的所有事件
class GameEvent {
  /// 事件唯一 ID
  final String id;

  /// 事件類型
  final GameEventType type;

  /// 事件發起者 ID（玩家或系統）
  final String actorId;

  /// 目標 ID（可選）
  final String? targetId;

  /// 事件資料
  final Map<String, dynamic> data;

  /// 事件時間戳
  final DateTime timestamp;

  /// 是否為公開事件（所有玩家可見）
  final bool isPublic;

  /// 事件描述（用於顯示）
  final String description;

  const GameEvent({
    required this.id,
    required this.type,
    required this.actorId,
    this.targetId,
    this.data = const {},
    required this.timestamp,
    this.isPublic = true,
    required this.description,
  });

  /// 創建系統事件
  factory GameEvent.system({
    required GameEventType type,
    required String description,
    Map<String, dynamic> data = const {},
  }) {
    return GameEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      type: type,
      actorId: 'system',
      data: data,
      timestamp: DateTime.now(),
      isPublic: true,
      description: description,
    );
  }

  /// 創建玩家事件
  factory GameEvent.player({
    required GameEventType type,
    required String actorId,
    String? targetId,
    required String description,
    Map<String, dynamic> data = const {},
    bool isPublic = true,
  }) {
    return GameEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      type: type,
      actorId: actorId,
      targetId: targetId,
      data: data,
      timestamp: DateTime.now(),
      isPublic: isPublic,
      description: description,
    );
  }

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'] as String,
      type: GameEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GameEventType.playerSpeak,
      ),
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isPublic: json['isPublic'] as bool? ?? true,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isPublic': isPublic,
      'description': description,
    };
  }

  @override
  String toString() => description;
}

// ============================================================
// 遊戲配置
// ============================================================

/// 單人遊戲配置
class SoloGameConfig {
  /// 難度等級
  final AIDifficulty difficulty;

  /// AI 玩家數量
  final int aiPlayerCount;

  /// 人類玩家選擇的角色 ID
  final String humanCharacterId;

  /// 人類玩家名稱
  final String humanPlayerName;

  /// 遊戲模式
  final SoloModeType modeType;

  /// 遊戲速度 (0.5, 1.0, 1.5, 2.0)
  final double gameSpeed;

  /// 是否啟用教學提示
  final bool showTutorialHints;

  /// 戰役關卡（僅戰役模式）
  final int? campaignLevel;

  /// 挑戰目標（僅挑戰模式）
  final ChallengeObjective? challengeObjective;

  const SoloGameConfig({
    required this.difficulty,
    this.aiPlayerCount = 3,
    required this.humanCharacterId,
    required this.humanPlayerName,
    this.modeType = SoloModeType.practice,
    this.gameSpeed = 1.0,
    this.showTutorialHints = false,
    this.campaignLevel,
    this.challengeObjective,
  });

  /// 創建練習模式配置
  factory SoloGameConfig.practice({
    required AIDifficulty difficulty,
    required String humanCharacterId,
    required String humanPlayerName,
    int aiPlayerCount = 3,
    double gameSpeed = 1.0,
  }) {
    return SoloGameConfig(
      difficulty: difficulty,
      aiPlayerCount: aiPlayerCount,
      humanCharacterId: humanCharacterId,
      humanPlayerName: humanPlayerName,
      modeType: SoloModeType.practice,
      gameSpeed: gameSpeed,
    );
  }

  /// 創建教學模式配置
  factory SoloGameConfig.tutorial({
    required String humanCharacterId,
    required String humanPlayerName,
  }) {
    return SoloGameConfig(
      difficulty: AIDifficulty.beginner,
      aiPlayerCount: 1,
      humanCharacterId: humanCharacterId,
      humanPlayerName: humanPlayerName,
      modeType: SoloModeType.tutorial,
      gameSpeed: 0.5,
      showTutorialHints: true,
    );
  }
}

// ============================================================
// 遊戲結果
// ============================================================

/// 單人遊戲結果
class SoloGameResult {
  /// 獲勝選項（A/B/C）
  final String winningOption;

  /// 獲勝陣營
  final Faction? winningFaction;

  /// 人類玩家是否勝利
  final bool isHumanVictory;

  /// 人類玩家最終得分
  final int humanScore;

  /// 所有玩家得分
  final Map<String, int> playerScores;

  /// MVP 玩家 ID
  final String? mvpPlayerId;

  /// 遊戲時長（秒）
  final int gameDuration;

  /// 遊戲統計
  final GameStatistics statistics;

  /// 獲得的成就
  final List<Achievement> achievements;

  const SoloGameResult({
    required this.winningOption,
    this.winningFaction,
    required this.isHumanVictory,
    required this.humanScore,
    required this.playerScores,
    this.mvpPlayerId,
    required this.gameDuration,
    required this.statistics,
    this.achievements = const [],
  });

  factory SoloGameResult.fromJson(Map<String, dynamic> json) {
    return SoloGameResult(
      winningOption: json['winningOption'] as String,
      winningFaction: json['winningFaction'] != null
          ? Faction.values.firstWhere(
              (e) => e.name == json['winningFaction'],
              orElse: () => Faction.neutral,
            )
          : null,
      isHumanVictory: json['isHumanVictory'] as bool? ?? false,
      humanScore: json['humanScore'] as int? ?? 0,
      playerScores: Map<String, int>.from(json['playerScores'] as Map),
      mvpPlayerId: json['mvpPlayerId'] as String?,
      gameDuration: json['gameDuration'] as int? ?? 0,
      statistics: json['statistics'] != null
          ? GameStatistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : const GameStatistics(),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'winningOption': winningOption,
      'winningFaction': winningFaction?.name,
      'isHumanVictory': isHumanVictory,
      'humanScore': humanScore,
      'playerScores': playerScores,
      'mvpPlayerId': mvpPlayerId,
      'gameDuration': gameDuration,
      'statistics': statistics.toJson(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }
}

/// 遊戲統計
class GameStatistics {
  /// 質詢次數
  final int queriesCount;

  /// 反駁次數
  final int rebutsCount;

  /// 技能使用次數
  final int skillsUsed;

  /// 結盟次數
  final int alliancesFormed;

  /// 背叛次數
  final int betrayalsCount;

  /// 造成的總傷害
  final int totalDamageDealt;

  /// 受到的總傷害
  final int totalDamageTaken;

  /// 私訊次數
  final int privateMessagesCount;

  const GameStatistics({
    this.queriesCount = 0,
    this.rebutsCount = 0,
    this.skillsUsed = 0,
    this.alliancesFormed = 0,
    this.betrayalsCount = 0,
    this.totalDamageDealt = 0,
    this.totalDamageTaken = 0,
    this.privateMessagesCount = 0,
  });

  GameStatistics copyWith({
    int? queriesCount,
    int? rebutsCount,
    int? skillsUsed,
    int? alliancesFormed,
    int? betrayalsCount,
    int? totalDamageDealt,
    int? totalDamageTaken,
    int? privateMessagesCount,
  }) {
    return GameStatistics(
      queriesCount: queriesCount ?? this.queriesCount,
      rebutsCount: rebutsCount ?? this.rebutsCount,
      skillsUsed: skillsUsed ?? this.skillsUsed,
      alliancesFormed: alliancesFormed ?? this.alliancesFormed,
      betrayalsCount: betrayalsCount ?? this.betrayalsCount,
      totalDamageDealt: totalDamageDealt ?? this.totalDamageDealt,
      totalDamageTaken: totalDamageTaken ?? this.totalDamageTaken,
      privateMessagesCount: privateMessagesCount ?? this.privateMessagesCount,
    );
  }

  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      queriesCount: json['queriesCount'] as int? ?? 0,
      rebutsCount: json['rebutsCount'] as int? ?? 0,
      skillsUsed: json['skillsUsed'] as int? ?? 0,
      alliancesFormed: json['alliancesFormed'] as int? ?? 0,
      betrayalsCount: json['betrayalsCount'] as int? ?? 0,
      totalDamageDealt: json['totalDamageDealt'] as int? ?? 0,
      totalDamageTaken: json['totalDamageTaken'] as int? ?? 0,
      privateMessagesCount: json['privateMessagesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queriesCount': queriesCount,
      'rebutsCount': rebutsCount,
      'skillsUsed': skillsUsed,
      'alliancesFormed': alliancesFormed,
      'betrayalsCount': betrayalsCount,
      'totalDamageDealt': totalDamageDealt,
      'totalDamageTaken': totalDamageTaken,
      'privateMessagesCount': privateMessagesCount,
    };
  }
}

// ============================================================
// AI 私訊內容
// ============================================================

/// AI 私訊模板
class AIMessageTemplates {
  AIMessageTemplates._();

  /// 結盟邀請訊息
  static const List<String> allianceRequests = [
    '我觀察您許久了，我們的立場似乎相近。不如結盟？',
    '這場辯論中我們需要盟友。您願意與我合作嗎？',
    '敵人的敵人就是朋友。我們應該聯手。',
    '我有一個提議：我們結盟，共同對抗那些威脅我們的人。',
    '明智的人知道何時需要盟友。您願意成為我的盟友嗎？',
  ];

  /// 警告訊息
  static const List<String> warnings = [
    '小心那個人，他似乎對您不懷好意。',
    '我聽到一些風聲，您可能是下一個目標。',
    '有人在背後議論您，請多加注意。',
    '我必須警告您，局勢對您不利。',
  ];

  /// 威脅訊息
  static const List<String> threats = [
    '如果您繼續這樣做，我不會客氣。',
    '這是最後的警告，別逼我動手。',
    '您的選擇會決定您的命運。',
  ];

  /// 交易提議
  static const List<String> tradeOffers = [
    '我有一個互惠的提議，您有興趣聽嗎？',
    '我願意用我的資源換取您的支持。',
    '我們可以達成一個對雙方都有利的協議。',
  ];

  /// 友好訊息
  static const List<String> friendly = [
    '辯論歸辯論，希望我們能保持君子之風。',
    '無論結果如何，能與您同場競技是榮幸。',
    '祝您好運，願最優秀的人勝出。',
  ];

  /// 根據 AI 個性獲取訊息
  static String getMessageForPersonality(
    AIPersonality personality,
    MessageIntent intent,
    Random random,
  ) {
    List<String> pool;

    switch (intent) {
      case MessageIntent.alliance:
        pool = allianceRequests;
      case MessageIntent.warning:
        pool = warnings;
      case MessageIntent.threat:
        pool = threats;
      case MessageIntent.trade:
        pool = tradeOffers;
      case MessageIntent.friendly:
        pool = friendly;
    }

    return pool[random.nextInt(pool.length)];
  }
}

/// 訊息意圖
enum MessageIntent {
  alliance,
  warning,
  threat,
  trade,
  friendly,
}

// ============================================================
// 回合管理相關類別
// ============================================================

/// 待處理的攻擊（等待反駁）
class PendingAttack {
  /// 攻擊者 ID
  final String attackerId;

  /// 目標 ID
  final String targetId;

  /// 基礎傷害
  final int baseDamage;

  /// 攻擊類型（query, skill, betray）
  final String attackType;

  /// 額外資料
  final Map<String, dynamic> data;

  /// 創建時間
  final DateTime timestamp;

  /// 反駁窗口時間（秒）
  final int rebutWindowSeconds;

  const PendingAttack({
    required this.attackerId,
    required this.targetId,
    required this.baseDamage,
    required this.attackType,
    this.data = const {},
    required this.timestamp,
    this.rebutWindowSeconds = 5,
  });

  /// 是否已過期
  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > rebutWindowSeconds;
  }
}

/// 玩家回合狀態
class TurnState {
  /// 玩家 ID
  final String playerId;

  /// 剩餘行動次數
  final int remainingActions;

  /// 是否已完成回合
  final bool isCompleted;

  /// 是否被跳過（如被沉默）
  final bool isSkipped;

  const TurnState({
    required this.playerId,
    required this.remainingActions,
    this.isCompleted = false,
    this.isSkipped = false,
  });

  TurnState copyWith({
    String? playerId,
    int? remainingActions,
    bool? isCompleted,
    bool? isSkipped,
  }) {
    return TurnState(
      playerId: playerId ?? this.playerId,
      remainingActions: remainingActions ?? this.remainingActions,
      isCompleted: isCompleted ?? this.isCompleted,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }
}

/// 技能效果結果
class SkillEffectResult {
  /// 是否成功
  final bool success;

  /// 效果描述
  final String description;

  /// 傷害值（如果造成傷害）
  final int? damage;

  /// 治療值（如果治療）
  final int? healing;

  /// 防禦加成（如果增加防禦）
  final int? defenseBonus;

  /// 額外效果
  final Map<String, dynamic> effects;

  const SkillEffectResult({
    required this.success,
    required this.description,
    this.damage,
    this.healing,
    this.defenseBonus,
    this.effects = const {},
  });
}

// ============================================================
// 單人遊戲控制器
// ============================================================

/// 單人遊戲控制器
///
/// 負責管理單人遊戲的整體流程，包括：
/// - 遊戲初始化
/// - 階段計時和轉換
/// - AI 行為執行
/// - 結果計算
class SoloGameController {
  /// AI 決策引擎
  final AIDecisionEngine _decisionEngine;

  /// 計時器
  Timer? _timer;

  /// 階段完成回調
  final void Function(GamePhase completedPhase)? _onPhaseComplete;

  /// 遊戲事件回調
  final void Function(GameEvent event)? _onGameEvent;

  /// 狀態更新回調
  final void Function(SoloGameRoom room)? _onStateUpdate;

  /// 隨機數生成器
  final Random _random;

  /// 當前遊戲房間
  SoloGameRoom? _currentRoom;

  /// 遊戲事件日誌
  final List<GameEvent> _eventLog = [];

  /// 遊戲統計
  GameStatistics _statistics = const GameStatistics();

  /// 投票收集
  final Map<String, VoteAction> _votes = {};

  /// 是否正在運行
  bool _isRunning = false;

  // ===== 回合管理 =====

  /// 當前回合索引
  int _currentTurnIndex = 0;

  /// 發言順序（玩家 ID 列表，按聲望排序）
  List<String> _turnOrder = [];

  /// 每個角色的剩餘行動次數
  final Map<String, int> _remainingActions = {};

  /// 每個角色每回合的基礎行動次數
  static const int _baseActionsPerTurn = 2;

  /// 當前防禦狀態（玩家 ID -> 防禦值）
  final Map<String, int> _activeDefenses = {};

  /// 被沉默的玩家列表（玩家 ID -> 剩餘回合數）
  final Map<String, int> _silencedPlayers = {};

  /// 等待玩家介入（如反駁）
  bool _awaitingPlayerIntervention = false;

  /// 待處理的攻擊（等待反駁）
  PendingAttack? _pendingAttack;

  SoloGameController({
    AIDecisionEngine? decisionEngine,
    void Function(GamePhase completedPhase)? onPhaseComplete,
    void Function(GameEvent event)? onGameEvent,
    void Function(SoloGameRoom room)? onStateUpdate,
    Random? random,
  })  : _decisionEngine = decisionEngine ?? AIDecisionEngine(),
        _onPhaseComplete = onPhaseComplete,
        _onGameEvent = onGameEvent,
        _onStateUpdate = onStateUpdate,
        _random = random ?? Random();

  /// 當前遊戲房間
  SoloGameRoom? get currentRoom => _currentRoom;

  /// 事件日誌
  List<GameEvent> get eventLog => List.unmodifiable(_eventLog);

  /// 遊戲統計
  GameStatistics get statistics => _statistics;

  /// 是否正在運行
  bool get isRunning => _isRunning;

  // ============================================================
  // 遊戲初始化
  // ============================================================

  /// 初始化遊戲
  ///
  /// 根據配置建立遊戲房間，分配角色和資源
  SoloGameRoom initializeGame(SoloGameConfig config) {
    _eventLog.clear();
    _statistics = const GameStatistics();
    _votes.clear();

    // 1. 獲取人類玩家角色
    final humanRole = RoleDatabase.getRoleById(config.humanCharacterId);
    if (humanRole == null) {
      throw ArgumentError('Invalid human character ID: ${config.humanCharacterId}');
    }

    // 2. 創建人類玩家
    final humanPlayer = Player(
      id: 'human_player',
      name: config.humanPlayerName,
      roleId: humanRole.id,
      reputation: humanRole.initialReputation,
      gold: humanRole.initialGold,
      intel: humanRole.initialIntel,
      favor: humanRole.initialFavor,
      isReady: true,
      isHost: true,
    );

    // 3. 獲取可用的 AI 角色（排除人類選擇的角色）
    final availableRoles = RoleDatabase.mvpRoles
        .where((role) => role.id != config.humanCharacterId)
        .toList();

    // 打亂角色順序
    availableRoles.shuffle(_random);

    // 4. 創建 AI 玩家
    final aiPlayers = <AIPlayer>[];
    final aiNames = ['湯瑪斯爵士', '伊麗莎白夫人', '約翰先生', '瑪格麗特小姐', '威廉公爵'];

    for (int i = 0; i < config.aiPlayerCount && i < availableRoles.length; i++) {
      final role = availableRoles[i];
      final aiPlayer = AIPlayer.createRandom(
        id: 'ai_$i',
        name: aiNames[i % aiNames.length],
        difficulty: config.difficulty,
        avatarIndex: i,
        roleId: role.id,
        reputation: role.initialReputation,
      );

      // 更新 AI 玩家的資源
      final updatedPlayer = aiPlayer.updatePlayer((p) => p.copyWith(
        gold: role.initialGold,
        intel: role.initialIntel,
        favor: role.initialFavor,
      ));

      aiPlayers.add(updatedPlayer);
    }

    // 5. 設置 AI 引擎的角色映射
    final playerRoles = <String, Role?>{
      humanPlayer.id: humanRole,
      for (final ai in aiPlayers)
        ai.id: ai.roleId != null ? RoleDatabase.getRoleById(ai.roleId!) : null,
    };
    _decisionEngine.setPlayerRoles(playerRoles);

    // 6. 創建遊戲房間
    _currentRoom = SoloGameRoom(
      id: 'solo_${DateTime.now().millisecondsSinceEpoch}',
      modeType: config.modeType,
      difficulty: config.difficulty,
      humanPlayer: humanPlayer,
      aiPlayers: aiPlayers,
      currentBill: BillDatabase.mvpBill,
      currentPhase: GamePhase.waiting,
      gameSpeed: config.gameSpeed,
      startTime: DateTime.now(),
    );

    // 7. 記錄遊戲開始事件
    _emitEvent(GameEvent.system(
      type: GameEventType.gameStart,
      description: '遊戲開始！議題：${BillDatabase.mvpBill.title}',
      data: {
        'difficulty': config.difficulty.name,
        'playerCount': 1 + config.aiPlayerCount,
        'billId': BillDatabase.mvpBill.id,
      },
    ));

    return _currentRoom!;
  }

  // ============================================================
  // 階段管理
  // ============================================================

  /// 開始階段
  ///
  /// 啟動計時器並初始化階段
  void startPhase(GamePhase phase, int durationSeconds) {
    if (_currentRoom == null) {
      throw StateError('Game not initialized');
    }

    _isRunning = true;

    // 更新階段
    _currentRoom = _currentRoom!.copyWith(
      currentPhase: phase,
      timeRemaining: durationSeconds,
    );

    // 記錄階段開始事件
    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '進入${_currentRoom!.phaseName}',
      data: {
        'phase': phase.name,
        'duration': durationSeconds,
      },
    ));

    // 階段特定初始化
    switch (phase) {
      case GamePhase.debate:
        _initializeDebatePhase();
      case GamePhase.voting:
        _votes.clear();
      default:
        break;
    }

    _notifyStateUpdate();

    // 啟動計時器
    _startTimer(durationSeconds);
  }

  /// 初始化辯論階段
  void _initializeDebatePhase() {
    if (_currentRoom == null) return;

    // 按聲望高低排序發言順序
    final allPlayerIds = [
      _currentRoom!.humanPlayer.id,
      ..._currentRoom!.aiPlayers.map((ai) => ai.id),
    ];

    // 排序：聲望高的先發言
    allPlayerIds.sort((a, b) {
      final repA = _getPlayerReputation(a);
      final repB = _getPlayerReputation(b);
      return repB.compareTo(repA);
    });

    _currentRoom = _currentRoom!.copyWith(
      speakingOrder: allPlayerIds,
      currentSpeakerId: allPlayerIds.isNotEmpty ? allPlayerIds[0] : null,
    );
  }

  /// 啟動計時器
  void _startTimer(int durationSeconds) {
    _timer?.cancel();

    // 根據遊戲速度調整計時器間隔
    final intervalMs = (1000 / (_currentRoom?.gameSpeed ?? 1.0)).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentRoom == null || !_isRunning) {
        timer.cancel();
        return;
      }

      final newTime = _currentRoom!.timeRemaining - 1;

      if (newTime <= 0) {
        timer.cancel();
        _onPhaseTimeUp();
      } else {
        _currentRoom = _currentRoom!.copyWith(timeRemaining: newTime);
        _notifyStateUpdate();
      }
    });
  }

  /// 階段時間結束
  void _onPhaseTimeUp() {
    if (_currentRoom == null) return;

    final completedPhase = _currentRoom!.currentPhase;

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '${_currentRoom!.phaseName}結束',
    ));

    _onPhaseComplete?.call(completedPhase);
  }

  /// 暫停遊戲
  void pauseGame() {
    _isRunning = false;
    _timer?.cancel();

    if (_currentRoom != null) {
      _currentRoom = _currentRoom!.copyWith(isPaused: true);
      _notifyStateUpdate();
    }
  }

  /// 恢復遊戲
  void resumeGame() {
    if (_currentRoom == null) return;

    _isRunning = true;
    _currentRoom = _currentRoom!.copyWith(isPaused: false);
    _notifyStateUpdate();

    // 重新啟動計時器
    _startTimer(_currentRoom!.timeRemaining);
  }

  /// 停止遊戲
  void stopGame() {
    _isRunning = false;
    _timer?.cancel();
    _currentRoom = null;
  }

  // ============================================================
  // 密謀階段
  // ============================================================

  /// 執行密謀階段
  ///
  /// AI 在此階段會：發送私訊、發起結盟
  /// 每個 AI 有 2-3 次行動機會
  Future<void> runConspiracyPhase() async {
    if (_currentRoom == null) return;

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '密謀階段開始，各方勢力暗中角力...',
    ));

    // 每個 AI 執行 2-3 次行動
    for (final aiPlayer in _currentRoom!.aiPlayers) {
      if (!aiPlayer.isAlive) continue;

      final actionCount = 2 + _random.nextInt(2); // 2-3 次

      for (int i = 0; i < actionCount; i++) {
        // 模擬思考時間（根據遊戲速度調整）
        final thinkingDelay = Duration(
          milliseconds: (1000 + _random.nextInt(2000)) ~/ (_currentRoom?.gameSpeed ?? 1.0).round(),
        );
        await Future.delayed(thinkingDelay);

        if (!_isRunning || _currentRoom == null) return;

        await _executeAIConspiracyAction(aiPlayer);
      }
    }

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '密謀階段結束',
    ));
  }

  /// 執行 AI 密謀動作
  Future<void> _executeAIConspiracyAction(AIPlayer ai) async {
    if (_currentRoom == null) return;

    // 將 SoloGameRoom 轉換為 GameState
    final gameState = _convertToGameState(_currentRoom!);

    // 獲取 AI 決策
    final decision = _decisionEngine.decide(ai, gameState);

    switch (decision.actionType) {
      case AIActionType.ally:
        await _handleAIAllianceRequest(ai, decision);

      case AIActionType.speak:
        await _handleAIPrivateMessage(ai, decision);

      case AIActionType.trade:
        await _handleAITradeOffer(ai, decision);

      default:
        // 密謀階段只處理社交動作
        break;
    }
  }

  /// 處理 AI 結盟請求
  Future<void> _handleAIAllianceRequest(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null || decision.targetId == null) return;

    final targetId = decision.targetId!;
    final message = AIMessageTemplates.getMessageForPersonality(
      ai.personality,
      MessageIntent.alliance,
      _random,
    );

    _emitEvent(GameEvent.player(
      type: GameEventType.allianceRequest,
      actorId: ai.id,
      targetId: targetId,
      description: '${ai.displayName} 向 ${_getPlayerName(targetId)} 發起結盟請求',
      data: {'message': message},
      isPublic: false,
    ));

    // 如果目標是人類玩家，等待回應
    // 如果目標是 AI，自動決定
    if (targetId != 'human_player') {
      final targetAI = _currentRoom!.getAIPlayer(targetId);
      if (targetAI != null) {
        final targetGameState = _convertToGameState(_currentRoom!);
        final targetDecision = _decisionEngine.decide(targetAI, targetGameState);

        // 根據關係分數決定是否接受
        final relationshipScore = targetAI.getRelationshipScore(ai.id);
        final shouldAccept = relationshipScore > -20 &&
            targetDecision.actionType != AIActionType.betray;

        if (shouldAccept) {
          _formAlliance(ai.id, targetId);
        } else {
          _emitEvent(GameEvent.player(
            type: GameEventType.allianceRejected,
            actorId: targetId,
            targetId: ai.id,
            description: '${_getPlayerName(targetId)} 拒絕了結盟請求',
            isPublic: false,
          ));
        }
      }
    }
  }

  /// 處理 AI 私訊
  Future<void> _handleAIPrivateMessage(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null || decision.targetId == null) return;

    final targetId = decision.targetId!;

    // 根據 AI 個性選擇訊息意圖
    MessageIntent intent;
    if (ai.personality == AIPersonality.aggressive) {
      intent = _random.nextBool() ? MessageIntent.threat : MessageIntent.warning;
    } else if (ai.personality == AIPersonality.diplomatic) {
      intent = _random.nextBool() ? MessageIntent.friendly : MessageIntent.alliance;
    } else {
      intent = MessageIntent.values[_random.nextInt(MessageIntent.values.length)];
    }

    final message = AIMessageTemplates.getMessageForPersonality(
      ai.personality,
      intent,
      _random,
    );

    _emitEvent(GameEvent.player(
      type: GameEventType.privateMessage,
      actorId: ai.id,
      targetId: targetId,
      description: '${ai.displayName} 向 ${_getPlayerName(targetId)} 發送私訊',
      data: {'message': message, 'intent': intent.name},
      isPublic: false,
    ));

    _statistics = _statistics.copyWith(
      privateMessagesCount: _statistics.privateMessagesCount + 1,
    );
  }

  /// 處理 AI 交易提議
  Future<void> _handleAITradeOffer(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null || decision.targetId == null) return;

    final targetId = decision.targetId!;
    final message = AIMessageTemplates.getMessageForPersonality(
      ai.personality,
      MessageIntent.trade,
      _random,
    );

    _emitEvent(GameEvent.player(
      type: GameEventType.privateMessage,
      actorId: ai.id,
      targetId: targetId,
      description: '${ai.displayName} 向 ${_getPlayerName(targetId)} 提出交易',
      data: {'message': message, 'type': 'trade'},
      isPublic: false,
    ));
  }

  /// 建立聯盟
  void _formAlliance(String player1Id, String player2Id) {
    if (_currentRoom == null) return;

    // 更新人類玩家的盟友列表
    if (player1Id == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer(
        (p) => p.copyWith(allies: [...p.allies, player2Id]),
      );
    } else if (player2Id == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer(
        (p) => p.copyWith(allies: [...p.allies, player1Id]),
      );
    }

    // 更新 AI 玩家的盟友列表
    if (player1Id != 'human_player') {
      _currentRoom = _currentRoom!.updateAIPlayer(player1Id, (ai) {
        return ai.updatePlayer((p) => p.copyWith(allies: [...p.allies, player2Id]));
      });
    }

    if (player2Id != 'human_player') {
      _currentRoom = _currentRoom!.updateAIPlayer(player2Id, (ai) {
        return ai.updatePlayer((p) => p.copyWith(allies: [...p.allies, player1Id]));
      });
    }

    _emitEvent(GameEvent.player(
      type: GameEventType.allianceAccepted,
      actorId: player1Id,
      targetId: player2Id,
      description: '${_getPlayerName(player1Id)} 與 ${_getPlayerName(player2Id)} 建立了秘密聯盟',
      isPublic: false,
    ));

    _statistics = _statistics.copyWith(
      alliancesFormed: _statistics.alliancesFormed + 1,
    );

    _notifyStateUpdate();
  }

  // ============================================================
  // 辯論階段
  // ============================================================

  /// 執行辯論階段
  ///
  /// 決定發言順序（依聲望高低）
  /// AI 輪流發言/質詢/反駁
  /// 處理玩家介入
  Future<void> runDebatePhase() async {
    if (_currentRoom == null) return;

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '辯論階段開始！議員們開始針鋒相對...',
    ));

    final speakingOrder = _currentRoom!.speakingOrder;

    for (int i = 0; i < speakingOrder.length; i++) {
      if (!_isRunning || _currentRoom == null) return;

      final speakerId = speakingOrder[i];

      _currentRoom = _currentRoom!.copyWith(currentSpeakerId: speakerId);
      _notifyStateUpdate();

      // 如果是人類玩家，跳過（等待玩家輸入）
      if (speakerId == 'human_player') {
        _emitEvent(GameEvent.system(
          type: GameEventType.playerSpeak,
          description: '輪到您發言了',
        ));
        continue;
      }

      // AI 發言
      final aiPlayer = _currentRoom!.getAIPlayer(speakerId);
      if (aiPlayer != null && aiPlayer.isAlive) {
        await _executeAIDebateAction(aiPlayer);
      }
    }

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '辯論階段結束',
    ));
  }

  /// 執行 AI 辯論動作
  Future<void> _executeAIDebateAction(AIPlayer ai) async {
    if (_currentRoom == null) return;

    // 模擬思考時間
    final thinkingDelay = Duration(
      milliseconds: (800 + _random.nextInt(1500)) ~/ (_currentRoom?.gameSpeed ?? 1.0).round(),
    );
    await Future.delayed(thinkingDelay);

    if (!_isRunning || _currentRoom == null) return;

    // 獲取 AI 決策
    final gameState = _convertToGameState(_currentRoom!);
    final decision = _decisionEngine.decide(ai, gameState);

    switch (decision.actionType) {
      case AIActionType.attack:
        await _executeAIQuery(ai, decision);

      case AIActionType.defend:
        await _executeAIRebut(ai, decision);

      case AIActionType.useSkill:
        await _executeAISkill(ai, decision);

      case AIActionType.speak:
        await _executeAISpeak(ai, decision);

      case AIActionType.betray:
        await _executeAIBetray(ai, decision);

      default:
        // 等待
        _emitEvent(GameEvent.player(
          type: GameEventType.playerSpeak,
          actorId: ai.id,
          description: '${ai.displayName} 保持沉默，靜觀其變',
        ));
    }
  }

  /// 執行 AI 質詢
  Future<void> _executeAIQuery(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null || decision.targetId == null) return;

    final targetId = decision.targetId!;
    final targetName = _getPlayerName(targetId);

    // 計算傷害
    const damage = GameConstants.queryBaseDamage;
    const cost = GameConstants.queryCost;

    // 更新 AI 聲望
    _currentRoom = _currentRoom!.updateAIPlayer(ai.id, (aiPlayer) {
      return aiPlayer.updatePlayer((p) => p.copyWith(
        reputation: (p.reputation - cost).clamp(0, GameConstants.maxReputation),
      ));
    });

    // 對目標造成傷害
    _applyDamage(targetId, damage);

    _emitEvent(GameEvent.player(
      type: GameEventType.playerQuery,
      actorId: ai.id,
      targetId: targetId,
      description: '${ai.displayName} 對 $targetName 發起質詢，造成 $damage 點傷害',
      data: {'damage': damage, 'cost': cost},
    ));

    _statistics = _statistics.copyWith(
      queriesCount: _statistics.queriesCount + 1,
      totalDamageDealt: _statistics.totalDamageDealt + damage,
    );

    _notifyStateUpdate();
  }

  /// 執行 AI 反駁
  Future<void> _executeAIRebut(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null) return;

    const block = GameConstants.rebutBlock;
    const cost = GameConstants.rebutCost;

    // 更新 AI 聲望
    _currentRoom = _currentRoom!.updateAIPlayer(ai.id, (aiPlayer) {
      return aiPlayer.updatePlayer((p) => p.copyWith(
        reputation: (p.reputation - cost).clamp(0, GameConstants.maxReputation),
      ));
    });

    _emitEvent(GameEvent.player(
      type: GameEventType.playerRebut,
      actorId: ai.id,
      description: '${ai.displayName} 提出反駁，防禦 $block 點傷害',
      data: {'block': block, 'cost': cost},
    ));

    _statistics = _statistics.copyWith(
      rebutsCount: _statistics.rebutsCount + 1,
    );

    _notifyStateUpdate();
  }

  /// 執行 AI 技能
  Future<void> _executeAISkill(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null) return;

    final role = ai.roleId != null ? RoleDatabase.getRoleById(ai.roleId!) : null;
    if (role == null || role.skills.isEmpty) return;

    final skill = role.skills.first;

    _emitEvent(GameEvent.player(
      type: GameEventType.playerSkill,
      actorId: ai.id,
      targetId: decision.targetId,
      description: '${ai.displayName} 使用技能「${skill.name}」：${skill.description}',
      data: {'skillId': skill.id, 'skillName': skill.name},
    ));

    _statistics = _statistics.copyWith(
      skillsUsed: _statistics.skillsUsed + 1,
    );

    _notifyStateUpdate();
  }

  /// 執行 AI 發言
  Future<void> _executeAISpeak(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null) return;

    // 根據 AI 個性生成發言內容
    final speeches = [
      '各位議員，我們必須認真考慮這個議案的後果！',
      '這項法案關係到我們國家的未來！',
      '我強烈反對這種不公正的提案！',
      '讓我們用理性來辯論，而非情緒！',
      '歷史將會證明，我們今天的選擇是正確的！',
    ];

    final speech = speeches[_random.nextInt(speeches.length)];

    _emitEvent(GameEvent.player(
      type: GameEventType.playerSpeak,
      actorId: ai.id,
      description: '${ai.displayName} 發言：「$speech」',
      data: {'content': speech},
    ));
  }

  /// 執行 AI 背叛
  Future<void> _executeAIBetray(AIPlayer ai, AIDecision decision) async {
    if (_currentRoom == null || decision.targetId == null) return;

    final targetId = decision.targetId!;

    // 檢查是否確實是盟友
    if (!ai.allies.contains(targetId)) return;

    const bonusDamage = GameConstants.betrayBonusDamage;
    const selfLoss = GameConstants.betraySelfLoss;

    // 移除聯盟關係
    _currentRoom = _currentRoom!.updateAIPlayer(ai.id, (aiPlayer) {
      final newAllies = List<String>.from(aiPlayer.allies)..remove(targetId);
      return aiPlayer.updatePlayer((p) => p.copyWith(
        allies: newAllies,
        reputation: (p.reputation - selfLoss).clamp(0, GameConstants.maxReputation),
      ));
    });

    // 對目標造成額外傷害
    _applyDamage(targetId, bonusDamage);

    _emitEvent(GameEvent.player(
      type: GameEventType.betrayal,
      actorId: ai.id,
      targetId: targetId,
      description: '${ai.displayName} 背叛了 ${_getPlayerName(targetId)}！造成 $bonusDamage 點傷害',
      data: {'damage': bonusDamage, 'selfLoss': selfLoss},
    ));

    _statistics = _statistics.copyWith(
      betrayalsCount: _statistics.betrayalsCount + 1,
      totalDamageDealt: _statistics.totalDamageDealt + bonusDamage,
    );

    _notifyStateUpdate();
  }

  /// 對目標造成傷害
  void _applyDamage(String targetId, int damage) {
    if (_currentRoom == null) return;

    if (targetId == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer((p) {
        final newRep = (p.reputation - damage).clamp(0, GameConstants.maxReputation);
        return p.copyWith(
          reputation: newRep,
          isAlive: newRep > 0,
        );
      });

      if (!_currentRoom!.humanPlayer.isAlive) {
        _emitEvent(GameEvent.player(
          type: GameEventType.playerEliminated,
          actorId: 'system',
          targetId: targetId,
          description: '您的聲望歸零，政治死亡！',
        ));
      }
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(targetId, (ai) {
        return ai.updatePlayer((p) {
          final newRep = (p.reputation - damage).clamp(0, GameConstants.maxReputation);
          return p.copyWith(
            reputation: newRep,
            isAlive: newRep > 0,
          );
        });
      });

      final targetAI = _currentRoom!.getAIPlayer(targetId);
      if (targetAI != null && !targetAI.isAlive) {
        _emitEvent(GameEvent.player(
          type: GameEventType.playerEliminated,
          actorId: 'system',
          targetId: targetId,
          description: '${targetAI.displayName} 的聲望歸零，政治死亡！',
        ));
      }
    }
  }

  // ============================================================
  // 投票階段
  // ============================================================

  /// 執行投票階段
  ///
  /// 收集所有投票，AI 根據策略投票
  Future<void> runVotingPhase() async {
    if (_currentRoom == null) return;

    _votes.clear();

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '投票階段開始！請各位議員投下您神聖的一票',
    ));

    // AI 投票
    for (final aiPlayer in _currentRoom!.aiPlayers) {
      if (!aiPlayer.isAlive) continue;

      // 模擬思考時間
      final thinkingDelay = Duration(
        milliseconds: (500 + _random.nextInt(1000)) ~/ (_currentRoom?.gameSpeed ?? 1.0).round(),
      );
      await Future.delayed(thinkingDelay);

      if (!_isRunning || _currentRoom == null) return;

      await _executeAIVote(aiPlayer);
    }

    _emitEvent(GameEvent.system(
      type: GameEventType.phaseChange,
      description: '等待您投票...',
    ));
  }

  /// 執行 AI 投票
  Future<void> _executeAIVote(AIPlayer ai) async {
    if (_currentRoom == null || _currentRoom!.currentBill == null) return;

    final gameState = _convertToGameState(_currentRoom!);
    final decision = _decisionEngine.decide(ai, gameState);

    // 從決策中獲取投票選項
    String option = decision.parameters['option'] as String? ?? 'C';

    // 計算投票權重
    final weight = _calculateVoteWeight(ai.reputation);

    final voteAction = VoteAction(
      id: 'vote_${ai.id}_${DateTime.now().millisecondsSinceEpoch}',
      actorId: ai.id,
      timestamp: DateTime.now(),
      option: option,
      weight: weight,
    );

    _votes[ai.id] = voteAction;

    _emitEvent(GameEvent.player(
      type: GameEventType.voteSubmitted,
      actorId: ai.id,
      description: '${ai.displayName} 已投票',
      data: {'option': option, 'weight': weight},
      isPublic: false, // 投票內容不公開
    ));
  }

  /// 提交人類玩家投票
  void submitHumanVote(String option) {
    if (_currentRoom == null) return;

    final weight = _calculateVoteWeight(_currentRoom!.humanPlayer.reputation);

    final voteAction = VoteAction(
      id: 'vote_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: 'human_player',
      timestamp: DateTime.now(),
      option: option,
      weight: weight,
    );

    _votes['human_player'] = voteAction;

    _emitEvent(GameEvent.player(
      type: GameEventType.voteSubmitted,
      actorId: 'human_player',
      description: '您已投票給選項 $option',
      data: {'option': option, 'weight': weight},
    ));

    _notifyStateUpdate();
  }

  /// 計算投票權重
  double _calculateVoteWeight(int reputation) {
    if (reputation <= 0) return GameConstants.voteWeightDead;
    if (reputation < 30) return GameConstants.voteWeightVeryLow;
    if (reputation < 50) return GameConstants.voteWeightLow;
    if (reputation > 80) return GameConstants.voteWeightHigh;
    return GameConstants.voteWeightNormal;
  }

  // ============================================================
  // 結果計算
  // ============================================================

  /// 計算遊戲結果
  SoloGameResult calculateResults() {
    if (_currentRoom == null) {
      throw StateError('Game not initialized');
    }

    // 1. 計算各選項得票
    final voteCounts = <String, double>{'A': 0, 'B': 0, 'C': 0};

    for (final vote in _votes.values) {
      voteCounts[vote.option] = (voteCounts[vote.option] ?? 0) + vote.weight;
    }

    // 2. 決定獲勝選項
    String winningOption = 'C';
    double maxVotes = 0;

    voteCounts.forEach((option, count) {
      if (count > maxVotes) {
        maxVotes = count;
        winningOption = option;
      }
    });

    // 3. 確定獲勝陣營
    Faction? winningFaction;
    final bill = _currentRoom!.currentBill;
    if (bill != null) {
      switch (winningOption) {
        case 'A':
          winningFaction = bill.optionA.benefitFaction;
        case 'B':
          winningFaction = bill.optionB.benefitFaction;
        case 'C':
          winningFaction = bill.optionC.benefitFaction;
      }
    }

    // 4. 計算玩家得分
    final playerScores = <String, int>{};
    int humanScore = 0;
    String? mvpPlayerId;
    int maxScore = 0;

    // 人類玩家得分
    final humanRole = RoleDatabase.getRoleById(_currentRoom!.humanPlayer.roleId ?? '');
    humanScore = _calculatePlayerScore(
      _currentRoom!.humanPlayer,
      humanRole,
      winningOption,
      winningFaction,
    );
    playerScores['human_player'] = humanScore;

    if (humanScore > maxScore) {
      maxScore = humanScore;
      mvpPlayerId = 'human_player';
    }

    // AI 玩家得分
    for (final ai in _currentRoom!.aiPlayers) {
      final aiRole = ai.roleId != null ? RoleDatabase.getRoleById(ai.roleId!) : null;
      final score = _calculatePlayerScore(ai.player, aiRole, winningOption, winningFaction);
      playerScores[ai.id] = score;

      if (score > maxScore) {
        maxScore = score;
        mvpPlayerId = ai.id;
      }
    }

    // 5. 判斷人類是否勝利
    final isHumanVictory = humanRole != null &&
        (humanRole.faction == winningFaction || winningFaction == null);

    // 6. 計算遊戲時長
    final gameDuration = _currentRoom!.startTime != null
        ? DateTime.now().difference(_currentRoom!.startTime!).inSeconds
        : 0;

    // 7. 生成結果事件
    _emitEvent(GameEvent.system(
      type: GameEventType.voteResult,
      description: '投票結果：選項 $winningOption 獲勝！',
      data: {
        'voteCounts': voteCounts,
        'winningOption': winningOption,
        'winningFaction': winningFaction?.name,
      },
    ));

    // 8. 構建結果
    final result = SoloGameResult(
      winningOption: winningOption,
      winningFaction: winningFaction,
      isHumanVictory: isHumanVictory,
      humanScore: humanScore,
      playerScores: playerScores,
      mvpPlayerId: mvpPlayerId,
      gameDuration: gameDuration,
      statistics: _statistics,
      achievements: _calculateAchievements(isHumanVictory),
    );

    _emitEvent(GameEvent.system(
      type: GameEventType.gameEnd,
      description: isHumanVictory ? '恭喜您取得勝利！' : '很遺憾，這次您未能獲勝',
      data: {'isHumanVictory': isHumanVictory, 'humanScore': humanScore},
    ));

    return result;
  }

  /// 計算玩家得分
  int _calculatePlayerScore(
    Player player,
    Role? role,
    String winningOption,
    Faction? winningFaction,
  ) {
    int score = 0;

    // 基礎分：剩餘聲望
    score += player.reputation;

    // 陣營勝利加分
    if (role != null && role.faction == winningFaction) {
      score += GameConstants.billVictoryScore;
    } else if (winningFaction == null) {
      // 折衷方案
      score += GameConstants.billCompromiseScore;
    }

    // 存活加分
    if (player.isAlive) {
      score += 20;
    }

    return score;
  }

  /// 計算成就
  List<Achievement> _calculateAchievements(bool isHumanVictory) {
    final achievements = <Achievement>[];

    // 勝利成就
    if (isHumanVictory) {
      achievements.add(const Achievement(
        id: 'victory',
        name: '議會新星',
        description: '在單人模式中取得勝利',
        playerId: 'human_player',
      ));
    }

    // 統計類成就
    if (_statistics.queriesCount >= 5) {
      achievements.add(const Achievement(
        id: 'eloquent',
        name: '雄辯家',
        description: '發起 5 次以上質詢',
        playerId: 'human_player',
      ));
    }

    if (_statistics.alliancesFormed >= 2) {
      achievements.add(const Achievement(
        id: 'diplomat',
        name: '外交家',
        description: '建立 2 個以上聯盟',
        playerId: 'human_player',
      ));
    }

    if (_statistics.betrayalsCount > 0) {
      achievements.add(const Achievement(
        id: 'backstabber',
        name: '背刺者',
        description: '背叛盟友',
        playerId: 'human_player',
      ));
    }

    return achievements;
  }

  // ============================================================
  // 輔助方法
  // ============================================================

  /// 將 SoloGameRoom 轉換為 GameState
  GameState _convertToGameState(SoloGameRoom room) {
    final allPlayers = [
      room.humanPlayer,
      ...room.aiPlayers.map((ai) => ai.player),
    ];

    return GameState(
      roomId: room.id,
      roomCode: 'SOLO',
      phase: room.currentPhase,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      timeRemaining: room.timeRemaining,
      players: allPlayers,
      currentBill: room.currentBill,
      actionLog: room.actionLog,
      currentSpeakerId: room.currentSpeakerId,
      speakingOrder: room.speakingOrder,
      startTime: room.startTime,
    );
  }

  /// 獲取玩家名稱
  String _getPlayerName(String playerId) {
    if (_currentRoom == null) return '未知';

    if (playerId == 'human_player') {
      return _currentRoom!.humanPlayer.name;
    }

    final aiPlayer = _currentRoom!.getAIPlayer(playerId);
    return aiPlayer?.displayName ?? '未知';
  }

  /// 發送事件
  void _emitEvent(GameEvent event) {
    _eventLog.add(event);
    _onGameEvent?.call(event);
  }

  /// 通知狀態更新
  void _notifyStateUpdate() {
    if (_currentRoom != null) {
      _onStateUpdate?.call(_currentRoom!);
    }
  }

  // ============================================================
  // AI 行動執行系統
  // ============================================================

  /// 模擬 AI 思考時間
  ///
  /// 根據難度等級決定延遲時間：
  /// - beginner: 0.5-1 秒
  /// - intermediate: 0.8-1.5 秒
  /// - advanced: 1-2 秒
  /// - expert/master: 1.5-2.5 秒
  Future<void> simulateAIThinking(AIDifficulty difficulty) async {
    if (_currentRoom == null) return;

    int minMs;
    int maxMs;

    switch (difficulty) {
      case AIDifficulty.beginner:
        minMs = 500;
        maxMs = 1000;
      case AIDifficulty.intermediate:
        minMs = 800;
        maxMs = 1500;
      case AIDifficulty.advanced:
        minMs = 1000;
        maxMs = 2000;
      case AIDifficulty.expert:
      case AIDifficulty.master:
        minMs = 1500;
        maxMs = 2500;
    }

    // 根據遊戲速度調整
    final gameSpeed = _currentRoom?.gameSpeed ?? 1.0;
    final adjustedMinMs = (minMs / gameSpeed).round();
    final adjustedMaxMs = (maxMs / gameSpeed).round();

    final delayMs = adjustedMinMs + _random.nextInt(adjustedMaxMs - adjustedMinMs);

    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// 執行 AI 行動
  ///
  /// 完整的 AI 行動執行流程：
  /// 1. 顯示 AI 正在思考
  /// 2. 模擬思考延遲
  /// 3. 執行行動
  /// 4. 產生遊戲事件
  /// 5. 更新狀態
  Future<void> executeAIAction(AIPlayer ai, GameAction action) async {
    if (_currentRoom == null || !_isRunning) return;

    // 1. 發送思考中事件
    _emitEvent(GameEvent.player(
      type: GameEventType.aiThinking,
      actorId: ai.id,
      description: '${ai.displayName} 正在思考...',
      data: {'difficulty': ai.difficulty.name},
    ));

    _notifyStateUpdate();

    // 2. 模擬思考時間
    await simulateAIThinking(ai.difficulty);

    if (!_isRunning || _currentRoom == null) return;

    // 3. 發送決策完成事件
    _emitEvent(GameEvent.player(
      type: GameEventType.aiDecided,
      actorId: ai.id,
      description: '${ai.displayName} 做出了決定',
      data: {'actionType': action.type.name},
    ));

    // 4. 根據動作類型執行
    switch (action.type) {
      case ActionType.query:
        if (action is QueryAction) {
          await _processQueryAction(ai, action);
        }

      case ActionType.rebut:
        if (action is RebutAction) {
          await _processRebutAction(ai, action);
        }

      case ActionType.skill:
        if (action is SkillAction) {
          await _processSkillAction(ai, action);
        }

      case ActionType.speak:
        if (action is SpeakAction) {
          _processSpeakAction(ai, action);
        }

      case ActionType.ally:
        if (action is AllyAction && action.targetId != null) {
          await _processAllyAction(ai, action);
        }

      case ActionType.betray:
        if (action is BetrayAction && action.targetId != null) {
          await _processBetrayAction(ai, action);
        }

      case ActionType.vote:
        if (action is VoteAction) {
          _processVoteAction(ai, action);
        }

      default:
        break;
    }

    // 5. 更新剩餘行動次數
    final remaining = _remainingActions[ai.id] ?? 0;
    if (remaining > 0) {
      _remainingActions[ai.id] = remaining - 1;
    }

    _notifyStateUpdate();
  }

  // ============================================================
  // 行動效果處理
  // ============================================================

  /// 處理攻擊（質詢）
  ///
  /// 流程：
  /// 1. 檢查目標是否有防禦
  /// 2. 計算實際傷害
  /// 3. 更新聲望
  /// 4. 檢查政治死亡
  Future<AttackResult> processAttack({
    required String attackerId,
    required String targetId,
    required int baseDamage,
    bool allowRebut = true,
    String attackType = 'query',
  }) async {
    if (_currentRoom == null) {
      return const AttackResult(
        success: false,
        actualDamage: 0,
        wasRebutted: false,
        description: '遊戲未初始化',
      );
    }

    final attackerName = _getPlayerName(attackerId);
    final targetName = _getPlayerName(targetId);

    // 1. 檢查攻擊者是否被沉默
    if (_silencedPlayers.containsKey(attackerId)) {
      return AttackResult(
        success: false,
        actualDamage: 0,
        wasRebutted: false,
        description: '$attackerName 被沉默，無法發起攻擊',
      );
    }

    // 2. 如果允許反駁，設置待處理攻擊
    if (allowRebut && targetId == 'human_player') {
      _pendingAttack = PendingAttack(
        attackerId: attackerId,
        targetId: targetId,
        baseDamage: baseDamage,
        attackType: attackType,
        timestamp: DateTime.now(),
      );
      _awaitingPlayerIntervention = true;

      _emitEvent(GameEvent.system(
        type: GameEventType.playerQuery,
        description: '$attackerName 對您發起攻擊！您可以選擇反駁',
        data: {'damage': baseDamage, 'canRebut': true},
      ));

      // 等待玩家反應或超時
      await Future.delayed(Duration(seconds: _pendingAttack!.rebutWindowSeconds));

      if (_pendingAttack == null) {
        // 玩家已反駁
        return const AttackResult(
          success: false,
          actualDamage: 0,
          wasRebutted: true,
          description: '攻擊被反駁',
        );
      }

      _awaitingPlayerIntervention = false;
    }

    // 3. 檢查目標防禦
    int defense = _activeDefenses[targetId] ?? 0;
    int actualDamage = (baseDamage - defense).clamp(0, baseDamage);

    // 清除已使用的防禦
    if (defense > 0) {
      _activeDefenses.remove(targetId);
      _emitEvent(GameEvent.player(
        type: GameEventType.defenseActivated,
        actorId: targetId,
        description: '$targetName 的防禦生效，抵擋了 $defense 點傷害',
        data: {'blocked': defense},
      ));
    }

    // 4. 計算陣營克制加成
    final attackerRole = _getPlayerRole(attackerId);
    final targetRole = _getPlayerRole(targetId);
    if (attackerRole != null && targetRole != null) {
      final multiplier = FactionCounter.getDamageMultiplier(
        attackerRole.faction,
        targetRole.faction,
      );
      actualDamage = (actualDamage * multiplier).round();
    }

    // 5. 應用傷害
    _applyDamage(targetId, actualDamage);

    // 6. 檢查政治死亡
    final targetAlive = _isPlayerAlive(targetId);

    _pendingAttack = null;

    return AttackResult(
      success: true,
      actualDamage: actualDamage,
      wasRebutted: false,
      targetEliminated: !targetAlive,
      description: '$attackerName 對 $targetName 造成 $actualDamage 點傷害',
    );
  }

  /// 處理防禦（反駁）
  ///
  /// 抵銷攻擊，更新防禦狀態
  void processDefense({
    required String defenderId,
    int? defenseValue,
  }) {
    if (_currentRoom == null) return;

    final defense = defenseValue ?? GameConstants.rebutBlock;
    final defenderName = _getPlayerName(defenderId);

    // 設置防禦狀態
    _activeDefenses[defenderId] = defense;

    // 消耗聲望
    const cost = GameConstants.rebutCost;
    _updatePlayerReputation(defenderId, -cost);

    _emitEvent(GameEvent.player(
      type: GameEventType.playerRebut,
      actorId: defenderId,
      description: '$defenderName 準備反駁，獲得 $defense 點防禦',
      data: {'defense': defense, 'cost': cost},
    ));

    // 如果有待處理的攻擊，嘗試抵消
    if (_pendingAttack != null && _pendingAttack!.targetId == defenderId) {
      _emitEvent(GameEvent.player(
        type: GameEventType.defenseActivated,
        actorId: defenderId,
        description: '$defenderName 成功反駁了攻擊！',
      ));
      _pendingAttack = null;
      _awaitingPlayerIntervention = false;
    }

    _statistics = _statistics.copyWith(
      rebutsCount: _statistics.rebutsCount + 1,
    );

    _notifyStateUpdate();
  }

  /// 處理結盟
  ///
  /// 建立同盟關係，更新雙方狀態
  void processAlly({
    required String initiatorId,
    required String targetId,
    bool isPublic = false,
  }) {
    if (_currentRoom == null) return;

    final initiatorName = _getPlayerName(initiatorId);
    final targetName = _getPlayerName(targetId);

    // 更新盟友關係
    _addAlly(initiatorId, targetId);
    _addAlly(targetId, initiatorId);

    _emitEvent(GameEvent.player(
      type: GameEventType.allianceAccepted,
      actorId: initiatorId,
      targetId: targetId,
      description: isPublic
          ? '$initiatorName 與 $targetName 公開結盟'
          : '$initiatorName 與 $targetName 建立了秘密同盟',
      isPublic: isPublic,
      data: {'isPublic': isPublic},
    ));

    _statistics = _statistics.copyWith(
      alliancesFormed: _statistics.alliancesFormed + 1,
    );

    _notifyStateUpdate();
  }

  /// 處理技能
  ///
  /// 根據技能類型執行對應效果
  Future<SkillEffectResult> processSkill({
    required String userId,
    required String skillId,
    String? targetId,
  }) async {
    if (_currentRoom == null) {
      return const SkillEffectResult(
        success: false,
        description: '遊戲未初始化',
      );
    }

    final role = _getPlayerRole(userId);
    if (role == null) {
      return const SkillEffectResult(
        success: false,
        description: '無法找到角色資料',
      );
    }

    final skill = role.skills.where((s) => s.id == skillId).firstOrNull;
    if (skill == null) {
      return const SkillEffectResult(
        success: false,
        description: '技能不存在',
      );
    }

    final userName = _getPlayerName(userId);

    // 根據角色和技能執行不同效果
    switch (role.id) {
      case 'worker_thomas':
        return _processWorkerThomasSkill(userId, skillId, targetId);

      case 'factory_richard':
        return _processFactoryRichardSkill(userId, skillId, targetId);

      case 'press_edward':
        return _processPressEdwardSkill(userId, skillId, targetId);

      case 'luddite_george':
        return _processLudditeGeorgeSkill(userId, skillId, targetId);

      default:
        _emitEvent(GameEvent.player(
          type: GameEventType.skillActivated,
          actorId: userId,
          targetId: targetId,
          description: '$userName 使用技能「${skill.name}」',
          data: {'skillId': skillId},
        ));

        return SkillEffectResult(
          success: true,
          description: '${skill.name}：${skill.description}',
        );
    }
  }

  /// 工人湯瑪斯技能處理
  SkillEffectResult _processWorkerThomasSkill(
    String userId,
    String skillId,
    String? targetId,
  ) {
    final userName = _getPlayerName(userId);

    switch (skillId) {
      case 'worker_rage':
        // 工人之怒：對資方角色造成 +50% 聲望傷害
        if (targetId == null) {
          return const SkillEffectResult(
            success: false,
            description: '需要指定目標',
          );
        }

        final targetRole = _getPlayerRole(targetId);
        if (targetRole?.faction != Faction.factory) {
          return const SkillEffectResult(
            success: false,
            description: '工人之怒只能對資方角色使用',
          );
        }

        const baseDamage = GameConstants.queryBaseDamage;
        final bonusDamage = (baseDamage * 0.5).round();
        final totalDamage = baseDamage + bonusDamage;

        _applyDamage(targetId, totalDamage);

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          targetId: targetId,
          description: '$userName 發動「工人之怒」，造成 $totalDamage 點傷害！',
          data: {'damage': totalDamage, 'bonus': bonusDamage},
        ));

        _statistics = _statistics.copyWith(
          skillsUsed: _statistics.skillsUsed + 1,
          totalDamageDealt: _statistics.totalDamageDealt + totalDamage,
        );

        return SkillEffectResult(
          success: true,
          description: '工人之怒對資方造成加倍傷害',
          damage: totalDamage,
        );

      case 'unity':
        // 團結一致：被動技能，計算防禦加成
        final allies = _getPlayerAllies(userId);
        int workerAllyCount = 0;

        for (final allyId in allies) {
          final allyRole = _getPlayerRole(allyId);
          if (allyRole?.faction == Faction.worker) {
            workerAllyCount++;
          }
        }

        final defenseBonus = workerAllyCount * 10;
        _activeDefenses[userId] = (_activeDefenses[userId] ?? 0) + defenseBonus;

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          description: '$userName 的「團結一致」生效，獲得 +$defenseBonus 防禦',
          data: {'defenseBonus': defenseBonus, 'allyCount': workerAllyCount},
        ));

        return SkillEffectResult(
          success: true,
          description: '每有一名工人盟友，防禦 +10',
          defenseBonus: defenseBonus,
        );

      case 'sympathy_card':
        // 悲情牌：消耗 10 聲望，獲得 20 金幣
        _updatePlayerReputation(userId, -10);
        _updatePlayerGold(userId, 20);

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          description: '$userName 打出「悲情牌」，消耗 10 聲望獲得 20 金幣',
          data: {'reputationCost': 10, 'goldGain': 20},
        ));

        return const SkillEffectResult(
          success: true,
          description: '消耗 10 聲望，獲得 20 金幣',
        );

      default:
        return const SkillEffectResult(
          success: false,
          description: '未知技能',
        );
    }
  }

  /// 工廠主理查技能處理
  SkillEffectResult _processFactoryRichardSkill(
    String userId,
    String skillId,
    String? targetId,
  ) {
    final userName = _getPlayerName(userId);

    switch (skillId) {
      case 'bribe':
        // 金錢攻勢：消耗 30 金幣，使目標本回合沉默
        if (targetId == null) {
          return const SkillEffectResult(
            success: false,
            description: '需要指定目標',
          );
        }

        final currentGold = _getPlayerGold(userId);
        if (currentGold < 30) {
          return const SkillEffectResult(
            success: false,
            description: '金幣不足',
          );
        }

        _updatePlayerGold(userId, -30);
        _silencedPlayers[targetId] = 1; // 沉默 1 回合

        final targetName = _getPlayerName(targetId);

        _emitEvent(GameEvent.player(
          type: GameEventType.playerSilenced,
          actorId: userId,
          targetId: targetId,
          description: '$userName 對 $targetName 使用「金錢攻勢」，使其本回合沉默！',
          data: {'goldCost': 30, 'silenceTurns': 1},
        ));

        _statistics = _statistics.copyWith(skillsUsed: _statistics.skillsUsed + 1);

        return const SkillEffectResult(
          success: true,
          description: '目標本回合無法行動',
          effects: {'silenced': true},
        );

      case 'economic_argument':
        // 經濟論述：被動技能，質詢時說服力 +30%
        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          description: '$userName 的「經濟論述」增強了攻擊效果',
        ));

        return const SkillEffectResult(
          success: true,
          description: '使用數據論點時，說服力 +30%',
          effects: {'damageMultiplier': 1.3},
        );

      case 'industry_alliance':
        // 產業聯盟：所有資方角色本回合獲得 +15 防禦
        _updatePlayerReputation(userId, -10);

        int affected = 0;
        if (_currentRoom != null) {
          for (final ai in _currentRoom!.aiPlayers) {
            final aiRole = ai.roleId != null ? RoleDatabase.getRoleById(ai.roleId!) : null;
            if (aiRole?.faction == Faction.factory) {
              _activeDefenses[ai.id] = (_activeDefenses[ai.id] ?? 0) + 15;
              affected++;
            }
          }

          final humanRole = _getPlayerRole('human_player');
          if (humanRole?.faction == Faction.factory) {
            _activeDefenses['human_player'] = (_activeDefenses['human_player'] ?? 0) + 15;
            affected++;
          }
        }

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          description: '$userName 發動「產業聯盟」，所有資方獲得 +15 防禦',
          data: {'affectedCount': affected, 'defenseBonus': 15},
        ));

        return SkillEffectResult(
          success: true,
          description: '所有資方角色獲得 +15 防禦',
          defenseBonus: 15,
          effects: {'affectedCount': affected},
        );

      default:
        return const SkillEffectResult(
          success: false,
          description: '未知技能',
        );
    }
  }

  /// 記者愛德華技能處理
  SkillEffectResult _processPressEdwardSkill(
    String userId,
    String skillId,
    String? targetId,
  ) {
    final userName = _getPlayerName(userId);

    switch (skillId) {
      case 'exclusive_report':
        // 獨家報導：免費獲得 1 張隨機情報卡
        _updatePlayerIntel(userId, 1);

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          description: '$userName 發布「獨家報導」，獲得情報',
        ));

        return const SkillEffectResult(
          success: true,
          description: '獲得 1 點情報',
          effects: {'intelGain': 1},
        );

      case 'deep_investigation':
        // 深入調查：揭露目標陣營
        if (targetId == null) {
          return const SkillEffectResult(
            success: false,
            description: '需要指定目標',
          );
        }

        final targetRole = _getPlayerRole(targetId);
        final targetName = _getPlayerName(targetId);

        if (targetRole != null) {
          _emitEvent(GameEvent.player(
            type: GameEventType.skillEffect,
            actorId: userId,
            targetId: targetId,
            description: '$userName 調查揭露：$targetName 屬於${targetRole.factionName}！',
            data: {'faction': targetRole.faction.name},
          ));

          return SkillEffectResult(
            success: true,
            description: '揭露了 $targetName 的陣營',
            effects: {'revealedFaction': targetRole.faction.name},
          );
        }

        return const SkillEffectResult(
          success: false,
          description: '無法找到目標資料',
        );

      case 'public_opinion':
        // 輿論操控：被動技能，揭露情報時額外造成 +20% 傷害
        return const SkillEffectResult(
          success: true,
          description: '揭露情報時，額外造成 +20% 傷害',
          effects: {'revealDamageBonus': 0.2},
        );

      default:
        return const SkillEffectResult(
          success: false,
          description: '未知技能',
        );
    }
  }

  /// 盧德派喬治技能處理
  SkillEffectResult _processLudditeGeorgeSkill(
    String userId,
    String skillId,
    String? targetId,
  ) {
    final userName = _getPlayerName(userId);

    switch (skillId) {
      case 'rage_fire':
        // 怒火：造成雙倍傷害，但自己也扣 10 聲望
        if (targetId == null) {
          return const SkillEffectResult(
            success: false,
            description: '需要指定目標',
          );
        }

        const baseDamage = GameConstants.queryBaseDamage;
        const doubleDamage = baseDamage * 2;
        const selfDamage = 10;

        _applyDamage(targetId, doubleDamage);
        _updatePlayerReputation(userId, -selfDamage);

        final targetName = _getPlayerName(targetId);

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          targetId: targetId,
          description: '$userName 怒火中燒，對 $targetName 造成 $doubleDamage 點傷害！（自損 $selfDamage）',
          data: {'damage': doubleDamage, 'selfDamage': selfDamage},
        ));

        _statistics = _statistics.copyWith(
          skillsUsed: _statistics.skillsUsed + 1,
          totalDamageDealt: _statistics.totalDamageDealt + doubleDamage,
        );

        return const SkillEffectResult(
          success: true,
          description: '造成雙倍傷害，但自己也扣 10 聲望',
          damage: doubleDamage,
        );

      case 'intimidation':
        // 威嚇：目標下回合無法對你使用質詢
        if (targetId == null) {
          return const SkillEffectResult(
            success: false,
            description: '需要指定目標',
          );
        }

        final targetName = _getPlayerName(targetId);

        _emitEvent(GameEvent.player(
          type: GameEventType.skillEffect,
          actorId: userId,
          targetId: targetId,
          description: '$userName 威嚇 $targetName，使其下回合無法對您發起質詢',
        ));

        // 這個效果需要在處理質詢時檢查
        return const SkillEffectResult(
          success: true,
          description: '目標下回合無法對你使用質詢',
          effects: {'intimidated': true},
        );

      case 'resilience':
        // 堅韌：被動技能，聲望低於 30 時，防禦 +20
        final reputation = _getPlayerReputation(userId);
        if (reputation < 30) {
          _activeDefenses[userId] = (_activeDefenses[userId] ?? 0) + 20;

          _emitEvent(GameEvent.player(
            type: GameEventType.skillEffect,
            actorId: userId,
            description: '$userName 的「堅韌」觸發，防禦 +20',
          ));

          return const SkillEffectResult(
            success: true,
            description: '聲望低於 30 時，防禦 +20',
            defenseBonus: 20,
          );
        }

        return const SkillEffectResult(
          success: false,
          description: '聲望高於 30，堅韌未觸發',
        );

      default:
        return const SkillEffectResult(
          success: false,
          description: '未知技能',
        );
    }
  }

  // ============================================================
  // 回合管理系統
  // ============================================================

  /// 初始化回合順序
  ///
  /// 按聲望高低排序玩家
  void initializeTurnOrder() {
    if (_currentRoom == null) return;

    // 獲取所有存活玩家
    final allPlayerIds = <String>[];

    if (_currentRoom!.humanPlayer.isAlive) {
      allPlayerIds.add('human_player');
    }

    for (final ai in _currentRoom!.aiPlayers) {
      if (ai.isAlive) {
        allPlayerIds.add(ai.id);
      }
    }

    // 按聲望排序（高到低）
    allPlayerIds.sort((a, b) {
      final repA = _getPlayerReputation(a);
      final repB = _getPlayerReputation(b);
      return repB.compareTo(repA);
    });

    _turnOrder = allPlayerIds;
    _currentTurnIndex = 0;

    // 初始化每個玩家的行動次數
    for (final playerId in allPlayerIds) {
      _remainingActions[playerId] = _baseActionsPerTurn;
    }

    // 更新沉默狀態
    _updateSilenceStatus();

    _emitEvent(GameEvent.system(
      type: GameEventType.roundStart,
      description: '新回合開始，發言順序已決定',
      data: {'order': _turnOrder},
    ));
  }

  /// 更新沉默狀態
  void _updateSilenceStatus() {
    final toRemove = <String>[];

    _silencedPlayers.forEach((playerId, turnsRemaining) {
      if (turnsRemaining <= 1) {
        toRemove.add(playerId);
      } else {
        _silencedPlayers[playerId] = turnsRemaining - 1;
      }
    });

    for (final playerId in toRemove) {
      _silencedPlayers.remove(playerId);
    }
  }

  /// 獲取當前回合玩家
  String? getCurrentTurnPlayer() {
    if (_turnOrder.isEmpty || _currentTurnIndex >= _turnOrder.length) {
      return null;
    }
    return _turnOrder[_currentTurnIndex];
  }

  /// 推進到下一個回合
  ///
  /// 返回是否還有更多回合
  bool advanceToNextTurn() {
    _currentTurnIndex++;

    if (_currentTurnIndex >= _turnOrder.length) {
      // 回合結束
      _emitEvent(GameEvent.system(
        type: GameEventType.roundEnd,
        description: '本輪發言結束',
      ));
      return false;
    }

    final nextPlayerId = _turnOrder[_currentTurnIndex];
    final playerName = _getPlayerName(nextPlayerId);

    // 檢查是否被沉默
    if (_silencedPlayers.containsKey(nextPlayerId)) {
      _emitEvent(GameEvent.player(
        type: GameEventType.playerSilenced,
        actorId: nextPlayerId,
        description: '$playerName 被沉默，跳過回合',
      ));
      return advanceToNextTurn(); // 遞歸跳過
    }

    _emitEvent(GameEvent.system(
      type: GameEventType.turnChange,
      description: '輪到 $playerName 行動',
      data: {'playerId': nextPlayerId},
    ));

    _notifyStateUpdate();
    return true;
  }

  /// 玩家可以在任何時候插入反駁
  bool canPlayerIntervene(String playerId) {
    // 檢查是否有待處理的攻擊針對該玩家
    if (_pendingAttack != null && _pendingAttack!.targetId == playerId) {
      return true;
    }

    // 檢查是否被沉默
    if (_silencedPlayers.containsKey(playerId)) {
      return false;
    }

    return true;
  }

  /// 人類玩家介入（如反駁）
  void humanPlayerIntervene(GameAction action) {
    if (!_awaitingPlayerIntervention) return;

    if (action.type == ActionType.rebut) {
      processDefense(defenderId: 'human_player');
    }
  }

  /// 檢查玩家是否還有行動次數
  bool hasRemainingActions(String playerId) {
    return (_remainingActions[playerId] ?? 0) > 0;
  }

  /// 獲取玩家剩餘行動次數
  int getRemainingActions(String playerId) {
    return _remainingActions[playerId] ?? 0;
  }

  // ============================================================
  // 私有輔助方法
  // ============================================================

  /// 處理質詢動作
  Future<void> _processQueryAction(AIPlayer ai, QueryAction action) async {
    if (action.targetId == null) return;

    final result = await processAttack(
      attackerId: ai.id,
      targetId: action.targetId!,
      baseDamage: action.damage,
    );

    // 消耗聲望
    _updatePlayerReputation(ai.id, -action.reputationCost);

    _emitEvent(GameEvent.player(
      type: GameEventType.playerQuery,
      actorId: ai.id,
      targetId: action.targetId,
      description: result.description,
      data: {
        'damage': result.actualDamage,
        'wasRebutted': result.wasRebutted,
      },
    ));

    _statistics = _statistics.copyWith(
      queriesCount: _statistics.queriesCount + 1,
      totalDamageDealt: _statistics.totalDamageDealt + result.actualDamage,
    );
  }

  /// 處理反駁動作
  Future<void> _processRebutAction(AIPlayer ai, RebutAction action) async {
    processDefense(
      defenderId: ai.id,
      defenseValue: action.damageReduced,
    );
  }

  /// 處理技能動作
  Future<void> _processSkillAction(AIPlayer ai, SkillAction action) async {
    await processSkill(
      userId: ai.id,
      skillId: action.skillId,
      targetId: action.targetId,
    );
  }

  /// 處理發言動作
  void _processSpeakAction(AIPlayer ai, SpeakAction action) {
    _emitEvent(GameEvent.player(
      type: GameEventType.playerSpeak,
      actorId: ai.id,
      targetId: action.targetId,
      description: '${ai.displayName} 發言：「${action.content}」',
      data: {'content': action.content, 'isPublic': action.isPublic},
      isPublic: action.isPublic,
    ));
  }

  /// 處理結盟動作
  Future<void> _processAllyAction(AIPlayer ai, AllyAction action) async {
    if (action.targetId == null) return;

    processAlly(
      initiatorId: ai.id,
      targetId: action.targetId!,
      isPublic: action.isPublic,
    );
  }

  /// 處理背叛動作
  Future<void> _processBetrayAction(AIPlayer ai, BetrayAction action) async {
    if (action.targetId == null) return;

    // 移除聯盟
    _removeAlly(ai.id, action.targetId!);

    // 造成額外傷害
    _applyDamage(action.targetId!, action.bonusDamage);

    // 自損聲望
    _updatePlayerReputation(ai.id, -action.selfReputationLoss);

    _emitEvent(GameEvent.player(
      type: GameEventType.betrayal,
      actorId: ai.id,
      targetId: action.targetId,
      description: '${ai.displayName} 背叛了 ${_getPlayerName(action.targetId!)}！',
      data: {
        'damage': action.bonusDamage,
        'selfLoss': action.selfReputationLoss,
      },
    ));

    _statistics = _statistics.copyWith(
      betrayalsCount: _statistics.betrayalsCount + 1,
      totalDamageDealt: _statistics.totalDamageDealt + action.bonusDamage,
    );
  }

  /// 處理投票動作
  void _processVoteAction(AIPlayer ai, VoteAction action) {
    _votes[ai.id] = action;

    _emitEvent(GameEvent.player(
      type: GameEventType.voteSubmitted,
      actorId: ai.id,
      description: '${ai.displayName} 已投票',
      data: {'option': action.option, 'weight': action.weight},
      isPublic: false,
    ));
  }

  /// 獲取玩家角色
  Role? _getPlayerRole(String playerId) {
    if (_currentRoom == null) return null;

    if (playerId == 'human_player') {
      return RoleDatabase.getRoleById(_currentRoom!.humanPlayer.roleId ?? '');
    }

    final ai = _currentRoom!.getAIPlayer(playerId);
    if (ai?.roleId != null) {
      return RoleDatabase.getRoleById(ai!.roleId!);
    }

    return null;
  }

  /// 獲取玩家聲望
  int _getPlayerReputation(String playerId) {
    if (_currentRoom == null) return 0;

    if (playerId == 'human_player') {
      return _currentRoom!.humanPlayer.reputation;
    }

    return _currentRoom!.getAIPlayer(playerId)?.reputation ?? 0;
  }

  /// 更新玩家聲望
  void _updatePlayerReputation(String playerId, int delta) {
    if (_currentRoom == null) return;

    if (playerId == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(
        reputation: (p.reputation + delta).clamp(0, GameConstants.maxReputation),
      ));
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(playerId, (ai) {
        return ai.updatePlayer((p) => p.copyWith(
          reputation: (p.reputation + delta).clamp(0, GameConstants.maxReputation),
        ));
      });
    }

    if (delta != 0) {
      _emitEvent(GameEvent.player(
        type: GameEventType.reputationChange,
        actorId: playerId,
        description: '${_getPlayerName(playerId)} 聲望 ${delta > 0 ? '+' : ''}$delta',
        data: {'delta': delta},
      ));
    }
  }

  /// 獲取玩家金幣
  int _getPlayerGold(String playerId) {
    if (_currentRoom == null) return 0;

    if (playerId == 'human_player') {
      return _currentRoom!.humanPlayer.gold;
    }

    return _currentRoom!.getAIPlayer(playerId)?.gold ?? 0;
  }

  /// 更新玩家金幣
  void _updatePlayerGold(String playerId, int delta) {
    if (_currentRoom == null) return;

    if (playerId == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(
        gold: (p.gold + delta).clamp(0, GameConstants.maxGold),
      ));
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(playerId, (ai) {
        return ai.updatePlayer((p) => p.copyWith(
          gold: (p.gold + delta).clamp(0, GameConstants.maxGold),
        ));
      });
    }
  }

  /// 更新玩家情報
  void _updatePlayerIntel(String playerId, int delta) {
    if (_currentRoom == null) return;

    if (playerId == 'human_player') {
      _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(
        intel: (p.intel + delta).clamp(0, GameConstants.maxIntel),
      ));
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(playerId, (ai) {
        return ai.updatePlayer((p) => p.copyWith(
          intel: (p.intel + delta).clamp(0, GameConstants.maxIntel),
        ));
      });
    }
  }

  /// 檢查玩家是否存活
  bool _isPlayerAlive(String playerId) {
    if (_currentRoom == null) return false;

    if (playerId == 'human_player') {
      return _currentRoom!.humanPlayer.isAlive;
    }

    return _currentRoom!.getAIPlayer(playerId)?.isAlive ?? false;
  }

  /// 獲取玩家盟友列表
  List<String> _getPlayerAllies(String playerId) {
    if (_currentRoom == null) return [];

    if (playerId == 'human_player') {
      return _currentRoom!.humanPlayer.allies;
    }

    return _currentRoom!.getAIPlayer(playerId)?.allies ?? [];
  }

  /// 添加盟友
  void _addAlly(String playerId, String allyId) {
    if (_currentRoom == null) return;

    if (playerId == 'human_player') {
      final allies = List<String>.from(_currentRoom!.humanPlayer.allies);
      if (!allies.contains(allyId)) {
        allies.add(allyId);
        _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(allies: allies));
      }
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(playerId, (ai) {
        final allies = List<String>.from(ai.allies);
        if (!allies.contains(allyId)) {
          allies.add(allyId);
          return ai.updatePlayer((p) => p.copyWith(allies: allies));
        }
        return ai;
      });
    }
  }

  /// 移除盟友
  void _removeAlly(String playerId, String allyId) {
    if (_currentRoom == null) return;

    if (playerId == 'human_player') {
      final allies = List<String>.from(_currentRoom!.humanPlayer.allies)..remove(allyId);
      _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(allies: allies));
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(playerId, (ai) {
        final allies = List<String>.from(ai.allies)..remove(allyId);
        return ai.updatePlayer((p) => p.copyWith(allies: allies));
      });
    }

    // 也從對方移除
    if (allyId == 'human_player') {
      final allies = List<String>.from(_currentRoom!.humanPlayer.allies)..remove(playerId);
      _currentRoom = _currentRoom!.updateHumanPlayer((p) => p.copyWith(allies: allies));
    } else {
      _currentRoom = _currentRoom!.updateAIPlayer(allyId, (ai) {
        final allies = List<String>.from(ai.allies)..remove(playerId);
        return ai.updatePlayer((p) => p.copyWith(allies: allies));
      });
    }
  }

  /// 釋放資源
  void dispose() {
    _timer?.cancel();
    _isRunning = false;
    _currentRoom = null;
    _eventLog.clear();
    _turnOrder.clear();
    _remainingActions.clear();
    _activeDefenses.clear();
    _silencedPlayers.clear();
    _pendingAttack = null;
    _awaitingPlayerIntervention = false;
  }
}

/// 攻擊結果
class AttackResult {
  /// 是否成功
  final bool success;

  /// 實際造成的傷害
  final int actualDamage;

  /// 是否被反駁
  final bool wasRebutted;

  /// 目標是否被擊敗
  final bool targetEliminated;

  /// 描述
  final String description;

  const AttackResult({
    required this.success,
    required this.actualDamage,
    required this.wasRebutted,
    this.targetEliminated = false,
    required this.description,
  });
}
