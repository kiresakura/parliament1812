// 1812 國會風雲 - 教學提示氣泡
//
// 提供帶箭頭的說明文字氣泡和動畫效果

import 'package:flutter/material.dart';

/// 箭頭方向
enum ArrowDirection {
  none,
  up,
  down,
  left,
  right,
}

/// 教學提示氣泡
class TutorialTooltip extends StatefulWidget {
  /// 標題
  final String title;

  /// 說明文字
  final String description;

  /// 當前步驟
  final int currentStep;

  /// 總步驟數
  final int totalSteps;

  /// 是否顯示提示
  final bool showHint;

  /// 提示文字
  final String? hintText;

  /// 是否為第一步
  final bool isFirstStep;

  /// 是否為最後一步
  final bool isLastStep;

  /// 是否正在演示中
  final bool isDemonstrating;

  /// 演示進度
  final double demoProgress;

  /// 下一步回調
  final VoidCallback? onNext;

  /// 上一步回調
  final VoidCallback? onPrevious;

  /// 跳過回調
  final VoidCallback? onSkip;

  /// 箭頭方向
  final ArrowDirection arrowDirection;

  const TutorialTooltip({
    super.key,
    required this.title,
    required this.description,
    this.currentStep = 1,
    this.totalSteps = 1,
    this.showHint = false,
    this.hintText,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.isDemonstrating = false,
    this.demoProgress = 0.0,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.arrowDirection = ArrowDirection.none,
  });

  @override
  State<TutorialTooltip> createState() => _TutorialTooltipState();
}

class _TutorialTooltipState extends State<TutorialTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 浮動動畫
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上方箭頭
          if (widget.arrowDirection == ArrowDirection.up)
            _buildArrow(ArrowDirection.up),

          // 主體氣泡
          _buildBubble(),

          // 下方箭頭
          if (widget.arrowDirection == ArrowDirection.down)
            _buildArrow(ArrowDirection.down),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題欄
          _buildHeader(),

          // 分隔線
          Container(
            height: 1,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          ),

          // 內容
          _buildContent(),

          // 分隔線
          Container(
            height: 1,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          ),

          // 底部按鈕
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          // 標題
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 步驟指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '${widget.currentStep}/${widget.totalSteps}',
              style: TextStyle(
                color: const Color(0xFFE8E8E8).withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 說明文字
          Text(
            widget.description,
            style: const TextStyle(
              color: Color(0xFFE8E8E8),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // 提示
          if (widget.showHint && widget.hintText != null) ...[
            const SizedBox(height: 12),
            _buildHint(),
          ],

          // 演示進度條
          if (widget.isDemonstrating) ...[
            const SizedBox(height: 12),
            _buildDemoProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.hintText!,
              style: TextStyle(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFD4AF37),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '演示中...',
              style: TextStyle(
                color: const Color(0xFFE8E8E8).withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.demoProgress,
            backgroundColor: const Color(0xFF16213E),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFD4AF37),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 跳過按鈕
          if (widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA0A0A0),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('跳過'),
            ),

          const Spacer(),

          // 進度指示點
          _buildProgressDots(),

          const Spacer(),

          // 上一步按鈕
          if (!widget.isFirstStep && widget.onPrevious != null)
            TextButton(
              onPressed: widget.onPrevious,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE8E8E8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('上一步'),
            ),

          const SizedBox(width: 8),

          // 下一步/完成按鈕
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.totalSteps, (index) {
        final isActive = index == widget.currentStep - 1;
        final isCompleted = index < widget.currentStep - 1;

        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFFD4AF37)
                : isCompleted
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                    : const Color(0xFF16213E),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    final isDisabled = widget.onNext == null;
    final buttonText = widget.isLastStep ? '完成' : '下一步';

    return ElevatedButton(
      onPressed: isDisabled ? null : widget.onNext,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDisabled ? const Color(0xFF16213E) : const Color(0xFFD4AF37),
        foregroundColor:
            isDisabled ? const Color(0xFFA0A0A0) : const Color(0xFF1A1A2E),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isDisabled ? 0 : 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(buttonText),
          if (!widget.isLastStep) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildArrow(ArrowDirection direction) {
    return CustomPaint(
      size: const Size(24, 12),
      painter: _ArrowPainter(
        direction: direction,
        color: const Color(0xFFD4AF37),
      ),
    );
  }
}

/// 箭頭繪製器
class _ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;

  _ArrowPainter({
    required this.direction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case ArrowDirection.up:
        path.moveTo(size.width / 2, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.close();
        break;

      case ArrowDirection.down:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width / 2, size.height);
        path.close();
        break;

      case ArrowDirection.left:
        path.moveTo(0, size.height / 2);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.close();
        break;

      case ArrowDirection.right:
        path.moveTo(size.width, size.height / 2);
        path.lineTo(0, 0);
        path.lineTo(0, size.height);
        path.close();
        break;

      case ArrowDirection.none:
        return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}

/// 脈衝動畫裝飾器
class PulsingDecoration extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final Duration duration;

  const PulsingDecoration({
    super.key,
    required this.child,
    this.pulseColor = const Color(0xFFD4AF37),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsingDecoration> createState() => _PulsingDecorationState();
}

class _PulsingDecorationState extends State<PulsingDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.pulseColor.withValues(
                  alpha: (1 - _animation.value) * 0.5,
                ),
                blurRadius: 10 + _animation.value * 20,
                spreadRadius: _animation.value * 10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 手指點擊動畫
class TapFingerAnimation extends StatefulWidget {
  final Offset position;
  final double size;

  const TapFingerAnimation({
    super.key,
    required this.position,
    this.size = 48,
  });

  @override
  State<TapFingerAnimation> createState() => _TapFingerAnimationState();
}

class _TapFingerAnimationState extends State<TapFingerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.7),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.7),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - widget.size / 2,
      top: widget.position.dy - widget.size / 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: Icon(
          Icons.touch_app,
          size: widget.size,
          color: const Color(0xFFD4AF37),
        ),
      ),
    );
  }
}
