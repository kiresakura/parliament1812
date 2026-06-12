import 'package:flutter/animation.dart';

/// 羅塞蒂動畫參數系統 v1.0 — 14 個標準動畫 + 脈衝迴圈
///
/// 設計：羅塞蒂（美學大臣）
/// 實現：艾達（技術大臣）
///
/// 動畫哲學：每個操作都必須有「物理反饋感」。
/// 點下去沒有任何反應的按鈕，是設計犯罪。
class GameAnimation {
  GameAnimation._();

  // ═══════════════════════════════════════════
  // 按鈕 / 互動
  // ═══════════════════════════════════════════

  /// 按鈕按壓 — 快速彈跳手感
  /// scaleEffect: 0.95 → 1.0
  static const Curve buttonPressCurve = _SpringCurve(0.25, 0.6);
  static const Duration buttonPressDuration = Duration(milliseconds: 250);

  /// 卡牌選中 — 帶有彈性的選中動畫
  /// scaleEffect: 1.0 → 1.05, offset(y: -6), shadow glow
  static const Curve cardSelectCurve = _SpringCurve(0.35, 0.65);
  static const Duration cardSelectDuration = Duration(milliseconds: 350);

  /// 卡牌取消選中 — 比選中稍快、更沈穩
  static const Curve cardDeselectCurve = _SpringCurve(0.3, 0.7);
  static const Duration cardDeselectDuration = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════
  // 出牌 / 移除
  // ═══════════════════════════════════════════

  /// 卡牌出牌 — 向上飛出消失
  /// opacity: 1 → 0, scale: 1.0 → 0.3, offset(y: -80)
  static const Curve cardPlayCurve = Curves.easeOut;
  static const Duration cardPlayDuration = Duration(milliseconds: 400);

  /// 卡牌抽牌 — 從牌庫彈入手牌
  static const Curve cardDrawCurve = _SpringCurve(0.45, 0.7);
  static const Duration cardDrawDuration = Duration(milliseconds: 450);

  // ═══════════════════════════════════════════
  // 獎勵 / 反饋
  // ═══════════════════════════════════════════

  /// 獎勵彈出 — 任務完成、段位提升
  static const Curve rewardPopCurve = _SpringCurve(0.4, 0.55);
  static const Duration rewardPopDuration = Duration(milliseconds: 400);

  /// 數字翻轉 — 回合數、資源數字切換
  static const Curve numberFlipCurve = _SpringCurve(0.3, 0.75);
  static const Duration numberFlipDuration = Duration(milliseconds: 300);

  /// 浮動淡出 — +N/-N 數字從元素上方升起消失
  /// offset(y: -28), opacity: 1 → 0
  static const Curve floatFadeCurve = Curves.easeOut;
  static const Duration floatFadeDuration = Duration(milliseconds: 800);

  // ═══════════════════════════════════════════
  // 場景 / 進場
  // ═══════════════════════════════════════════

  /// 議案進場 — 從上方 -40pt 滑入 + fade in
  static const Curve billEntranceCurve = Curves.easeOut;
  static const Duration billEntranceDuration = Duration(milliseconds: 350);

  /// 事件日誌進場 — fade in + 從左 -20pt 滑入
  static const Curve eventEntranceCurve = Curves.easeOut;
  static const Duration eventEntranceDuration = Duration(milliseconds: 300);

  /// 面板滑入 — 側面面板、底部面板進場
  static const Curve panelSlideInCurve = _SpringCurve(0.5, 0.8);
  static const Duration panelSlideInDuration = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════
  // 結束回合儀式
  // ═══════════════════════════════════════════

  /// 結束回合動畫序列：
  /// 0.0s: scaleEffect 壓縮至 0.92
  /// 0.15s: 爆發至 1.08（spring 彈跳）
  /// 0.3s: 回到 1.0
  /// 0.35s: 金色光暈爆發（radius 0→20→0, 0.5s）
  /// 0.4s: 觸發回合切換
  static const Curve endTurnCurve = _SpringCurve(0.5, 0.5);
  static const Duration endTurnDuration = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════
  // 脈衝 / 迴圈（無限循環）
  // ═══════════════════════════════════════════

  /// 呼吸脈衝 — 回合指示器、重要 UI
  /// 1.5s 週期，easeInOut，autoreverses
  static const Duration breathePulseDuration = Duration(milliseconds: 1500);

  /// 緩慢脈衝 — 「開始對局」按鈕待機光暈
  /// 2.0s 週期
  static const Duration slowPulseDuration = Duration(milliseconds: 2000);

  /// 燭光閃爍 — LoginView 燭火
  /// 0.8s 週期
  static const Duration candleFlickerDuration = Duration(milliseconds: 800);

