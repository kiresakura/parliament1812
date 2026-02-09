import 'package:flutter/services.dart';

/// 震動反饋服務
class HapticService {
  /// 出牌時的觸覺反饋（中等強度）
  static Future<void> cardPlayed() async {
    await HapticFeedback.mediumImpact();
  }

  /// 受傷時的觸覺反饋（重擊）
  static Future<void> damageTaken() async {
    await HapticFeedback.heavyImpact();
  }

  /// 勝利時的觸覺反饋（連續輕拍）
  static Future<void> victory() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// 投票確認的觸覺反饋（輕拍）
  static Future<void> voteConfirmed() async {
    await HapticFeedback.lightImpact();
  }

  /// 聲望變化的觸覺反饋
  static Future<void> reputationChanged(int delta) async {
    if (delta > 0) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// 卡片長按預覽的觸覺反饋
  static Future<void> cardPreview() async {
    await HapticFeedback.selectionClick();
  }

  /// 拖曳開始
  static Future<void> dragStart() async {
    await HapticFeedback.selectionClick();
  }

  /// 拖曳放下（成功出牌）
  static Future<void> dragAccepted() async {
    await HapticFeedback.mediumImpact();
  }
}
