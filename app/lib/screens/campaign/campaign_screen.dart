import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';
import '../../services/stamina_service.dart';
import '../../widgets/stamina_bar.dart';

/// 故事戰役地圖畫面
/// 顯示 5 章節的列表，包含已完成/鎖定/可玩的狀態
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  // 章節資料（本地定義）
  final List<_ChapterData> _chapters = [
    _ChapterData(
      id: 1,
      title: '議會新手',
      subtitle: 'Easy',
      description: '你第一次踏入議會大廳，一切都是新的。\n學習基本的政治運作，結交你的第一個盟友。',
      icon: Icons.school,
      color: const Color(0xFF4CAF50),
      introText: '1812年，英國議會。\n\n'
          '工業革命的浪潮席捲全國，新機器取代了手工勞動。\n'
          '你，一個新晉議員，踏入了這座古老的議會大廳。\n\n'
          '歡迎來到國會風雲。',
      rewards: '🎁 50 寶石 · 🏅 新手議員',
      gemCost: 0,
      isUnlocked: true,
      isCompleted: false,
    ),
    _ChapterData(
      id: 2,
      title: '政治風暴',
      subtitle: 'Normal',
      description: '議會中的黨派紛爭加劇。\n引入聯盟機制，學會在合縱連橫中生存。',
      icon: Icons.groups,
      color: const Color(0xFFFF9800),
      introText: '議會中的黨派紛爭日益激烈。\n\n'
          '工人派、資方派、改革派——每個陣營都在爭奪控制權。\n'
          '用你手中有限的牌，證明你值得留在這個舞台上。',
      rewards: '🎁 100 寶石 · 🏅 黨派鬥士',
      gemCost: 0,
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 3,
      title: '工業革命',
      subtitle: 'Hard',
      description: '工人與工廠主的激烈對決。\n在資源匱乏的困境中做出艱難選擇。',
      icon: Icons.trending_up,
      color: const Color(0xFF2196F3),
      introText: '蒸汽機的轟鳴聲迴盪在整個城市。\n\n'
          '工廠主們追求利潤最大化，工人們爭取基本權益。\n'
          '你必須在這場博弈中找到自己的位置。',
      rewards: '🎁 150 寶石 · 🏅 工業先鋒',
      gemCost: 50,
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 4,
      title: '改革之路',
      subtitle: 'Hard',
      description: '多方博弈，每個選擇都至關重要。\n聯盟、背叛、妥協——政治的真諦。',
      icon: Icons.warning_amber,
      color: const Color(0xFFF44336),
      introText: '改革的呼聲越來越高。\n\n'
          '保守派死守舊制，改革派推動變革。\n'
          '在這個多方博弈的漩渦中，你的每個選擇都將改變歷史。',
      rewards: '🎁 200 寶石 · 🏅 改革先驅',
      gemCost: 100,
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 5,
      title: '彼得盧之役',
      subtitle: 'Expert',
      description: '終極挑戰。\n全規則、Expert AI。\n這是你的最終審判。',
      icon: Icons.emoji_events,
      color: const Color(0xFFD4AF37),
      introText: '一切都在這一刻。\n\n'
          '彼得盧廣場的血腥鎮壓震驚了全國。\n'
          '議會內外的風暴即將到達頂峰。\n\n'
          '準備好了嗎？這是你的最終審判。',
      rewards: '🎁 500 寶石 · 🏅 議會之王',
      gemCost: 200,
      isUnlocked: false,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        title: const Text('故事戰役'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: Column(
          children: [
            // 行動力顯示
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StaminaBar(),
            ),

            // 登入提示（訪客模式）
            if (!authState.isAuthenticated)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3)),
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isLast = index == _chapters.length - 1;

                  return Column(
                    children: [
                      _ChapterCard(
                        chapter: chapter,
                        onTap: chapter.isUnlocked
                            ? () => _showChapterDetail(chapter)
                            : null,
                      ),
                      if (!isLast)
                        _ConnectionLine(
                          isCompleted: chapter.isCompleted,
                          color: chapter.color,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterDetail(_ChapterData chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChapterDetailSheet(
        chapter: chapter,
        onStart: () {
          Navigator.pop(ctx);
          _startChapter(chapter);
        },
      ),
    );
  }

  void _startChapter(_ChapterData chapter) async {
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

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final campaignNotifier = ref.read(campaignProvider.notifier);
    final result = await campaignNotifier.startChapter(
      chapter: chapter.id,
    );

    // Dismiss loading
    if (mounted) Navigator.of(context).pop();

    if (result != null && mounted) {
      ref
          .read(singlePlayerProvider.notifier)
          .setGameState(result.state, result.sessionId);
      context.go('/single-player/game');
    } else if (mounted) {
      // 退還行動力
      await staminaService.purchase(StaminaService.costCampaign, 0);
      ref.invalidate(currentStaminaProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法開始戰役，請稍後再試。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ============================================================
// Chapter Card
// ============================================================

class _ChapterCard extends StatelessWidget {
  final _ChapterData chapter;
  final VoidCallback? onTap;

  const _ChapterCard({required this.chapter, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = !chapter.isUnlocked;

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              // 章節標題列
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: chapter.color.withValues(alpha: 0.12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: chapter.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : chapter.icon,
                        color: chapter.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '第 ${chapter.id} 章',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: chapter.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            chapter.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 狀態標籤
                    if (chapter.isCompleted)
                      Chip(
                        label: const Text('✅ 完成'),
                        backgroundColor:
                            Colors.green.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    else if (chapter.isUnlocked)
                      Chip(
                        label: const Text('▶ 可玩'),
                        backgroundColor:
                            chapter.color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: chapter.color,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      Chip(
                        label: Text(chapter.gemCost > 0
                            ? '💎 ${chapter.gemCost}'
                            : '🔒 鎖定'),
                        backgroundColor:
                            Colors.grey.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),

              // 描述 + 難度
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
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: chapter.color),
                        const SizedBox(width: 4),
                        Text(
                          '難度：${chapter.subtitle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: chapter.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.bolt,
                            size: 14, color: Colors.amber),
                        Text(
                          ' ${StaminaService.costCampaign}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          chapter.rewards,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Connection Line
// ============================================================

class _ConnectionLine extends StatelessWidget {
  final bool isCompleted;
  final Color color;

  const _ConnectionLine({required this.isCompleted, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Center(
        child: Container(
          width: 3,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? color.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Chapter Detail Sheet
// ============================================================

class _ChapterDetailSheet extends StatelessWidget {
  final _ChapterData chapter;
  final VoidCallback onStart;

  const _ChapterDetailSheet({
    required this.chapter,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // 拖曳把手
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 標題
              Row(
                children: [
                  Icon(chapter.icon, color: chapter.color, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第 ${chapter.id} 章',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: chapter.color,
                        ),
                      ),
                      Text(
                        chapter.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 過場文字
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chapter.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: chapter.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  chapter.introText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 行動力消耗提示
              Row(
                children: [
                  const Icon(Icons.bolt, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '消耗 ${StaminaService.costCampaign} 行動力',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 獎勵
              Row(
                children: [
                  const Icon(Icons.card_giftcard, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '完成獎勵：${chapter.rewards}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 開始按鈕
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  chapter.isCompleted ? '重新挑戰' : '開始挑戰',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: chapter.color,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// Data Model
// ============================================================

class _ChapterData {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String introText;
  final String rewards;
  final int gemCost;
  final bool isUnlocked;
  final bool isCompleted;

  const _ChapterData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.introText,
    required this.rewards,
    required this.gemCost,
    required this.isUnlocked,
    required this.isCompleted,
  });
}
