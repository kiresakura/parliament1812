import 'package:flutter/material.dart';

import '../../providers/quests_provider.dart';

/// 單一任務卡片 Widget
///
/// 顯示任務名稱、描述、進度條、獎勵與領取按鈕。
class QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final VoidCallback? onClaim;

  const QuestCard({
    super.key,
    required this.quest,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressRatio = quest.target > 0 ? quest.progress / quest.target : 0.0;
    final clampedRatio = progressRatio.clamp(0.0, 1.0);

    // 狀態顏色
    final Color statusColor;
    final String statusText;
    if (quest.claimed) {
      statusColor = Colors.grey;
      statusText = '已領取';
    } else if (quest.completed) {
      statusColor = const Color(0xFF4CAF50);
      statusText = '可領取';
    } else {
      statusColor = theme.colorScheme.secondary;
      statusText = '${quest.progress}/${quest.target}';
    }

    // 獎勵圖標
    final IconData rewardIcon;
    final Color rewardColor;
    switch (quest.reward.type) {
      case 'gems':
        rewardIcon = Icons.diamond;
        rewardColor = const Color(0xFF9C27B0);
        break;
      case 'card_pack':
        rewardIcon = Icons.card_giftcard;
        rewardColor = const Color(0xFF2196F3);
        break;
      case 'exp_boost':
        rewardIcon = Icons.trending_up;
        rewardColor = const Color(0xFF4CAF50);
        break;
      default: // gold
        rewardIcon = Icons.monetization_on;
        rewardColor = const Color(0xFFD4AF37);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quest.claimed
              ? Colors.grey.withValues(alpha: 0.3)
              : quest.completed
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: quest.completed && !quest.claimed ? 2 : 1,
        ),
        color: theme.cardTheme.color,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                // 任務圖標
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _questIcon(quest.questId),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 名稱 + 描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: quest.claimed ? TextDecoration.lineThrough : null,
                          color: quest.claimed
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // 獎勵
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rewardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rewardIcon, color: rewardColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        quest.reward.display,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: rewardColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 進度條
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: clampedRatio),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            quest.claimed
                                ? Colors.grey
                                : quest.completed
                                    ? const Color(0xFF4CAF50)
                                    : theme.colorScheme.secondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 狀態 / 領取按鈕
                if (quest.completed && !quest.claimed)
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('領取'),
                    ),
                  )
                else
                  Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 根據任務 ID 選擇圖標
  IconData _questIcon(String questId) {
    switch (questId) {
      case 'play_games':
        return Icons.sports_esports;
      case 'win_games':
        return Icons.emoji_events;
      case 'play_as_character':
        return Icons.person;
      case 'use_attack_cards':
        return Icons.gavel;
      case 'use_defense_cards':
        return Icons.shield;
      case 'vote_on_bills':
        return Icons.how_to_vote;
      case 'form_alliance':
        return Icons.handshake;
      case 'win_with_reputation':
        return Icons.star;
      case 'spectate_games':
        return Icons.visibility;
      case 'initiate_challenge':
        return Icons.record_voice_over;
      case 'successful_counter':
        return Icons.reply;
      case 'use_character_skill':
        return Icons.auto_awesome;
      case 'play_cards_in_debate':
        return Icons.style;
      case 'betray_alliance':
        return Icons.heart_broken;
      case 'vote_for_winner':
        return Icons.thumb_up;
      case 'deal_reputation_damage':
        return Icons.local_fire_department;
      case 'heal_reputation':
        return Icons.healing;
      case 'earn_gold':
        return Icons.monetization_on;
      case 'draw_cards':
        return Icons.add_card;
      case 'survive_to_end':
        return Icons.security;
      default:
        return Icons.task_alt;
    }
  }
}
