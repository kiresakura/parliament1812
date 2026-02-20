import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════
// 畫面品質等級
// ═══════════════════════════════════════════

/// 圖形品質等級
enum GraphicsQuality {
  low,
  medium,
  high,
  auto;

  String get displayName {
    switch (this) {
      case GraphicsQuality.low:
        return '低';
      case GraphicsQuality.medium:
        return '中';
      case GraphicsQuality.high:
        return '高';
      case GraphicsQuality.auto:
        return '自動';
    }
  }

  String get description {
    switch (this) {
      case GraphicsQuality.low:
        return '適合低配設備，減少動畫與特效';
      case GraphicsQuality.medium:
        return '平衡畫質與效能';
      case GraphicsQuality.high:
        return '完整動畫與視覺效果';
      case GraphicsQuality.auto:
        return '根據設備自動選擇最佳設定';
    }
  }

  IconName get iconName {
    switch (this) {
      case GraphicsQuality.low:
        return IconName.speed;
      case GraphicsQuality.medium:
        return IconName.balance;
      case GraphicsQuality.high:
        return IconName.highQuality;
      case GraphicsQuality.auto:
        return IconName.autoAwesome;
    }
  }
}

/// 用於映射到 Flutter Icons（避免直接 import material）
enum IconName { speed, balance, highQuality, autoAwesome }

// ═══════════════════════════════════════════
// 品質配置
// ═══════════════════════════════════════════

/// 各品質等級的具體配置
class QualityConfig {
  // 動畫
  final bool enableAnimations;
  final bool enableElasticCurves;
  final Duration phaseTransitionDuration;
  final bool skipPhaseTransition;

  // 視覺
  final bool enableShadows;
  final bool enableFullShadows;
  final bool enableGradients;
  final bool enableFullGradients;

  // 圖片
  final int? imageCacheWidth; // null = 不限

  // 列表上限
  final int maxChatMessages;
  final int maxGameEvents;

  // 聲望動畫
  final ReputationAnimationMode reputationAnimationMode;
  final Duration reputationAnimationDuration;

  // 卡牌
  final bool enableHoverAnimation;
  final bool enableDragFeedbackAnimation;
  final bool enableCardPlayAnimation;
  final Duration cardPlayAnimationDuration;

  // 卡牌圖鑑
  final CardFilterMode unownedCardFilterMode;

  // 投票動畫
  final VoteAnimationMode voteAnimationMode;
  final Duration voteAnimationDuration;

  const QualityConfig({
    required this.enableAnimations,
    required this.enableElasticCurves,
    required this.phaseTransitionDuration,
    required this.skipPhaseTransition,
    required this.enableShadows,
    required this.enableFullShadows,
    required this.enableGradients,
    required this.enableFullGradients,
    required this.imageCacheWidth,
    required this.maxChatMessages,
    required this.maxGameEvents,
    required this.reputationAnimationMode,
    required this.reputationAnimationDuration,
    required this.enableHoverAnimation,
    required this.enableDragFeedbackAnimation,
    required this.enableCardPlayAnimation,
    required this.cardPlayAnimationDuration,
    required this.unownedCardFilterMode,
    required this.voteAnimationMode,
    required this.voteAnimationDuration,
  });

  /// 低品質配置
  static const low = QualityConfig(
    enableAnimations: false,
    enableElasticCurves: false,
    phaseTransitionDuration: Duration.zero,
    skipPhaseTransition: true,
    enableShadows: false,
    enableFullShadows: false,
    enableGradients: false,
    enableFullGradients: false,
    imageCacheWidth: 128,
    maxChatMessages: 30,
    maxGameEvents: 10,
    reputationAnimationMode: ReputationAnimationMode.instant,
    reputationAnimationDuration: Duration.zero,
    enableHoverAnimation: false,
    enableDragFeedbackAnimation: false,
    enableCardPlayAnimation: false,
    cardPlayAnimationDuration: Duration.zero,
    unownedCardFilterMode: CardFilterMode.opacity,
    voteAnimationMode: VoteAnimationMode.instant,
    voteAnimationDuration: Duration.zero,
  );

  /// 中品質配置
  static const medium = QualityConfig(
    enableAnimations: true,
    enableElasticCurves: false,
    phaseTransitionDuration: Duration(milliseconds: 800),
    skipPhaseTransition: false,
    enableShadows: true,
    enableFullShadows: false,
    enableGradients: true,
    enableFullGradients: false,
    imageCacheWidth: 256,
    maxChatMessages: 50,
    maxGameEvents: 20,
    reputationAnimationMode: ReputationAnimationMode.fast,
    reputationAnimationDuration: Duration(milliseconds: 300),
    enableHoverAnimation: true,
    enableDragFeedbackAnimation: true,
    enableCardPlayAnimation: true,
    cardPlayAnimationDuration: Duration(milliseconds: 400),
    unownedCardFilterMode: CardFilterMode.simpleGrayscale,
    voteAnimationMode: VoteAnimationMode.fast,
    voteAnimationDuration: Duration(milliseconds: 500),
  );

