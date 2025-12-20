import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/accessibility_provider.dart';

// ==================== 無障礙與效能工具 ====================

/// 效能優化包裝器 - 自動加入 RepaintBoundary
class PerformanceWrapper extends StatelessWidget {
  final Widget child;
  final bool useRepaintBoundary;

  const PerformanceWrapper({
    super.key,
    required this.child,
    this.useRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useRepaintBoundary) {
      return RepaintBoundary(child: child);
    }
    return child;
  }
}

/// 無障礙動畫包裝器 - 當減少動畫時提供靜態替代
class AccessibleAnimation extends StatelessWidget {
  final Widget animatedChild;
  final Widget? staticChild;
  final bool forceAnimate;

  const AccessibleAnimation({
    super.key,
    required this.animatedChild,
    this.staticChild,
    this.forceAnimate = false,
  });

  @override
  Widget build(BuildContext context) {
    // 嘗試使用 Provider，如果不可用則使用靜態設定
    try {
      final accessibility = context.watch<AccessibilityProvider>();
      if (!forceAnimate && accessibility.reduceMotion) {
        return staticChild ?? animatedChild;
      }
    } catch (_) {
      // Provider 不可用時使用靜態設定
      if (!forceAnimate && AccessibilitySettings.reduceMotion) {
        return staticChild ?? animatedChild;
      }
    }
    return animatedChild;
  }
}

/// 取得適應性動畫時長
Duration getAdaptiveDuration(BuildContext context, Duration normalDuration) {
  try {
    final accessibility = context.read<AccessibilityProvider>();
    return accessibility.getAnimationDuration(normalDuration);
  } catch (_) {
    return AccessibilitySettings.animationDuration(normalDuration);
  }
}

/// 取得適應性動畫曲線
Curve getAdaptiveCurve(BuildContext context, Curve normalCurve) {
  try {
    final accessibility = context.read<AccessibilityProvider>();
    return accessibility.getAnimationCurve(normalCurve);
  } catch (_) {
    return AccessibilitySettings.animationCurve(normalCurve);
  }
}

// ==================== 維多利亞風格裝飾元件 ====================

/// 六角形徽章 (Civ 6 風格)
class HexagonBadge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? borderColor;
  final Color? fillColor;
  final Color? glowColor;

  const HexagonBadge({
    super.key,
    required this.child,
    this.size = 80,
    this.borderColor,
    this.fillColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? glowColor ?? AppTheme.accentGold;
    return Container(
      width: size,
      height: size,
      decoration: glowColor != null
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        painter: HexagonPainter(
          borderColor: effectiveBorderColor,
          fillColor: fillColor ?? AppTheme.panelBackground.withValues(alpha: 0.8),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  HexagonPainter({required this.borderColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2 - 2;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 六角形圖示
class HexagonIcon extends StatelessWidget {
  final double size;
  final bool filled;
  final Color? color;

  const HexagonIcon({
    super.key,
    this.size = 24,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HexagonIconPainter(
          filled: filled,
          color: color ?? AppTheme.accentGold,
        ),
      ),
    );
  }
}

class HexagonIconPainter extends CustomPainter {
  final bool filled;
  final Color color;

  HexagonIconPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2 - 1;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 皇冠圖示
class CrownIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CrownIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.workspace_premium,
      size: size,
      color: color ?? AppTheme.accentGold,
    );
  }
}

/// 旋轉齒輪圖示 (Civ 6 風格)
class GearIcon extends StatefulWidget {
  final double size;
  final Color? color;
  final bool spinning;

  const GearIcon({
    super.key,
    this.size = 24,
    this.color,
    this.spinning = false,
  });

  @override
  State<GearIcon> createState() => _GearIconState();
}

class _GearIconState extends State<GearIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _shouldAnimate = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _checkReduceMotion();
    if (widget.spinning && _shouldAnimate) {
      _controller.repeat();
    }
  }

  void _checkReduceMotion() {
    try {
      _shouldAnimate = !AccessibilitySettings.reduceMotion;
    } catch (_) {
      _shouldAnimate = true;
    }
  }

  @override
  void didUpdateWidget(GearIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkReduceMotion();
    if (widget.spinning && _shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!widget.spinning || !_shouldAnimate) && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.settings,
      size: widget.size,
      color: widget.color ?? AppTheme.textTertiary,
    );

    // 減少動畫模式下直接返回靜態圖示
    if (!_shouldAnimate) {
      return icon;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.spinning ? _controller.value * 2 * math.pi : 0,
          child: icon,
        );
      },
    );
  }
}

