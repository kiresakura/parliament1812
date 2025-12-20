import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 階段指示器元件
class PhaseIndicator extends StatelessWidget {
  final int currentPhase;
  final String phaseName;

  const PhaseIndicator({
    super.key,
    required this.currentPhase,
    required this.phaseName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.secondaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '階段 $currentPhase / 12',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phaseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentPhase / 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
