// 1812 國會風雲 - 單人模式房間模型

import 'player.dart';
import 'ai_player.dart';
import 'game_state.dart';
import 'bill.dart';
import 'action.dart';

/// 單人模式類型
enum SoloModeType {
  practice,      // 練習模式 - 無限制，可隨時重來
  challenge,     // 挑戰模式 - 有特定目標
  campaign,      // 戰役模式 - 連續關卡
  tutorial,      // 教學模式 - 引導新手
}

/// SoloModeType 擴展方法
extension SoloModeTypeExtension on SoloModeType {
  /// 模式名稱
  String get displayName {
    switch (this) {
      case SoloModeType.practice:
        return '練習模式';
      case SoloModeType.challenge:
        return '挑戰模式';
      case SoloModeType.campaign:
        return '戰役模式';
      case SoloModeType.tutorial:
        return '新手教學';
    }
  }

  /// 模式描述
  String get description {
    switch (this) {
      case SoloModeType.practice:
        return '自由練習，熟悉遊戲機制';
      case SoloModeType.challenge:
        return '完成特定目標，獲得獎勵';
      case SoloModeType.campaign:
        return '連續闖關，體驗完整劇情';
      case SoloModeType.tutorial:
        return '循序漸進學習遊戲';
    }
  }

  /// 模式圖標
  String get icon {
    switch (this) {
      case SoloModeType.practice:
        return '🎯';
      case SoloModeType.challenge:
        return '⚔️';
      case SoloModeType.campaign:
        return '📜';
      case SoloModeType.tutorial:
        return '📖';
    }
  }
}

/// 單人遊戲房間模型
class SoloGameRoom {
  /// 房間唯一識別碼
  final String id;

  /// 單人模式類型
  final SoloModeType modeType;

  /// AI 難度等級
  final AIDifficulty difficulty;

  /// 人類玩家
  final Player humanPlayer;

  /// AI 玩家列表
  final List<AIPlayer> aiPlayers;

  /// 當前遊戲階段
  final GamePhase currentPhase;

  /// 當前回合數
  final int currentRound;

  /// 總回合數
  final int totalRounds;

  /// 剩餘時間（秒）
  final int timeRemaining;

  /// 當前議案
  final Bill? currentBill;

  /// 動作日誌
  final List<GameAction> actionLog;

  /// 當前發言者 ID
  final String? currentSpeakerId;

  /// 發言順序
  final List<String> speakingOrder;

  /// 戰役關卡等級（僅戰役模式）
  final int? campaignLevel;

  /// 挑戰目標（僅挑戰模式）
  final ChallengeObjective? challengeObjective;

  /// 遊戲開始時間
  final DateTime? startTime;

  /// 遊戲結束時間
  final DateTime? endTime;

  /// 是否暫停
  final bool isPaused;

  /// 遊戲速度倍率 (0.5, 1.0, 1.5, 2.0)
  final double gameSpeed;

  const SoloGameRoom({
    required this.id,
    required this.modeType,
    required this.difficulty,
    required this.humanPlayer,
    required this.aiPlayers,
    this.currentPhase = GamePhase.waiting,
    this.currentRound = 0,
    this.totalRounds = 3,
    this.timeRemaining = 0,
    this.currentBill,
    this.actionLog = const [],
    this.currentSpeakerId,
    this.speakingOrder = const [],
    this.campaignLevel,
    this.challengeObjective,
    this.startTime,
    this.endTime,
    this.isPaused = false,
    this.gameSpeed = 1.0,
  });

  /// 創建練習模式房間
  factory SoloGameRoom.practice({
    required String id,
    required Player humanPlayer,
    required AIDifficulty difficulty,
    int aiCount = 3,
  }) {
    final aiPlayers = _generateAIPlayers(
      difficulty: difficulty,
      count: aiCount,
    );

    return SoloGameRoom(
      id: id,
      modeType: SoloModeType.practice,
      difficulty: difficulty,
      humanPlayer: humanPlayer,
      aiPlayers: aiPlayers,
    );
  }

