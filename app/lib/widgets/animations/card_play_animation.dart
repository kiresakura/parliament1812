import 'package:flutter/material.dart';

/// 出牌動畫 — 卡片飛出效果
class CardPlayAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;

  const CardPlayAnimation({
    super.key,
    required this.child,
    this.onComplete,
  });

  @override
  State<CardPlayAnimation> createState() => CardPlayAnimationState();
}

class CardPlayAnimationState extends State<CardPlayAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInBack,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.6),
        weight: 70,
      ),
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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 觸發出牌動畫
  void play() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
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