  /// 高品質配置
  static const high = QualityConfig(
    enableAnimations: true,
    enableElasticCurves: true,
    phaseTransitionDuration: Duration(milliseconds: 1500),
    skipPhaseTransition: false,
    enableShadows: true,
    enableFullShadows: true,
    enableGradients: true,
    enableFullGradients: true,
    imageCacheWidth: null,
    maxChatMessages: 100,
    maxGameEvents: 50,
    reputationAnimationMode: ReputationAnimationMode.full,
    reputationAnimationDuration: Duration(milliseconds: 1000),
    enableHoverAnimation: true,
    enableDragFeedbackAnimation: true,
    enableCardPlayAnimation: true,
    cardPlayAnimationDuration: Duration(milliseconds: 600),
    unownedCardFilterMode: CardFilterMode.fullGrayscaleMatrix,
    voteAnimationMode: VoteAnimationMode.full,
    voteAnimationDuration: Duration(milliseconds: 1200),
  );

  /// 根據品質等級取得配置
  static QualityConfig forQuality(GraphicsQuality quality) {
    switch (quality) {
      case GraphicsQuality.low:
        return low;
      case GraphicsQuality.medium:
        return medium;
      case GraphicsQuality.high:
        return high;
      case GraphicsQuality.auto:
        return _detectQuality();
    }
  }

  /// 自動偵測設備品質
  static QualityConfig _detectQuality() {
    final detected = PerformanceService.detectRecommendedQuality();
    return forQuality(detected);
  }
}

/// 聲望動畫模式
enum ReputationAnimationMode {
  /// 直接跳轉到最終數值
  instant,
  /// 快速滾動（無浮動增減標示）
  fast,
  /// 完整滾動 + 浮動增減標示
  full,
}

/// 投票動畫模式
enum VoteAnimationMode {
  instant,
  fast,
  full,
}

/// 未擁有卡牌的濾鏡模式
enum CardFilterMode {
  /// 僅用 Opacity 降低透明度
  opacity,
  /// 簡化灰階
  simpleGrayscale,
  /// 完整灰階矩陣
  fullGrayscaleMatrix,
}

// ═══════════════════════════════════════════
// 效能服務
// ═══════════════════════════════════════════

class PerformanceService {
  static const _prefsKey = 'graphics_quality';

  /// 從 SharedPreferences 讀取品質設定
  static GraphicsQuality loadQuality(SharedPreferences prefs) {
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return GraphicsQuality.auto;
    return GraphicsQuality.values.firstWhere(
      (q) => q.name == stored,
      orElse: () => GraphicsQuality.auto,
    );
  }

  /// 儲存品質設定
  static Future<void> saveQuality(
      SharedPreferences prefs, GraphicsQuality quality) async {
    await prefs.setString(_prefsKey, quality.name);
  }

  /// 自動偵測建議的品質等級
  static GraphicsQuality detectRecommendedQuality() {
    try {
      // 透過 PlatformDispatcher 取得顯示資訊
      final displays =
          PlatformDispatcher.instance.displays;
      if (displays.isNotEmpty) {
        final display = displays.first;
        final refreshRate = display.refreshRate;
        final size = display.size;
        final pixelCount = size.width * size.height;

        // 高刷新率 + 高解析度 → 高品質
        if (refreshRate >= 90 && pixelCount > 2000000) {
          return GraphicsQuality.high;
        }

        // 一般刷新率或中等解析度 → 中品質
        if (refreshRate >= 60 && pixelCount > 800000) {
          return GraphicsQuality.medium;
        }
      }

      // 平台判斷（備用）
      if (Platform.isIOS) {
        // iOS 設備通常效能較好
        return GraphicsQuality.high;
      }

      if (Platform.isAndroid) {
        // Android 預設中品質，讓低階設備安全
        return GraphicsQuality.medium;
      }

      // 桌面平台
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return GraphicsQuality.high;
      }
    } catch (e) {
      debugPrint('Performance detection failed: $e');
    }

    return GraphicsQuality.medium;
  }

  /// 取得自動模式下偵測到的實際品質等級
  static GraphicsQuality getEffectiveQuality(GraphicsQuality setting) {
    if (setting == GraphicsQuality.auto) {
      return detectRecommendedQuality();
    }
    return setting;
  }

  /// 取得指定品質的配置
  static QualityConfig getConfig(GraphicsQuality quality) {
    if (quality == GraphicsQuality.auto) {
      final detected = detectRecommendedQuality();
      return QualityConfig.forQuality(detected);
    }
    return QualityConfig.forQuality(quality);
  }
}

// ═══════════════════════════════════════════
// Riverpod Providers
// ═══════════════════════════════════════════

/// 圖形品質設定 Provider
final graphicsQualityProvider =
    StateNotifierProvider<GraphicsQualityNotifier, GraphicsQuality>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GraphicsQualityNotifier(prefs);
});

/// 圖形品質通知器
class GraphicsQualityNotifier extends StateNotifier<GraphicsQuality> {
  final SharedPreferences _prefs;

  GraphicsQualityNotifier(this._prefs)
      : super(PerformanceService.loadQuality(_prefs));

  /// 設定品質等級
  Future<void> setQuality(GraphicsQuality quality) async {
    state = quality;
    await PerformanceService.saveQuality(_prefs, quality);
  }
}

/// 當前有效品質等級（解析 auto）
final effectiveQualityProvider = Provider<GraphicsQuality>((ref) {
  final quality = ref.watch(graphicsQualityProvider);
  return PerformanceService.getEffectiveQuality(quality);
});

/// 當前品質配置
final qualityConfigProvider = Provider<QualityConfig>((ref) {
  final quality = ref.watch(graphicsQualityProvider);
  return PerformanceService.getConfig(quality);
});

/// 自動偵測建議的品質等級
final detectedQualityProvider = Provider<GraphicsQuality>((ref) {
  return PerformanceService.detectRecommendedQuality();
});
