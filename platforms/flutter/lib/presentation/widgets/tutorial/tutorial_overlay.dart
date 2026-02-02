// 1812 國會風雲 - 教學覆蓋層
//
// 提供半透明遮罩和目標元素高亮效果

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/tutorial.dart';
import '../../../providers/tutorial_provider.dart';
import 'tutorial_tooltip.dart';

/// 教學覆蓋層
///
/// 使用方式：
/// 1. 在需要教學的頁面外層包裹 TutorialOverlay
/// 2. 為需要高亮的元素添加 GlobalKey 並註冊到 TutorialTargetRegistry
class TutorialOverlay extends ConsumerStatefulWidget {
  /// 子組件
  final Widget child;

  /// 遮罩顏色
  final Color overlayColor;

  /// 遮罩透明度
  final double overlayOpacity;

  /// 高亮區域內邊距
  final double highlightPadding;

  /// 高亮區域圓角
  final double highlightBorderRadius;

  /// 是否允許點擊高亮區域
  final bool allowTargetTap;

  /// 是否允許點擊遮罩區域（關閉教學）
  final bool allowOverlayTap;

  /// 工具提示位置偏好
  final TooltipPosition tooltipPosition;

  const TutorialOverlay({
    super.key,
    required this.child,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
    this.highlightPadding = 8.0,
    this.highlightBorderRadius = 8.0,
    this.allowTargetTap = true,
    this.allowOverlayTap = false,
    this.tooltipPosition = TooltipPosition.auto,
  });

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(tutorialProvider);

    // 控制動畫
    if (tutorialState.isActive && !tutorialState.isPaused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return Stack(
      children: [
        // 主要內容
        widget.child,

        // 教學覆蓋層
        if (tutorialState.isActive)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _TutorialOverlayContent(
              state: tutorialState,
              overlayColor: widget.overlayColor,
              overlayOpacity: widget.overlayOpacity,
              highlightPadding: widget.highlightPadding,
              highlightBorderRadius: widget.highlightBorderRadius,
              allowTargetTap: widget.allowTargetTap,
              allowOverlayTap: widget.allowOverlayTap,
              tooltipPosition: widget.tooltipPosition,
            ),
          ),
      ],
    );
  }
}

/// 教學覆蓋層內容
class _TutorialOverlayContent extends ConsumerWidget {
  final TutorialState state;
  final Color overlayColor;
  final double overlayOpacity;
  final double highlightPadding;
  final double highlightBorderRadius;
  final bool allowTargetTap;
  final bool allowOverlayTap;
  final TooltipPosition tooltipPosition;

