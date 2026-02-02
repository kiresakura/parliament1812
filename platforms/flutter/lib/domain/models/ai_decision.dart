// 1812 國會風雲 - AI 決策模型

import 'action.dart';

/// AI 可執行的動作類型
enum AIActionType {
  attack,       // 攻擊（質詢）
  defend,       // 防禦（反駁）
  ally,         // 結盟
  betray,       // 背叛
  useSkill,     // 使用技能
  vote,         // 投票
  speak,        // 發言
  trade,        // 交易
  reveal,       // 揭露情報
  wait,         // 等待（不行動）
}

/// AIActionType 擴展方法
extension AIActionTypeExtension on AIActionType {
  /// 動作名稱
  String get displayName {
    switch (this) {
      case AIActionType.attack:
        return '質詢攻擊';
      case AIActionType.defend:
        return '反駁防禦';
      case AIActionType.ally:
        return '結盟';
      case AIActionType.betray:
        return '背叛';
      case AIActionType.useSkill:
        return '使用技能';
      case AIActionType.vote:
        return '投票';
      case AIActionType.speak:
        return '發言';
      case AIActionType.trade:
        return '交易';
      case AIActionType.reveal:
        return '揭露';
      case AIActionType.wait:
        return '等待';
    }
  }

  /// 對應的遊戲動作類型
  ActionType? get gameActionType {
    switch (this) {
      case AIActionType.attack:
        return ActionType.query;
      case AIActionType.defend:
        return ActionType.rebut;
      case AIActionType.ally:
        return ActionType.ally;
      case AIActionType.betray:
        return ActionType.betray;
      case AIActionType.useSkill:
        return ActionType.skill;
      case AIActionType.vote:
        return ActionType.vote;
      case AIActionType.speak:
        return ActionType.speak;
      case AIActionType.trade:
        return ActionType.trade;
      case AIActionType.reveal:
        return ActionType.reveal;
      case AIActionType.wait:
        return null;  // 等待沒有對應的遊戲動作
    }
  }

  /// 是否需要目標
  bool get requiresTarget {
    switch (this) {
      case AIActionType.attack:
      case AIActionType.ally:
      case AIActionType.betray:
      case AIActionType.trade:
      case AIActionType.reveal:
        return true;
      case AIActionType.defend:
      case AIActionType.useSkill:
      case AIActionType.vote:
      case AIActionType.speak:
      case AIActionType.wait:
        return false;
    }
  }
}

/// AI 決策 - 代表 AI 選擇的一個動作
class AIDecision {
  /// 動作類型
  final AIActionType actionType;

  /// 目標玩家 ID（如果適用）
  final String? targetId;

  /// 額外參數（如投票選項、技能 ID 等）
  final Map<String, dynamic> parameters;

  /// 決策評分（0-100，越高越好）
  final double score;

  /// 決策理由（用於調試和解釋）
  final String? reasoning;

  /// 決策時間
  final DateTime timestamp;

  const AIDecision({
    required this.actionType,
    this.targetId,
    this.parameters = const {},
    required this.score,
    this.reasoning,
    required this.timestamp,
  });

