// 1812 國會風雲 - 遊戲動作模型

/// 動作類型
enum ActionType {
  query,    // 質詢攻擊
  rebut,    // 反駁防禦
  skill,    // 使用技能
  vote,     // 投票
  speak,    // 發言
  ally,     // 結盟
  betray,   // 背叛
  trade,    // 交易
  reveal,   // 揭露情報
}

/// 遊戲動作抽象類
abstract class GameAction {
  /// 動作 ID
  final String id;

  /// 動作類型
  final ActionType type;

  /// 執行者 ID
  final String actorId;

  /// 目標 ID（可選）
  final String? targetId;

  /// 時間戳
  final DateTime timestamp;

  /// 是否成功
  final bool isSuccessful;

  /// 結果描述
  final String? resultMessage;

  const GameAction({
    required this.id,
    required this.type,
    required this.actorId,
    this.targetId,
    required this.timestamp,
    this.isSuccessful = true,
    this.resultMessage,
  });

  /// 動作名稱
  String get actionName;

  /// 轉換為 JSON（子類實現具體邏輯）
  Map<String, dynamic> toJson();

  /// 從 JSON 建立（工廠方法）
  static GameAction fromJson(Map<String, dynamic> json) {
    final type = ActionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ActionType.speak,
    );

    switch (type) {
      case ActionType.query:
        return QueryAction.fromJson(json);
      case ActionType.rebut:
        return RebutAction.fromJson(json);
      case ActionType.skill:
        return SkillAction.fromJson(json);
      case ActionType.vote:
        return VoteAction.fromJson(json);
      case ActionType.speak:
        return SpeakAction.fromJson(json);
      case ActionType.ally:
        return AllyAction.fromJson(json);
      case ActionType.betray:
        return BetrayAction.fromJson(json);
      case ActionType.trade:
        return TradeAction.fromJson(json);
      case ActionType.reveal:
        return RevealAction.fromJson(json);
    }
  }
}

/// 質詢攻擊動作
class QueryAction extends GameAction {
  /// 造成的傷害
  final int damage;

  /// 實際造成的傷害（考慮防禦後）
  final int actualDamage;

  /// 消耗的聲望
  final int reputationCost;

  const QueryAction({
    required super.id,
    required super.actorId,
    required super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.damage,
    required this.actualDamage,
    this.reputationCost = 10,
  }) : super(type: ActionType.query);

  @override
  String get actionName => '質詢';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'damage': damage,
      'actualDamage': actualDamage,
      'reputationCost': reputationCost,
    };
  }

  factory QueryAction.fromJson(Map<String, dynamic> json) {
    return QueryAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      damage: json['damage'] as int? ?? 15,
      actualDamage: json['actualDamage'] as int? ?? 15,
      reputationCost: json['reputationCost'] as int? ?? 10,
    );
  }
}

/// 反駁防禦動作
class RebutAction extends GameAction {
  /// 抵擋的傷害
  final int damageReduced;

  /// 消耗的聲望
  final int reputationCost;

  /// 被反駁的質詢動作 ID
  final String? counterActionId;

  const RebutAction({
    required super.id,
    required super.actorId,
    super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.damageReduced,
    this.reputationCost = 5,
    this.counterActionId,
  }) : super(type: ActionType.rebut);

  @override
  String get actionName => '反駁';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'damageReduced': damageReduced,
      'reputationCost': reputationCost,
      'counterActionId': counterActionId,
    };
  }

  factory RebutAction.fromJson(Map<String, dynamic> json) {
    return RebutAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      damageReduced: json['damageReduced'] as int? ?? 15,
      reputationCost: json['reputationCost'] as int? ?? 5,
      counterActionId: json['counterActionId'] as String?,
    );
  }
}

/// 使用技能動作
class SkillAction extends GameAction {
  /// 技能 ID
  final String skillId;

  /// 技能名稱
  final String skillName;

  /// 技能效果描述
  final String effectDescription;

  const SkillAction({
    required super.id,
    required super.actorId,
    super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.skillId,
    required this.skillName,
    required this.effectDescription,
  }) : super(type: ActionType.skill);

  @override
  String get actionName => '技能: $skillName';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'skillId': skillId,
      'skillName': skillName,
      'effectDescription': effectDescription,
    };
  }

  factory SkillAction.fromJson(Map<String, dynamic> json) {
    return SkillAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String? ?? '',
      effectDescription: json['effectDescription'] as String? ?? '',
    );
  }
}

