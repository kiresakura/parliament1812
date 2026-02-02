// 1812 國會風雲 - 議員生涯數據模型

/// 議員等級
enum ParliamentLevel {
  trainee(1, '見習議員', 0),
  junior(2, '初級議員', 100),
  senior(3, '資深議員', 300),
  frontBench(4, '前排議員', 600),
  cabinet(5, '內閣成員', 1000),
  primeCandidate(6, '首相候選人', 1500),
  primeMinister(7, '首相', 2500);

  final int level;
  final String title;
  final int requiredExp;

  const ParliamentLevel(this.level, this.title, this.requiredExp);

  /// 獲取該等級的獎勵描述
  String get rewardDescription {
    switch (this) {
      case ParliamentLevel.trainee:
        return '初始';
      case ParliamentLevel.junior:
        return '解鎖 1 個角色';
      case ParliamentLevel.senior:
        return '解鎖頭像框';
      case ParliamentLevel.frontBench:
        return '解鎖 2 個角色';
      case ParliamentLevel.cabinet:
        return '解鎖稱號';
      case ParliamentLevel.primeCandidate:
        return '解鎖特殊皮膚';
      case ParliamentLevel.primeMinister:
        return '解鎖全部內容';
    }
  }

  /// 獲取等級圖標
  String get icon {
    switch (this) {
      case ParliamentLevel.trainee:
        return '📜';
      case ParliamentLevel.junior:
        return '🎖️';
      case ParliamentLevel.senior:
        return '⭐';
      case ParliamentLevel.frontBench:
        return '🌟';
      case ParliamentLevel.cabinet:
        return '💫';
      case ParliamentLevel.primeCandidate:
        return '👑';
      case ParliamentLevel.primeMinister:
        return '🏛️';
    }
  }

  /// 根據經驗值計算等級
  static ParliamentLevel fromExp(int exp) {
    for (final level in ParliamentLevel.values.reversed) {
      if (exp >= level.requiredExp) {
        return level;
      }
    }
    return ParliamentLevel.trainee;
  }

  /// 獲取下一等級
  ParliamentLevel? get nextLevel {
    final currentIndex = ParliamentLevel.values.indexOf(this);
    if (currentIndex < ParliamentLevel.values.length - 1) {
      return ParliamentLevel.values[currentIndex + 1];
    }
    return null;
  }
}

/// 解鎖內容類型
enum UnlockType {
  character,   // 角色
  avatarFrame, // 頭像框
  title,       // 稱號
  skin,        // 皮膚
  all,         // 全部內容
}

/// 解鎖內容
class UnlockContent {
  final String id;
  final UnlockType type;
  final String name;
  final String description;
  final ParliamentLevel requiredLevel;

  const UnlockContent({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.requiredLevel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'description': description,
    'requiredLevel': requiredLevel.level,
  };

  factory UnlockContent.fromJson(Map<String, dynamic> json) => UnlockContent(
    id: json['id'] as String,
    type: UnlockType.values.firstWhere((e) => e.name == json['type']),
    name: json['name'] as String,
    description: json['description'] as String,
    requiredLevel: ParliamentLevel.values.firstWhere(
      (e) => e.level == json['requiredLevel'],
    ),
  );
}

/// 經驗獲取來源
enum ExpSource {
  gameComplete('完成一局', 20, 50),
  factionVictory('陣營勝利', 30, 30),
  secretMission('完成秘密任務', 20, 20),
  mvp('獲得 MVP', 50, 50);

  final String description;
  final int minExp;
  final int maxExp;

  const ExpSource(this.description, this.minExp, this.maxExp);

  /// 計算經驗值（用於基於表現的經驗）
  int calculateExp({double performance = 0.5}) {
    if (minExp == maxExp) return minExp;
    return minExp + ((maxExp - minExp) * performance).round();
  }
}

/// 遊戲結算數據
class GameResultData {
  /// 是否完成遊戲
  final bool completed;
  
  /// 遊戲表現（0.0-1.0）
  final double performance;
  
  /// 是否陣營勝利
  final bool factionVictory;
  
  /// 是否完成秘密任務
  final bool secretMissionComplete;
  
  /// 是否獲得 MVP
  final bool isMvp;

  const GameResultData({
    this.completed = true,
    this.performance = 0.5,
    this.factionVictory = false,
    this.secretMissionComplete = false,
    this.isMvp = false,
  });

  /// 計算總經驗獲得
  int calculateTotalExp() {
    int total = 0;
    
    if (completed) {
      total += ExpSource.gameComplete.calculateExp(performance: performance);
    }
    
    if (factionVictory) {
      total += ExpSource.factionVictory.calculateExp();
    }
    
    if (secretMissionComplete) {
      total += ExpSource.secretMission.calculateExp();
    }
    
    if (isMvp) {
      total += ExpSource.mvp.calculateExp();
    }
    
    return total;
  }