  /// 創建攻擊決策
  factory AIDecision.attack({
    required String targetId,
    required double score,
    String? reasoning,
  }) {
    return AIDecision(
      actionType: AIActionType.attack,
      targetId: targetId,
      score: score,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// 創建防禦決策
  factory AIDecision.defend({
    required double score,
    String? reasoning,
  }) {
    return AIDecision(
      actionType: AIActionType.defend,
      score: score,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// 創建結盟決策
  factory AIDecision.ally({
    required String targetId,
    required double score,
    String? reasoning,
  }) {
    return AIDecision(
      actionType: AIActionType.ally,
      targetId: targetId,
      score: score,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// 創建背叛決策
  factory AIDecision.betray({
    required String targetId,
    required double score,
    String? reasoning,
  }) {
    return AIDecision(
      actionType: AIActionType.betray,
      targetId: targetId,
      score: score,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// 創建投票決策
  factory AIDecision.vote({
    required String option,
    required double score,
    String? reasoning,
  }) {
    return AIDecision(
      actionType: AIActionType.vote,
      parameters: {'option': option},
      score: score,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// 創建等待決策
  factory AIDecision.wait({String? reasoning}) {
    return AIDecision(
      actionType: AIActionType.wait,
      score: 0,
      reasoning: reasoning ?? '暫時觀望',
      timestamp: DateTime.now(),
    );
  }

  AIDecision copyWith({
    AIActionType? actionType,
    String? targetId,
    Map<String, dynamic>? parameters,
    double? score,
    String? reasoning,
    DateTime? timestamp,
  }) {
    return AIDecision(
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      parameters: parameters ?? this.parameters,
      score: score ?? this.score,
      reasoning: reasoning ?? this.reasoning,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory AIDecision.fromJson(Map<String, dynamic> json) {
    return AIDecision(
      actionType: AIActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => AIActionType.wait,
      ),
      targetId: json['targetId'] as String?,
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'targetId': targetId,
      'parameters': parameters,
      'score': score,
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AIDecision(${actionType.displayName}, target: $targetId, score: $score)';
  }
}

/// 動作評分 - 用於 AI 評估各種可能動作
class ActionScore {
  /// 動作類型
  final AIActionType actionType;

  /// 目標玩家 ID（如果適用）
  final String? targetId;

  /// 基礎分數
  final double baseScore;

  /// 各項評估因素的分數
  final Map<String, double> factors;

  /// 最終分數
  final double finalScore;

  const ActionScore({
    required this.actionType,
    this.targetId,
    required this.baseScore,
    this.factors = const {},
    required this.finalScore,
  });

  /// 計算最終分數
  factory ActionScore.calculate({
    required AIActionType actionType,
    String? targetId,
    required double baseScore,
    required Map<String, double> factors,
  }) {
    // 計算所有因素的加權總和
    double factorSum = 0;
    for (final factor in factors.values) {
      factorSum += factor;
    }
    final finalScore = (baseScore + factorSum).clamp(0, 100);

    return ActionScore(
      actionType: actionType,
      targetId: targetId,
      baseScore: baseScore,
      factors: factors,
      finalScore: finalScore.toDouble(),
    );
  }

  factory ActionScore.fromJson(Map<String, dynamic> json) {
    return ActionScore(
      actionType: AIActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => AIActionType.wait,
      ),
      targetId: json['targetId'] as String?,
      baseScore: (json['baseScore'] as num?)?.toDouble() ?? 0,
      factors: (json['factors'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'targetId': targetId,
      'baseScore': baseScore,
      'factors': factors,
      'finalScore': finalScore,
    };
  }

  @override
  String toString() {
    return 'ActionScore(${actionType.displayName}, target: $targetId, score: $finalScore)';
  }
}

/// 局勢分析 - AI 對當前遊戲狀態的評估
class SituationAnalysis {
  /// 分析時間
  final DateTime timestamp;

  /// 自身狀態評估（0-100，越高越好）
  final double selfStatus;

  /// 威脅等級（0-100，越高越危險）
  final double threatLevel;

  /// 機會等級（0-100，越高機會越好）
  final double opportunityLevel;

  /// 主要威脅來源（玩家 ID 列表）
  final List<String> mainThreats;

  /// 潛在盟友（玩家 ID 列表）
  final List<String> potentialAllies;

  /// 弱勢目標（玩家 ID 列表，適合攻擊）
  final List<String> weakTargets;

  /// 強勢玩家（玩家 ID 列表，需要警惕）
  final List<String> strongPlayers;

  /// 建議策略
  final SuggestedStrategy strategy;

  /// 詳細分析說明
  final String? analysisNotes;

  const SituationAnalysis({
    required this.timestamp,
    required this.selfStatus,
    required this.threatLevel,
    required this.opportunityLevel,
    this.mainThreats = const [],
    this.potentialAllies = const [],
    this.weakTargets = const [],
    this.strongPlayers = const [],
    required this.strategy,
    this.analysisNotes,
  });

  /// 是否處於危險狀態
  bool get isInDanger => selfStatus < 30 || threatLevel > 70;

  /// 是否處於優勢狀態
  bool get isInAdvantage => selfStatus > 70 && threatLevel < 30;

  /// 是否應該保守行動
  bool get shouldBeConservative => threatLevel > 50 || selfStatus < 40;

  /// 是否應該激進行動
  bool get shouldBeAggressive => opportunityLevel > 60 && selfStatus > 50;

  factory SituationAnalysis.fromJson(Map<String, dynamic> json) {
    return SituationAnalysis(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      selfStatus: (json['selfStatus'] as num?)?.toDouble() ?? 50,
      threatLevel: (json['threatLevel'] as num?)?.toDouble() ?? 50,
      opportunityLevel: (json['opportunityLevel'] as num?)?.toDouble() ?? 50,
      mainThreats: (json['mainThreats'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      potentialAllies: (json['potentialAllies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weakTargets: (json['weakTargets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      strongPlayers: (json['strongPlayers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      strategy: SuggestedStrategy.values.firstWhere(
        (e) => e.name == json['strategy'],
        orElse: () => SuggestedStrategy.balanced,
      ),
      analysisNotes: json['analysisNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'selfStatus': selfStatus,
      'threatLevel': threatLevel,
      'opportunityLevel': opportunityLevel,
      'mainThreats': mainThreats,
      'potentialAllies': potentialAllies,
      'weakTargets': weakTargets,
      'strongPlayers': strongPlayers,
      'strategy': strategy.name,
      'analysisNotes': analysisNotes,
    };
  }

  @override
  String toString() {
    return 'SituationAnalysis(self: $selfStatus, threat: $threatLevel, opportunity: $opportunityLevel, strategy: ${strategy.displayName})';
  }
}

/// 建議策略
enum SuggestedStrategy {
  aggressive,      // 激進 - 主動攻擊
  defensive,       // 防守 - 保護聲望
  diplomatic,      // 外交 - 建立盟友
  opportunistic,   // 機會主義 - 趁火打劫
  survival,        // 求生 - 盡可能保命
  balanced,        // 平衡 - 攻守兼備
  betrayal,        // 背叛 - 背刺盟友獲利
}

/// SuggestedStrategy 擴展方法
extension SuggestedStrategyExtension on SuggestedStrategy {
  /// 策略名稱
  String get displayName {
    switch (this) {
      case SuggestedStrategy.aggressive:
        return '激進進攻';
      case SuggestedStrategy.defensive:
        return '穩健防守';
      case SuggestedStrategy.diplomatic:
        return '外交結盟';
      case SuggestedStrategy.opportunistic:
        return '伺機而動';
      case SuggestedStrategy.survival:
        return '求生保命';
      case SuggestedStrategy.balanced:
        return '攻守平衡';
      case SuggestedStrategy.betrayal:
        return '背刺獲利';
    }
  }

  /// 策略描述
  String get description {
    switch (this) {
      case SuggestedStrategy.aggressive:
        return '主動發起攻擊，削弱對手';
      case SuggestedStrategy.defensive:
        return '保護自己的聲望，等待時機';
      case SuggestedStrategy.diplomatic:
        return '積極建立盟友關係，合作共贏';
      case SuggestedStrategy.opportunistic:
        return '觀察局勢，抓住機會出手';
      case SuggestedStrategy.survival:
        return '聲望危急，全力保命';
      case SuggestedStrategy.balanced:
        return '攻守兼備，靈活應對';
      case SuggestedStrategy.betrayal:
        return '時機成熟，背叛盟友獲取優勢';
    }
  }
}

/// 投票分析 - AI 對投票選項的評估
class VoteAnalysis {
  /// 選項 ID
  final String optionId;

  /// 選項名稱
  final String optionName;

  /// 對自己的預期收益 (-100 到 +100)
  final double selfBenefit;

  /// 對陣營的預期收益 (-100 到 +100)
  final double factionBenefit;

  /// 其他玩家可能的投票傾向
  final Map<String, double> predictedVotes;

  /// 選項勝出概率 (0-1)
  final double winProbability;

  /// 最終推薦分數 (0-100)
  final double recommendScore;

  const VoteAnalysis({
    required this.optionId,
    required this.optionName,
    required this.selfBenefit,
    required this.factionBenefit,
    this.predictedVotes = const {},
    required this.winProbability,
    required this.recommendScore,
  });

  factory VoteAnalysis.fromJson(Map<String, dynamic> json) {
    return VoteAnalysis(
      optionId: json['optionId'] as String,
      optionName: json['optionName'] as String? ?? '',
      selfBenefit: (json['selfBenefit'] as num?)?.toDouble() ?? 0,
      factionBenefit: (json['factionBenefit'] as num?)?.toDouble() ?? 0,
      predictedVotes: (json['predictedVotes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      winProbability: (json['winProbability'] as num?)?.toDouble() ?? 0.5,
      recommendScore: (json['recommendScore'] as num?)?.toDouble() ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'optionName': optionName,
      'selfBenefit': selfBenefit,
      'factionBenefit': factionBenefit,
      'predictedVotes': predictedVotes,
      'winProbability': winProbability,
      'recommendScore': recommendScore,
    };
  }

  @override
  String toString() {
    return 'VoteAnalysis($optionName, score: $recommendScore, winProb: ${(winProbability * 100).toStringAsFixed(1)}%)';
  }
}
