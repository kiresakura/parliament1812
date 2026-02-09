import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/friends_provider.dart';
import '../providers/quests_provider.dart';
import '../services/audio_service.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 播放主選單 BGM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBgm(BgmType.menu);
    });

    return Scaffold(
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // 標題
                        Column(
                          children: [
                            Text(
                              '1812',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '國會風雲',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '政治角力與卡牌策略',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // 主選單
                        _MenuButton(
                          icon: Icons.play_circle_fill,
                          title: '快速匹配',
                          subtitle: '立即開始一局遊戲',
                          onPressed: () => context.go('/rooms'),
                        ),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.group,
                          title: '房間列表',
                          subtitle: '加入或創建房間',
                          onPressed: () => context.go('/rooms'),
                        ),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.leaderboard,
                          title: '排行榜',
                          subtitle: '查看全球排名與 ELO 評分',
                          onPressed: () => context.go('/rankings'),
                        ),
                        const SizedBox(height: 12),
                        _QuestMenuButton(ref: ref),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.collections_bookmark,
                          title: '卡牌圖鑑',
                          subtitle: '收藏圖鑑與成就系統',
                          onPressed: () => context.go('/codex'),
                        ),
                        const SizedBox(height: 12),
                        _FriendsMenuButton(ref: ref),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.school,
                          title: '遊戲教學',
                          subtitle: '學習遊戲規則與策略',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TutorialScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // 設定
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/settings'),
                            icon: const Icon(Icons.settings),
                            label: const Text('設定'),
                          ),
                        ),

                        const Spacer(),

                        // 版本
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              'Parliament 1812 v1.0.0 — M6',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Menu Button
// ============================================================

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Quest Menu Button (with badge)
// ============================================================

class _QuestMenuButton extends ConsumerWidget {
  final WidgetRef ref;

  const _QuestMenuButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questState = ref.watch(questsProvider);
    final pendingCount = questState.pendingCount;

    return Card(
      child: InkWell(
        onTap: () => GoRouter.of(context).go('/quests'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每日任務', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '完成任務獲取獎勵',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Friends Menu Button (with badge)
// ============================================================

class _FriendsMenuButton extends ConsumerWidget {
  final WidgetRef ref;

  const _FriendsMenuButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pendingCount = ref.watch(pendingFriendCountProvider);

    return Card(
      child: InkWell(
        onTap: () => GoRouter.of(context).go('/friends'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.people, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('好友', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '管理好友與對戰邀請',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Card Catalog Screen (卡牌圖鑒)
// ============================================================

class CardCatalogScreen extends StatelessWidget {
  const CardCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = _allCards;

    return Scaffold(
      appBar: AppBar(title: const Text('卡牌圖鑒')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(card.icon, color: card.color, size: 22),
                ),
              ),
              title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(card.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.type, style: theme.textTheme.labelSmall?.copyWith(color: card.color)),
                  if (card.cost > 0)
                    Text('⚡${ card.cost}', style: theme.textTheme.labelSmall),
                ],
              ),
              onTap: () => _showCardDetail(context, card),
            ),
          );
        },
      ),
    );
  }

  void _showCardDetail(BuildContext context, _CardData card) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card.icon, color: card.color, size: 32),
                const SizedBox(width: 12),
                Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            Chip(label: Text(card.type), backgroundColor: card.color.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text(card.description),
            if (card.cost > 0) ...[
              const SizedBox(height: 8),
              Text('影響力消耗：${card.cost}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (card.value > 0) ...[
              const SizedBox(height: 4),
              Text('效果值：${card.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (card.role != null) ...[
              const SizedBox(height: 4),
              Text('專屬角色：${card.role}', style: TextStyle(color: card.color)),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tutorial Screen (遊戲教學)
// ============================================================

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('遊戲教學')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TutorialSection(
            icon: Icons.info_outline,
            title: '遊戲簡介',
            content: '1812 國會風雲是一款以英國國會為背景的卡牌策略遊戲。'
                '4 名玩家分別扮演不同陣營的角色，透過質詢、辯論、結盟與投票，爭奪政治影響力。',
          ),
          _TutorialSection(
            icon: Icons.loop,
            title: '遊戲流程',
            content: '每回合分為三個階段：\n\n'
                '🤝 密謀階段（120秒）\n'
                '私下協商，決定結盟或背叛。\n\n'
                '⚔️ 辯論階段（300秒）\n'
                '出卡攻擊、防禦、使用技能。消耗影響力和金幣。\n\n'
                '🗳️ 投票階段（60秒）\n'
                '對當回合議案投支持或反對票。',
          ),
          _TutorialSection(
            icon: Icons.casino,
            title: '卡牌系統',
            content: '開局發 6 張手牌，每回合自動抽 1 張。\n\n'
                '🗡️ 攻擊卡 — 對目標造成聲望傷害\n'
                '🛡️ 防禦卡 — 抵消攻擊\n'
                '🔧 功能卡 — 恢復聲望或特殊效果\n'
                '⭐ 專屬卡 — 角色獨有的強力卡牌',
          ),
          _TutorialSection(
            icon: Icons.people,
            title: '角色介紹',
            content: '🔨 工人湯瑪斯 — 初始聲望 70，技能：團結\n'
                '🏭 工廠主理查 — 初始聲望 60，技能：收買\n'
                '📰 記者愛德華 — 初始聲望 50，技能：爆料\n'
                '🔥 盧德派喬治 — 初始聲望 80，技能：怒火',
          ),
          _TutorialSection(
            icon: Icons.emoji_events,
            title: '勝利條件',
            content: '聲望歸零 = 政治死亡（淘汰）。\n'
                '存活到最後、聲望最高的玩家獲勝。\n'
                '投票結果會影響所有人的聲望和資源。',
          ),
        ],
      ),
    );
  }
}

