/// 卡牌資料模型
/// 1812 國會風雲 - 卡牌系統
library card;

/// 卡牌類型枚舉
enum CardType {
  attack,   // ⚔️ 攻擊 - 降低對手聲望
  defense,  // 🛡️ 防禦 - 阻擋攻擊、保護自己
  control,  // 🔒 控制 - 限制對手行動
  buff,     // ⬆️ 增益 - 提升自己能力
  intel,    // 🔍 情報 - 獲取資訊、揭露秘密
  social,   // 🤝 社交 - 結盟、交易
  heal,     // 💚 治療 - 恢復聲望
  special,  // ⭐ 特殊 - 獨特效果
}

/// 卡牌類型顯示名稱
extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.attack:
        return '攻擊';
      case CardType.defense:
        return '防禦';
      case CardType.control:
        return '控制';
      case CardType.buff:
        return '增益';
      case CardType.intel:
        return '情報';
      case CardType.social:
        return '社交';
      case CardType.heal:
        return '治療';
      case CardType.special:
        return '特殊';
    }
  }

  String get icon {
    switch (this) {
      case CardType.attack:
        return '⚔️';
      case CardType.defense:
        return '🛡️';
      case CardType.control:
        return '🔒';
      case CardType.buff:
        return '⬆️';
      case CardType.intel:
        return '🔍';
      case CardType.social:
        return '🤝';
      case CardType.heal:
        return '💚';
      case CardType.special:
        return '⭐';
    }
  }

  static CardType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'attack':
        return CardType.attack;
      case 'defense':
        return CardType.defense;
      case 'control':
        return CardType.control;
      case 'buff':
        return CardType.buff;
      case 'intel':
        return CardType.intel;
      case 'social':
        return CardType.social;
      case 'heal':
        return CardType.heal;
      case 'special':
        return CardType.special;
      default:
        return CardType.attack;
    }
  }
}

/// 卡牌稀有度枚舉
enum CardRarity {
  n,    // ⚪ 普通 Normal - 53% 抽取機率
  r,    // 🔵 稀有 Rare - 25% 抽取機率
  sr,   // 🟣 史詩 Super Rare - 17% 抽取機率
  ssr,  // 🟡 傳說 Super Super Rare - 5% 抽取機率
}

/// 卡牌稀有度顯示
extension CardRarityExtension on CardRarity {
  String get displayName {
    switch (this) {
      case CardRarity.n:
        return '普通';
      case CardRarity.r:
        return '稀有';
      case CardRarity.sr:
        return '史詩';
      case CardRarity.ssr:
        return '傳說';
    }
  }

  String get icon {
    switch (this) {
      case CardRarity.n:
        return '⚪';
      case CardRarity.r:
        return '🔵';
      case CardRarity.sr:
        return '🟣';
      case CardRarity.ssr:
        return '🟡';
    }
  }

  /// 抽取機率（百分比）
  int get drawProbability {
    switch (this) {
      case CardRarity.n:
        return 53;
      case CardRarity.r:
        return 25;
      case CardRarity.sr:
        return 17;
      case CardRarity.ssr:
        return 5;
    }
  }

  static CardRarity fromString(String value) {
    switch (value.toUpperCase()) {
      case 'N':
        return CardRarity.n;
      case 'R':
        return CardRarity.r;
      case 'SR':
        return CardRarity.sr;
      case 'SSR':
        return CardRarity.ssr;
      default:
        return CardRarity.n;
    }
  }
}

/// 卡牌目標類型枚舉
enum CardTargetType {
  self,           // 自己
  singleEnemy,    // 單一敵人
  singleAlly,     // 單一盟友
  singleAny,      // 任意單一玩家
  allEnemies,     // 所有敵人
  allAllies,      // 所有盟友
  allPlayers,     // 所有玩家
  none,           // 無目標（被動效果）
}

