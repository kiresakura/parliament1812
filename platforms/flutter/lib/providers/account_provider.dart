import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/account_service.dart';
import '../domain/models/user_account.dart';
import '../domain/models/user_stats.dart';
import '../domain/models/user_currency.dart';
import '../domain/models/user_settings.dart';
import '../domain/models/skin.dart';
import 'auth_provider.dart';

/// 帳號資料載入狀態
enum AccountDataStatus {
  initial,
  loading,
  loaded,
  error,
}

/// 帳號完整狀態
class AccountState {
  /// 載入狀態
  final AccountDataStatus status;

  /// 用戶帳號
  final UserAccount? user;

  /// 用戶統計
  final UserStats? stats;

  /// 用戶貨幣
  final UserCurrency? currency;

  /// 用戶設定
  final UserSettings? settings;

  /// 用戶擁有的皮膚
  final List<OwnedSkin> ownedSkins;

  /// 當前裝備的皮膚
  final Map<String, String> equippedSkins; // characterId -> skinId

  /// 錯誤訊息
  final String? errorMessage;

  const AccountState({
    this.status = AccountDataStatus.initial,
    this.user,
    this.stats,
    this.currency,
    this.settings,
    this.ownedSkins = const [],
    this.equippedSkins = const {},
    this.errorMessage,
  });

  bool get isLoading => status == AccountDataStatus.loading;
  bool get isLoaded => status == AccountDataStatus.loaded;
  bool get hasError => status == AccountDataStatus.error;

  AccountState copyWith({
    AccountDataStatus? status,
    UserAccount? user,
    UserStats? stats,
    UserCurrency? currency,
    UserSettings? settings,
    List<OwnedSkin>? ownedSkins,
    Map<String, String>? equippedSkins,
    String? errorMessage,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: user ?? this.user,
      stats: stats ?? this.stats,
      currency: currency ?? this.currency,
      settings: settings ?? this.settings,
      ownedSkins: ownedSkins ?? this.ownedSkins,
      equippedSkins: equippedSkins ?? this.equippedSkins,
      errorMessage: errorMessage,
    );
  }

  factory AccountState.loading() {
    return const AccountState(status: AccountDataStatus.loading);
  }

  factory AccountState.loaded({
    required UserAccount user,
    required UserStats stats,
    required UserCurrency currency,
    required UserSettings settings,
    required List<OwnedSkin> ownedSkins,
    required Map<String, String> equippedSkins,
  }) {
    return AccountState(
      status: AccountDataStatus.loaded,
      user: user,
      stats: stats,
      currency: currency,
      settings: settings,
      ownedSkins: ownedSkins,
      equippedSkins: equippedSkins,
    );
  }

  factory AccountState.error(String message) {
    return AccountState(
      status: AccountDataStatus.error,
      errorMessage: message,
    );
  }
}

/// 帳號管理 Provider
class AccountNotifier extends StateNotifier<AccountState> {
  final AccountService _accountService;
  final Ref _ref;

  AccountNotifier(this._accountService, this._ref) : super(const AccountState());

