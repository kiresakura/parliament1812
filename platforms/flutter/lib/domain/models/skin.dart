// 1812 國會風雲 - 皮膚系統模型
//
// 定義角色皮膚、卡背、表情等裝飾品

/// 皮膚稀有度
enum SkinRarity {
  normal,     // N - 普通
  rare,       // R - 稀有
  superRare,  // SR - 超稀有
  ultraRare,  // SSR - 極稀有
  legendary,  // UR - 傳說
}

/// 皮膚類型
enum SkinType {
  character,  // 角色皮膚
  cardBack,   // 卡背
  emote,      // 表情
  avatarFrame,// 頭像框
  title,      // 稱號
  effect,     // 特效
}

/// 獲取方式
enum ObtainMethod {
  shop,           // 商城購買
  battlePass,     // Battle Pass 獎勵
  achievement,    // 成就解鎖
  event,          // 活動獎勵
  gacha,          // 抽獎
  promotion,      // 促銷禮包
  default_,       // 預設（免費）
}

/// 皮膚稀有度配置
class SkinRarityConfig {
  /// 顯示名稱
  final String displayName;

  /// 顏色代碼
  final int colorCode;

  /// 金幣價格（金基尼）
  final int goldPrice;

  /// 銀幣價格（銀先令）
  final int silverPrice;

  /// 分解獲得碎片
  final int dismantleShards;

  const SkinRarityConfig({
    required this.displayName,
    required this.colorCode,
    required this.goldPrice,
    required this.silverPrice,
    required this.dismantleShards,
  });

  static const Map<SkinRarity, SkinRarityConfig> configs = {
    SkinRarity.normal: SkinRarityConfig(
      displayName: 'N',
      colorCode: 0xFF808080,  // 灰色
      goldPrice: 50,
      silverPrice: 500,
      dismantleShards: 5,
    ),
    SkinRarity.rare: SkinRarityConfig(
      displayName: 'R',
      colorCode: 0xFF4169E1,  // 藍色
      goldPrice: 150,
      silverPrice: 1500,
      dismantleShards: 15,
    ),
    SkinRarity.superRare: SkinRarityConfig(
      displayName: 'SR',
      colorCode: 0xFF9932CC,  // 紫色
      goldPrice: 350,
      silverPrice: 0,  // 不可用銀幣購買
      dismantleShards: 50,
    ),
    SkinRarity.ultraRare: SkinRarityConfig(
      displayName: 'SSR',
      colorCode: 0xFFFFD700,  // 金色
      goldPrice: 680,
      silverPrice: 0,
      dismantleShards: 100,
    ),
    SkinRarity.legendary: SkinRarityConfig(
      displayName: 'UR',
      colorCode: 0xFFFF4500,  // 橙紅色
      goldPrice: 1280,
      silverPrice: 0,
      dismantleShards: 200,
    ),
  };
}

/// 皮膚模型
class Skin {
  /// 皮膚 ID
  final String id;

  /// 皮膚名稱
  final String name;

  /// 描述
  final String description;

  /// 皮膚類型
  final SkinType type;

  /// 稀有度
  final SkinRarity rarity;

  /// 所屬角色 ID（角色皮膚專用）
  final String? characterId;

  /// 預覽圖路徑
  final String? previewPath;

  /// 資源路徑
  final String? assetPath;

  /// 獲取方式
  final ObtainMethod obtainMethod;

  /// 是否限定
  final bool isLimited;

  /// 限定描述（如：S1 Battle Pass 限定）
  final String? limitedDescription;

  /// 上架時間
  final DateTime? releaseDate;

  /// 下架時間（限時）
  final DateTime? endDate;

  /// 特殊效果描述
  final String? specialEffect;

  /// 是否啟用
  final bool isEnabled;

  const Skin({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    this.characterId,
    this.previewPath,
    this.assetPath,
    this.obtainMethod = ObtainMethod.shop,
    this.isLimited = false,
    this.limitedDescription,
    this.releaseDate,
    this.endDate,
    this.specialEffect,
    this.isEnabled = true,
  });

  /// 獲取稀有度配置
  SkinRarityConfig get rarityConfig =>
      SkinRarityConfig.configs[rarity] ?? SkinRarityConfig.configs[SkinRarity.normal]!;

  /// 金幣價格
  int get goldPrice => rarityConfig.goldPrice;

  /// 銀幣價格
  int get silverPrice => rarityConfig.silverPrice;

  /// 是否可用銀幣購買
  bool get canBuyWithSilver => silverPrice > 0;

  /// 是否限時
  bool get isTimeLimited => endDate != null;

  /// 是否已下架
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// 是否可購買
  bool get isPurchasable =>
      isEnabled && obtainMethod == ObtainMethod.shop && !isExpired;

