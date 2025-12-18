import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vote.dart';

/// 投票選項卡元件
class VoteOptionCard extends StatelessWidget {
  final VoteOption option;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const VoteOptionCard({
    super.key,
    required this.option,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryColor.withOpacity(0.2)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 選項標記
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.id,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppTheme.darkBackground
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 選項內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.secondaryColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // 選中圖示
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// 投票結果條元件
class VoteResultBar extends StatelessWidget {
  final String label;
  final double percentage;
  final int count;
  final bool isWinner;
  final Color? color;

  const VoteResultBar({
    super.key,
    required this.label,
    required this.percentage,
    this.count = 0,
    this.isWinner = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? (isWinner ? Colors.green : AppTheme.secondaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.green : Colors.white,
              ),
            ),
            Row(
              children: [
                if (count > 0)
                  Text(
                    '$count 票',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green : AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // 背景
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // 進度
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
