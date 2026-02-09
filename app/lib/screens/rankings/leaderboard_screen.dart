import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/rankings_provider.dart';

/// 排行榜畫面
///
/// TabBar：全球排行 / 我的排名
/// 1812 主題配色 (dark red #8B0000, gold #D4AF37)
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 載入初始資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingsProvider.notifier).loadInitial();
    });

    // 無限滾動
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(rankingsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Parliament1812Theme.gold,
          labelColor: Parliament1812Theme.gold,
          unselectedLabelColor:
              Parliament1812Theme.cream.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: '全球排行', icon: Icon(Icons.public, size: 18)),
            Tab(text: '我的排名', icon: Icon(Icons.person, size: 18)),
          ],
        ),
        actions: [
          if (state.seasons.isNotEmpty)
            PopupMenuButton<int>(
              icon: const Icon(Icons.calendar_month),
              tooltip: '切換賽季',
              onSelected: (seasonId) {
                ref.read(rankingsProvider.notifier).changeSeason(seasonId);
              },
              itemBuilder: (_) => state.seasons
                  .map(
                    (s) => PopupMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          if (s.isActive)
                            const Icon(Icons.circle, size: 8, color: Colors.green)
                          else
                            const SizedBox(width: 8),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 全球排行
          _GlobalRankingsTab(
            state: state,
            scrollController: _scrollController,
          ),
          // Tab 2: 我的排名
          _MyRankingTab(state: state),
        ],
      ),
    );
  }
}

// ============================================================
// 全球排行 Tab
// ============================================================

class _GlobalRankingsTab extends StatelessWidget {
  final RankingsState state;
  final ScrollController scrollController;

  const _GlobalRankingsTab({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.rankings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Parliament1812Theme.gold),
      );
    }

    if (state.error != null && state.rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (state.rankings.isEmpty) {
      return const Center(
        child: Text('本賽季尚無排名資料', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.rankings.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.rankings.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child:
                  CircularProgressIndicator(color: Parliament1812Theme.gold),
            ),
          );
        }

        final entry = state.rankings[index];

        // TOP 3 特殊樣式
        if (entry.rank <= 3) {
          return _TopRankCard(entry: entry);
        }

        return _RankingListTile(entry: entry);
      },
    );
  }
}

// ============================================================
// TOP 3 金銀銅卡片
// ============================================================

class _TopRankCard extends StatelessWidget {
  final RankingEntry entry;

  const _TopRankCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (entry.rank) {
      1 => (const Color(0xFFFFD700), Icons.emoji_events, '🥇'),
      2 => (const Color(0xFFC0C0C0), Icons.emoji_events, '🥈'),
      3 => (const Color(0xFFCD7F32), Icons.emoji_events, '🥉'),
      _ => (Parliament1812Theme.gold, Icons.person, '#${entry.rank}'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            Parliament1812Theme.charcoal,
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.3),
              child: Text(
                entry.name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(
          '${entry.gamesPlayed} 場 | 勝率 ${entry.winRate.toStringAsFixed(1)}%',
          style: TextStyle(
            color: Parliament1812Theme.cream.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.eloRating}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'ELO',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 一般排名列表項
// ============================================================

class _RankingListTile extends StatelessWidget {
  final RankingEntry entry;

  const _RankingListTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Parliament1812Theme.charcoal,
      ),
      child: ListTile(
        dense: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      Parliament1812Theme.cream.withValues(alpha: 0.8),
                ),
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Parliament1812Theme.darkRed.withValues(alpha: 0.3),
              child: Text(
                entry.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Parliament1812Theme.cream,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.gamesPlayed} 場 | 勝率 ${entry.winRate.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: Parliament1812Theme.cream.withValues(alpha: 0.6),
          ),
        ),
        trailing: Text(
          '${entry.eloRating}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Parliament1812Theme.gold,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 我的排名 Tab
// ============================================================

class _MyRankingTab extends StatelessWidget {
  final RankingsState state;

  const _MyRankingTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final my = state.myRanking;

    if (state.isLoading && my == null) {
      return const Center(
        child: CircularProgressIndicator(color: Parliament1812Theme.gold),
      );
    }

    if (my == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 64,
                color: Parliament1812Theme.gold.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              '尚未參與排名賽',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '完成一場排名賽以獲得排名',
              style: TextStyle(
                color: Parliament1812Theme.cream.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 排名大卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B0000),
                  Color(0xFF4A0000),
                ],
              ),
              border: Border.all(
                color: Parliament1812Theme.gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Parliament1812Theme.darkRed.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 賽季名稱
                Text(
                  my.seasonName,
                  style: TextStyle(
                    color:
                        Parliament1812Theme.gold.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // 排名
                if (my.rank != null) ...[
                  Text(
                    '#${my.rank}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Parliament1812Theme.gold,
                    ),
                  ),
                  Text(
                    '/ ${my.totalRanked} 人',
                    style: TextStyle(
                      color:
                          Parliament1812Theme.cream.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  const Text(
                    '未上榜',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Parliament1812Theme.gold,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ELO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Parliament1812Theme.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ELO ${my.eloRating}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Parliament1812Theme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 統計卡片
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.sports_esports,
                  label: '場次',
                  value: '${my.gamesPlayed}',
                  color: Parliament1812Theme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events,
                  label: '勝場',
                  value: '${my.wins}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.percent,
                  label: '勝率',
                  value: '${my.winRate.toStringAsFixed(1)}%',
                  color: Parliament1812Theme.darkRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 統計小卡片
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Parliament1812Theme.charcoal,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Parliament1812Theme.cream.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
