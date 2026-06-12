import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 行動力系統
/// SharedPreferences 持久化，支援離線回復計算
class StaminaService {
  static const String _keyStamina = 'stamina_current';
  static const String _keyLastUpdate = 'stamina_last_update';

  /// 最大行動力
  static const int maxStamina = 100;

  /// 回復速率：每 6 分鐘 +1（360 秒）
  static const int regenIntervalSeconds = 360;

  /// 消耗定義
  static const int costQuickMatch = 15;
  static const int costCampaign = 20;
  static const int costMultiplayer = 5;

  /// 寶石購買選項
  static const int gemCostFull = 10;      // 10 寶石 → 回滿
  static const int gemCostHalf = 5;       // 5 寶石 → +50
  static const int staminaHalfRefill = 50;

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 取得當前行動力（含離線回復計算）
  Future<int> get currentStamina async {
    final prefs = await _preferences;
    final stored = prefs.getInt(_keyStamina) ?? maxStamina;
    final lastUpdate = prefs.getInt(_keyLastUpdate) ?? 
        DateTime.now().millisecondsSinceEpoch;

    if (stored >= maxStamina) return maxStamina;

    // 計算離線回復
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastUpdate) ~/ 1000;
    final regenPoints = elapsedSeconds ~/ regenIntervalSeconds;

    if (regenPoints > 0) {
      final newStamina = (stored + regenPoints).clamp(0, maxStamina);
      await _save(newStamina);
      return newStamina;
    }

    return stored;
  }

  /// 是否有足夠行動力
  Future<bool> canAfford(int cost) async {
    final current = await currentStamina;
    return current >= cost;
  }

  /// 消耗行動力
  Future<bool> consume(int cost) async {
    final current = await currentStamina;
    if (current < cost) return false;
    await _save(current - cost);
    return true;
  }

  /// 寶石購買行動力
  /// 返回 true 表示成功（寶石扣除邏輯由呼叫方處理）
  Future<bool> purchase(int amount, int gemCost) async {
    // 這裡只處理行動力增加，寶石扣除由外部處理
    final current = await currentStamina;
    final newStamina = (current + amount).clamp(0, maxStamina);
    await _save(newStamina);
    return true;
  }

  /// 回滿行動力
  Future<void> refillFull() async {
    await _save(maxStamina);
  }

  /// 距離下一點回復的剩餘秒數
  Future<int> get timeUntilNextPoint async {
    final prefs = await _preferences;
    final current = await currentStamina;
    if (current >= maxStamina) return 0;

    final lastUpdate = prefs.getInt(_keyLastUpdate) ??
        DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastUpdate) ~/ 1000;
    final elapsed = elapsedSeconds % regenIntervalSeconds;
    return regenIntervalSeconds - elapsed;
  }

  /// 預計回滿時間（分鐘）
  Future<int> get minutesUntilFull async {
    final current = await currentStamina;
    if (current >= maxStamina) return 0;
    final remaining = maxStamina - current;
    return remaining * (regenIntervalSeconds ~/ 60);
  }

  /// 格式化回滿時間
  Future<String> get formattedTimeUntilFull async {
    final minutes = await minutesUntilFull;
    if (minutes <= 0) return '已滿';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours小時$mins分鐘';
    }
    return '$mins分鐘';
  }

  /// 內部儲存
  Future<void> _save(int stamina) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyStamina, stamina.clamp(0, maxStamina));
    await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
  }
}

/// Riverpod Provider
final staminaServiceProvider = Provider<StaminaService>((ref) {
  return StaminaService();
});

/// 當前行動力的 FutureProvider
final currentStaminaProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(staminaServiceProvider);
  await service.init();
  return service.currentStamina;
});

/// 回滿時間的 FutureProvider
final staminaTimeProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(staminaServiceProvider);
  await service.init();
  return service.formattedTimeUntilFull;
});
