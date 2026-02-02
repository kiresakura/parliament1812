// 1812 國會風雲 - 用戶貨幣系統模型
//
// 管理遊戲內貨幣：金基尼（付費）與銀先令（免費）

/// 貨幣類型
enum CurrencyType {
  /// 金基尼（Guinea） - 付費貨幣
  gold,

  /// 銀先令（Shilling） - 免費貨幣
  silver,

  /// 皮膚碎片 - 分解皮膚獲得
  shards,
}

/// 貨幣配置
extension CurrencyConfig on CurrencyType {
  String get displayName {
    switch (this) {
      case CurrencyType.gold:
        return '金基尼';
      case CurrencyType.silver:
        return '銀先令';
      case CurrencyType.shards:
        return '皮膚碎片';
    }
  }

  String get shortName {
    switch (this) {
      case CurrencyType.gold:
        return '金';
      case CurrencyType.silver:
        return '銀';
      case CurrencyType.shards:
        return '碎';
    }
  }

  String get iconPath => 'assets/images/currency/${name}.png';

  int get colorCode {
    switch (this) {
      case CurrencyType.gold:
        return 0xFFFFD700;  // 金色
      case CurrencyType.silver:
        return 0xFFC0C0C0;  // 銀色
      case CurrencyType.shards:
        return 0xFF9370DB;  // 紫色
    }
  }

  /// 每日免費獲取上限
  int get dailyFreeLimit {
    switch (this) {
      case CurrencyType.gold:
        return 0;  // 金幣無法免費獲得
      case CurrencyType.silver:
        return 500;
      case CurrencyType.shards:
        return 0;
    }
  }
}

/// 貨幣交易類型
enum TransactionType {
  /// 購買
  purchase,

  /// 遊戲獎勵
  gameReward,

  /// 每日獎勵
  dailyReward,

  /// 成就獎勵
  achievementReward,

  /// Battle Pass 獎勵
  battlePassReward,

  /// 活動獎勵
  eventReward,

  /// 商店購買（消費）
  shopSpend,

  /// 抽獎消費
  gachaSpend,

  /// 皮膚分解
  skinDismantle,

  /// 皮膚合成
  skinCraft,

  /// 退款
  refund,

  /// 系統調整
  systemAdjust,
}

/// 交易記錄
class CurrencyTransaction {
  /// 交易 ID
  final String transactionId;

  /// 貨幣類型
  final CurrencyType currencyType;

  /// 金額（正為收入，負為支出）
  final int amount;

  /// 交易類型
  final TransactionType type;

  /// 交易前餘額
  final int balanceBefore;

  /// 交易後餘額
  final int balanceAfter;

  /// 交易時間
  final DateTime createdAt;

  /// 相關物品 ID（如購買的皮膚 ID）
  final String? relatedItemId;

  /// 交易描述
  final String? description;

  /// 是否為收入
  bool get isIncome => amount > 0;

  const CurrencyTransaction({
    required this.transactionId,
    required this.currencyType,
    required this.amount,
    required this.type,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    this.relatedItemId,
    this.description,
  });

  factory CurrencyTransaction.fromJson(Map<String, dynamic> json) {
    return CurrencyTransaction(
      transactionId: json['transaction_id'] as String,
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == json['currency_type'],
        orElse: () => CurrencyType.silver,
      ),
      amount: json['amount'] as int,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.systemAdjust,
      ),
      balanceBefore: json['balance_before'] as int,
      balanceAfter: json['balance_after'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedItemId: json['related_item_id'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'currency_type': currencyType.name,
      'amount': amount,
      'type': type.name,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'created_at': createdAt.toIso8601String(),
      'related_item_id': relatedItemId,
      'description': description,
    };
  }
}

/// 每日獎勵狀態
class DailyRewardState {
  /// 已連續簽到天數
  final int consecutiveDays;

  /// 本週期內已領取天數（7 天一週期）
  final int currentCycleDays;

  /// 今日是否已領取
  final bool todayClaimed;

  /// 最後領取時間
  final DateTime? lastClaimedAt;

  /// 下次重置時間
  final DateTime nextResetAt;

  /// 是否可以領取今日獎勵
  bool get canClaimToday => !todayClaimed;

  const DailyRewardState({
    this.consecutiveDays = 0,
    this.currentCycleDays = 0,
    this.todayClaimed = false,
    this.lastClaimedAt,
    required this.nextResetAt,
  });

  DailyRewardState copyWith({
    int? consecutiveDays,
    int? currentCycleDays,
    bool? todayClaimed,
    DateTime? lastClaimedAt,
    DateTime? nextResetAt,
  }) {
    return DailyRewardState(
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      currentCycleDays: currentCycleDays ?? this.currentCycleDays,
      todayClaimed: todayClaimed ?? this.todayClaimed,
      lastClaimedAt: lastClaimedAt ?? this.lastClaimedAt,
      nextResetAt: nextResetAt ?? this.nextResetAt,
    );
  }