  /// 創建挑戰模式房間
  factory SoloGameRoom.challenge({
    required String id,
    required Player humanPlayer,
    required AIDifficulty difficulty,
    required ChallengeObjective objective,
    int aiCount = 3,
  }) {
    final aiPlayers = _generateAIPlayers(
      difficulty: difficulty,
      count: aiCount,
    );

    return SoloGameRoom(
      id: id,
      modeType: SoloModeType.challenge,
      difficulty: difficulty,
      humanPlayer: humanPlayer,
      aiPlayers: aiPlayers,
      challengeObjective: objective,
    );
  }

  /// 創建戰役模式房間
  factory SoloGameRoom.campaign({
    required String id,
    required Player humanPlayer,
    required int level,
  }) {
    // 根據關卡決定難度
    final difficulty = _getDifficultyForLevel(level);
    final aiCount = _getAICountForLevel(level);
    final aiPlayers = _generateAIPlayers(
      difficulty: difficulty,
      count: aiCount,
    );

    return SoloGameRoom(
      id: id,
      modeType: SoloModeType.campaign,
      difficulty: difficulty,
      humanPlayer: humanPlayer,
      aiPlayers: aiPlayers,
      campaignLevel: level,
    );
  }

  /// 創建教學模式房間
  factory SoloGameRoom.tutorial({
    required String id,
    required Player humanPlayer,
    int tutorialStep = 1,
  }) {
    // 教學模式使用最簡單的 AI
    final aiPlayers = _generateAIPlayers(
      difficulty: AIDifficulty.beginner,
      count: 1,  // 教學模式只有 1 個 AI
    );

    return SoloGameRoom(
      id: id,
      modeType: SoloModeType.tutorial,
      difficulty: AIDifficulty.beginner,
      humanPlayer: humanPlayer,
      aiPlayers: aiPlayers,
      campaignLevel: tutorialStep,  // 使用 campaignLevel 存儲教學步驟
      gameSpeed: 0.5,  // 教學模式較慢
    );
  }

  /// 生成 AI 玩家列表
  static List<AIPlayer> _generateAIPlayers({
    required AIDifficulty difficulty,
    required int count,
  }) {
    final names = [
      '湯瑪斯爵士',
      '伊麗莎白夫人',
      '約翰先生',
      '瑪格麗特小姐',
      '威廉公爵',
      '安妮女士',
      '理查德伯爵',
    ];

    return List.generate(count, (index) {
      return AIPlayer.createRandom(
        id: 'ai_$index',
        name: names[index % names.length],
        difficulty: difficulty,
        avatarIndex: index,
      );
    });
  }

  /// 根據關卡獲取難度
  static AIDifficulty _getDifficultyForLevel(int level) {
    if (level <= 3) return AIDifficulty.beginner;
    if (level <= 6) return AIDifficulty.intermediate;
    if (level <= 9) return AIDifficulty.advanced;
    if (level <= 12) return AIDifficulty.expert;
    return AIDifficulty.master;
  }

  /// 根據關卡獲取 AI 數量
  static int _getAICountForLevel(int level) {
    if (level <= 2) return 2;
    if (level <= 5) return 3;
    if (level <= 8) return 4;
    return 5;  // 最多 5 個 AI
  }

  /// 所有玩家列表（包含人類和 AI）
  List<Player> get allPlayers {
    return [humanPlayer, ...aiPlayers.map((ai) => ai.player)];
  }

  /// 玩家總數
  int get playerCount => 1 + aiPlayers.length;

  /// 存活玩家數
  int get alivePlayerCount => allPlayers.where((p) => p.isAlive).length;

  /// 是否遊戲已開始
  bool get isGameStarted => currentPhase != GamePhase.waiting;

  /// 是否遊戲已結束
  bool get isGameEnded => currentPhase == GamePhase.result && endTime != null;

  /// 人類玩家是否存活
  bool get isHumanAlive => humanPlayer.isAlive;