  /// 獲取經驗獲得明細
  List<ExpBreakdown> getExpBreakdown() {
    final breakdown = <ExpBreakdown>[];
    
    if (completed) {
      final exp = ExpSource.gameComplete.calculateExp(performance: performance);
      breakdown.add(ExpBreakdown(
        source: ExpSource.gameComplete,
        amount: exp,
      ));
    }
    
    if (factionVictory) {
      breakdown.add(ExpBreakdown(
        source: ExpSource.factionVictory,
        amount: ExpSource.factionVictory.calculateExp(),
      ));
    }
    
    if (secretMissionComplete) {
      breakdown.add(ExpBreakdown(
        source: ExpSource.secretMission,
        amount: ExpSource.secretMission.calculateExp(),
      ));
    }
    
    if (isMvp) {
      breakdown.add(ExpBreakdown(
        source: ExpSource.mvp,
        amount: ExpSource.mvp.calculateExp(),
      ));
    }
    
    return breakdown;
  }
}

/// 經驗獲得明細
class ExpBreakdown {
  final ExpSource source;
  final int amount;

  const ExpBreakdown({
    required this.source,
    required this.amount,
  });
}

/// 玩家生涯數據
class PlayerCareer {
  /// 玩家 ID
  final String playerId;
  
  /// 玩家暱稱
  final String nickname;
  
  /// 當前經驗值
  final int experience;
  
  /// 總遊戲場次
  final int totalGames;
  
  /// 勝利場次
  final int victories;
  
  /// MVP 次數
  final int mvpCount;
  
  /// 解鎖的內容 ID 列表
  final List<String> unlockedContentIds;
  
  /// 裝備的頭像框 ID
  final String? equippedAvatarFrameId;
  
  /// 裝備的稱號 ID
  final String? equippedTitleId;
  
  /// 裝備的皮膚 ID
  final String? equippedSkinId;
  
  /// 創建時間
  final DateTime createdAt;
  
  /// 最後遊戲時間
  final DateTime? lastPlayedAt;

