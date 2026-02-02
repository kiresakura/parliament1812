// 1812 國會風雲 - 用戶統計數據模型
//
// 追蹤玩家遊戲表現與進度

import 'dart:math' as math;

/// 遊戲模式統計
class ModeStats {
  /// 遊玩場數
  final int gamesPlayed;

  /// 勝利場數
  final int gamesWon;

  /// 最高連勝
  final int maxWinStreak;

  /// 當前連勝
  final int currentWinStreak;

  /// 最高得分（單場）
  final int highestScore;

  /// 總得分
  final int totalScore;

  /// 平均得分
  double get averageScore =>
      gamesPlayed > 0 ? totalScore / gamesPlayed : 0.0;

  /// 勝率
  double get winRate =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;

  const ModeStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.maxWinStreak = 0,
    this.currentWinStreak = 0,
    this.highestScore = 0,
    this.totalScore = 0,
  });

  ModeStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? maxWinStreak,
    int? currentWinStreak,
    int? highestScore,
    int? totalScore,
  }) {
    return ModeStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      maxWinStreak: maxWinStreak ?? this.maxWinStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestScore: highestScore ?? this.highestScore,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  /// 記錄一場遊戲
  ModeStats recordGame({required bool won, required int score}) {
    final newWinStreak = won ? currentWinStreak + 1 : 0;
    return copyWith(
      gamesPlayed: gamesPlayed + 1,
      gamesWon: won ? gamesWon + 1 : gamesWon,
      currentWinStreak: newWinStreak,
      maxWinStreak: newWinStreak > maxWinStreak ? newWinStreak : maxWinStreak,
      highestScore: score > highestScore ? score : highestScore,
      totalScore: totalScore + score,
    );
  }

  factory ModeStats.fromJson(Map<String, dynamic> json) {
    return ModeStats(
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      maxWinStreak: json['max_win_streak'] as int? ?? 0,
      currentWinStreak: json['current_win_streak'] as int? ?? 0,
      highestScore: json['highest_score'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'max_win_streak': maxWinStreak,
      'current_win_streak': currentWinStreak,
      'highest_score': highestScore,
      'total_score': totalScore,
    };
  }
}

/// 角色使用統計
class CharacterStats {
  /// 角色 ID
  final String characterId;

  /// 使用次數
  final int timesPlayed;

  /// 勝利次數
  final int timesWon;

  /// 勝率
  double get winRate =>
      timesPlayed > 0 ? (timesWon / timesPlayed) * 100 : 0.0;

  const CharacterStats({
    required this.characterId,
    this.timesPlayed = 0,
    this.timesWon = 0,
  });

  CharacterStats recordGame({required bool won}) {
    return CharacterStats(
      characterId: characterId,
      timesPlayed: timesPlayed + 1,
      timesWon: won ? timesWon + 1 : timesWon,
    );
  }

  factory CharacterStats.fromJson(Map<String, dynamic> json) {
    return CharacterStats(
      characterId: json['character_id'] as String,
      timesPlayed: json['times_played'] as int? ?? 0,
      timesWon: json['times_won'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character_id': characterId,
      'times_played': timesPlayed,
      'times_won': timesWon,
    };
  }
}

/// 排位段位
enum RankTier {
  unranked,       // 未定級
  bronze,         // 黃銅
  silver,         // 白銀
  gold,           // 黃金
  platinum,       // 白金
  diamond,        // 鑽石
  master,         // 大師
  grandMaster,    // 宗師
}

/// 排位段位配置
extension RankTierConfig on RankTier {
  String get displayName {
    switch (this) {
      case RankTier.unranked:
        return '未定級';
      case RankTier.bronze:
        return '黃銅';
      case RankTier.silver:
        return '白銀';
      case RankTier.gold:
        return '黃金';
      case RankTier.platinum:
        return '白金';
      case RankTier.diamond:
        return '鑽石';
      case RankTier.master:
        return '大師';
      case RankTier.grandMaster:
        return '宗師';
    }
  }

  String get iconPath => 'assets/images/ranks/${name}.png';

  int get colorCode {
    switch (this) {
      case RankTier.unranked:
        return 0xFF808080;
      case RankTier.bronze:
        return 0xFFCD7F32;
      case RankTier.silver:
        return 0xFFC0C0C0;
      case RankTier.gold:
        return 0xFFFFD700;
      case RankTier.platinum:
        return 0xFF00CED1;
      case RankTier.diamond:
        return 0xFF00BFFF;
      case RankTier.master:
        return 0xFF9932CC;
      case RankTier.grandMaster:
        return 0xFFFF4500;
    }
  }

  /// 晉級所需積分
  int get requiredPoints {
    switch (this) {
      case RankTier.unranked:
        return 0;
      case RankTier.bronze:
        return 100;
      case RankTier.silver:
        return 300;
      case RankTier.gold:
        return 600;
      case RankTier.platinum:
        return 1000;
      case RankTier.diamond:
        return 1500;
      case RankTier.master:
        return 2200;
      case RankTier.grandMaster:
        return 3000;
    }
  }
}

/// 排位資訊
class RankInfo {
  /// 當前段位
  final RankTier tier;

  /// 當前段位內的級數（1-5，5最高）
  final int division;

  /// 當前積分
  final int points;

  /// 本賽季最高段位
  final RankTier peakTier;

  /// 本賽季最高級數
  final int peakDivision;

  /// 賽季場次
  final int seasonGames;

  /// 賽季勝場
  final int seasonWins;

  /// 賽季勝率
  double get seasonWinRate =>
      seasonGames > 0 ? (seasonWins / seasonGames) * 100 : 0.0;

  const RankInfo({
    this.tier = RankTier.unranked,
    this.division = 5,
    this.points = 0,
    this.peakTier = RankTier.unranked,
    this.peakDivision = 5,
    this.seasonGames = 0,
    this.seasonWins = 0,
  });

  RankInfo copyWith({
    RankTier? tier,
    int? division,
    int? points,
    RankTier? peakTier,
    int? peakDivision,
    int? seasonGames,
    int? seasonWins,
  }) {
    return RankInfo(
      tier: tier ?? this.tier,
      division: division ?? this.division,
      points: points ?? this.points,
      peakTier: peakTier ?? this.peakTier,
      peakDivision: peakDivision ?? this.peakDivision,
      seasonGames: seasonGames ?? this.seasonGames,
      seasonWins: seasonWins ?? this.seasonWins,
    );
  }

  factory RankInfo.fromJson(Map<String, dynamic> json) {
    return RankInfo(
      tier: RankTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => RankTier.unranked,
      ),
      division: json['division'] as int? ?? 5,
      points: json['points'] as int? ?? 0,
      peakTier: RankTier.values.firstWhere(
        (e) => e.name == json['peak_tier'],
        orElse: () => RankTier.unranked,
      ),
      peakDivision: json['peak_division'] as int? ?? 5,
      seasonGames: json['season_games'] as int? ?? 0,
      seasonWins: json['season_wins'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'division': division,
      'points': points,
      'peak_tier': peakTier.name,
      'peak_division': peakDivision,
      'season_games': seasonGames,
      'season_wins': seasonWins,
    };
  }

  /// 顯示的完整段位名稱
  String get displayName => tier == RankTier.unranked
      ? tier.displayName
      : '${tier.displayName} $division';
}

/// 成就進度
class AchievementProgress {
  /// 成就 ID
  final String achievementId;

  /// 當前進度
  final int currentProgress;

  /// 目標值
  final int targetValue;

  /// 是否已完成
  final bool isCompleted;

  /// 完成時間
  final DateTime? completedAt;

  /// 是否已領取獎勵
  final bool isRewardClaimed;

  /// 進度百分比
  double get progressPercent =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  const AchievementProgress({
    required this.achievementId,
    this.currentProgress = 0,
    required this.targetValue,
    this.isCompleted = false,
    this.completedAt,
    this.isRewardClaimed = false,
  });

  AchievementProgress copyWith({
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isRewardClaimed,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetValue: targetValue,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievement_id'] as String,
      currentProgress: json['current_progress'] as int? ?? 0,
      targetValue: json['target_value'] as int? ?? 1,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isRewardClaimed: json['is_reward_claimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'current_progress': currentProgress,
      'target_value': targetValue,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'is_reward_claimed': isRewardClaimed,
    };
  }
}

/// 用戶統計數據
class UserStats {
  /// 用戶 ID
  final String userId;

  /// 帳號等級
  final int level;

  /// 當前經驗值
  final int experience;

  /// 升級所需經驗值
  final int experienceToNextLevel;

  /// 總遊戲時長（分鐘）
  final int totalPlayTimeMinutes;

  /// 單人模式統計
  final ModeStats soloStats;

  /// 多人模式統計
  final ModeStats multiplayerStats;

  /// 排位模式統計
  final ModeStats rankedStats;

  /// 排位資訊
  final RankInfo rankInfo;

  /// 角色使用統計
  final Map<String, CharacterStats> characterStats;

  /// 成就進度
  final List<AchievementProgress> achievements;

  /// 最後遊玩時間
  final DateTime? lastPlayedAt;

  /// 註冊時間
  final DateTime createdAt;

  /// 經驗值百分比
  double get experiencePercent => experienceToNextLevel > 0
      ? (experience / experienceToNextLevel).clamp(0.0, 1.0)
      : 0.0;

  /// 總遊戲場數
  int get totalGames =>
      soloStats.gamesPlayed +
      multiplayerStats.gamesPlayed +
      rankedStats.gamesPlayed;

  /// 總勝利場數
  int get totalWins =>
      soloStats.gamesWon + multiplayerStats.gamesWon + rankedStats.gamesWon;

  /// 總勝率
  double get totalWinRate =>
      totalGames > 0 ? (totalWins / totalGames) * 100 : 0.0;

  /// 已完成成就數量
  int get completedAchievements =>
      achievements.where((a) => a.isCompleted).length;

  /// 最愛角色（使用次數最多）
  String? get favoriteCharacter {
    if (characterStats.isEmpty) return null;
    return characterStats.entries
        .reduce((a, b) => a.value.timesPlayed > b.value.timesPlayed ? a : b)
        .key;
  }

  const UserStats({
    required this.userId,
    this.level = 1,
    this.experience = 0,
    this.experienceToNextLevel = 100,
    this.totalPlayTimeMinutes = 0,
    this.soloStats = const ModeStats(),
    this.multiplayerStats = const ModeStats(),
    this.rankedStats = const ModeStats(),
    this.rankInfo = const RankInfo(),
    this.characterStats = const {},
    this.achievements = const [],
    this.lastPlayedAt,
    required this.createdAt,
  });

  UserStats copyWith({
    int? level,
    int? experience,
    int? experienceToNextLevel,
    int? totalPlayTimeMinutes,
    ModeStats? soloStats,
    ModeStats? multiplayerStats,
    ModeStats? rankedStats,
    RankInfo? rankInfo,
    Map<String, CharacterStats>? characterStats,
    List<AchievementProgress>? achievements,
    DateTime? lastPlayedAt,
  }) {
    return UserStats(
      userId: userId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      experienceToNextLevel: experienceToNextLevel ?? this.experienceToNextLevel,
      totalPlayTimeMinutes: totalPlayTimeMinutes ?? this.totalPlayTimeMinutes,
      soloStats: soloStats ?? this.soloStats,
      multiplayerStats: multiplayerStats ?? this.multiplayerStats,
      rankedStats: rankedStats ?? this.rankedStats,
      rankInfo: rankInfo ?? this.rankInfo,
      characterStats: characterStats ?? this.characterStats,
      achievements: achievements ?? this.achievements,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt,
    );
  }

  /// 計算升級所需經驗（等級公式）
  static int calculateExpForLevel(int level) {
    // 經驗公式：100 * (level ^ 1.5)
    return (100 * math.sqrt(level.toDouble()) * level).round();
  }

  /// 增加經驗值並處理升級
  UserStats addExperience(int amount) {
    var newExp = experience + amount;
    var newLevel = level;
    var newExpToNext = experienceToNextLevel;

    // 處理升級
    while (newExp >= newExpToNext) {
      newExp -= newExpToNext;
      newLevel++;
      newExpToNext = calculateExpForLevel(newLevel);
    }

    return copyWith(
      level: newLevel,
      experience: newExp,
      experienceToNextLevel: newExpToNext,
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      experienceToNextLevel: json['experience_to_next_level'] as int? ?? 100,
      totalPlayTimeMinutes: json['total_play_time_minutes'] as int? ?? 0,
      soloStats: json['solo_stats'] != null
          ? ModeStats.fromJson(json['solo_stats'] as Map<String, dynamic>)
          : const ModeStats(),
      multiplayerStats: json['multiplayer_stats'] != null
          ? ModeStats.fromJson(json['multiplayer_stats'] as Map<String, dynamic>)
          : const ModeStats(),
      rankedStats: json['ranked_stats'] != null
          ? ModeStats.fromJson(json['ranked_stats'] as Map<String, dynamic>)
          : const ModeStats(),
      rankInfo: json['rank_info'] != null
          ? RankInfo.fromJson(json['rank_info'] as Map<String, dynamic>)
          : const RankInfo(),
      characterStats: (json['character_stats'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, CharacterStats.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) =>
                  AchievementProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'level': level,
      'experience': experience,
      'experience_to_next_level': experienceToNextLevel,
      'total_play_time_minutes': totalPlayTimeMinutes,
      'solo_stats': soloStats.toJson(),
      'multiplayer_stats': multiplayerStats.toJson(),
      'ranked_stats': rankedStats.toJson(),
      'rank_info': rankInfo.toJson(),
      'character_stats':
          characterStats.map((k, v) => MapEntry(k, v.toJson())),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserStats.initial(String userId) {
    return UserStats(
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserStats(userId: $userId, level: $level, totalGames: $totalGames, '
        'winRate: ${totalWinRate.toStringAsFixed(1)}%)';
  }
}