  const _TutorialOverlayContent({
    required this.state,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.highlightPadding,
    required this.highlightBorderRadius,
    required this.allowTargetTap,
    required this.allowOverlayTap,
    required this.tooltipPosition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightedElement = state.highlightedElement;
    final currentStep = state.currentStep;

    // 獲取高亮區域
    Rect? highlightRect;
    if (highlightedElement != null) {
      highlightRect = TutorialTargetRegistry.getTargetRect(highlightedElement);
    }

    return Stack(
      children: [
        // 遮罩層（帶挖洞效果）
        Positioned.fill(
          child: GestureDetector(
            onTap: allowOverlayTap
                ? () => ref.read(tutorialProvider.notifier).skipLesson()
                : null,
            child: CustomPaint(
              painter: _OverlayPainter(
                overlayColor: overlayColor.withValues(alpha: overlayOpacity),
                highlightRect: highlightRect,
                highlightPadding: highlightPadding,
                highlightBorderRadius: highlightBorderRadius,
              ),
            ),
          ),
        ),

        // 高亮區域點擊處理
        if (highlightRect != null && allowTargetTap)
          Positioned(
            left: highlightRect.left - highlightPadding,
            top: highlightRect.top - highlightPadding,
            width: highlightRect.width + highlightPadding * 2,
            height: highlightRect.height + highlightPadding * 2,
            child: GestureDetector(
              onTap: () {
                // 如果需要點擊按鈕，通知 provider
                if (currentStep?.requiredAction == TutorialAction.tapButton) {
                  ref.read(tutorialProvider.notifier).onPlayerActionCompleted(
                    action: TutorialAction.tapButton,
                    data: {'buttonId': highlightedElement},
                  );
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(highlightBorderRadius),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

        // 教學提示氣泡
        if (currentStep != null)
          _TutorialBubble(
            step: currentStep,
            highlightRect: highlightRect,
            tooltipPosition: tooltipPosition,
            state: state,
          ),
      ],
    );
  }
}

/// 教學氣泡
class _TutorialBubble extends ConsumerWidget {
  final TutorialStep step;
  final Rect? highlightRect;
  final TooltipPosition tooltipPosition;
  final TutorialState state;

  const _TutorialBubble({
    required this.step,
    required this.highlightRect,
    required this.tooltipPosition,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;

    // 計算氣泡位置
    final position = _calculateBubblePosition(
      screenSize: screenSize,
      highlightRect: highlightRect,
      tooltipPosition: tooltipPosition,
    );

    return Positioned(
      left: position.left,
      top: position.top,
      right: position.right,
      bottom: position.bottom,
      child: TutorialTooltip(
        title: step.title,
        description: step.description,
        currentStep: state.currentStepIndex + 1,
        totalSteps: state.totalStepsInLesson,
        showHint: state.showHint,
        hintText: step.requiredAction?.hintText,
        isFirstStep: state.isFirstStepInLesson,
        isLastStep: state.isLastStepInLesson,
        isDemonstrating: state.isDemonstrating,
        demoProgress: state.demoProgress,
        onNext: step.requiresPlayerAction && !state.isDemonstrating
            ? null
            : () => ref.read(tutorialProvider.notifier).nextStep(),
        onPrevious: state.isFirstStepInLesson
            ? null
            : () => ref.read(tutorialProvider.notifier).previousStep(),
        onSkip: step.skippable
            ? () => ref.read(tutorialProvider.notifier).skipLesson()
            : null,
        arrowDirection: _getArrowDirection(highlightRect, position),
      ),
    );
  }

  _BubblePosition _calculateBubblePosition({
    required Size screenSize,
    required Rect? highlightRect,
    required TooltipPosition tooltipPosition,
  }) {
    const bubbleMargin = 16.0;
    const bubbleMaxWidth = 320.0;

    // 如果沒有高亮區域，顯示在螢幕中央
    if (highlightRect == null) {
      return _BubblePosition(
        left: (screenSize.width - bubbleMaxWidth) / 2,
        top: screenSize.height * 0.3,
        right: null,
        bottom: null,
      );
    }

    // 計算高亮區域中心
    final highlightCenter = highlightRect.center;

    // 根據高亮區域位置決定氣泡位置
    final isUpperHalf = highlightCenter.dy < screenSize.height / 2;

    double? left, top, right, bottom;

    if (tooltipPosition == TooltipPosition.auto) {
      // 自動決定位置
      if (isUpperHalf) {
        // 高亮在上半部，氣泡顯示在下方
        top = highlightRect.bottom + bubbleMargin + 20; // 20 為箭頭空間
        left = bubbleMargin;
        right = bubbleMargin;
      } else {
        // 高亮在下半部，氣泡顯示在上方
        bottom = screenSize.height - highlightRect.top + bubbleMargin + 20;
        left = bubbleMargin;
        right = bubbleMargin;
      }
    } else {
      // 使用指定位置
      switch (tooltipPosition) {
        case TooltipPosition.top:
          bottom = screenSize.height - highlightRect.top + bubbleMargin + 20;
          left = bubbleMargin;
          right = bubbleMargin;
          break;
        case TooltipPosition.bottom:
          top = highlightRect.bottom + bubbleMargin + 20;
          left = bubbleMargin;
          right = bubbleMargin;
          break;
        case TooltipPosition.left:
          right = screenSize.width - highlightRect.left + bubbleMargin + 20;
          top = highlightRect.top;
          break;
        case TooltipPosition.right:
          left = highlightRect.right + bubbleMargin + 20;
          top = highlightRect.top;
          break;
        case TooltipPosition.center:
        case TooltipPosition.auto:
          left = (screenSize.width - bubbleMaxWidth) / 2;
          top = screenSize.height * 0.3;
          break;
      }
    }

    return _BubblePosition(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  ArrowDirection _getArrowDirection(
    Rect? highlightRect,
    _BubblePosition position,
  ) {
    if (highlightRect == null) return ArrowDirection.none;

    if (position.top != null && position.bottom == null) {
      return ArrowDirection.up;
    } else if (position.bottom != null && position.top == null) {
      return ArrowDirection.down;
    } else if (position.left != null && position.right == null) {
      return ArrowDirection.left;
    } else if (position.right != null && position.left == null) {
      return ArrowDirection.right;
    }

    return ArrowDirection.none;
  }
}

/// 氣泡位置
class _BubblePosition {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const _BubblePosition({
    this.left,
    this.top,
    this.right,
    this.bottom,
  });
}

/// 遮罩繪製器（帶挖洞效果）
class _OverlayPainter extends CustomPainter {
  final Color overlayColor;
  final Rect? highlightRect;
  final double highlightPadding;
  final double highlightBorderRadius;

  _OverlayPainter({
    required this.overlayColor,
    required this.highlightRect,
    required this.highlightPadding,
    required this.highlightBorderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // 繪製全螢幕遮罩
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (highlightRect == null) {
      // 無高亮區域，繪製完整遮罩
      canvas.drawRect(fullRect, paint);
    } else {
      // 有高亮區域，使用 Path 挖洞
      final expandedHighlight = Rect.fromLTRB(
        highlightRect!.left - highlightPadding,
        highlightRect!.top - highlightPadding,
        highlightRect!.right + highlightPadding,
        highlightRect!.bottom + highlightPadding,
      );

      final path = Path()
        ..addRect(fullRect)
        ..addRRect(RRect.fromRectAndRadius(
          expandedHighlight,
          Radius.circular(highlightBorderRadius),
        ));

      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);

      // 繪製高亮邊框光暈
      final glowPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          expandedHighlight,
          Radius.circular(highlightBorderRadius),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.overlayColor != overlayColor ||
        oldDelegate.highlightRect != highlightRect ||
        oldDelegate.highlightPadding != highlightPadding ||
        oldDelegate.highlightBorderRadius != highlightBorderRadius;
  }
}

/// 工具提示位置
enum TooltipPosition {
  auto,
  top,
  bottom,
  left,
  right,
  center,
}

// ============================================================
// 教學目標註冊表
// ============================================================

/// 教學目標註冊表
///
/// 用於註冊和管理需要高亮的 UI 元素
class TutorialTargetRegistry {
  TutorialTargetRegistry._();

  static final Map<String, GlobalKey> _targets = {};

  /// 註冊目標元素
  static void register(String id, GlobalKey key) {
    _targets[id] = key;
  }

  /// 取消註冊
  static void unregister(String id) {
    _targets.remove(id);
  }

  /// 獲取目標元素的位置和大小
  static Rect? getTargetRect(String id) {
    final key = _targets[id];
    if (key == null) return null;

    final context = key.currentContext;
    if (context == null) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  /// 清除所有註冊
  static void clear() {
    _targets.clear();
  }

  /// 檢查是否已註冊
  static bool isRegistered(String id) {
    return _targets.containsKey(id);
  }
}

/// 教學目標包裝器
///
/// 自動註冊和取消註冊目標元素
class TutorialTarget extends StatefulWidget {
  /// 目標 ID（用於高亮）
  final String targetId;

  /// 子組件
  final Widget child;

  const TutorialTarget({
    super.key,
    required this.targetId,
    required this.child,
  });

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialTargetRegistry.register(widget.targetId, _key);
  }

  @override
  void didUpdateWidget(TutorialTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetId != widget.targetId) {
      TutorialTargetRegistry.unregister(oldWidget.targetId);
      TutorialTargetRegistry.register(widget.targetId, _key);
    }
  }

  @override
  void dispose() {
    TutorialTargetRegistry.unregister(widget.targetId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