  factory Skin.fromJson(Map<String, dynamic> json) {
    return Skin(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: SkinType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SkinType.character,
      ),
      rarity: SkinRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => SkinRarity.normal,
      ),
      characterId: json['characterId'] as String?,
      previewPath: json['previewPath'] as String?,
      assetPath: json['assetPath'] as String?,
      obtainMethod: ObtainMethod.values.firstWhere(
        (e) => e.name == json['obtainMethod'],
        orElse: () => ObtainMethod.shop,
      ),
      isLimited: json['isLimited'] as bool? ?? false,
      limitedDescription: json['limitedDescription'] as String?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      specialEffect: json['specialEffect'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'rarity': rarity.name,
      'characterId': characterId,
      'previewPath': previewPath,
      'assetPath': assetPath,
      'obtainMethod': obtainMethod.name,
      'isLimited': isLimited,
      'limitedDescription': limitedDescription,
      'releaseDate': releaseDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'specialEffect': specialEffect,
      'isEnabled': isEnabled,
    };
  }
}

/// 玩家皮膚收藏
class SkinCollection {
  /// 擁有的皮膚 ID
  final Set<String> ownedSkins;

  /// 當前裝備的角色皮膚（characterId -> skinId）
  final Map<String, String> equippedCharacterSkins;

  /// 當前裝備的卡背
  final String? equippedCardBack;

  /// 當前裝備的頭像框
  final String? equippedAvatarFrame;

  /// 當前裝備的稱號
  final String? equippedTitle;

  /// 皮膚碎片
  final int skinShards;

  const SkinCollection({
    this.ownedSkins = const {},
    this.equippedCharacterSkins = const {},
    this.equippedCardBack,
    this.equippedAvatarFrame,
    this.equippedTitle,
    this.skinShards = 0,
  });

  /// 檢查是否擁有皮膚
  bool ownsSkin(String skinId) => ownedSkins.contains(skinId);

  /// 獲取角色當前皮膚
  String? getEquippedSkin(String characterId) =>
      equippedCharacterSkins[characterId];

  /// 擁有的皮膚數量
  int get ownedCount => ownedSkins.length;

  SkinCollection copyWith({
    Set<String>? ownedSkins,
    Map<String, String>? equippedCharacterSkins,
    String? equippedCardBack,
    String? equippedAvatarFrame,
    String? equippedTitle,
    int? skinShards,
    bool clearCardBack = false,
    bool clearAvatarFrame = false,
    bool clearTitle = false,
  }) {
    return SkinCollection(
      ownedSkins: ownedSkins ?? this.ownedSkins,
      equippedCharacterSkins:
          equippedCharacterSkins ?? this.equippedCharacterSkins,
      equippedCardBack:
          clearCardBack ? null : (equippedCardBack ?? this.equippedCardBack),
      equippedAvatarFrame: clearAvatarFrame
          ? null
          : (equippedAvatarFrame ?? this.equippedAvatarFrame),
      equippedTitle:
          clearTitle ? null : (equippedTitle ?? this.equippedTitle),
      skinShards: skinShards ?? this.skinShards,
    );
  }