  /// 結束回合按鈕待機脈衝
  /// 1.2s 週期
  static const Duration endTurnPulseDuration = Duration(milliseconds: 1200);

  // ═══════════════════════════════════════════
  // 登入流程
  // ═══════════════════════════════════════════

  /// 登入成功 — 全螢幕 flash + scaleEffect 1.0→1.1 + fade out
  static const Curve loginSuccessCurve = Curves.easeOut;
  static const Duration loginSuccessDuration = Duration(milliseconds: 350);

  /// 登入失敗 — 水平抖動
  /// offset x: 0 → -8 → 8 → -5 → 5 → 0
  static const Curve loginErrorCurve = Curves.easeInOut;
  static const Duration loginErrorDuration = Duration(milliseconds: 400);

  // ═══════════════════════════════════════════
  // 便利方法
  // ═══════════════════════════════════════════

  /// 建立標準脈衝 AnimationController 參數
  ///
  /// 用法：
  /// ```dart
  /// final controller = AnimationController(
  ///   duration: GameAnimation.breathePulseDuration,
  ///   vsync: this,
  /// )..repeat(reverse: true);
  /// ```
  static const Curve pulseCurve = Curves.easeInOut;

  /// 連勝計數器進入動畫
  /// spring 從右側彈入
  static const Curve winStreakEnterCurve = _SpringCurve(0.5, 0.6);
  static const Duration winStreakEnterDuration = Duration(milliseconds: 500);

  /// 連勝數字更新 — scaleEffect 1.0→1.3→1.0
  static const Duration winStreakUpdateDuration = Duration(milliseconds: 350);

  // ═══════════════════════════════════════════
  // 議會多人制新增（Phase 2）
  // ═══════════════════════════════════════════

  /// 結束發言按鈕持續光暈
  static const Duration buttonPulseDuration = Duration(milliseconds: 1200);

  /// 行動順序切換 spring 彈跳
  static const Curve turnOrderSwitchCurve = _SpringCurve(0.4, 0.5);
  static const Duration turnOrderSwitchDuration = Duration(milliseconds: 400);

  /// 辯論日誌條目淡入
  static const Curve debateLogEntryCurve = Curves.easeIn;
  static const Duration debateLogEntryDuration = Duration(milliseconds: 300);

  /// 影響力條 shimmer 光澤
  static const Duration shimmerSlideDuration = Duration(milliseconds: 1800);
}

/// 自訂 Spring Curve — 模擬 SwiftUI `.spring(response:dampingFraction:)`
///
/// response: 彈簧響應時間（越小越快）
/// dampingFraction: 阻尼比（0=永不停止, 1=無彈跳, 0.5~0.7=自然彈跳）
class _SpringCurve extends Curve {
  final double response;
  final double dampingFraction;

  const _SpringCurve(this.response, this.dampingFraction);

  @override
  double transformInternal(double t) {
    // 將 SwiftUI spring 參數轉換為 Flutter 可用的 spring simulation
    // 使用臨界阻尼公式近似
    final omega = 2 * 3.14159 / response;
    final zeta = dampingFraction;

    if (zeta < 1.0) {
      // 欠阻尼（有彈跳）
      final dampedOmega = omega * (1 - zeta * zeta).clamp(0.0, 1.0);
      final decay = (-zeta * omega * t).clamp(-20.0, 0.0);
      final expDecay = _exp(decay);
      return 1.0 -
          expDecay *
              (_cos(dampedOmega * t) +
                  (zeta / (1 - zeta * zeta).clamp(0.001, 1.0)) *
                      _sin(dampedOmega * t));
    } else {
      // 過阻尼或臨界阻尼
      final decay = (-omega * t).clamp(-20.0, 0.0);
      return 1.0 - (1 + omega * t) * _exp(decay);
    }
  }

  // 數學工具（避免 dart:math import 開銷）
  static double _exp(double x) {
    // 快速近似 exp
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 12; i++) {
      term *= x / i;
      result += term;
    }
    return result.clamp(0.0, double.infinity);
  }

  static double _sin(double x) {
    // Taylor series sin
    x = x % (2 * 3.14159);
    double result = 0;
    double term = x;
    for (int i = 0; i < 8; i++) {
      result += term;
      term *= -x * x / ((2 * i + 2) * (2 * i + 3));
    }
    return result;
  }

  static double _cos(double x) {
    // Taylor series cos
    x = x % (2 * 3.14159);
    double result = 0;
    double term = 1.0;
    for (int i = 0; i < 8; i++) {
      result += term;
      term *= -x * x / ((2 * i + 1) * (2 * i + 2));
    }
    return result;
  }
}
