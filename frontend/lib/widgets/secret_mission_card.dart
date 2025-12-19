import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/player.dart';

/// 秘密任務卡元件 - 火漆密封風格
class SecretMissionCard extends StatelessWidget {
  final SecretMission mission;

  const SecretMissionCard({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.waxSealColor.withValues(alpha: 0.15),
            AppTheme.cardBackground,
            AppTheme.waxSealColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.waxSealColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.waxSealColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 標題區 - 帶有蠟封圖示
          _buildHeader(),
          // 內容區
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任務標題
                _buildMissionTitle(),
                const SizedBox(height: 16),
                // 裝飾分隔線
                _buildDivider(),
                const SizedBox(height: 16),
                // 任務描述
                _buildDescription(),
                // 成功條件
                if (mission.successCondition != null &&
                    mission.successCondition!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSuccessCondition(),
                ],
                // 警告提示
                const SizedBox(height: 20),
                _buildWarning(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.waxSealColor.withValues(alpha: 0.3),
            AppTheme.waxSealColor.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          // 蠟封圖示
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.waxSealColor,
                  AppTheme.waxSealColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // 標題
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '密函',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.waxSealColor,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'SECRET MISSION',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.waxSealColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // 分數標籤
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor,
                  AppTheme.candleGlow,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.candleGlow.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: AppTheme.darkBackground,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${mission.points}',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.darkBackground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.waxSealColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            mission.title,
            style: AppTheme.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.waxSealColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.auto_awesome,
            size: 14,
            color: AppTheme.waxSealColor.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.waxSealColor.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.waxSealColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        mission.description,
        style: AppTheme.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.7,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildSuccessCondition() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.workerColor.withValues(alpha: 0.15),
            AppTheme.workerColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.workerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.workerColor.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: AppTheme.workerColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '達成條件',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.workerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mission.successCondition!,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ludditeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.ludditeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off,
            color: AppTheme.ludditeColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '此密函僅閣下可見，切勿讓他人知曉',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.ludditeColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .fadeIn()
        .then(delay: 2000.ms)
        .shimmer(
          duration: 2000.ms,
          color: AppTheme.ludditeColor.withValues(alpha: 0.3),
        );
  }
}
