// 1812 國會風雲 - 角色模型

/// 陣營類型
enum Faction {
  worker,     // 勞工派 - 支持禁止機器
  factory,    // 資方派 - 支持保護財產
  reform,     // 改革派 - 支持折衷改革
  press,      // 記者 - 中立，情報為主
  royal,      // 皇室 - 特殊角色
  neutral,    // 中立派 - 只關心個人任務
}

/// 技能類型
enum SkillType {
  active,   // 主動技能 - 需要手動觸發
  passive,  // 被動技能 - 自動生效
}

/// 角色技能
class Skill {
  /// 技能 ID
  final String id;

  /// 技能名稱
  final String name;

  /// 技能描述
  final String description;

  /// 技能類型
  final SkillType type;

  /// 冷卻回合數（0 表示無冷卻）
  final int cooldown;

  /// 消耗的聲望
  final int reputationCost;

  /// 消耗的金幣
  final int goldCost;

  /// 消耗的情報
  final int intelCost;

  /// 消耗的人情
  final int favorCost;

  /// 每局使用次數限制（0 表示無限制）
  final int usesPerGame;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.cooldown = 0,
    this.reputationCost = 0,
    this.goldCost = 0,
    this.intelCost = 0,
    this.favorCost = 0,
    this.usesPerGame = 0,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SkillType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SkillType.active,
      ),
      cooldown: json['cooldown'] as int? ?? 0,
      reputationCost: json['reputationCost'] as int? ?? 0,
      goldCost: json['goldCost'] as int? ?? 0,
      intelCost: json['intelCost'] as int? ?? 0,
      favorCost: json['favorCost'] as int? ?? 0,
      usesPerGame: json['usesPerGame'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'cooldown': cooldown,
      'reputationCost': reputationCost,
      'goldCost': goldCost,
      'intelCost': intelCost,
      'favorCost': favorCost,
      'usesPerGame': usesPerGame,
    };
  }
}

/// 角色模型
class Role {
  /// 角色 ID
  final String id;

  /// 角色名稱
  final String name;

  /// 角色英文名
  final String englishName;

  /// 陣營
  final Faction faction;

  /// 角色圖標 emoji
  final String emoji;

  /// 角色描述
  final String description;

  /// 初始聲望
  final int initialReputation;

  /// 初始金幣
  final int initialGold;

  /// 初始情報數
  final int initialIntel;

  /// 初始人情
  final int initialFavor;

  /// 基礎防禦
  final int baseDefense;

  /// 角色技能列表
  final List<Skill> skills;

  /// 特色標籤
  final List<String> traits;

  const Role({
    required this.id,
    required this.name,
    required this.englishName,
    required this.faction,
    required this.emoji,
    required this.description,
    required this.initialReputation,
    required this.initialGold,
    required this.initialIntel,
    required this.initialFavor,
    required this.baseDefense,
    required this.skills,
    this.traits = const [],
  });

  /// 陣營名稱
  String get factionName {
    switch (faction) {
      case Faction.worker:
        return '勞工派';
      case Faction.factory:
        return '資方派';
      case Faction.reform:
        return '改革派';
      case Faction.press:
        return '記者';
      case Faction.royal:
        return '皇室';
      case Faction.neutral:
        return '中立派';
    }
  }

  /// 主要技能（第一個技能）
  Skill? get primarySkill => skills.isNotEmpty ? skills.first : null;

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String? ?? '',
      faction: Faction.values.firstWhere(
        (e) => e.name == json['faction'],
        orElse: () => Faction.neutral,
      ),
      emoji: json['emoji'] as String? ?? '👤',
      description: json['description'] as String? ?? '',
      initialReputation: json['initialReputation'] as int? ?? 50,
      initialGold: json['initialGold'] as int? ?? 0,
      initialIntel: json['initialIntel'] as int? ?? 0,
      initialFavor: json['initialFavor'] as int? ?? 0,
      baseDefense: json['baseDefense'] as int? ?? 0,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      traits: (json['traits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'faction': faction.name,
      'emoji': emoji,
      'description': description,
      'initialReputation': initialReputation,
      'initialGold': initialGold,
      'initialIntel': initialIntel,
      'initialFavor': initialFavor,
      'baseDefense': baseDefense,
      'skills': skills.map((e) => e.toJson()).toList(),
      'traits': traits,
    };
  }

  @override
  String toString() {
    return 'Role(id: $id, name: $name, faction: $factionName)';
  }
}

/// 陣營克制關係
class FactionCounter {
  /// 克制關係：A 克制 B
  static const Map<Faction, Faction> counters = {
    Faction.worker: Faction.factory,   // 勞工克制資方
    Faction.factory: Faction.reform,   // 資方克制改革
    Faction.reform: Faction.worker,    // 改革克制勞工
  };

  /// 檢查是否克制
  static bool doesCounter(Faction attacker, Faction defender) {
    return counters[attacker] == defender;
  }

  /// 計算克制傷害加成（克制 +30%，被克制 -20%）
  static double getDamageMultiplier(Faction attacker, Faction defender) {
    if (doesCounter(attacker, defender)) {
      return 1.3; // 克制 +30%
    }
    if (doesCounter(defender, attacker)) {
      return 0.8; // 被克制 -20%
    }
    return 1.0; // 無克制關係
  }
}