  /// 當前發言者
  Player? get currentSpeaker {
    if (currentSpeakerId == null) return null;
    return allPlayers.where((p) => p.id == currentSpeakerId).firstOrNull;
  }

  /// 取得 AI 玩家
  AIPlayer? getAIPlayer(String playerId) {
    try {
      return aiPlayers.firstWhere((ai) => ai.id == playerId);
    } catch (e) {
      return null;
    }
  }

  /// 取得任意玩家
  Player? getPlayerById(String playerId) {
    if (playerId == humanPlayer.id) return humanPlayer;
    return aiPlayers.where((ai) => ai.id == playerId).firstOrNull?.player;
  }

  /// 階段名稱
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
    final adjustedTime = (timeRemaining / gameSpeed).round();
    final minutes = adjustedTime ~/ 60;
    final seconds = adjustedTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  SoloGameRoom copyWith({
    String? id,
    SoloModeType? modeType,
    AIDifficulty? difficulty,
    Player? humanPlayer,
    List<AIPlayer>? aiPlayers,
    GamePhase? currentPhase,
    int? currentRound,
    int? totalRounds,
    int? timeRemaining,
    Bill? currentBill,
    List<GameAction>? actionLog,
    String? currentSpeakerId,
    List<String>? speakingOrder,
    int? campaignLevel,
    ChallengeObjective? challengeObjective,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPaused,
    double? gameSpeed,
  }) {
    return SoloGameRoom(
      id: id ?? this.id,
      modeType: modeType ?? this.modeType,
      difficulty: difficulty ?? this.difficulty,
      humanPlayer: humanPlayer ?? this.humanPlayer,
      aiPlayers: aiPlayers ?? this.aiPlayers,
      currentPhase: currentPhase ?? this.currentPhase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      currentBill: currentBill ?? this.currentBill,
      actionLog: actionLog ?? this.actionLog,
      currentSpeakerId: currentSpeakerId ?? this.currentSpeakerId,
      speakingOrder: speakingOrder ?? this.speakingOrder,
      campaignLevel: campaignLevel ?? this.campaignLevel,
      challengeObjective: challengeObjective ?? this.challengeObjective,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPaused: isPaused ?? this.isPaused,
      gameSpeed: gameSpeed ?? this.gameSpeed,
    );
  }

  /// 更新人類玩家
  SoloGameRoom updateHumanPlayer(Player Function(Player) updater) {
    return copyWith(humanPlayer: updater(humanPlayer));
  }

  /// 更新指定 AI 玩家
  SoloGameRoom updateAIPlayer(String playerId, AIPlayer Function(AIPlayer) updater) {
    final index = aiPlayers.indexWhere((ai) => ai.id == playerId);
    if (index < 0) return this;

    final newAIPlayers = List<AIPlayer>.from(aiPlayers);
    newAIPlayers[index] = updater(aiPlayers[index]);
    return copyWith(aiPlayers: newAIPlayers);
  }

  /// 添加動作到日誌
  SoloGameRoom addAction(GameAction action) {
    return copyWith(actionLog: [...actionLog, action]);
  }

