import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 故事戰役地圖畫面
/// 顯示 5 章節的列表，包含已完成/鎖定/可玩的狀態
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  // 章節資料（本地定義，與後端同步）
  final List<_ChapterData> _chapters = [
    _ChapterData(
      id: 1,
      title: '初入議會',
      subtitle: 'Easy',
      description: '你第一次踏入議會大廳，一切都是新的。\n學習基本的政治運作，結交你的第一個盟友。',
      icon: Icons.school,
      color: const Color(0xFF4CAF50),
      introText: '1812年，英國議會。\n\n'
          '工業革命的浪潮席捲全國，新機器取代了手工勞動。\n'
          '你，一個新晉議員，踏入了這座古老的議會大廳。\n\n'
          '歡迎來到國會風雲。',
      rewards: '🎁 50 寶石 · 🏅 新手議員',
      isUnlocked: true,
      isCompleted: false,
    ),
    _ChapterData(
      id: 2,
      title: '黨派之爭',
      subtitle: 'Easy → Normal',
      description: '議會中的黨派紛爭加劇。\n你只能使用基本卡牌，學會在限制中尋找機會。',
      icon: Icons.groups,
      color: const Color(0xFFFF9800),
      introText: '議會中的黨派紛爭日益激烈。\n\n'
          '工人派、資方派、改革派——每個陣營都在爭奪控制權。\n'
          '用你手中有限的牌，證明你值得留在這個舞台上。',
      rewards: '🎁 100 寶石 · 🏅 黨派鬥士',
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 3,
      title: '預算風暴',
      subtitle: 'Normal',
      description: '國家預算案引發激烈辯論。\n時間緊迫，你必須在更短的時限內做出決策。',
      icon: Icons.trending_up,
      color: const Color(0xFF2196F3),
      introText: '年度預算案擺在議會面前。\n\n'
          '軍費、社會福利、工業補貼——每一項都關係到千萬人的命運。\n'
          '而時間不等人，預算必須在期限前通過。',
      rewards: '🎁 150 寶石 · 🏅 預算專家',
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 4,
      title: '彈劾危機',
      subtitle: 'Normal → Hard',
      description: '你面臨彈劾威脅。\n兩個 AI 聯手對付你，你必須在逆境中求生。',
      icon: Icons.warning_amber,
      color: const Color(0xFFF44336),
      introText: '噩耗傳來。\n\n'
          '工廠主理查和盧德派喬治——這兩個本應水火不容的勢力，\n'
          '竟然聯手對你發動了彈劾。\n\n'
          '以一敵二，你能否在這場政治風暴中存活？',
      rewards: '🎁 200 寶石 · 🏅 不倒翁',
      isUnlocked: false,
      isCompleted: false,
    ),
    _ChapterData(
      id: 5,
      title: '最終表決',
      subtitle: 'Hard',
      description: '最後的決戰。\n全規則、困難 AI、加上隨機特殊事件。\n這是你的終極挑戰。',
      icon: Icons.emoji_events,
      color: const Color(0xFFD4AF37),
      introText: '一切都在這一刻。\n\n'
          '《機器法案》的最終表決即將開始。\n'
          '這一票，將決定工人的未來、工業的走向、整個國家的命運。\n\n'
          '準備好了嗎？這是你的最終審判。',
      rewards: '🎁 500 寶石 · 🏅 議會之王',
      isUnlocked: false,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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

  void _startChapter(_ChapterData chapter) {
    // TODO: 連接到單人遊戲 session
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('開始第 ${chapter.id} 章：${chapter.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
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
                        backgroundColor: chapter.color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: chapter.color,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      Chip(
                        label: const Text('🔒 鎖定'),
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                        const Spacer(),
                        Text(
                          chapter.rewards,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
    required this.isUnlocked,
    required this.isCompleted,
  });
}
