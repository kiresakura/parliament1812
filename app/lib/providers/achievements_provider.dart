import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════
// 成就資料模型
// ═══════════════════════════════════════════

/// 成就定義 + 進度
class Achievement {
  final String id;
  final String name;
  final String description;
  final String difficulty; // easy / medium / hard / hidden
  final bool isHidden;
  final String iconHint;
  final int progress;
  final int target;
  final bool completed;
  final bool claimed;
  final List<AchievementReward> rewards;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.isHidden = false,
    required this.iconHint,
    this.progress = 0,
    required this.target,
    this.completed = false,
    this.claimed = false,
    this.rewards = const [],
  });

  double get progressPercent => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0;
}

/// 成就獎勵
class AchievementReward {
  final String type; // unlock_card / title / gold
  final String? cardId;
  final String? title;
  final int? amount;

  const AchievementReward({
    required this.type,
    this.cardId,
    this.title,
    this.amount,
  });

  String get displayText {
    switch (type) {
      case 'unlock_card':
        return '解鎖卡牌';
      case 'title':
        return '稱號：$title';
      case 'gold':
        return '$amount 金幣';
      default:
        return type;
    }
  }
}

/// 成就狀態
class AchievementsState {
  final List<Achievement> achievements;
  final int completedCount;
  final int totalCount;
  final int unclaimedCount;
  final bool isLoading;
  final String? error;

  const AchievementsState({
    this.achievements = const [],
    this.completedCount = 0,
    this.totalCount = 25,
    this.unclaimedCount = 0,
    this.isLoading = false,
    this.error,
  });

  AchievementsState copyWith({
    List<Achievement>? achievements,
    int? completedCount,
    int? totalCount,
    int? unclaimedCount,
    bool? isLoading,
    String? error,
  }) =>
      AchievementsState(
        achievements: achievements ?? this.achievements,
        completedCount: completedCount ?? this.completedCount,
        totalCount: totalCount ?? this.totalCount,
        unclaimedCount: unclaimedCount ?? this.unclaimedCount,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ═══════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier();
});

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier() : super(const AchievementsState(isLoading: true)) {
    _loadLocalData();
  }

  void _loadLocalData() {
    final achievements = _buildAllAchievements();
    // 模擬進度：前幾個簡單成就部分完成
    final withProgress = achievements.map((a) {
      switch (a.id) {
        case 'FIRST_MATCH':
          return Achievement(id: a.id, name: a.name, description: a.description, difficulty: a.difficulty, isHidden: a.isHidden, iconHint: a.iconHint, target: a.target, rewards: a.rewards, progress: 1, completed: true, claimed: true);
        case 'FIRST_WIN':
          return Achievement(id: a.id, name: a.name, description: a.description, difficulty: a.difficulty, isHidden: a.isHidden, iconHint: a.iconHint, target: a.target, rewards: a.rewards, progress: 1, completed: true, claimed: false);
        case 'PLAY_10':
          return Achievement(id: a.id, name: a.name, description: a.description, difficulty: a.difficulty, isHidden: a.isHidden, iconHint: a.iconHint, target: a.target, rewards: a.rewards, progress: 4);
        default:
          return a;
      }
    }).toList();

    final completed = withProgress.where((a) => a.completed).length;
    final unclaimed = withProgress.where((a) => a.completed && !a.claimed).length;

    state = AchievementsState(
      achievements: withProgress,
      completedCount: completed,
      totalCount: withProgress.length,
      unclaimedCount: unclaimed,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    _loadLocalData();
  }

  Future<bool> claimReward(String achievementId) async {
    // TODO: API call
    final updated = state.achievements.map((a) {
      if (a.id == achievementId && a.completed && !a.claimed) {
        return Achievement(
          id: a.id, name: a.name, description: a.description,
          difficulty: a.difficulty, isHidden: a.isHidden, iconHint: a.iconHint,
          target: a.target, rewards: a.rewards, progress: a.progress,
          completed: true, claimed: true,
        );
      }
      return a;
    }).toList();
    final unclaimed = updated.where((a) => a.completed && !a.claimed).length;
    state = state.copyWith(achievements: updated, unclaimedCount: unclaimed);
    return true;
  }
}