/// 維多利亞風格分隔線
class VictorianDivider extends StatelessWidget {
  final double width;
  final Color? color;

  const VictorianDivider({super.key, this.width = 200, this.color});

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppTheme.accentGold;
    return SizedBox(
      width: width,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    dividerColor.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dividerColor,
                  border: Border.all(color: dividerColor, width: 1),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    dividerColor.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 數據面板 (Victoria 3 風格)
class DataPanel extends StatelessWidget {
  final String title;
  final String value;
  final Widget? icon;
  final String? trend; // 'up', 'down', 'neutral'

  const DataPanel({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.8),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.accentGold,
                      fontSize: 16,
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trend == 'up'
                          ? Icons.arrow_upward
                          : trend == 'down'
                              ? Icons.arrow_downward
                              : Icons.remove,
                      size: 12,
                      color: trend == 'up'
                          ? AppTheme.successColor
                          : trend == 'down'
                              ? AppTheme.errorColor
                              : AppTheme.textTertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 六角形背景圖案
class HexagonPatternBackground extends StatelessWidget {
  final Color? color;
  final double opacity;

  const HexagonPatternBackground({
    super.key,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: HexagonPatternPainter(
          color: (color ?? AppTheme.accentGold).withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class HexagonPatternPainter extends CustomPainter {
  final Color color;

  HexagonPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 40.0;
    const hexWidth = hexSize * 2;
    final hexHeight = hexSize * math.sqrt(3);

    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight * 0.75) {
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth * 1.5) {
        final offsetX = ((y / (hexHeight * 0.75)).floor() % 2) * hexWidth * 0.75;
        _drawHexagon(canvas, Offset(x + offsetX, y), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 氣氛粒子效果 (更精緻的版本)
class AtmosphereParticles extends StatefulWidget {
  final int particleCount;
  final Color? color;

  const AtmosphereParticles({
    super.key,
    this.particleCount = 20,
    this.color,
  });

  @override
  State<AtmosphereParticles> createState() => _AtmosphereParticlesState();
}

class _AtmosphereParticlesState extends State<AtmosphereParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<AtmosphereParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => AtmosphereParticle.random(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式下顯示靜態替代
    return AccessibleAnimation(
      animatedChild: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: AtmosphereParticlePainter(
                particles: _particles,
                progress: _controller.value,
                color: widget.color ?? AppTheme.accentGold,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
      staticChild: CustomPaint(
        painter: AtmosphereParticlePainter(
          particles: _particles,
          progress: 0,
          color: widget.color ?? AppTheme.accentGold,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class AtmosphereParticle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double phase;

  AtmosphereParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });

  factory AtmosphereParticle.random() {
    final random = math.Random();
    return AtmosphereParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: 0.02 + random.nextDouble() * 0.05,
      size: 1 + random.nextDouble() * 2,
      opacity: 0.1 + random.nextDouble() * 0.3,
      phase: random.nextDouble() * 2 * math.pi,
    );
  }
}

class AtmosphereParticlePainter extends CustomPainter {
  final List<AtmosphereParticle> particles;
  final double progress;
  final Color color;

  AtmosphereParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y - progress * particle.speed) % 1.0;
      final flickerOpacity = particle.opacity *
          (0.7 + 0.3 * math.sin(progress * 2 * math.pi + particle.phase));

      final paint = Paint()
        ..color = color.withValues(alpha: flickerOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AtmosphereParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 角落裝飾
class CornerFlourish extends StatelessWidget {
  final double size;
  final Color? color;
  final CornerPosition position;

  const CornerFlourish({
    super.key,
    this.size = 40,
    this.color,
    this.position = CornerPosition.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    double rotation = 0;
    switch (position) {
      case CornerPosition.topLeft:
        rotation = 0;
        break;
      case CornerPosition.topRight:
        rotation = math.pi / 2;
        break;
      case CornerPosition.bottomRight:
        rotation = math.pi;
        break;
      case CornerPosition.bottomLeft:
        rotation = -math.pi / 2;
        break;
    }

    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: CornerFlourishPainter(
            color: color ?? AppTheme.accentGold,
          ),
        ),
      ),
    );
  }
}

enum CornerPosition { topLeft, topRight, bottomRight, bottomLeft }

class CornerFlourishPainter extends CustomPainter {
  final Color color;

  CornerFlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(0, 0, size.width * 0.3, 0);

    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(0, 0, size.width * 0.5, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 翻牌動畫元件
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final VoidCallback? onFlip;
  final bool autoFlip;
  final Duration autoFlipDelay;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 800),
    this.onFlip,
    this.autoFlip = false,
    this.autoFlipDelay = const Duration(seconds: 1),
  });

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    if (widget.autoFlip) {
      Future.delayed(widget.autoFlipDelay, () {
        if (mounted) flip();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_controller.isAnimating) return;
    widget.onFlip?.call();
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showFront = !_showFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < math.pi / 2
                ? widget.front
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// 火漆蠟封動畫元件
class WaxSeal extends StatefulWidget {
  final double size;
  final String? letter;
  final VoidCallback? onTap;
  final bool animate;

  const WaxSeal({
    super.key,
    this.size = 80,
    this.letter,
    this.onTap,
    this.animate = true,
  });

  @override
  State<WaxSeal> createState() => _WaxSealState();
}

class _WaxSealState extends State<WaxSeal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.waxSealColor.withValues(alpha: 0.9),
                      AppTheme.waxSealColor,
                      AppTheme.waxSealColor.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.waxSealColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.letter != null
                      ? Text(
                          widget.letter!,
                          style: AppTheme.displayMedium.copyWith(
                            color: AppTheme.parchmentColor,
                            fontSize: widget.size * 0.4,
                          ),
                        )
                      : Icon(
                          Icons.lock,
                          color: AppTheme.parchmentColor,
                          size: widget.size * 0.4,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 蠟燭光暈動畫
class CandleGlow extends StatefulWidget {
  final Widget child;
  final double intensity;
  final double? size;
  final Color? glowColor;

  const CandleGlow({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.size,
    this.glowColor,
  });

  @override
  State<CandleGlow> createState() => _CandleGlowState();
}

class _CandleGlowState extends State<CandleGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _flickerAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.glowColor ?? AppTheme.candleGlow;

    // 減少動畫模式下使用靜態光暈
    final reduceMotion = AccessibilitySettings.reduceMotion;
    if (reduceMotion) {
      Widget content = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3 * widget.intensity),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: widget.child,
      );

      if (widget.size != null) {
        content = SizedBox(
          width: widget.size,
          height: widget.size,
          child: content,
        );
      }

      return content;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _flickerAnimation,
        builder: (context, child) {
          Widget content = Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: 0.3 * _flickerAnimation.value * widget.intensity,
                  ),
                  blurRadius: 30 * _flickerAnimation.value,
                  spreadRadius: 5 * _flickerAnimation.value,
                ),
              ],
            ),
            child: widget.child,
          );

          if (widget.size != null) {
            content = SizedBox(
              width: widget.size,
              height: widget.size,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}

/// 羊皮紙展開動畫
class ParchmentReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool autoPlay;

  const ParchmentReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.autoPlay = true,
  });

  @override
  State<ParchmentReveal> createState() => _ParchmentRevealState();
}

class _ParchmentRevealState extends State<ParchmentReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// 脈動動畫元件
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _shouldAnimate = true;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !AccessibilitySettings.reduceMotion;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (_shouldAnimate) {
      _controller.repeat(reverse: true);
    }

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
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

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式下直接返回子元件
    if (!_shouldAnimate) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// 閃爍金色邊框
class GoldenShimmer extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GoldenShimmer({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  State<GoldenShimmer> createState() => _GoldenShimmerState();
}

class _GoldenShimmerState extends State<GoldenShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _shouldAnimate = true;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !AccessibilitySettings.reduceMotion;

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (_shouldAnimate) {
      _controller.repeat();
    }

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式下使用靜態邊框
    if (!_shouldAnimate) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
            ),
            child: widget.child,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value, 0),
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.3),
                  AppTheme.candleGlow.withValues(alpha: 0.8),
                  AppTheme.secondaryColor.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 打字機效果文字
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 50),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _typeNextChar();
  }

