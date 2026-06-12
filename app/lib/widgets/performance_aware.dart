import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/performance_service.dart';

// ═══════════════════════════════════════════
// 效能感知 Helper 函數
// ═══════════════════════════════════════════

/// 快速檢查是否該播放動畫
bool shouldAnimate(WidgetRef ref) {
  final config = ref.watch(qualityConfigProvider);
  return config.enableAnimations;
}

/// 返回當前品質的聊天上限
int maxChatMessages(WidgetRef ref) {
  final config = ref.watch(qualityConfigProvider);
  return config.maxChatMessages;
}

/// 返回當前品質的事件上限
int maxGameEvents(WidgetRef ref) {
  final config = ref.watch(qualityConfigProvider);
  return config.maxGameEvents;
}

/// 取得品質配置（非 Widget 環境用）
QualityConfig getQualityConfig(WidgetRef ref) {
  return ref.watch(qualityConfigProvider);
}

// ═══════════════════════════════════════════
// PerformanceAwareDecoration
// ═══════════════════════════════════════════

/// 根據品質等級自動調整 BoxDecoration
class PerformanceAwareDecoration {
  /// 根據品質配置生成 BoxDecoration
  ///
  /// - 低品質：移除 shadow、gradient 替換為純色
  /// - 中品質：簡化 shadow、保留 gradient
  /// - 高品質：完整效果
  static BoxDecoration build({
    required QualityConfig config,
    Color? color,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    Border? border,
    BoxShape shape = BoxShape.rectangle,
  }) {
    // 處理 Gradient
    Gradient? effectiveGradient;
    Color? effectiveColor = color;

    if (gradient != null) {
      if (config.enableFullGradients) {
        effectiveGradient = gradient;
      } else if (config.enableGradients) {
        // 中品質：簡化漸層（只保留首尾兩色）
        if (gradient is LinearGradient && gradient.colors.length > 2) {
          effectiveGradient = LinearGradient(
            begin: gradient.begin,
            end: gradient.end,
            colors: [gradient.colors.first, gradient.colors.last],
          );
        } else {
          effectiveGradient = gradient;
        }
      } else {
        // 低品質：漸層替換為純色（取第一個顏色）
        effectiveGradient = null;
        if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
          effectiveColor = gradient.colors.first;
        }
      }
    }

    // 處理 BoxShadow
    List<BoxShadow>? effectiveShadow;
    if (boxShadow != null && boxShadow.isNotEmpty) {
      if (config.enableFullShadows) {
        effectiveShadow = boxShadow;
      } else if (config.enableShadows) {
        // 中品質：簡化陰影（降低模糊度、去掉 spread）
        effectiveShadow = boxShadow.map((s) {
          return BoxShadow(
            color: s.color.withValues(alpha: s.color.a * 0.5),
            blurRadius: s.blurRadius * 0.5,
            offset: s.offset,
          );
        }).toList();
      } else {
        // 低品質：完全移除陰影
        effectiveShadow = null;
      }
    }

    return BoxDecoration(
      color: effectiveGradient == null ? effectiveColor : null,
      gradient: effectiveGradient,
      boxShadow: effectiveShadow,
      borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      border: border,
      shape: shape,
    );
  }
}

// ═══════════════════════════════════════════
// PerformanceAwareAnimation
// ═══════════════════════════════════════════

/// 根據品質控制動畫時長或跳過
class PerformanceAwareAnimation extends ConsumerWidget {
  final Widget child;
  final Duration fullDuration;
  final Curve fullCurve;
  final Widget Function(BuildContext, Widget, AnimationController)?
      animationBuilder;

  const PerformanceAwareAnimation({
    super.key,
    required this.child,
    this.fullDuration = const Duration(milliseconds: 300),
    this.fullCurve = Curves.easeInOut,
    this.animationBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(qualityConfigProvider);

    if (!config.enableAnimations) {
      // 低品質：不播放動畫，直接顯示
      return child;
    }

    // 中/高品質：正常播放
    return child;
  }
}

// ═══════════════════════════════════════════
// PerformanceAwareImage
// ═══════════════════════════════════════════

/// 根據品質等級自動設定 cacheWidth 的 Image.asset
class PerformanceAwareImage extends ConsumerWidget {
  final String assetPath;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const PerformanceAwareImage({
    super.key,
    required this.assetPath,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(qualityConfigProvider);

    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: config.imageCacheWidth,
      errorBuilder: errorBuilder,
    );
  }
}
