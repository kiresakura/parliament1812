import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/achievements_provider.dart';

/// 成就列表 Widget
class AchievementsListView extends ConsumerWidget {
  const AchievementsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.achievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚無成就資料', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    // 分組：簡單 → 中等 → 困難 → 隱藏
    final groups = <String, List<Achievement>>{};
    for (final a in state.achievements) {
      groups.putIfAbsent(a.difficulty, () => []).add(a);
    }

    final orderedKeys = ['easy', 'medium', 'hard', 'hidden'];
    final groupNames = {
      'easy': '🟢 簡單',
      'medium': '🟡 中等',
      'hard': '🔴 困難',
      'hidden': '🟣 隱藏',
    };

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 總進度
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                '${state.completedCount}/${state.totalCount} 已完成',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              if (state.unclaimedCount > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.unclaimedCount} 待領取',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        for (final key in orderedKeys)
          if (groups.containsKey(key)) ...[
            _SectionHeader(title: groupNames[key] ?? key),
            ...groups[key]!.map((a) => _AchievementTile(achievement: a)),
          ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _AchievementTile extends ConsumerWidget {
  final Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = achievement;
    final isHiddenLocked = a.isHidden && !a.completed;
    final progressPercent = a.progressPercent;

    Color statusColor;
    if (a.claimed) {
      statusColor = Colors.green;
    } else if (a.completed) {
      statusColor = Colors.amber;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 狀態圖示
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      a.claimed
                          ? Icons.check_circle
                          : a.completed
                              ? Icons.card_giftcard
                              : isHiddenLocked
                                  ? Icons.help_outline
                                  : Icons.emoji_events_outlined,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 名稱 + 描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHiddenLocked ? '🏆 ???' : a.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: a.completed ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHiddenLocked ? '隱藏成就 — 達成特殊條件解鎖' : a.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 領取按鈕
                  if (a.completed && !a.claimed)
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(achievementsProvider.notifier)
                            .claimReward(a.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('領取'),
                    ),
                ],
              ),

              // 進度條
              if (!a.completed && !isHiddenLocked) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(statusColor.withValues(alpha: 0.7)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${a.progress}/${a.target}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    final a = achievement;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F2F2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),

            // 獎勵列表
            const Text('獎勵', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...a.rewards.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        r.type == 'gold'
                            ? Icons.monetization_on
                            : r.type == 'unlock_card'
                                ? Icons.style
                                : Icons.badge,
                        size: 16,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Text(r.displayText, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),

            const SizedBox(height: 16),
            if (a.completed && !a.claimed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(achievementsProvider.notifier).claimReward(a.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('領取獎勵'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