  void _typeNextChar() {
    if (_charIndex < widget.text.length) {
      Future.delayed(widget.charDuration, () {
        if (mounted) {
          setState(() {
            _displayText = widget.text.substring(0, _charIndex + 1);
            _charIndex++;
          });
          _typeNextChar();
        }
      });
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style ?? AppTheme.bodyMedium,
    );
  }
}

/// 淡入淡出頁面轉場
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

/// 滑動頁面轉場
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
              case AxisDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
            }
            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// 粒子背景效果
class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final Widget? child;

  const ParticleBackground({
    super.key,
    this.particleCount = 50,
    this.particleColor = AppTheme.secondaryColor,
    this.child,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => Particle.random(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式下顯示靜態替代
    return AccessibleAnimation(
      animatedChild: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                    color: widget.particleColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
      staticChild: Stack(
        children: [
          CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              progress: 0,
              color: widget.particleColor,
            ),
            size: Size.infinite,
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: 0.1 + random.nextDouble() * 0.3,
      size: 1 + random.nextDouble() * 3,
      opacity: 0.1 + random.nextDouble() * 0.5,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 連接線 (Civ 6 風格)
class ConnectorLine extends StatelessWidget {
  final double width;
  final Color? color;
  final String direction; // 'horizontal', 'vertical', 'diagonal'

  const ConnectorLine({
    super.key,
    this.width = 100,
    this.color,
    this.direction = 'horizontal',
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? AppTheme.accentGold;
    return SizedBox(
      width: direction == 'vertical' ? 20 : width,
      height: direction == 'vertical' ? width : 20,
      child: CustomPaint(
        painter: ConnectorLinePainter(
          color: lineColor,
          direction: direction,
        ),
      ),
    );
  }
}

class ConnectorLinePainter extends CustomPainter {
  final Color color;
  final String direction;

  ConnectorLinePainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path path = Path();
    if (direction == 'vertical') {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width / 2, size.height);
    } else if (direction == 'diagonal') {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, size.height / 2);
    }

    // Draw dashed line
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = 0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          dashPaint,
        );
        distance += dashWidth + dashSpace;
      }
    }

    // Draw center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 華麗框架
class OrnateFrame extends StatelessWidget {
  final Widget child;
  final double padding;
  final Color? flourishColor;

  const OrnateFrame({
    super.key,
    required this.child,
    this.padding = 16,
    this.flourishColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = flourishColor ?? AppTheme.accentGold.withValues(alpha: 0.4);
    return Stack(
      children: [
        // Corner flourishes
        Positioned(
          top: -8,
          left: -8,
          child: CornerFlourish(
            size: 32,
            color: color,
            position: CornerPosition.topLeft,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: CornerFlourish(
            size: 32,
            color: color,
            position: CornerPosition.topRight,
          ),
        ),
        Positioned(
          bottom: -8,
          left: -8,
          child: CornerFlourish(
            size: 32,
            color: color,
            position: CornerPosition.bottomLeft,
          ),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: CornerFlourish(
            size: 32,
            color: color,
            position: CornerPosition.bottomRight,
          ),
        ),
        // Content
        Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        ),
      ],
    );
  }
}

/// 羊皮紙紋理
class ParchmentTexture extends StatelessWidget {
  final double opacity;

  const ParchmentTexture({super.key, this.opacity = 0.1});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ParchmentTexturePainter(opacity: opacity),
        ),
      ),
    );
  }
}