  /// 載入帳號資料
  Future<void> loadAccountData() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      debugPrint('AccountNotifier: 用戶未登入');
      return;
    }

    final userId = authState.user!.odUserId;
    debugPrint('AccountNotifier: 載入帳號資料 - $userId');
    state = AccountState.loading();

    try {
      final results = await Future.wait([
        _accountService.getUserStats(userId),
        _accountService.getUserCurrency(userId),
        _accountService.getUserSettings(userId),
        _accountService.getOwnedSkins(userId),
        _accountService.getEquippedSkins(userId),
      ]);

      state = AccountState.loaded(
        user: authState.user!,
        stats: results[0] as UserStats,
        currency: results[1] as UserCurrency,
        settings: results[2] as UserSettings,
        ownedSkins: results[3] as List<OwnedSkin>,
        equippedSkins: results[4] as Map<String, String>,
      );

      debugPrint('AccountNotifier: 帳號資料載入完成');
    } catch (e) {
      debugPrint('AccountNotifier: 載入失敗 - $e');
      state = AccountState.error(e.toString());
    }
  }

  /// 更新用戶資料
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (state.user == null) return false;

    try {
      final result = await _ref.read(authProvider.notifier).updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (result) {
        // 重新載入資料
        await loadAccountData();
      }
      return result;
    } catch (e) {
      debugPrint('AccountNotifier: 更新資料失敗 - $e');
      return false;
    }
  }

  /// 更新用戶設定
  Future<bool> updateSettings(UserSettings newSettings) async {
    if (state.user == null) return false;

    try {
      await _accountService.updateUserSettings(state.user!.odUserId, newSettings);
      state = state.copyWith(settings: newSettings);
      debugPrint('AccountNotifier: 設定已更新');
      return true;
    } catch (e) {
      debugPrint('AccountNotifier: 更新設定失敗 - $e');
      return false;
    }
  }

  /// 領取每日獎勵
  Future<bool> claimDailyReward() async {
    if (state.currency == null || !state.currency!.dailyRewardState.canClaimToday) {
      return false;
    }

    try {
      final result = await _accountService.claimDailyReward(state.user!.odUserId);
      if (result != null) {
        state = state.copyWith(currency: result);
        debugPrint('AccountNotifier: 每日獎勵已領取');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AccountNotifier: 領取每日獎勵失敗 - $e');
      return false;
    }
  }

  /// 消費貨幣
  Future<bool> spendCurrency({
    required CurrencyType type,
    required int amount,
    required TransactionType transactionType,
    String? relatedItemId,
  }) async {
    if (state.currency == null || !state.currency!.canAfford(type, amount)) {
      return false;
    }

    try {
      final result = await _accountService.spendCurrency(
        userId: state.user!.odUserId,
        type: type,
        amount: amount,
        transactionType: transactionType,
        relatedItemId: relatedItemId,
      );

      if (result != null) {
        state = state.copyWith(currency: result);
        debugPrint('AccountNotifier: 消費成功 - $amount ${type.displayName}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AccountNotifier: 消費失敗 - $e');
      return false;
    }
  }

  /// 購買皮膚
  Future<bool> purchaseSkin(Skin skin, CurrencyType paymentType) async {
    if (state.currency == null) return false;

    final config = SkinRarityConfig.configs[skin.rarity]!;
    final price = paymentType == CurrencyType.gold
        ? config.goldPrice
        : config.silverPrice;

    if (price <= 0 || !state.currency!.canAfford(paymentType, price)) {
      return false;
    }

    // 檢查是否已擁有
    if (state.ownedSkins.any((s) => s.skin.id == skin.id)) {
      debugPrint('AccountNotifier: 已擁有此皮膚');
      return false;
    }

    try {
      final success = await spendCurrency(
        type: paymentType,
        amount: price,
        transactionType: TransactionType.shopSpend,
        relatedItemId: skin.id,
      );

      if (success) {
        // 加入擁有的皮膚
        final newOwnedSkin = OwnedSkin(
          skin: skin,
          obtainedAt: DateTime.now(),
          obtainMethod: ObtainMethod.shop,
        );
        state = state.copyWith(
          ownedSkins: [...state.ownedSkins, newOwnedSkin],
        );
        debugPrint('AccountNotifier: 皮膚購買成功 - ${skin.name}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AccountNotifier: 購買皮膚失敗 - $e');
      return false;
    }
  }

  /// 裝備皮膚
  Future<bool> equipSkin(String characterId, String skinId) async {
    // 檢查是否擁有此皮膚
    if (!state.ownedSkins.any((s) => s.skin.id == skinId)) {
      debugPrint('AccountNotifier: 未擁有此皮膚');
      return false;
    }

    try {
      await _accountService.equipSkin(
        state.user!.odUserId,
        characterId,
        skinId,
      );

      final newEquipped = Map<String, String>.from(state.equippedSkins);
      newEquipped[characterId] = skinId;
      state = state.copyWith(equippedSkins: newEquipped);

      debugPrint('AccountNotifier: 皮膚已裝備 - $skinId');
      return true;
    } catch (e) {
      debugPrint('AccountNotifier: 裝備皮膚失敗 - $e');
      return false;
    }
  }

  /// 記錄遊戲結果
  Future<void> recordGameResult({
    required String mode, // 'solo', 'multiplayer', 'ranked'
    required bool won,
    required int score,
    required String characterId,
    required int playTimeMinutes,
    required int experienceGained,
  }) async {
    if (state.stats == null) return;

    try {
      // 更新本地統計
      var newStats = state.stats!;

      // 更新對應模式統計
      switch (mode) {
        case 'solo':
          newStats = newStats.copyWith(
            soloStats: newStats.soloStats.recordGame(won: won, score: score),
          );
          break;
        case 'multiplayer':
          newStats = newStats.copyWith(
            multiplayerStats:
                newStats.multiplayerStats.recordGame(won: won, score: score),
          );
          break;
        case 'ranked':
          newStats = newStats.copyWith(
            rankedStats: newStats.rankedStats.recordGame(won: won, score: score),
          );
          break;
      }

      // 更新角色統計
      final characterStat = newStats.characterStats[characterId] ??
          CharacterStats(characterId: characterId);
      final updatedCharacterStats =
          Map<String, CharacterStats>.from(newStats.characterStats);
      updatedCharacterStats[characterId] = characterStat.recordGame(won: won);

      // 更新總體統計
      newStats = newStats.copyWith(
        characterStats: updatedCharacterStats,
        totalPlayTimeMinutes: newStats.totalPlayTimeMinutes + playTimeMinutes,
        lastPlayedAt: DateTime.now(),
      );

      // 增加經驗值
      newStats = newStats.addExperience(experienceGained);

      state = state.copyWith(stats: newStats);

      // 同步到後端
      await _accountService.updateUserStats(state.user!.odUserId, newStats);

      debugPrint('AccountNotifier: 遊戲結果已記錄');
    } catch (e) {
      debugPrint('AccountNotifier: 記錄遊戲結果失敗 - $e');
    }
  }

  /// 清除帳號資料（登出時調用）
  void clearAccountData() {
    state = const AccountState();
    debugPrint('AccountNotifier: 帳號資料已清除');
  }
}

// ===== Riverpod Providers =====

/// AccountService Provider
final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService();
});

