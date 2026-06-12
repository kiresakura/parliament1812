import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/quests_provider.dart';
import '../services/audio_service.dart';
import '../services/performance_service.dart';
import '../config/theme.dart';
import '../ui/theme/game_colors.dart' as gc;
import '../ui/theme/game_fonts.dart';
import '../widgets/stamina_bar.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 播放主選單 BGM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBgm(BgmType.menu);
    });

    final config = ref.watch(qualityConfigProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // 低品質：純色替代漸層
          color: !config.enableGradients ? gc.GameColors.bgPrimary : null,
          gradient: config.enableGradients
              ? gc.GameColors.bgGradient
              : null,
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

                        // 標題 — 維多利亞金
                        Column(
                          children: [
                            Text(
                              '1812',
                              style: GameFont.gameTitle.copyWith(
                                color: gc.GameColors.victorianGold,
                                fontSize: 56,
                                shadows: [
                                  Shadow(
                                    color: gc.GameColors.goldDim,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '國會風雲',
                              style: GameFont.sectionTitle.copyWith(
                                color: gc.GameColors.victorianGold,
                                fontSize: 28,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '政治角力與卡牌策略',
                              style: GameFont.billBody.copyWith(
                                color: gc.GameColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 用戶資訊區
                        _UserInfoBanner(ref: ref),

                        const SizedBox(height: 12),

                        // 行動力顯示
                        const StaminaBar(),

                        const SizedBox(height: 24),

                        // 主選單
                        _MenuButton(
                          icon: Icons.play_circle_fill,
                          title: '快速匹配',
                          subtitle: '立即開始一局遊戲',
                          onPressed: () => context.go('/rooms'),
                        ),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.smart_toy,
                          title: 'AI 對戰',
                          subtitle: '挑戰 AI，每日 10 場免費',
                          onPressed: () => context.go('/single-player/difficulty'),
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
                          icon: Icons.auto_stories,
                          title: '故事戰役',
                          subtitle: '5 章節故事模式',
                          onPressed: () => context.go('/campaign'),
                        ),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.school,
                          title: '遊戲教學',
                          subtitle: '學習遊戲規則與策略',
                          onPressed: () => context.go('/tutorial'),
                        ),

                        const SizedBox(height: 24),

                        // 設定 & 個人檔案
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.go('/profile'),
                              icon: const Icon(Icons.person),
                              label: const Text('個人檔案'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/settings'),
                              icon: const Icon(Icons.settings),
                              label: const Text('設定'),
                            ),
                          ],
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
// User Info Banner
// ============================================================

class _UserInfoBanner extends ConsumerWidget {
  final WidgetRef ref;

  const _UserInfoBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      // 訪客模式：顯示登入提示
      return Card(
        child: InkWell(
          onTap: () => context.go('/login'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Parliament1812Theme.charcoal,
                  child: Icon(
                    Icons.account_circle,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '登入以保存進度',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Parliament1812Theme.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 已登入：顯示用戶資訊
    final elo = user.eloRating ?? 1000;
    final rankEmoji = _getRankEmoji(elo);

    return Card(
      child: InkWell(
        onTap: () => context.go('/profile'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 頭像
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Parliament1812Theme.gold.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Parliament1812Theme.charcoal,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          _getInitial(user.displayName ?? user.username),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Parliament1812Theme.gold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // 名稱 + ELO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$rankEmoji ELO $elo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Parliament1812Theme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _getRankEmoji(int elo) {
    if (elo >= 1800) return '👑';
    if (elo >= 1600) return '💠';
    if (elo >= 1400) return '💎';
    if (elo >= 1200) return '🥇';
    if (elo >= 1000) return '🥈';
    return '🥉';
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
