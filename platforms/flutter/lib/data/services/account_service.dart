import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/user_currency.dart';
import '../../domain/models/user_settings.dart';
import '../../domain/models/skin.dart';

/// 帳號服務 - 處理用戶資料的存取
///
/// 目前為本地儲存實作，後續可改為 API 調用
class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  // 儲存 Key 前綴
  static const _keyPrefix = 'account_';
  static const _keyStats = '${_keyPrefix}stats_';
  static const _keyCurrency = '${_keyPrefix}currency_';
  static const _keySettings = '${_keyPrefix}settings_';
  static const _keyOwnedSkins = '${_keyPrefix}owned_skins_';
  static const _keyEquippedSkins = '${_keyPrefix}equipped_skins_';

  /// 取得用戶統計
  Future<UserStats> getUserStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keyStats$userId');

      if (data != null) {
        return UserStats.fromJson(json.decode(data));
      }

      // 建立初始統計
      final initialStats = UserStats.initial(userId);
      await _saveUserStats(userId, initialStats);
      return initialStats;
    } catch (e) {
      debugPrint('AccountService: 取得統計失敗 - $e');
      return UserStats.initial(userId);
    }
  }

  /// 更新用戶統計
  Future<void> updateUserStats(String userId, UserStats stats) async {
    await _saveUserStats(userId, stats);
  }

  Future<void> _saveUserStats(String userId, UserStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyStats$userId', json.encode(stats.toJson()));
      debugPrint('AccountService: 統計已儲存');
    } catch (e) {
      debugPrint('AccountService: 儲存統計失敗 - $e');
    }
  }

  /// 取得用戶貨幣
  Future<UserCurrency> getUserCurrency(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keyCurrency$userId');

      if (data != null) {
        final currency = UserCurrency.fromJson(json.decode(data));
        // 檢查並重置每日限制
        return _checkAndResetDailyLimits(currency);
      }

      // 建立初始貨幣
      final initialCurrency = UserCurrency.initial(userId);
      await _saveUserCurrency(userId, initialCurrency);
      return initialCurrency;
    } catch (e) {
      debugPrint('AccountService: 取得貨幣失敗 - $e');
      return UserCurrency.initial(userId);
    }
  }

  /// 檢查並重置每日限制
  UserCurrency _checkAndResetDailyLimits(UserCurrency currency) {
    final now = DateTime.now();
    final resetTime = currency.dailyRewardState.nextResetAt;

    if (now.isAfter(resetTime)) {
      // 重置每日限制
      return currency.copyWith(
        todaySilverEarned: 0,
        dailyRewardState: currency.dailyRewardState.copyWith(
          todayClaimed: false,
          nextResetAt: DateTime(now.year, now.month, now.day + 1),
        ),
      );
    }
    return currency;
  }

  /// 更新用戶貨幣
  Future<void> updateUserCurrency(String userId, UserCurrency currency) async {
    await _saveUserCurrency(userId, currency);
  }

  Future<void> _saveUserCurrency(String userId, UserCurrency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_keyCurrency$userId', json.encode(currency.toJson()));
      debugPrint('AccountService: 貨幣已儲存');
    } catch (e) {
      debugPrint('AccountService: 儲存貨幣失敗 - $e');
    }
  }

  /// 領取每日獎勵
  Future<UserCurrency?> claimDailyReward(String userId) async {
    try {
      var currency = await getUserCurrency(userId);

      if (!currency.dailyRewardState.canClaimToday) {
        debugPrint('AccountService: 今日獎勵已領取');
        return null;
      }

      // 計算獎勵
      final day = currency.dailyRewardState.currentCycleDays + 1;
      final reward = DailyReward.getRewardForDay(day);

      // 更新貨幣
      currency = currency.copyWith(
        silver: currency.silver + reward.silverAmount,
        gold: currency.gold + reward.goldAmount,
        shards: currency.shards + reward.shardsAmount,
        totalSilverEarned: currency.totalSilverEarned + reward.silverAmount,
        totalGoldEarned: currency.totalGoldEarned + reward.goldAmount,
        dailyRewardState: currency.dailyRewardState.copyWith(
          todayClaimed: true,
          consecutiveDays: currency.dailyRewardState.consecutiveDays + 1,
          currentCycleDays: day >= 7 ? 0 : day,
          lastClaimedAt: DateTime.now(),
        ),
      );

      await _saveUserCurrency(userId, currency);
      debugPrint('AccountService: 每日獎勵已領取 - Day $day');
      return currency;
    } catch (e) {
      debugPrint('AccountService: 領取每日獎勵失敗 - $e');
      return null;
    }
  }

  /// 消費貨幣
  Future<UserCurrency?> spendCurrency({
    required String userId,
    required CurrencyType type,
    required int amount,
    required TransactionType transactionType,
    String? relatedItemId,
  }) async {
    try {
      var currency = await getUserCurrency(userId);

      if (!currency.canAfford(type, amount)) {
        debugPrint('AccountService: 餘額不足');
        return null;
      }

      // 計算新餘額
      int newGold = currency.gold;
      int newSilver = currency.silver;
      int newShards = currency.shards;

      switch (type) {
        case CurrencyType.gold:
          newGold -= amount;
          break;
        case CurrencyType.silver:
          newSilver -= amount;
          break;
        case CurrencyType.shards:
          newShards -= amount;
          break;
      }

      // 建立交易記錄
      final transaction = CurrencyTransaction(
        transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        currencyType: type,
        amount: -amount,
        type: transactionType,
        balanceBefore: currency.getBalance(type),
        balanceAfter: currency.getBalance(type) - amount,
        createdAt: DateTime.now(),
        relatedItemId: relatedItemId,
      );

      // 更新貨幣
      currency = currency.copyWith(
        gold: newGold,
        silver: newSilver,
        shards: newShards,
        recentTransactions: [transaction, ...currency.recentTransactions]
            .take(50)
            .toList(),
      );

      await _saveUserCurrency(userId, currency);
      debugPrint('AccountService: 消費成功 - $amount ${type.displayName}');
      return currency;
    } catch (e) {
      debugPrint('AccountService: 消費失敗 - $e');
      return null;
    }
  }

  /// 增加貨幣
  Future<UserCurrency?> addCurrency({
    required String userId,
    required CurrencyType type,
    required int amount,
    required TransactionType transactionType,
    String? relatedItemId,
  }) async {
    try {
      var currency = await getUserCurrency(userId);

      // 檢查每日上限（銀幣）
      if (type == CurrencyType.silver &&
          transactionType == TransactionType.gameReward) {
        final dailyLimit = CurrencyType.silver.dailyFreeLimit;
        final remaining = dailyLimit - currency.todaySilverEarned;
        if (remaining <= 0) {
          debugPrint('AccountService: 今日銀幣已達上限');
          return currency;
        }
        amount = amount.clamp(0, remaining);
      }

      // 計算新餘額
      int newGold = currency.gold;
      int newSilver = currency.silver;
      int newShards = currency.shards;
      int newTodaySilver = currency.todaySilverEarned;

      switch (type) {
        case CurrencyType.gold:
          newGold += amount;
          break;
        case CurrencyType.silver:
          newSilver += amount;
          newTodaySilver += amount;
          break;
        case CurrencyType.shards:
          newShards += amount;
          break;
      }

      // 建立交易記錄
      final transaction = CurrencyTransaction(
        transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        currencyType: type,
        amount: amount,
        type: transactionType,
        balanceBefore: currency.getBalance(type),
        balanceAfter: currency.getBalance(type) + amount,
        createdAt: DateTime.now(),
        relatedItemId: relatedItemId,
      );

      // 更新貨幣
      currency = currency.copyWith(
        gold: newGold,
        silver: newSilver,
        shards: newShards,
        totalGoldEarned: type == CurrencyType.gold
            ? currency.totalGoldEarned + amount
            : currency.totalGoldEarned,
        totalSilverEarned: type == CurrencyType.silver
            ? currency.totalSilverEarned + amount
            : currency.totalSilverEarned,
        todaySilverEarned: newTodaySilver,
        recentTransactions: [transaction, ...currency.recentTransactions]
            .take(50)
            .toList(),
      );

      await _saveUserCurrency(userId, currency);
      debugPrint('AccountService: 獲得 $amount ${type.displayName}');
      return currency;
    } catch (e) {
      debugPrint('AccountService: 增加貨幣失敗 - $e');
      return null;
    }
  }

  /// 取得用戶設定
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keySettings$userId');

      if (data != null) {
        return UserSettings.fromJson(json.decode(data));
      }

      // 建立初始設定
      final initialSettings = UserSettings.initial(userId);
      await _saveUserSettings(userId, initialSettings);
      return initialSettings;
    } catch (e) {
      debugPrint('AccountService: 取得設定失敗 - $e');
      return UserSettings.initial(userId);
    }
  }

  /// 更新用戶設定
  Future<void> updateUserSettings(String userId, UserSettings settings) async {
    await _saveUserSettings(userId, settings);
  }

  Future<void> _saveUserSettings(String userId, UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_keySettings$userId', json.encode(settings.toJson()));
      debugPrint('AccountService: 設定已儲存');
    } catch (e) {
      debugPrint('AccountService: 儲存設定失敗 - $e');
    }
  }

  /// 取得擁有的皮膚
  Future<List<OwnedSkin>> getOwnedSkins(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keyOwnedSkins$userId');

      if (data != null) {
        final list = json.decode(data) as List<dynamic>;
        return list
            .map((e) => OwnedSkin.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 建立預設皮膚（每個角色的 N 卡）
      final defaultSkins = _createDefaultSkins();
      await _saveOwnedSkins(userId, defaultSkins);
      return defaultSkins;
    } catch (e) {
      debugPrint('AccountService: 取得皮膚失敗 - $e');
      return [];
    }
  }

  List<OwnedSkin> _createDefaultSkins() {
    // 預設給予所有角色的 N 卡皮膚
    final characterIds = [
      'thomas',
      'richard',
      'edward',
      'george',
      'robert',
      'william',
      'king',
    ];

    return characterIds.map((charId) {
      return OwnedSkin(
        skin: Skin(
          id: '${charId}_default',
          characterId: charId,
          name: '預設造型',
          description: '預設角色外觀',
          rarity: SkinRarity.normal,
          type: SkinType.character,
          assetPath: 'assets/images/characters/$charId.png',
          obtainMethod: ObtainMethod.default_,
        ),
        obtainedAt: DateTime.now(),
        obtainMethod: ObtainMethod.default_,
      );
    }).toList();
  }

  Future<void> _saveOwnedSkins(String userId, List<OwnedSkin> skins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyOwnedSkins$userId',
        json.encode(skins.map((s) => s.toJson()).toList()),
      );
      debugPrint('AccountService: 皮膚已儲存');
    } catch (e) {
      debugPrint('AccountService: 儲存皮膚失敗 - $e');
    }
  }

  /// 新增皮膚
  Future<void> addOwnedSkin(String userId, OwnedSkin skin) async {
    final skins = await getOwnedSkins(userId);
    skins.add(skin);
    await _saveOwnedSkins(userId, skins);
  }

  /// 取得裝備的皮膚
  Future<Map<String, String>> getEquippedSkins(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keyEquippedSkins$userId');

      if (data != null) {
        final map = json.decode(data) as Map<String, dynamic>;
        return map.map((k, v) => MapEntry(k, v as String));
      }

      // 預設裝備 N 卡
      final defaultEquipped = <String, String>{
        'thomas': 'thomas_default',
        'richard': 'richard_default',
        'edward': 'edward_default',
        'george': 'george_default',
        'robert': 'robert_default',
        'william': 'william_default',
        'king': 'king_default',
      };
      await _saveEquippedSkins(userId, defaultEquipped);
      return defaultEquipped;
    } catch (e) {
      debugPrint('AccountService: 取得裝備皮膚失敗 - $e');
      return {};
    }
  }

  /// 裝備皮膚
  Future<void> equipSkin(
      String userId, String characterId, String skinId) async {
    final equipped = await getEquippedSkins(userId);
    equipped[characterId] = skinId;
    await _saveEquippedSkins(userId, equipped);
  }

  Future<void> _saveEquippedSkins(
      String userId, Map<String, String> equipped) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_keyEquippedSkins$userId', json.encode(equipped));
      debugPrint('AccountService: 裝備皮膚已儲存');
    } catch (e) {
      debugPrint('AccountService: 儲存裝備皮膚失敗 - $e');
    }
  }

  /// 清除用戶資料
  Future<void> clearUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyStats$userId');
      await prefs.remove('$_keyCurrency$userId');
      await prefs.remove('$_keySettings$userId');
      await prefs.remove('$_keyOwnedSkins$userId');
      await prefs.remove('$_keyEquippedSkins$userId');
      debugPrint('AccountService: 用戶資料已清除');
    } catch (e) {
      debugPrint('AccountService: 清除用戶資料失敗 - $e');
    }
  }
}