/// 投票動作
class VoteAction extends GameAction {
  /// 選擇的選項 (A/B/C)
  final String option;

  /// 投票權重
  final double weight;

  const VoteAction({
    required super.id,
    required super.actorId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.option,
    required this.weight,
  }) : super(type: ActionType.vote);

  @override
  String get actionName => '投票';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'option': option,
      'weight': weight,
    };
  }

  factory VoteAction.fromJson(Map<String, dynamic> json) {
    return VoteAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      option: json['option'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// 發言動作
class SpeakAction extends GameAction {
  /// 發言內容
  final String content;

  /// 是否為公開發言
  final bool isPublic;

  const SpeakAction({
    required super.id,
    required super.actorId,
    super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.content,
    this.isPublic = true,
  }) : super(type: ActionType.speak);

  @override
  String get actionName => isPublic ? '公開發言' : '私訊';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'content': content,
      'isPublic': isPublic,
    };
  }

  factory SpeakAction.fromJson(Map<String, dynamic> json) {
    return SpeakAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      content: json['content'] as String,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }
}

/// 結盟動作
class AllyAction extends GameAction {
  /// 是否為公開結盟
  final bool isPublic;

  /// 是否被接受
  final bool isAccepted;

  const AllyAction({
    required super.id,
    required super.actorId,
    required super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    this.isPublic = false,
    this.isAccepted = false,
  }) : super(type: ActionType.ally);

  @override
  String get actionName => isPublic ? '公開結盟' : '秘密結盟';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'isPublic': isPublic,
      'isAccepted': isAccepted,
    };
  }

  factory AllyAction.fromJson(Map<String, dynamic> json) {
    return AllyAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }
}

/// 背叛動作
class BetrayAction extends GameAction {
  /// 造成的額外傷害
  final int bonusDamage;

  /// 自己損失的聲望
  final int selfReputationLoss;

  const BetrayAction({
    required super.id,
    required super.actorId,
    required super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.bonusDamage,
    this.selfReputationLoss = 20,
  }) : super(type: ActionType.betray);

  @override
  String get actionName => '背叛';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'bonusDamage': bonusDamage,
      'selfReputationLoss': selfReputationLoss,
    };
  }

  factory BetrayAction.fromJson(Map<String, dynamic> json) {
    return BetrayAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      bonusDamage: json['bonusDamage'] as int? ?? 30,
      selfReputationLoss: json['selfReputationLoss'] as int? ?? 20,
    );
  }
}

/// 交易動作
class TradeAction extends GameAction {
  /// 交易內容描述
  final String tradeDescription;

  /// 是否完成交易
  final bool isCompleted;

  const TradeAction({
    required super.id,
    required super.actorId,
    required super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.tradeDescription,
    this.isCompleted = false,
  }) : super(type: ActionType.trade);

  @override
  String get actionName => '交易';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'tradeDescription': tradeDescription,
      'isCompleted': isCompleted,
    };
  }

  factory TradeAction.fromJson(Map<String, dynamic> json) {
    return TradeAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      tradeDescription: json['tradeDescription'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// 揭露情報動作
class RevealAction extends GameAction {
  /// 情報內容
  final String intelContent;

  /// 情報等級 (1-4)
  final int intelLevel;

  /// 造成的聲望傷害
  final int reputationDamage;

  const RevealAction({
    required super.id,
    required super.actorId,
    required super.targetId,
    required super.timestamp,
    super.isSuccessful,
    super.resultMessage,
    required this.intelContent,
    required this.intelLevel,
    required this.reputationDamage,
  }) : super(type: ActionType.reveal);

  @override
  String get actionName => '揭露';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'resultMessage': resultMessage,
      'intelContent': intelContent,
      'intelLevel': intelLevel,
      'reputationDamage': reputationDamage,
    };
  }

  factory RevealAction.fromJson(Map<String, dynamic> json) {
    return RevealAction(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      resultMessage: json['resultMessage'] as String?,
      intelContent: json['intelContent'] as String,
      intelLevel: json['intelLevel'] as int? ?? 1,
      reputationDamage: json['reputationDamage'] as int? ?? 10,
    );
  }
}