class _TutorialSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _TutorialSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Card Data
// ============================================================

class _CardData {
  final String name;
  final String description;
  final String type;
  final IconData icon;
  final Color color;
  final int cost;
  final int value;
  final String? role;

  const _CardData({
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    this.cost = 0,
    this.value = 0,
    this.role,
  });
}

const _allCards = [
  _CardData(name: '質詢', description: '對目標議員提出尖銳質詢，造成 15 點聲望傷害。', type: '攻擊', icon: Icons.gavel, color: Colors.red, cost: 3, value: 15),
  _CardData(name: '反駁', description: '抵消一次針對你的質詢攻擊。', type: '防禦', icon: Icons.shield, color: Colors.blue, cost: 2),
  _CardData(name: '揭露醜聞', description: '揭露目標的不光彩過去，造成 25 點聲望傷害。', type: '攻擊', icon: Icons.newspaper, color: Colors.red, cost: 5, value: 25),
  _CardData(name: '背書', description: '公開支持目標議員，恢復 20 點聲望。', type: '功能', icon: Icons.thumb_up, color: Colors.green, cost: 4, value: 20),
  _CardData(name: '團結', description: '每有 1 名工人盟友，防禦效果 +10。', type: '專屬', icon: Icons.handshake, color: Colors.amber, cost: 3, value: 10, role: '工人湯瑪斯'),
  _CardData(name: '收買', description: '花費 30 金幣使目標沉默 1 回合。', type: '專屬', icon: Icons.monetization_on, color: Colors.amber, cost: 2, role: '工廠主理查'),
  _CardData(name: '爆料', description: '揭露目標的秘密任務。', type: '專屬', icon: Icons.campaign, color: Colors.amber, cost: 4, role: '記者愛德華'),
  _CardData(name: '怒火', description: '造成 30 點傷害，但自己也扣 10 聲望。', type: '專屬', icon: Icons.local_fire_department, color: Colors.amber, cost: 4, value: 30, role: '盧德派喬治'),
];