  const PlayerCareer({
    required this.playerId,
    required this.nickname,
    this.experience = 0,
    this.totalGames = 0,
    this.victories = 0,
    this.mvpCount = 0,
    this.unlockedContentIds = const [],
    this.equippedAvatarFrameId,
    this.equippedTitleId,
    this.equippedSkinId,
    DateTime? createdAt,
    this.lastPlayedAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime();

  /// 當前等級
  ParliamentLevel get level => ParliamentLevel.fromExp(experience);

  /// 當前等級進度（0.0-1.0）
  double get levelProgress {
    final currentLevel = level;
    final nextLevel = currentLevel.nextLevel;
    
    if (nextLevel == null) return 1.0; // 已滿級
    
    final currentExp = experience - currentLevel.requiredExp;
    final requiredExp = nextLevel.requiredExp - currentLevel.requiredExp;
    
    return currentExp / requiredExp;
  }

  /// 距離下一級所需經驗
  int get expToNextLevel {
    final nextLevel = level.nextLevel;
    if (nextLevel == null) return 0;
    return nextLevel.requiredExp - experience;
  }

  /// 勝率
  double get winRate {
    if (totalGames == 0) return 0.0;
    return victories / totalGames;
  }

  /// 是否已滿級
  bool get isMaxLevel => level == ParliamentLevel.primeMinister;

  /// 檢查是否解鎖了指定內容
  bool isContentUnlocked(String contentId) {
    return unlockedContentIds.contains(contentId);
  }

  /// 添加經驗並返回新狀態
  PlayerCareer addExperience(int amount) {
    final newExp = experience + amount;
    final oldLevel = level;
    final newLevel = ParliamentLevel.fromExp(newExp);
    
    // 檢查是否升級並解鎖新內容
    List<String> newUnlocks = List.from(unlockedContentIds);
    if (newLevel.level > oldLevel.level) {
      // 解鎖新等級獎勵
      final unlockedContent = UnlockDatabase.getUnlocksForLevel(newLevel);
      for (final content in unlockedContent) {
        if (!newUnlocks.contains(content.id)) {
          newUnlocks.add(content.id);
        }
      }
    }
    
    return copyWith(
      experience: newExp,
      unlockedContentIds: newUnlocks,
    );
  }

  /// 記錄遊戲結果
  PlayerCareer recordGameResult(GameResultData result) {
    final expGained = result.calculateTotalExp();
    
    return copyWith(
      totalGames: totalGames + 1,
      victories: result.factionVictory ? victories + 1 : victories,
      mvpCount: result.isMvp ? mvpCount + 1 : mvpCount,
      lastPlayedAt: DateTime.now(),
    ).addExperience(expGained);
  }

  PlayerCareer copyWith({
    String? playerId,
    String? nickname,
    int? experience,
    int? totalGames,
    int? victories,
    int? mvpCount,
    List<String>? unlockedContentIds,
    String? equippedAvatarFrameId,
    String? equippedTitleId,
    String? equippedSkinId,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
  }) {
    return PlayerCareer(
      playerId: playerId ?? this.playerId,
      nickname: nickname ?? this.nickname,
      experience: experience ?? this.experience,
      totalGames: totalGames ?? this.totalGames,
      victories: victories ?? this.victories,
      mvpCount: mvpCount ?? this.mvpCount,
      unlockedContentIds: unlockedContentIds ?? this.unlockedContentIds,
      equippedAvatarFrameId: equippedAvatarFrameId ?? this.equippedAvatarFrameId,
      equippedTitleId: equippedTitleId ?? this.equippedTitleId,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'nickname': nickname,
    'experience': experience,
    'totalGames': totalGames,
    'victories': victories,
    'mvpCount': mvpCount,
    'unlockedContentIds': unlockedContentIds,
    'equippedAvatarFrameId': equippedAvatarFrameId,
    'equippedTitleId': equippedTitleId,
    'equippedSkinId': equippedSkinId,
    'createdAt': createdAt.toIso8601String(),
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
  };

  factory PlayerCareer.fromJson(Map<String, dynamic> json) => PlayerCareer(
    playerId: json['playerId'] as String,
    nickname: json['nickname'] as String,
    experience: json['experience'] as int? ?? 0,
    totalGames: json['totalGames'] as int? ?? 0,
    victories: json['victories'] as int? ?? 0,
    mvpCount: json['mvpCount'] as int? ?? 0,
    unlockedContentIds: (json['unlockedContentIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    equippedAvatarFrameId: json['equippedAvatarFrameId'] as String?,
    equippedTitleId: json['equippedTitleId'] as String?,
    equippedSkinId: json['equippedSkinId'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    lastPlayedAt: json['lastPlayedAt'] != null
        ? DateTime.parse(json['lastPlayedAt'] as String)
        : null,
  );

  /// 創建新玩家生涯
  factory PlayerCareer.create({
    required String playerId,
    required String nickname,
  }) {
    return PlayerCareer(
      playerId: playerId,
      nickname: nickname,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PlayerCareer(playerId: $playerId, level: ${level.title}, exp: $experience)';
  }
}

/// 用於 const 構造函數的默認 DateTime
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

/// 解鎖內容資料庫
class UnlockDatabase {
  static const List<UnlockContent> _allContent = [
    // 等級 2 解鎖
    UnlockContent(
      id: 'char_radical_leader',
      type: UnlockType.character,
      name: '激進派領袖',
      description: '改革派的狂熱支持者',
      requiredLevel: ParliamentLevel.junior,
    ),
    
    // 等級 3 解鎖
    UnlockContent(
      id: 'frame_parliament',
      type: UnlockType.avatarFrame,
      name: '議會徽章',
      description: '象徵議員身份的金色邊框',
      requiredLevel: ParliamentLevel.senior,
    ),
    
    // 等級 4 解鎖
    UnlockContent(
      id: 'char_spy_master',
      type: UnlockType.character,
      name: '情報頭子',
      description: '掌握暗中情報的神秘人物',
      requiredLevel: ParliamentLevel.frontBench,
    ),
    UnlockContent(
      id: 'char_royal_advisor',
      type: UnlockType.character,
      name: '王室顧問',
      description: '與王室有密切關係的重臣',
      requiredLevel: ParliamentLevel.frontBench,
    ),
    
    // 等級 5 解鎖
    UnlockContent(
      id: 'title_honorable',
      type: UnlockType.title,
      name: '尊敬的',
      description: '議員的尊稱',
      requiredLevel: ParliamentLevel.cabinet,
    ),
    UnlockContent(
      id: 'title_right_honorable',
      type: UnlockType.title,
      name: '極尊敬的',
      description: '內閣成員的尊稱',
      requiredLevel: ParliamentLevel.cabinet,
    ),
    
    // 等級 6 解鎖
    UnlockContent(
      id: 'skin_golden_robe',
      type: UnlockType.skin,
      name: '金袍議員',
      description: '華麗的金色議員袍',
      requiredLevel: ParliamentLevel.primeCandidate,
    ),
    
    // 等級 7 解鎖（全部內容）
    UnlockContent(
      id: 'all_content',
      type: UnlockType.all,
      name: '議會之主',
      description: '解鎖全部遊戲內容',
      requiredLevel: ParliamentLevel.primeMinister,
    ),
  ];

  /// 獲取所有可解鎖內容
  static List<UnlockContent> get allContent => _allContent;

  /// 獲取指定等級解鎖的內容
  static List<UnlockContent> getUnlocksForLevel(ParliamentLevel level) {
    return _allContent.where((c) => c.requiredLevel == level).toList();
  }

  /// 獲取指定類型的所有內容
  static List<UnlockContent> getContentByType(UnlockType type) {
    return _allContent.where((c) => c.type == type).toList();
  }

  /// 根據 ID 獲取內容
  static UnlockContent? getContentById(String id) {
    try {
      return _allContent.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
