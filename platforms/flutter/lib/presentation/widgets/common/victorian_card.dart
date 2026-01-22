import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 維多利亞風格卡片
class VictorianCard extends StatelessWidget {
  /// 子元件
  final Widget child;

  /// 內邊距
  final EdgeInsets padding;

  /// 是否有金色邊框
  final bool hasBorder;

  /// 邊框顏色
  final Color? borderColor;

  /// 點擊回調
  final VoidCallback? onTap;

  /// 是否選中
  final bool isSelected;

  const VictorianCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.hasBorder = true,
    this.borderColor,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ??
        (isSelected ? AppTheme.accent : AppTheme.accent.withAlpha(77));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(
                  color: effectiveBorderColor,
                  width: isSelected ? 2 : 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (isSelected)
              BoxShadow(
                color: AppTheme.accent.withAlpha(51),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 維多利亞風格裝飾邊框
class VictorianBorder extends StatelessWidget {
  /// 子元件
  final Widget child;

  /// 邊框顏色
  final Color color;

  /// 邊框寬度
  final double width;

  const VictorianBorder({
    super.key,
    required this.child,
    this.color = AppTheme.accent,
    this.width = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: width),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