/// 卡牌目標類型顯示
extension CardTargetTypeExtension on CardTargetType {
  String get displayName {
    switch (this) {
      case CardTargetType.self:
        return '自己';
      case CardTargetType.singleEnemy:
        return '單一敵人';
      case CardTargetType.singleAlly:
        return '單一盟友';
      case CardTargetType.singleAny:
        return '任意玩家';
      case CardTargetType.allEnemies:
        return '所有敵人';
      case CardTargetType.allAllies:
        return '所有盟友';
      case CardTargetType.allPlayers:
        return '所有玩家';
      case CardTargetType.none:
        return '無';
    }
  }

  static CardTargetType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'self':
        return CardTargetType.self;
      case 'single_enemy':
      case 'singleenemy':
        return CardTargetType.singleEnemy;
      case 'single_ally':
      case 'singleally':
        return CardTargetType.singleAlly;
      case 'single_any':
      case 'singleany':
        return CardTargetType.singleAny;
      case 'all_enemies':
      case 'allenemies':
        return CardTargetType.allEnemies;
      case 'all_allies':
      case 'allallies':
        return CardTargetType.allAllies;
      case 'all_players':
      case 'allplayers':
        return CardTargetType.allPlayers;
      case 'none':
        return CardTargetType.none;
      default:
        return CardTargetType.singleEnemy;
    }
  }
}

/// 卡牌分類枚舉
enum CardCategory {
  universal,      // 通用對策卡 - 公共牌池
  characterSpecific,  // 角色專屬卡
  negative,       // 負面特質卡
}

/// 卡牌分類顯示
extension CardCategoryExtension on CardCategory {
  String get displayName {
    switch (this) {
      case CardCategory.universal:
        return '通用卡';
      case CardCategory.characterSpecific:
        return '專屬卡';
      case CardCategory.negative:
        return '負面卡';
    }
  }

  static CardCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'universal':
        return CardCategory.universal;
      case 'character_specific':
      case 'characterspecific':
        return CardCategory.characterSpecific;
      case 'negative':
        return CardCategory.negative;
      default:
        return CardCategory.universal;
    }
  }
}

/// 卡牌效果模型
class CardEffect {
  final String effectType;      // 效果類型（damage, heal, control, etc.）
  final int? value;             // 效果數值
  final int? duration;          // 持續回合數
  final String? condition;      // 觸發條件
  final String description;     // 效果描述

  const CardEffect({
    required this.effectType,
    this.value,
    this.duration,
    this.condition,
    required this.description,
  });

