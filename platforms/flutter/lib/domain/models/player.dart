// 1812 國會風雲 - 玩家模型

/// 玩家模型
/// 代表遊戲中的一位玩家，包含所有相關狀態
class Player {
  /// 玩家唯一識別碼
  final String id;

  /// 玩家暱稱
  final String name;

  /// 分配的角色 ID（遊戲開始後才有）
  final String? roleId;

  /// 聲望值（生命值）- 初始值依角色而定，歸零則政治死亡
  final int reputation;

  /// 金幣 - 用於賄賂、交易
  final int gold;

  /// 情報卡數量
  final int intel;

  /// 人情點數 - 用於請求幫助
  final int favor;

  /// 防禦值 - 減少受到的聲望傷害
  final int defense;

  /// 是否存活（政治死亡判定：聲望 <= 0）
  final bool isAlive;

  /// 是否已準備（大廳階段）
  final bool isReady;

  /// 是否為房主
  final bool isHost;

  /// 當前狀態效果列表
  final List<StatusEffect> statusEffects;

  /// 結盟對象 ID 列表
  final List<String> allies;

  const Player({
    required this.id,
    required this.name,
    this.roleId,
    this.reputation = 50,
    this.gold = 0,
    this.intel = 0,
    this.favor = 0,
    this.defense = 0,
    this.isAlive = true,
    this.isReady = false,
    this.isHost = false,
    this.statusEffects = const [],
    this.allies = const [],
  });

  /// 是否處於政治死亡狀態
  bool get isPoliticallyDead => reputation <= 0;

  /// 計算投票權重
  double get voteWeight {
    if (isPoliticallyDead) return 0.0;
    if (reputation > 80) return 1.5;
    if (reputation >= 50) return 1.0;
    if (reputation >= 30) return 0.7;
    return 0.5;
  }

  /// 計算實際受到的傷害（考慮防禦）
  int calculateActualDamage(int baseDamage) {
    final reduction = defense / 200;
    return (baseDamage * (1 - reduction)).round();
  }

  /// 複製並修改
  Player copyWith({
    String? id,
    String? name,
    String? roleId,
    int? reputation,
    int? gold,
    int? intel,
    int? favor,
    int? defense,
    bool? isAlive,
    bool? isReady,
    bool? isHost,
    List<StatusEffect>? statusEffects,
    List<String>? allies,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      reputation: reputation ?? this.reputation,
      gold: gold ?? this.gold,
      intel: intel ?? this.intel,
      favor: favor ?? this.favor,
      defense: defense ?? this.defense,
      isAlive: isAlive ?? (reputation ?? this.reputation) > 0,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      statusEffects: statusEffects ?? this.statusEffects,
      allies: allies ?? this.allies,
    );
  }

  /// 從 JSON 建立
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      roleId: json['roleId'] as String?,
      reputation: json['reputation'] as int? ?? 50,
      gold: json['gold'] as int? ?? 0,
      intel: json['intel'] as int? ?? 0,
      favor: json['favor'] as int? ?? 0,
      defense: json['defense'] as int? ?? 0,
      isAlive: json['isAlive'] as bool? ?? true,
      isReady: json['isReady'] as bool? ?? false,
      isHost: json['isHost'] as bool? ?? false,
      statusEffects: (json['statusEffects'] as List<dynamic>?)
              ?.map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      allies: (json['allies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roleId': roleId,
      'reputation': reputation,
      'gold': gold,
      'intel': intel,
      'favor': favor,
      'defense': defense,
      'isAlive': isAlive,
      'isReady': isReady,
      'isHost': isHost,
      'statusEffects': statusEffects.map((e) => e.toJson()).toList(),
      'allies': allies,
    };
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, roleId: $roleId, reputation: $reputation, isAlive: $isAlive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 狀態效果類型
enum StatusEffectType {
  // 正面狀態 (Buff)
  prestigious,       // 聲威大振 - 聲望 +20%
  popular,           // 眾望所歸 - 防禦 +30
  intelAdvantage,    // 情報優勢 - 下次攻擊 +50%
  allySupport,       // 盟友加持 - 每回合回復 5 聲望
  royalProtection,   // 王室庇護 - 免疫下一次攻擊

  // 負面狀態 (Debuff)
  scandal,           // 醜聞纏身 - 聲望 -20%
  betrayed,          // 眾叛親離 - 無法獲得盟友加成
  targeted,          // 被盯上 - 受到傷害 +30%
  silenced,          // 沉默 - 無法發言
  bankrupt,          // 破產 - 無法使用金幣
  confused,          // 精神錯亂 - 隨機行動

  // 銀行家亨利專屬狀態
  debt,              // 負債 - 3 回合後若未還 40 金幣，聲望 -25
}

/// 狀態效果
class StatusEffect {
  /// 效果類型
  final StatusEffectType type;

  /// 剩餘回合數（0 表示永久或直到觸發）
  final int remainingTurns;

  /// 效果強度（百分比或固定值）
  final int value;

  const StatusEffect({
    required this.type,
    this.remainingTurns = 1,
    this.value = 0,
  });

  /// 是否為正面效果
  bool get isBuff {
    return type == StatusEffectType.prestigious ||
        type == StatusEffectType.popular ||
        type == StatusEffectType.intelAdvantage ||
        type == StatusEffectType.allySupport ||
        type == StatusEffectType.royalProtection;
  }

  /// 效果名稱
  String get name {
    switch (type) {
      case StatusEffectType.prestigious:
        return '聲威大振';
      case StatusEffectType.popular:
        return '眾望所歸';
      case StatusEffectType.intelAdvantage:
        return '情報優勢';
      case StatusEffectType.allySupport:
        return '盟友加持';
      case StatusEffectType.royalProtection:
        return '王室庇護';
      case StatusEffectType.scandal:
        return '醜聞纏身';
      case StatusEffectType.betrayed:
        return '眾叛親離';
      case StatusEffectType.targeted:
        return '被盯上';
      case StatusEffectType.silenced:
        return '沉默';
      case StatusEffectType.bankrupt:
        return '破產';
      case StatusEffectType.confused:
        return '精神錯亂';
      case StatusEffectType.debt:
        return '負債';
    }
  }

  /// 效果圖標
  String get icon {
    switch (type) {
      case StatusEffectType.prestigious:
        return '⬆️';
      case StatusEffectType.popular:
        return '👥';
      case StatusEffectType.intelAdvantage:
        return '🔍';
      case StatusEffectType.allySupport:
        return '🤝';
      case StatusEffectType.royalProtection:
        return '👑';
      case StatusEffectType.scandal:
        return '📰';
      case StatusEffectType.betrayed:
        return '💔';
      case StatusEffectType.targeted:
        return '🎯';
      case StatusEffectType.silenced:
        return '🤐';
      case StatusEffectType.bankrupt:
        return '💸';
      case StatusEffectType.confused:
        return '😵';
      case StatusEffectType.debt:
        return '💳';
    }
  }

  StatusEffect copyWith({
    StatusEffectType? type,
    int? remainingTurns,
    int? value,
  }) {
    return StatusEffect(
      type: type ?? this.type,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }

  factory StatusEffect.fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      type: StatusEffectType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StatusEffectType.scandal,
      ),
      remainingTurns: json['remainingTurns'] as int? ?? 1,
      value: json['value'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'remainingTurns': remainingTurns,
      'value': value,
    };
  }
}
