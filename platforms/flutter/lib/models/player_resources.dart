/// 玩家資源模型
/// 1812 國會風雲 - 三資源經濟系統
library player_resources;

/// 資源類型枚舉
enum ResourceType {
  reputation,   // ❤️ 聲望 - 政治生命值，歸零=政治死亡
  influence,    // 🌟 影響力 - 打牌能量，每回合回復
  gold,         // 💰 金幣 - 特殊交易、賄賂
}

/// 資源類型顯示
extension ResourceTypeExtension on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.reputation:
        return '聲望';
      case ResourceType.influence:
        return '影響力';
      case ResourceType.gold:
        return '金幣';
    }
  }

  String get icon {
    switch (this) {
      case ResourceType.reputation:
        return '❤️';
      case ResourceType.influence:
        return '🌟';
      case ResourceType.gold:
        return '💰';
    }
  }

  /// 資源上限
  int get maxValue {
    switch (this) {
      case ResourceType.reputation:
        return 100;
      case ResourceType.influence:
        return 15;
      case ResourceType.gold:
        return 150;
    }
  }
}

/// 玩家資源模型
class PlayerResources {
  final String playerId;          // 玩家 ID
  final int reputation;           // ❤️ 聲望 (0-100)
  final int influence;            // 🌟 影響力 (0-15)
  final int gold;                 // 💰 金幣 (0-150)
  final bool isPoliticallyDead;   // 是否政治死亡
  final DateTime? updatedAt;      // 最後更新時間

  /// 聲望上限
  static const int maxReputation = 100;
  /// 影響力上限
  static const int maxInfluence = 15;
  /// 金幣上限
  static const int maxGold = 150;
  /// 每回合影響力回復量
  static const int influencePerTurn = 3;
  /// 政治死亡閾值
  static const int politicalDeathThreshold = 0;

  const PlayerResources({
    required this.playerId,
    this.reputation = 50,
    this.influence = 10,
    this.gold = 20,
    this.isPoliticallyDead = false,
    this.updatedAt,
  });

  /// 根據角色類型建立初始資源
  factory PlayerResources.forCharacter({
    required String playerId,
    required String characterType,
  }) {
    switch (characterType.toLowerCase()) {
      case 'worker':
      case 'thomas':
        // 工人湯瑪斯 - 勞工派
        return PlayerResources(
          playerId: playerId,
          reputation: 70,
          influence: 10,
          gold: 15,
        );
      case 'factory_owner':
      case 'richard':
        // 工廠主理查 - 資方派
        return PlayerResources(
          playerId: playerId,
          reputation: 65,
          influence: 8,
          gold: 100,
        );
      case 'luddite':
      case 'george_luddite':
        // 盧德派喬治 - 勞工派
        return PlayerResources(
          playerId: playerId,
          reputation: 80,
          influence: 12,
          gold: 10,
        );
      case 'reformer':
      case 'robert':
        // 改革者羅伯特 - 改革派
        return PlayerResources(
          playerId: playerId,
          reputation: 60,
          influence: 10,
          gold: 30,
        );
      case 'journalist':
      case 'edward':
        // 記者愛德華 - 中立派
        return PlayerResources(
          playerId: playerId,
          reputation: 55,
          influence: 11,
          gold: 25,
        );
      case 'parliamentarian':
      case 'william':
        // 議員威廉 - 中立派
        return PlayerResources(
          playerId: playerId,
          reputation: 50,
          influence: 9,
          gold: 50,
        );
      case 'king':
      case 'george_iii':
        // 喬治三世 - 皇室
        return PlayerResources(
          playerId: playerId,
          reputation: 90,
          influence: 8,
          gold: 80,
        );
      default:
        return PlayerResources(playerId: playerId);
    }
  }

  /// 聲望百分比 (0.0 - 1.0)
  double get reputationPercentage => reputation / maxReputation;

  /// 影響力百分比 (0.0 - 1.0)
  double get influencePercentage => influence / maxInfluence;

  /// 金幣百分比 (0.0 - 1.0)
  double get goldPercentage => gold / maxGold;