/// AccountNotifier Provider
final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final accountService = ref.watch(accountServiceProvider);
  return AccountNotifier(accountService, ref);
});

/// 用戶統計 Provider
final userStatsProvider = Provider<UserStats?>((ref) {
  return ref.watch(accountProvider).stats;
});

/// 用戶貨幣 Provider
final userCurrencyProvider = Provider<UserCurrency?>((ref) {
  return ref.watch(accountProvider).currency;
});

/// 用戶設定 Provider
final userSettingsProvider = Provider<UserSettings?>((ref) {
  return ref.watch(accountProvider).settings;
});

/// 用戶擁有的皮膚 Provider
final ownedSkinsProvider = Provider<List<OwnedSkin>>((ref) {
  return ref.watch(accountProvider).ownedSkins;
});

/// 裝備的皮膚 Provider
final equippedSkinsProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(accountProvider).equippedSkins;
});

/// 金幣餘額 Provider
final goldBalanceProvider = Provider<int>((ref) {
  return ref.watch(accountProvider).currency?.gold ?? 0;
});

/// 銀幣餘額 Provider
final silverBalanceProvider = Provider<int>((ref) {
  return ref.watch(accountProvider).currency?.silver ?? 0;
});

/// 碎片餘額 Provider
final shardsBalanceProvider = Provider<int>((ref) {
  return ref.watch(accountProvider).currency?.shards ?? 0;
});

/// 用戶等級 Provider
final userLevelProvider = Provider<int>((ref) {
  return ref.watch(accountProvider).stats?.level ?? 1;
});

/// 排位段位 Provider
final rankInfoProvider = Provider<RankInfo?>((ref) {
  return ref.watch(accountProvider).stats?.rankInfo;
});

/// 可領取每日獎勵 Provider
final canClaimDailyRewardProvider = Provider<bool>((ref) {
  return ref.watch(accountProvider).currency?.dailyRewardState.canClaimToday ??
      false;
});
