import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/single_player.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';

/// 故事戰役畫面
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(campaignProvider.notifier).loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapters = ref.watch(campaignProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('故事戰役'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: chapters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                return _ChapterCard(
                  chapter: chapters[index],
                  onTap: () => _startChapter(chapters[index]),
                );
              },
            ),
    );
  }

  void _startChapter(CampaignChapter chapter) {
    if (!chapter.isUnlocked && !chapter.isFree) {
      _showUnlockDialog(chapter);
      return;
    }

    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
    // TODO: Navigate to campaign game screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('開始 ${chapter.title}...')),
    );
  }

  void _showUnlockDialog(CampaignChapter chapter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('解鎖 ${chapter.title}'),
        content: Text(
          '需要 ${chapter.gemCost} 💎 寶石來解鎖此章節。\n'
          '或者購買章節解鎖包。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implement gem unlock
            },
            icon: const Text('💎'),
            label: Text('${chapter.gemCost} 寶石解鎖'),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final CampaignChapter chapter;
  final VoidCallback onTap;

  const _ChapterCard({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = !chapter.isUnlocked && !chapter.isFree;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLocked
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                ),
              ),
              child: Row(
                children: [
                  Text(
                    isLocked ? '🔒' : '📖',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '第 ${chapter.chapter} 章',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          chapter.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chapter.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '免費',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ProgressChip(
                        icon: '⭐',
                        text: '${chapter.stars}/${chapter.maxStars}',
                      ),
                      const SizedBox(width: 12),
                      _ProgressChip(
                        icon: '📋',
                        text:
                            '${chapter.stagesCompleted}/${chapter.totalStages}',
                      ),
                      const Spacer(),
                      if (isLocked)
                        Text(
                          '💎 ${chapter.gemCost}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.amber,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: chapter.totalStages > 0
                        ? chapter.stagesCompleted / chapter.totalStages
                        : 0,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String icon;
  final String text;

  const _ProgressChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