  /// 投票權重（根據聲望計算）
  double get voteWeight {
    if (isPoliticallyDead || reputation <= 0) return 0.0;
    if (reputation > 80) return 1.5;
    if (reputation > 60) return 1.2;
    if (reputation > 40) return 1.0;
    if (reputation > 20) return 0.8;
    return 0.5;
  }

  /// 投票權重等級描述
  String get voteWeightDescription {
    if (isPoliticallyDead || reputation <= 0) return '無投票權';
    if (reputation > 80) return '政治明星 (1.5×)';
    if (reputation > 60) return '有影響力 (1.2×)';
    if (reputation > 40) return '普通議員 (1.0×)';
    if (reputation > 20) return '邊緣人物 (0.8×)';
    return '瀕臨死亡 (0.5×)';
  }

  /// 是否能使用卡牌
  bool canUseCard({required int influenceCost, int goldCost = 0}) {
    if (isPoliticallyDead) return false;
    return influence >= influenceCost && gold >= goldCost;
  }

  /// 造成聲望傷害
  PlayerResources takeDamage(int damage) {
    final newReputation = (reputation - damage).clamp(0, maxReputation);
    return copyWith(
      reputation: newReputation,
      isPoliticallyDead: newReputation <= politicalDeathThreshold,
      updatedAt: DateTime.now(),
    );
  }

  /// 治療聲望
  PlayerResources heal(int amount) {
    if (isPoliticallyDead) {
      // 政治死亡時需要特殊卡牌復活
      return this;
    }
    final newReputation = (reputation + amount).clamp(0, maxReputation);
    return copyWith(
      reputation: newReputation,
      updatedAt: DateTime.now(),
    );
  }

  /// 復活（從政治死亡狀態恢復）
  PlayerResources revive({int startingReputation = 20}) {
    if (!isPoliticallyDead) return this;
    return copyWith(
      reputation: startingReputation.clamp(1, maxReputation),
      isPoliticallyDead: false,
      updatedAt: DateTime.now(),
    );
  }

  /// 消耗影響力
  PlayerResources spendInfluence(int amount) {
    if (influence < amount) return this;
    return copyWith(
      influence: influence - amount,
      updatedAt: DateTime.now(),
    );
  }

  /// 回復影響力（每回合開始時調用）
  PlayerResources restoreInfluence({int amount = influencePerTurn}) {
    final newInfluence = (influence + amount).clamp(0, maxInfluence);
    return copyWith(
      influence: newInfluence,
      updatedAt: DateTime.now(),
    );
  }

  /// 消耗金幣
  PlayerResources spendGold(int amount) {
    if (gold < amount) return this;
    return copyWith(
      gold: gold - amount,
      updatedAt: DateTime.now(),
    );
  }

  /// 獲得金幣
  PlayerResources earnGold(int amount) {
    final newGold = (gold + amount).clamp(0, maxGold);
    return copyWith(
      gold: newGold,
      updatedAt: DateTime.now(),
    );
  }

  /// 轉移資源給另一位玩家
  /// 返回 (更新後的自己, 轉移的資源量)
  (PlayerResources, ResourceTransfer) transferTo({
    required ResourceType type,
    required int amount,
  }) {
    int actualAmount = 0;
    PlayerResources updated;

    switch (type) {
      case ResourceType.reputation:
        actualAmount = amount.clamp(0, reputation);
        updated = takeDamage(actualAmount);
        break;
      case ResourceType.influence:
        actualAmount = amount.clamp(0, influence);
        updated = spendInfluence(actualAmount);
        break;
      case ResourceType.gold:
        actualAmount = amount.clamp(0, gold);
        updated = spendGold(actualAmount);
        break;
    }

    final transfer = ResourceTransfer(
      type: type,
      amount: actualAmount,
    );

    return (updated, transfer);
  }

  /// 接收資源轉移
  PlayerResources receiveTransfer(ResourceTransfer transfer) {
    switch (transfer.type) {
      case ResourceType.reputation:
        return heal(transfer.amount);
      case ResourceType.influence:
        return copyWith(
          influence: (influence + transfer.amount).clamp(0, maxInfluence),
          updatedAt: DateTime.now(),
        );
      case ResourceType.gold:
        return earnGold(transfer.amount);
    }
  }