  factory SkinCollection.fromJson(Map<String, dynamic> json) {
    return SkinCollection(
      ownedSkins: (json['ownedSkins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      equippedCharacterSkins:
          (json['equippedCharacterSkins'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v as String)) ??
              {},
      equippedCardBack: json['equippedCardBack'] as String?,
      equippedAvatarFrame: json['equippedAvatarFrame'] as String?,
      equippedTitle: json['equippedTitle'] as String?,
      skinShards: json['skinShards'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownedSkins': ownedSkins.toList(),
      'equippedCharacterSkins': equippedCharacterSkins,
      'equippedCardBack': equippedCardBack,
      'equippedAvatarFrame': equippedAvatarFrame,
      'equippedTitle': equippedTitle,
      'skinShards': skinShards,
    };
  }
}

/// 預設皮膚資料庫
class SkinDatabase {
  SkinDatabase._();

  /// 所有皮膚
  static final List<Skin> allSkins = [
    // ============================================================
    // 湯瑪斯皮膚
    // ============================================================
    const Skin(
      id: 'thomas_default',
      name: '預設',
      description: '工人湯瑪斯的預設外觀',
      type: SkinType.character,
      rarity: SkinRarity.normal,
      characterId: 'worker_thomas',
      obtainMethod: ObtainMethod.default_,
    ),
    const Skin(
      id: 'thomas_foreman',
      name: '工頭湯瑪斯',
      description: '升職為工頭的湯瑪斯，穿著更體面的工作服',
      type: SkinType.character,
      rarity: SkinRarity.rare,
      characterId: 'worker_thomas',
    ),
    const Skin(
      id: 'thomas_revolutionary',
      name: '革命者湯瑪斯',
      description: '投身革命的湯瑪斯，揮舞著紅旗',
      type: SkinType.character,
      rarity: SkinRarity.superRare,
      characterId: 'worker_thomas',
      specialEffect: '質詢時顯示特殊動畫',
    ),
    const Skin(
      id: 'thomas_union_leader',
      name: '工會領袖',
      description: 'S1 Battle Pass 限定皮膚',
      type: SkinType.character,
      rarity: SkinRarity.ultraRare,
      characterId: 'worker_thomas',
      obtainMethod: ObtainMethod.battlePass,
      isLimited: true,
      limitedDescription: 'S1 Battle Pass Lv.50 獎勵',
      specialEffect: '入場時顯示專屬特效',
    ),

    // ============================================================
    // 理查皮膚
    // ============================================================
    const Skin(
      id: 'richard_default',
      name: '預設',
      description: '工廠主理查的預設外觀',
      type: SkinType.character,
      rarity: SkinRarity.normal,
      characterId: 'factory_richard',
      obtainMethod: ObtainMethod.default_,
    ),
    const Skin(
      id: 'richard_tycoon',
      name: '鋼鐵大亨',
      description: '財富達到頂峰的理查，穿著華貴的禮服',
      type: SkinType.character,
      rarity: SkinRarity.superRare,
      characterId: 'factory_richard',
      specialEffect: '使用金幣技能時顯示金幣特效',
    ),

    // ============================================================
    // 卡背
    // ============================================================
    const Skin(
      id: 'cardback_default',
      name: '議會標準',
      description: '議會標準卡背',
      type: SkinType.cardBack,
      rarity: SkinRarity.normal,
      obtainMethod: ObtainMethod.default_,
    ),
    const Skin(
      id: 'cardback_royal',
      name: '皇家紋章',
      description: '繪有皇家紋章的華麗卡背',
      type: SkinType.cardBack,
      rarity: SkinRarity.rare,
    ),
    const Skin(
      id: 'cardback_industrial',
      name: '工業革命',
      description: '蒸汽朋克風格的卡背',
      type: SkinType.cardBack,
      rarity: SkinRarity.superRare,
    ),

    // ============================================================
    // 頭像框
    // ============================================================
    const Skin(
      id: 'frame_default',
      name: '預設框',
      description: '預設頭像框',
      type: SkinType.avatarFrame,
      rarity: SkinRarity.normal,
      obtainMethod: ObtainMethod.default_,
    ),
    const Skin(
      id: 'frame_golden',
      name: '金色華框',
      description: '閃耀的金色頭像框',
      type: SkinType.avatarFrame,
      rarity: SkinRarity.rare,
    ),
    const Skin(
      id: 'frame_champion',
      name: '冠軍之框',
      description: '排行榜前 100 名獎勵',
      type: SkinType.avatarFrame,
      rarity: SkinRarity.ultraRare,
      obtainMethod: ObtainMethod.achievement,
      isLimited: true,
    ),
  ];

  /// 根據 ID 獲取皮膚
  static Skin? getSkinById(String id) {
    try {
      return allSkins.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 獲取角色的所有皮膚
  static List<Skin> getSkinsForCharacter(String characterId) {
    return allSkins
        .where((s) =>
            s.type == SkinType.character && s.characterId == characterId)
        .toList();
  }

  /// 獲取所有卡背
  static List<Skin> get allCardBacks {
    return allSkins.where((s) => s.type == SkinType.cardBack).toList();
  }

  /// 獲取所有頭像框
  static List<Skin> get allAvatarFrames {
    return allSkins.where((s) => s.type == SkinType.avatarFrame).toList();
  }

  /// 獲取商城可購買的皮膚
  static List<Skin> get shopSkins {
    return allSkins.where((s) => s.isPurchasable).toList();
  }
}

/// 玩家擁有的皮膚
class OwnedSkin {
  /// 皮膚資料
  final Skin skin;

  /// 獲得時間
  final DateTime obtainedAt;

  /// 獲得方式
  final ObtainMethod obtainMethod;

  /// 是否為新獲得（用於顯示紅點）
  final bool isNew;

  const OwnedSkin({
    required this.skin,
    required this.obtainedAt,
    required this.obtainMethod,
    this.isNew = true,
  });

  OwnedSkin copyWith({
    Skin? skin,
    DateTime? obtainedAt,
    ObtainMethod? obtainMethod,
    bool? isNew,
  }) {
    return OwnedSkin(
      skin: skin ?? this.skin,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      obtainMethod: obtainMethod ?? this.obtainMethod,
      isNew: isNew ?? this.isNew,
    );
  }

  factory OwnedSkin.fromJson(Map<String, dynamic> json) {
    return OwnedSkin(
      skin: Skin.fromJson(json['skin'] as Map<String, dynamic>),
      obtainedAt: DateTime.parse(json['obtained_at'] as String),
      obtainMethod: ObtainMethod.values.firstWhere(
        (e) => e.name == json['obtain_method'],
        orElse: () => ObtainMethod.shop,
      ),
      isNew: json['is_new'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skin': skin.toJson(),
      'obtained_at': obtainedAt.toIso8601String(),
      'obtain_method': obtainMethod.name,
      'is_new': isNew,
    };
  }
}