// ═══════════════════════════════════════════
// 靜態成就定義（與 Rust achievements.rs 同步）
// ═══════════════════════════════════════════

List<Achievement> _buildAllAchievements() {
  return const [
    // 🟢 簡單 (8)
    Achievement(id: 'FIRST_MATCH', name: '🏆 新手議員', description: '完成第一場對局', difficulty: 'easy', iconHint: '議會入口大門', target: 1, rewards: [AchievementReward(type: 'gold', amount: 50), AchievementReward(type: 'unlock_card', cardId: 'common_brief_speech')]),
    Achievement(id: 'FIRST_WIN', name: '🏆 初嚐勝利', description: '贏得第一場對局', difficulty: 'easy', iconHint: '勝利獎盃', target: 1, rewards: [AchievementReward(type: 'gold', amount: 100), AchievementReward(type: 'unlock_card', cardId: 'common_filibuster')]),
    Achievement(id: 'PLAY_10', name: '🏆 常客', description: '完成 10 場對局', difficulty: 'easy', iconHint: '議員座椅', target: 10, rewards: [AchievementReward(type: 'gold', amount: 200), AchievementReward(type: 'unlock_card', cardId: 'common_petition')]),
    Achievement(id: 'COLLECT_50', name: '🏆 收藏入門', description: '收集 50% 的不同卡牌（28 張）', difficulty: 'easy', iconHint: '小型卡冊', target: 28, rewards: [AchievementReward(type: 'gold', amount: 300), AchievementReward(type: 'title', title: '收藏家')]),
    Achievement(id: 'BUILD_DECK', name: '🏆 組牌新手', description: '收集 10 張不同卡牌', difficulty: 'easy', iconHint: '卡牌堆疊', target: 10, rewards: [AchievementReward(type: 'gold', amount: 100)]),
    Achievement(id: 'FIRST_IAP', name: '🏆 贊助者', description: '完成首次商店購買', difficulty: 'easy', iconHint: '金幣袋', target: 1, rewards: [AchievementReward(type: 'gold', amount: 200), AchievementReward(type: 'title', title: '贊助者')]),
    Achievement(id: 'ADD_FRIEND', name: '🏆 政治結盟', description: '首次加入多人房間', difficulty: 'easy', iconHint: '握手', target: 1, rewards: [AchievementReward(type: 'gold', amount: 50)]),
    Achievement(id: 'TUTORIAL_DONE', name: '🏆 學成出師', description: '完成新手教學', difficulty: 'easy', iconHint: '畢業帽', target: 1, rewards: [AchievementReward(type: 'gold', amount: 100), AchievementReward(type: 'unlock_card', cardId: 'common_gather_intel')]),

    // 🟡 中等 (9)
    Achievement(id: 'ATTACK_STREAK_5', name: '🏆 辯論達人', description: '一場對局中連續出 5 張攻擊牌', difficulty: 'medium', iconHint: '火焰麥克風', target: 5, rewards: [AchievementReward(type: 'gold', amount: 200), AchievementReward(type: 'unlock_card', cardId: 'uncommon_propaganda')]),
    Achievement(id: 'WIN_50', name: '🏆 資深議員', description: '贏得 50 場對局', difficulty: 'medium', iconHint: '銀色議員徽章', target: 50, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'title', title: '資深議員'), AchievementReward(type: 'unlock_card', cardId: 'rare_blockade')]),
    Achievement(id: 'GOLD_10K', name: '🏆 金主', description: '累積獲得 10,000 金幣', difficulty: 'medium', iconHint: '金幣寶箱', target: 10000, rewards: [AchievementReward(type: 'gold', amount: 1000), AchievementReward(type: 'unlock_card', cardId: 'uncommon_charity')]),
    Achievement(id: 'COLLECT_200', name: '🏆 卡牌鑑賞家', description: '收集 80% 的不同卡牌（45 張）', difficulty: 'medium', iconHint: '大型卡冊', target: 45, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'title', title: '鑑賞家')]),
    Achievement(id: 'PERFECT_VOTE', name: '🏆 民意代表', description: '在投票階段獲得全數支持', difficulty: 'medium', iconHint: '舉手投票', target: 1, rewards: [AchievementReward(type: 'gold', amount: 300), AchievementReward(type: 'unlock_card', cardId: 'uncommon_royal_favor')]),
    Achievement(id: 'WIN_STREAK_5', name: '🏆 不敗神話', description: '連勝 5 場', difficulty: 'medium', iconHint: '連續火焰', target: 5, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'unlock_card', cardId: 'rare_no_confidence')]),
    Achievement(id: 'ALL_ROLES', name: '🏆 百變議員', description: '使用所有角色各贏一場', difficulty: 'medium', iconHint: '面具集合', target: 1, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'unlock_card', cardId: 'rare_reform_act'), AchievementReward(type: 'title', title: '百變議員')]),
    Achievement(id: 'DEFENSE_MASTER', name: '🏆 鐵壁防線', description: '一場對局中成功防禦 10 次攻擊', difficulty: 'medium', iconHint: '盾牌', target: 10, rewards: [AchievementReward(type: 'gold', amount: 300), AchievementReward(type: 'unlock_card', cardId: 'rare_habeas_corpus')]),
    Achievement(id: 'COMEBACK_WIN', name: '🏆 逆轉裁決', description: '在最後一回合逆轉勝', difficulty: 'medium', iconHint: '翻轉箭頭', target: 1, rewards: [AchievementReward(type: 'gold', amount: 300)]),

    // 🔴 困難 (5)
    Achievement(id: 'WIN_100', name: '🏆 人民之聲', description: '贏得 100 場對局', difficulty: 'hard', iconHint: '金色議員徽章', target: 100, rewards: [AchievementReward(type: 'gold', amount: 1000), AchievementReward(type: 'title', title: '人民之聲'), AchievementReward(type: 'unlock_card', cardId: 'legendary_magna_carta')]),
    Achievement(id: 'WIN_STREAK_10', name: '🏆 議會霸主', description: '連勝 10 場', difficulty: 'hard', iconHint: '皇冠', target: 10, rewards: [AchievementReward(type: 'gold', amount: 1000), AchievementReward(type: 'title', title: '議會霸主')]),
    Achievement(id: 'COLLECT_ALL', name: '🏆 全卡收藏家', description: '收集所有 56 張卡牌', difficulty: 'hard', iconHint: '彩虹卡冊', target: 56, rewards: [AchievementReward(type: 'gold', amount: 2000), AchievementReward(type: 'title', title: '全卡收藏家'), AchievementReward(type: 'unlock_card', cardId: 'legendary_peterloo')]),
    Achievement(id: 'GOLD_100K', name: '🏆 財閥', description: '累積獲得 100,000 金幣', difficulty: 'hard', iconHint: '金庫', target: 100000, rewards: [AchievementReward(type: 'gold', amount: 5000), AchievementReward(type: 'title', title: '財閥')]),
    Achievement(id: 'TOP_LEADERBOARD', name: '🏆 議長', description: '登上排行榜第一名', difficulty: 'hard', iconHint: '議長木槌', target: 1, rewards: [AchievementReward(type: 'gold', amount: 2000), AchievementReward(type: 'title', title: '議長')]),

    // 🟣 隱藏 (3)
    Achievement(id: 'PACIFIST', name: '🏆 和平使者', description: '一場對局中 0 張攻擊牌通關', difficulty: 'hidden', isHidden: true, iconHint: '和平鴿', target: 1, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'unlock_card', cardId: 'uncommon_amnesty'), AchievementReward(type: 'title', title: '和平使者')]),
    Achievement(id: 'ALL_ATTACK', name: '🏆 戰爭狂人', description: '一場對局中只出攻擊牌', difficulty: 'hidden', isHidden: true, iconHint: '交叉劍', target: 1, rewards: [AchievementReward(type: 'gold', amount: 500), AchievementReward(type: 'unlock_card', cardId: 'rare_political_assassination'), AchievementReward(type: 'title', title: '戰爭狂人')]),
    Achievement(id: 'EASTER_EGG', name: '🏆 歷史學家', description: '發現遊戲中的隱藏彩蛋', difficulty: 'hidden', isHidden: true, iconHint: '放大鏡', target: 1, rewards: [AchievementReward(type: 'gold', amount: 1000), AchievementReward(type: 'title', title: '歷史學家')]),
  ];
}