  factory PlayerResources.fromJson(Map<String, dynamic> json) {
    return PlayerResources(
      playerId: json['player_id'] ?? json['playerId'] ?? '',
      reputation: json['reputation'] ?? 50,
      influence: json['influence'] ?? 10,
      gold: json['gold'] ?? 20,
      isPoliticallyDead:
          json['is_politically_dead'] ?? json['isPoliticallyDead'] ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'reputation': reputation,
      'influence': influence,
      'gold': gold,
      'is_politically_dead': isPoliticallyDead,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PlayerResources copyWith({
    String? playerId,
    int? reputation,
    int? influence,
    int? gold,
    bool? isPoliticallyDead,
    DateTime? updatedAt,
  }) {
    return PlayerResources(
      playerId: playerId ?? this.playerId,
      reputation: reputation ?? this.reputation,
      influence: influence ?? this.influence,
      gold: gold ?? this.gold,
      isPoliticallyDead: isPoliticallyDead ?? this.isPoliticallyDead,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'PlayerResources(playerId: $playerId, ❤️$reputation, 🌟$influence, 💰$gold, dead: $isPoliticallyDead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerResources &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          reputation == other.reputation &&
          influence == other.influence &&
          gold == other.gold &&
          isPoliticallyDead == other.isPoliticallyDead;

  @override
  int get hashCode =>
      playerId.hashCode ^
      reputation.hashCode ^
      influence.hashCode ^
      gold.hashCode ^
      isPoliticallyDead.hashCode;
}

/// 資源轉移記錄
class ResourceTransfer {
  final ResourceType type;
  final int amount;

  const ResourceTransfer({
    required this.type,
    required this.amount,
  });

  factory ResourceTransfer.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] ?? 'gold';
    ResourceType type;
    switch (typeStr.toLowerCase()) {
      case 'reputation':
        type = ResourceType.reputation;
        break;
      case 'influence':
        type = ResourceType.influence;
        break;
      case 'gold':
      default:
        type = ResourceType.gold;
        break;
    }
    return ResourceTransfer(
      type: type,
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
    };
  }

  @override
  String toString() => 'ResourceTransfer(${type.icon}$amount)';
}

/// 資源變化記錄（用於動畫和歷史追蹤）
class ResourceChange {
  final String playerId;
  final ResourceType type;
  final int oldValue;
  final int newValue;
  final String? reason;         // 變化原因
  final String? sourcePlayerId; // 來源玩家（如果是被攻擊）
  final String? cardId;         // 相關卡牌
  final DateTime timestamp;

  const ResourceChange({
    required this.playerId,
    required this.type,
    required this.oldValue,
    required this.newValue,
    this.reason,
    this.sourcePlayerId,
    this.cardId,
    required this.timestamp,
  });

  /// 變化量（正數為增加，負數為減少）
  int get delta => newValue - oldValue;

  /// 是否為增加
  bool get isIncrease => delta > 0;

  /// 是否為減少
  bool get isDecrease => delta < 0;

  factory ResourceChange.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] ?? 'reputation';
    ResourceType type;
    switch (typeStr.toLowerCase()) {
      case 'reputation':
        type = ResourceType.reputation;
        break;
      case 'influence':
        type = ResourceType.influence;
        break;
      case 'gold':
      default:
        type = ResourceType.gold;
        break;
    }
    return ResourceChange(
      playerId: json['player_id'] ?? json['playerId'] ?? '',
      type: type,
      oldValue: json['old_value'] ?? json['oldValue'] ?? 0,
      newValue: json['new_value'] ?? json['newValue'] ?? 0,
      reason: json['reason'],
      sourcePlayerId: json['source_player_id'] ?? json['sourcePlayerId'],
      cardId: json['card_id'] ?? json['cardId'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'type': type.name,
      'old_value': oldValue,
      'new_value': newValue,
      'reason': reason,
      'source_player_id': sourcePlayerId,
      'card_id': cardId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'ResourceChange(${type.icon} $oldValue → $newValue, delta: $delta)';
}
