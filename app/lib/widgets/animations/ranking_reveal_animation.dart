import 'package:flutter/material.dart';

/// 勝負結算動畫 — 排名逐條出現
class RankingRevealAnimation extends StatefulWidget {
  final List<Widget> rankingItems;
  final Duration delayBetween;
  final Duration itemDuration;

  const RankingRevealAnimation({
    super.key,
    required this.rankingItems,
    this.delayBetween = const Duration(milliseconds: 300),
    this.itemDuration = const Duration(milliseconds: 500),
  });

  @override
  State<RankingRevealAnimation> createState() =>
      _RankingRevealAnimationState();
}

class _RankingRevealAnimationState extends State<RankingRevealAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.rankingItems.length,
      (i) => AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((c) {
      return Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack));
    }).toList();

    _scaleAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut),
      );
    }).toList();
  }

  void _startSequence() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.delayBetween);
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.rankingItems.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimations[i],
              child: SlideTransition(
                position: _slideAnimations[i],
                child: Transform.scale(
                  scale: _scaleAnimations[i].value,
                  child: widget.rankingItems[i],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// 單個排名項目的出現動畫包裝
class RankingItemAnimationWrapper extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const RankingItemAnimationWrapper({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 300),
  });

  @override
  State<RankingItemAnimationWrapper> createState() =>
      _RankingItemAnimationWrapperState();
}

class _RankingItemAnimationWrapperState
    extends State<RankingItemAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
