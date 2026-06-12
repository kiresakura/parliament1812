import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/single_player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';
import '../../services/stamina_service.dart';
import '../../widgets/stamina_bar.dart';

/// 故事戰役畫面（從 single_player 路徑存取）
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('故事戰役'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: Column(
        children: [
          // 行動力顯示
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StaminaBar(),
          ),

          // 登入提示
          if (!authState.isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '訪客模式：進度僅存在本地',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 章節列表
          Expanded(
            child: chapters.isEmpty
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
          ),
        ],
      ),
    );
  }

  Future<void> _startChapter(CampaignChapter chapter) async {
    if (!chapter.isUnlocked && !chapter.isFree) {
      _showUnlockDialog(chapter);
      return;
    }

    // 檢查行動力
    final staminaService = ref.read(staminaServiceProvider);
    await staminaService.init();
    final current = await staminaService.currentStamina;

    if (current < StaminaService.costCampaign) {
      if (!mounted) return;
      final purchased = await showStaminaInsufficientDialog(
        context,
        ref,
        cost: StaminaService.costCampaign,
        current: current,
      );
      if (!purchased) return;
    }

    // 消耗行動力
    final consumed =
        await staminaService.consume(StaminaService.costCampaign);
    if (!consumed) return;
    ref.invalidate(currentStaminaProvider);

    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);

    // 顯示 loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref.read(campaignProvider.notifier).startChapter(
          chapter: chapter.chapter,
          stage: chapter.stagesCompleted + 1,
        );

    // 關閉 loading
    if (!mounted) return;
    Navigator.of(context).pop();

    if (result != null) {
      ref
          .read(singlePlayerProvider.notifier)
          .setGameState(result.state, result.sessionId);
      if (!mounted) return;
      context.go('/single-player/game');
    } else {
      // 退還行動力
      await staminaService.purchase(StaminaService.costCampaign, 0);
      ref.invalidate(currentStaminaProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無法開始「${chapter.title}」，請稍後再試。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
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
                      const SizedBox(width: 12),
                      const Icon(Icons.bolt, size: 14, color: Colors.amber),
                      Text(
                        ' ${StaminaService.costCampaign}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber,
                        ),
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
