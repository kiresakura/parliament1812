import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/performance_service.dart';

/// 出牌動畫 — 卡片飛出效果
/// 低品質：無動畫，直接觸發 onComplete
/// 中品質：簡化（減少 rotation、縮短時長）
/// 高品質：完整效果
class CardPlayAnimation extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;

  const CardPlayAnimation({
    super.key,
    required this.child,
    this.onComplete,
  });

  @override
  ConsumerState<CardPlayAnimation> createState() => CardPlayAnimationState();
}

class CardPlayAnimationState extends ConsumerState<CardPlayAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    final config = ref.read(qualityConfigProvider);

    _controller = AnimationController(
      duration: config.cardPlayAnimationDuration,
      vsync: this,
    );

    _setupAnimations(config);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _setupAnimations(QualityConfig config) {
    if (!config.enableCardPlayAnimation) {
      // 低品質：不播放動畫
      _slideAnimation = const AlwaysStoppedAnimation(Offset.zero);
      _scaleAnimation = const AlwaysStoppedAnimation(1.0);
      _opacityAnimation = const AlwaysStoppedAnimation(1.0);
      _rotationAnimation = const AlwaysStoppedAnimation(0.0);
      return;
    }

    if (!config.enableElasticCurves) {
      // 中品質：簡化動畫
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -2.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ));

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.7,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      _opacityAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ));

      _rotationAnimation = const AlwaysStoppedAnimation(0.0);
      return;
    }

    // 高品質：完整動畫
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInBack,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 0.6), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 觸發出牌動畫
  void play() {
    final config = ref.read(qualityConfigProvider);

    if (!config.enableCardPlayAnimation) {
      // 低品質：直接完成
      widget.onComplete?.call();
      return;
    }

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(qualityConfigProvider);

    // 低品質：不包裝動畫
    if (!config.enableCardPlayAnimation) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