  factory DailyRewardState.fromJson(Map<String, dynamic> json) {
    return DailyRewardState(
      consecutiveDays: json['consecutive_days'] as int? ?? 0,
      currentCycleDays: json['current_cycle_days'] as int? ?? 0,
      todayClaimed: json['today_claimed'] as bool? ?? false,
      lastClaimedAt: json['last_claimed_at'] != null
          ? DateTime.parse(json['last_claimed_at'] as String)
          : null,
      nextResetAt: json['next_reset_at'] != null
          ? DateTime.parse(json['next_reset_at'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consecutive_days': consecutiveDays,
      'current_cycle_days': currentCycleDays,
      'today_claimed': todayClaimed,
      'last_claimed_at': lastClaimedAt?.toIso8601String(),
      'next_reset_at': nextResetAt.toIso8601String(),
    };
  }
}

/// 每日獎勵內容
class DailyReward {
  /// 第幾天
  final int day;

  /// 銀先令數量
  final int silverAmount;

  /// 金基尼數量（通常第 7 天送）
  final int goldAmount;

  /// 額外獎勵（如皮膚碎片）
  final int shardsAmount;

  /// 是否為特殊獎勵日（第 7 天）
  bool get isSpecialDay => day == 7;

  const DailyReward({
    required this.day,
    this.silverAmount = 0,
    this.goldAmount = 0,
    this.shardsAmount = 0,
  });

  /// 7 天簽到獎勵配置
  static const List<DailyReward> weeklyRewards = [
    DailyReward(day: 1, silverAmount: 50),
    DailyReward(day: 2, silverAmount: 75),
    DailyReward(day: 3, silverAmount: 100),
    DailyReward(day: 4, silverAmount: 100, shardsAmount: 5),
    DailyReward(day: 5, silverAmount: 150),
    DailyReward(day: 6, silverAmount: 150, shardsAmount: 10),
    DailyReward(day: 7, silverAmount: 200, goldAmount: 10, shardsAmount: 20),
  ];

  static DailyReward getRewardForDay(int day) {
    final index = (day - 1) % 7;
    return weeklyRewards[index];
  }
}

/// 用戶貨幣錢包
class UserCurrency {
  /// 用戶 ID
  final String userId;

  /// 金基尼餘額
  final int gold;

  /// 銀先令餘額
  final int silver;

  /// 皮膚碎片餘額
  final int shards;

  /// 累計金基尼（用於 VIP 計算）
  final int totalGoldEarned;

  /// 累計銀先令
  final int totalSilverEarned;

  /// 今日已獲得銀先令
  final int todaySilverEarned;

  /// 每日獎勵狀態
  final DailyRewardState dailyRewardState;

  /// 最近交易記錄
  final List<CurrencyTransaction> recentTransactions;

  /// 今日銀先令是否已達上限
  bool get isSilverDailyLimitReached =>
      todaySilverEarned >= CurrencyType.silver.dailyFreeLimit;

  const UserCurrency({
    required this.userId,
    this.gold = 0,
    this.silver = 100,  // 新手送 100 銀先令
    this.shards = 0,
    this.totalGoldEarned = 0,
    this.totalSilverEarned = 0,
    this.todaySilverEarned = 0,
    required this.dailyRewardState,
    this.recentTransactions = const [],
  });

  UserCurrency copyWith({
    int? gold,
    int? silver,
    int? shards,
    int? totalGoldEarned,
    int? totalSilverEarned,
    int? todaySilverEarned,
    DailyRewardState? dailyRewardState,
    List<CurrencyTransaction>? recentTransactions,
  }) {
    return UserCurrency(
      userId: userId,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      shards: shards ?? this.shards,
      totalGoldEarned: totalGoldEarned ?? this.totalGoldEarned,
      totalSilverEarned: totalSilverEarned ?? this.totalSilverEarned,
      todaySilverEarned: todaySilverEarned ?? this.todaySilverEarned,
      dailyRewardState: dailyRewardState ?? this.dailyRewardState,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }

  /// 取得特定貨幣餘額
  int getBalance(CurrencyType type) {
    switch (type) {
      case CurrencyType.gold:
        return gold;
      case CurrencyType.silver:
        return silver;
      case CurrencyType.shards:
        return shards;
    }
  }

  /// 是否能負擔指定消費
  bool canAfford(CurrencyType type, int amount) {
    return getBalance(type) >= amount;
  }

  factory UserCurrency.fromJson(Map<String, dynamic> json) {
    return UserCurrency(
      userId: json['user_id'] as String,
      gold: json['gold'] as int? ?? 0,
      silver: json['silver'] as int? ?? 100,
      shards: json['shards'] as int? ?? 0,
      totalGoldEarned: json['total_gold_earned'] as int? ?? 0,
      totalSilverEarned: json['total_silver_earned'] as int? ?? 0,
      todaySilverEarned: json['today_silver_earned'] as int? ?? 0,
      dailyRewardState: json['daily_reward_state'] != null
          ? DailyRewardState.fromJson(
              json['daily_reward_state'] as Map<String, dynamic>)
          : DailyRewardState(
              nextResetAt: DateTime.now().add(const Duration(hours: 24)),
            ),
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((e) =>
                  CurrencyTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'gold': gold,
      'silver': silver,
      'shards': shards,
      'total_gold_earned': totalGoldEarned,
      'total_silver_earned': totalSilverEarned,
      'today_silver_earned': todaySilverEarned,
      'daily_reward_state': dailyRewardState.toJson(),
      'recent_transactions':
          recentTransactions.map((t) => t.toJson()).toList(),
    };
  }

  factory UserCurrency.initial(String userId) {
    return UserCurrency(
      userId: userId,
      dailyRewardState: DailyRewardState(
        nextResetAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    );
  }

  @override
  String toString() {
    return 'UserCurrency(userId: $userId, gold: $gold, silver: $silver, shards: $shards)';
  }
}
