import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/performance_service.dart';

/// 投票動畫 — 票數跳動效果
/// 支援三種模式：instant（低品質）、fast（中品質）、full（高品質）
class VoteCountAnimation extends ConsumerStatefulWidget {
  final int targetCount;
  final String label;
  final Color? color;
  final TextStyle? textStyle;
  final Duration duration;

  const VoteCountAnimation({
    super.key,
    required this.targetCount,
    required this.label,
    this.color,
    this.textStyle,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  ConsumerState<VoteCountAnimation> createState() =>
      _VoteCountAnimationState();
}

class _VoteCountAnimationState extends ConsumerState<VoteCountAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final config = ref.read(qualityConfigProvider);

    _controller = AnimationController(
      duration: config.voteAnimationDuration,
      vsync: this,
    );

    _setupAnimations(config);

    if (config.voteAnimationMode != VoteAnimationMode.instant) {
      _controller.forward();
    }
  }

  void _setupAnimations(QualityConfig config) {
    switch (config.voteAnimationMode) {
      case VoteAnimationMode.instant:
        _countAnimation =
            AlwaysStoppedAnimation(widget.targetCount.toDouble());
        _scaleAnimation = const AlwaysStoppedAnimation(1.0);
        break;

      case VoteAnimationMode.fast:
        _countAnimation = Tween<double>(
          begin: 0,
          end: widget.targetCount.toDouble(),
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ));
        _scaleAnimation = const AlwaysStoppedAnimation(1.0);
        break;

      case VoteAnimationMode.full:
        _countAnimation = Tween<double>(
          begin: 0,
          end: widget.targetCount.toDouble(),
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ));
        _scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 1.3), weight: 15),
          TweenSequenceItem(
              tween: Tween(begin: 1.3, end: 1.0), weight: 15),
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 1.0), weight: 70),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
    }
  }

  @override
  void didUpdateWidget(VoteCountAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCount != widget.targetCount) {
      final config = ref.read(qualityConfigProvider);

      if (config.voteAnimationMode == VoteAnimationMode.instant) {
        _countAnimation =
            AlwaysStoppedAnimation(widget.targetCount.toDouble());
        setState(() {});
        return;
      }

      _countAnimation = Tween<double>(
        begin: oldWidget.targetCount.toDouble(),
        end: widget.targetCount.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(qualityConfigProvider);
    final color = widget.color ?? Parliament1812Theme.gold;

    // 低品質：直接顯示最終數字
    if (config.voteAnimationMode == VoteAnimationMode.instant) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.targetCount}',
            style:
                (widget.textStyle ?? theme.textTheme.displayMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_countAnimation.value.round()}',
                style: (widget.textStyle ?? theme.textTheme.displayMedium)
                    ?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 投票進度條動畫
class VoteProgressBar extends ConsumerWidget {
  final double progress;
  final Color color;
  final String label;
  final int count;

  const VoteProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(qualityConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '$count 票',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!config.enableAnimations)
          // 低品質：不播放動畫
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: min(progress, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: min(progress, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              );
            },
          ),
      ],
    );
  }
}