  factory SoloGameRoom.fromJson(Map<String, dynamic> json) {
    return SoloGameRoom(
      id: json['id'] as String,
      modeType: SoloModeType.values.firstWhere(
        (e) => e.name == json['modeType'],
        orElse: () => SoloModeType.practice,
      ),
      difficulty: AIDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => AIDifficulty.intermediate,
      ),
      humanPlayer: Player.fromJson(json['humanPlayer'] as Map<String, dynamic>),
      aiPlayers: (json['aiPlayers'] as List<dynamic>)
          .map((e) => AIPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPhase: GamePhase.values.firstWhere(
        (e) => e.name == json['currentPhase'],
        orElse: () => GamePhase.waiting,
      ),
      currentRound: json['currentRound'] as int? ?? 0,
      totalRounds: json['totalRounds'] as int? ?? 3,
      timeRemaining: json['timeRemaining'] as int? ?? 0,
      currentBill: json['currentBill'] != null
          ? Bill.fromJson(json['currentBill'] as Map<String, dynamic>)
          : null,
      actionLog: (json['actionLog'] as List<dynamic>?)
              ?.map((e) => GameAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentSpeakerId: json['currentSpeakerId'] as String?,
      speakingOrder: (json['speakingOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      campaignLevel: json['campaignLevel'] as int?,
      challengeObjective: json['challengeObjective'] != null
          ? ChallengeObjective.fromJson(
              json['challengeObjective'] as Map<String, dynamic>)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isPaused: json['isPaused'] as bool? ?? false,
      gameSpeed: (json['gameSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modeType': modeType.name,
      'difficulty': difficulty.name,
      'humanPlayer': humanPlayer.toJson(),
      'aiPlayers': aiPlayers.map((ai) => ai.toJson()).toList(),
      'currentPhase': currentPhase.name,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'timeRemaining': timeRemaining,
      'currentBill': currentBill?.toJson(),
      'actionLog': actionLog.map((a) => a.toJson()).toList(),
      'currentSpeakerId': currentSpeakerId,
      'speakingOrder': speakingOrder,
      'campaignLevel': campaignLevel,
      'challengeObjective': challengeObjective?.toJson(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isPaused': isPaused,
      'gameSpeed': gameSpeed,
    };
  }

  @override
  String toString() {
    return 'SoloGameRoom(id: $id, mode: ${modeType.displayName}, difficulty: ${difficulty.displayName}, players: $playerCount)';
  }
}

/// 挑戰目標
class ChallengeObjective {
  /// 目標 ID
  final String id;

  /// 目標名稱
  final String name;

  /// 目標描述
  final String description;

  /// 目標類型
  final ChallengeType type;

  /// 目標數值（如：達成 X 聲望）
  final int targetValue;

  /// 當前進度
  final int currentProgress;

  /// 是否已完成
  final bool isCompleted;

  /// 完成獎勵描述
  final String? rewardDescription;

  const ChallengeObjective({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.rewardDescription,
  });

  /// 進度百分比
  double get progressPercent {
    if (targetValue <= 0) return 0;
    return (currentProgress / targetValue).clamp(0, 1);
  }

  ChallengeObjective copyWith({
    String? id,
    String? name,
    String? description,
    ChallengeType? type,
    int? targetValue,
    int? currentProgress,
    bool? isCompleted,
    String? rewardDescription,
  }) {
    return ChallengeObjective(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardDescription: rewardDescription ?? this.rewardDescription,
    );
  }

  factory ChallengeObjective.fromJson(Map<String, dynamic> json) {
    return ChallengeObjective(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.surviveRounds,
      ),
      targetValue: json['targetValue'] as int? ?? 1,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      rewardDescription: json['rewardDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'rewardDescription': rewardDescription,
    };
  }
}

/// 挑戰類型
enum ChallengeType {
  surviveRounds,     // 存活指定回合
  reachReputation,   // 達到指定聲望
  winVote,           // 贏得投票
  formAlliance,      // 建立聯盟
  betrayAlly,        // 背叛盟友
  eliminatePlayer,   // 使某玩家政治死亡
  useSkill,          // 使用技能
  perfectVictory,    // 完美勝利（不損失聲望）
}

/// ChallengeType 擴展方法
extension ChallengeTypeExtension on ChallengeType {
  /// 類型名稱
  String get displayName {
    switch (this) {
      case ChallengeType.surviveRounds:
        return '生存挑戰';
      case ChallengeType.reachReputation:
        return '聲望目標';
      case ChallengeType.winVote:
        return '贏得投票';
      case ChallengeType.formAlliance:
        return '建立聯盟';
      case ChallengeType.betrayAlly:
        return '背刺盟友';
      case ChallengeType.eliminatePlayer:
        return '政治暗殺';
      case ChallengeType.useSkill:
        return '技能大師';
      case ChallengeType.perfectVictory:
        return '完美勝利';
    }
  }
}