class ParchmentTexturePainter extends CustomPainter {
  final double opacity;

  ParchmentTexturePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B7753).withValues(alpha: opacity * 0.3)
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical lines with lower opacity
    paint.color = const Color(0xFF8B7753).withValues(alpha: opacity * 0.2);
    for (double x = 0; x < size.width; x += 3) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 墨水印章動畫 (投票結果)
class InkStamp extends StatefulWidget {
  final String type; // 'voted', 'aye', 'nay'
  final bool show;

  const InkStamp({
    super.key,
    this.type = 'voted',
    this.show = false,
  });

  @override
  State<InkStamp> createState() => _InkStampState();
}

class _InkStampState extends State<InkStamp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 3.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(InkStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _stampColor {
    switch (widget.type) {
      case 'aye':
        return const Color(0xFF2D5A27);
      case 'nay':
        return const Color(0xFF8B2500);
      default:
        return const Color(0xFF8B7753);
    }
  }

  String get _stampText {
    switch (widget.type) {
      case 'aye':
        return 'APPROVED';
      case 'nay':
        return 'REJECTED';
      default:
        return 'RECORDED';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: -0.26, // -15 degrees
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _stampColor, width: 4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _stampText,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _stampColor,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: _stampColor.withValues(alpha: 0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏載入元件 (Shimmer Loading)
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
    this.isCircle = false,
  });

  /// 創建文字骨架
  factory SkeletonLoader.text({
    double width = 200,
    double height = 16,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// 創建圓形頭像骨架
  factory SkeletonLoader.avatar({double size = 48}) {
    return SkeletonLoader(
      width: size,
      height: size,
      isCircle: true,
    );
  }

  /// 創建卡片骨架
  factory SkeletonLoader.card({
    double width = double.infinity,
    double height = 120,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(12),
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  bool _shouldAnimate = true;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !AccessibilitySettings.reduceMotion;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (_shouldAnimate) {
      _controller.repeat();
    }

    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式下使用靜態佔位
    if (!_shouldAnimate) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : widget.borderRadius,
          color: AppTheme.cardBackground.withValues(alpha: 0.6),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(_shimmerAnimation.value - 1, 0),
                end: Alignment(_shimmerAnimation.value + 1, 0),
                colors: [
                  AppTheme.cardBackground.withValues(alpha: 0.6),
                  AppTheme.accentGold.withValues(alpha: 0.15),
                  AppTheme.cardBackground.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 骨架屏列表項目
class SkeletonListItem extends StatelessWidget {
  final bool hasAvatar;
  final int lines;

  const SkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (hasAvatar) ...[
            SkeletonLoader.avatar(size: 48),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
                  child: SkeletonLoader.text(
                    width: index == 0 ? 150 : 100,
                    height: index == 0 ? 16 : 12,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 固定底部欄按鈕
class BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isPrimary;

  const BottomBarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.accentGold
              : AppTheme.cardBackground.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.3)
                : AppTheme.accentGold.withValues(alpha: 0.3),
            width: isPrimary ? 2 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? AppTheme.primaryBackground : AppTheme.accentGold,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? AppTheme.primaryBackground : AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? AppTheme.primaryBackground : AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 固定底部操作欄
class FixedBottomBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;

  const FixedBottomBar({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }
}

/// 投票紙動畫
class BallotPaper extends StatefulWidget {
  final String option;
  final bool isSelected;
  final VoidCallback? onTap;

  const BallotPaper({
    super.key,
    required this.option,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<BallotPaper> createState() => _BallotPaperState();
}

class _BallotPaperState extends State<BallotPaper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BallotPaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.parchmentGradient,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.waxSealColor
                        : AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: widget.isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isSelected
                          ? AppTheme.waxSealColor.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: widget.isSelected ? 15 : 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.option,
                      style: AppTheme.parchmentText.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.waxSealColor,
                        size: 32,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
