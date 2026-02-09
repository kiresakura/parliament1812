import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// 聲望變化動畫 — 數字滾動 + 紅綠色標示
class ReputationChangeAnimation extends StatefulWidget {
  final int oldValue;
  final int newValue;
  final Duration duration;
  final TextStyle? textStyle;

  const ReputationChangeAnimation({
    super.key,
    required this.oldValue,
    required this.newValue,
    this.duration = const Duration(milliseconds: 1000),
    this.textStyle,
  });

  @override
  State<ReputationChangeAnimation> createState() =>
      _ReputationChangeAnimationState();
}

class _ReputationChangeAnimationState extends State<ReputationChangeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _valueAnimation;
  late Animation<double> _deltaOpacity;
  late Animation<Offset> _deltaSlide;

  int get _delta => widget.newValue - widget.oldValue;
  bool get _isPositive => _delta > 0;
  Color get _deltaColor =>
      _isPositive ? Parliament1812Theme.reputationUpColor : Parliament1812Theme.reputationDownColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _valueAnimation = Tween<double>(
      begin: widget.oldValue.toDouble(),
      end: widget.newValue.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _deltaOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _deltaSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (_delta != 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ReputationChangeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newValue != widget.newValue ||
        oldWidget.oldValue != widget.oldValue) {
      _valueAnimation = Tween<double>(
        begin: oldWidget.newValue.toDouble(),
        end: widget.newValue.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
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
    final baseStyle =
        widget.textStyle ?? theme.textTheme.titleLarge!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主數值（滾動）
            Text(
              '${_valueAnimation.value.round()}',
              style: baseStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            // 差值浮動標示
            if (_delta != 0)
              SlideTransition(
                position: _deltaSlide,
                child: Opacity(
                  opacity: _deltaOpacity.value,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      _isPositive ? '+$_delta' : '$_delta',
                      style: baseStyle.copyWith(
                        color: _deltaColor,
                        fontSize: (baseStyle.fontSize ?? 18) * 0.7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 聲望條動畫（帶漸變色）
class AnimatedReputationBar extends StatelessWidget {
  final int reputation;
  final int maxReputation;
  final double height;

  const AnimatedReputationBar({
    super.key,
    required this.reputation,
    this.maxReputation = 100,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (reputation / maxReputation).clamp(0.0, 1.0);

    Color barColor;
    if (reputation > 60) {
      barColor = Parliament1812Theme.reputationUpColor;
    } else if (reputation > 30) {
      barColor = Parliament1812Theme.gold;
    } else {
      barColor = Parliament1812Theme.reputationDownColor;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor:
                  Parliament1812Theme.lightBrown.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        );
      },
    );
  }
}