  factory CardEffect.fromJson(Map<String, dynamic> json) {
    return CardEffect(
      effectType: json['effect_type'] ?? json['effectType'] ?? '',
      value: json['value'],
      duration: json['duration'],
      condition: json['condition'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'effect_type': effectType,
      'value': value,
      'duration': duration,
      'condition': condition,
      'description': description,
    };
  }

  CardEffect copyWith({
    String? effectType,
    int? value,
    int? duration,
    String? condition,
    String? description,
  }) {
    return CardEffect(
      effectType: effectType ?? this.effectType,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      condition: condition ?? this.condition,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'CardEffect($effectType: $description)';
}

/// 卡牌模型
class GameCard {
  final String id;                  // 卡牌 ID (A01, D01, T01, etc.)
  final String name;                // 卡牌名稱
  final CardType type;              // 卡牌類型
  final CardRarity rarity;          // 稀有度
  final CardCategory category;      // 卡牌分類
  final int influenceCost;          // 影響力消耗 🌟
  final int goldCost;               // 金幣消耗 💰
  final CardTargetType targetType;  // 目標類型
  final int targetCount;            // 目標數量
  final CardEffect effect;          // 卡牌效果
  final String? characterType;      // 所屬角色類型（專屬卡用）
  final String? flavorText;         // 風味文字
  final String? imageUrl;           // 卡牌圖片 URL

  const GameCard({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.category,
    this.influenceCost = 0,
    this.goldCost = 0,
    required this.targetType,
    this.targetCount = 1,
    required this.effect,
    this.characterType,
    this.flavorText,
    this.imageUrl,
  });

  /// 是否為角色專屬卡
  bool get isCharacterSpecific => category == CardCategory.characterSpecific;

  /// 是否為負面特質卡
  bool get isNegative => category == CardCategory.negative;

  /// 是否需要選擇目標
  bool get requiresTarget =>
      targetType != CardTargetType.self && targetType != CardTargetType.none;

  /// 總消耗描述
  String get costDescription {
    final List<String> costs = [];
    if (influenceCost > 0) {
      costs.add('🌟$influenceCost');
    }
    if (goldCost > 0) {
      costs.add('💰$goldCost');
    }
    return costs.isEmpty ? '免費' : costs.join(' ');
  }

  /// 檢查是否能使用此卡牌
  bool canUse({required int influence, required int gold}) {
    return influence >= influenceCost && gold >= goldCost;
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: CardTypeExtension.fromString(json['type'] ?? 'attack'),
      rarity: CardRarityExtension.fromString(json['rarity'] ?? 'N'),
      category: CardCategoryExtension.fromString(json['category'] ?? 'universal'),
      influenceCost: json['influence_cost'] ?? json['influenceCost'] ?? 0,
      goldCost: json['gold_cost'] ?? json['goldCost'] ?? 0,
      targetType: CardTargetTypeExtension.fromString(
          json['target_type'] ?? json['targetType'] ?? 'single_enemy'),
      targetCount: json['target_count'] ?? json['targetCount'] ?? 1,
      effect: CardEffect.fromJson(json['effect'] ?? {'description': ''}),
      characterType: json['character_type'] ?? json['characterType'],
      flavorText: json['flavor_text'] ?? json['flavorText'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rarity': rarity.name.toUpperCase(),
      'category': category.name,
      'influence_cost': influenceCost,
      'gold_cost': goldCost,
      'target_type': targetType.name,
      'target_count': targetCount,
      'effect': effect.toJson(),
      'character_type': characterType,
      'flavor_text': flavorText,
      'image_url': imageUrl,
    };
  }

  GameCard copyWith({
    String? id,
    String? name,
    CardType? type,
    CardRarity? rarity,
    CardCategory? category,
    int? influenceCost,
    int? goldCost,
    CardTargetType? targetType,
    int? targetCount,
    CardEffect? effect,
    String? characterType,
    String? flavorText,
    String? imageUrl,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      category: category ?? this.category,
      influenceCost: influenceCost ?? this.influenceCost,
      goldCost: goldCost ?? this.goldCost,
      targetType: targetType ?? this.targetType,
      targetCount: targetCount ?? this.targetCount,
      effect: effect ?? this.effect,
      characterType: characterType ?? this.characterType,
      flavorText: flavorText ?? this.flavorText,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() =>
      'GameCard(id: $id, name: $name, type: ${type.displayName}, rarity: ${rarity.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 玩家手牌中的卡牌實例
class HandCard {
  final String instanceId;  // 手牌實例 ID（唯一）
  final GameCard card;      // 卡牌定義
  final bool isUsed;        // 是否已使用
  final DateTime? usedAt;   // 使用時間

  const HandCard({
    required this.instanceId,
    required this.card,
    this.isUsed = false,
    this.usedAt,
  });

  factory HandCard.fromJson(Map<String, dynamic> json) {
    return HandCard(
      instanceId: json['instance_id'] ?? json['instanceId'] ?? '',
      card: GameCard.fromJson(json['card'] ?? {}),
      isUsed: json['is_used'] ?? json['isUsed'] ?? false,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'])
          : json['usedAt'] != null
              ? DateTime.parse(json['usedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instance_id': instanceId,
      'card': card.toJson(),
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
    };
  }

  HandCard copyWith({
    String? instanceId,
    GameCard? card,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return HandCard(
      instanceId: instanceId ?? this.instanceId,
      card: card ?? this.card,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  /// 標記為已使用
  HandCard markAsUsed() {
    return copyWith(isUsed: true, usedAt: DateTime.now());
  }

  @override
  String toString() =>
      'HandCard(instanceId: $instanceId, card: ${card.name}, isUsed: $isUsed)';
}
