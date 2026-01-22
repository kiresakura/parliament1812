import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// 維多利亞風格按鈕類型
enum VictorianButtonType {
  primary,   // 主按鈕：金色漸層背景
  secondary, // 次按鈕：透明背景 + 金色邊框
  danger,    // 危險按鈕：紅色
}

/// 維多利亞風格按鈕
class VictorianButton extends StatefulWidget {
  /// 按鈕文字
  final String text;

  /// 點擊回調
  final VoidCallback? onPressed;

  /// 按鈕類型
  final VictorianButtonType type;

  /// 是否載入中
  final bool isLoading;

  /// 前置圖標
  final IconData? icon;

  /// 是否填滿寬度
  final bool fullWidth;

  /// 按鈕大小
  final VictorianButtonSize size;

  const VictorianButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = VictorianButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.size = VictorianButtonSize.medium,
  });

  @override
  State<VictorianButton> createState() => _VictorianButtonState();
}

/// 按鈕尺寸
enum VictorianButtonSize {
  small,
  medium,
  large,
}

class _VictorianButtonState extends State<VictorianButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case VictorianButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case VictorianButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case VictorianButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case VictorianButtonSize.small:
        return 12;
      case VictorianButtonSize.medium:
        return 14;
      case VictorianButtonSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) => _controller.reverse(),
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: _padding,
            decoration: _buildDecoration(),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: _fontSize,
                    height: _fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTextColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: _getTextColor(),
                    size: _fontSize + 4,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: GoogleFonts.cinzel(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    switch (widget.type) {
      case VictorianButtonType.primary:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withAlpha(102),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case VictorianButtonType.secondary:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accent, width: 1.5),
        );
      case VictorianButtonType.danger:
        return BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.danger.withAlpha(102),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case VictorianButtonType.primary:
        return AppTheme.primaryDark;
      case VictorianButtonType.secondary:
        return AppTheme.accent;
      case VictorianButtonType.danger:
        return Colors.white;
    }
  }
}
