import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/user_currency.dart';

/// 用戶個人主頁
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 載入帳號資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).loadAccountData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final accountState = ref.watch(accountProvider);

    if (!authState.isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: accountState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
          : CustomScrollView(
              slivers: [
                // 個人資料標頭
                SliverToBoxAdapter(
                  child: _buildProfileHeader(authState, accountState),
                ),
                // 貨幣與等級
                SliverToBoxAdapter(
                  child: _buildCurrencyBar(accountState),
                ),
                // 統計分頁
                SliverToBoxAdapter(
                  child: _buildTabBar(),
                ),
                // 分頁內容
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(accountState.stats),
                      _buildAchievementsTab(accountState.stats),
                      _buildHistoryTab(accountState.stats),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 個人資料標頭
  Widget _buildProfileHeader(AuthState authState, AccountState accountState) {
    final user = authState.user!;
    final stats = accountState.stats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D2D44), Color(0xFF1A1A2E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                // 返回按鈕
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                // 設定按鈕
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showSettings(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 頭像
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 3,
                    ),
                    image: user.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white54,
                        )
                      : null,
                ),
                // 等級標籤
                if (stats != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lv.${stats.level}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 名稱
            Text(
              user.effectiveDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // 用戶 ID
            Text(
              'UID: ${user.odUserId.substring(0, 8)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            // 排位段位
            if (stats?.rankInfo != null)
              _buildRankBadge(stats!.rankInfo),
            const SizedBox(height: 16),
            // 經驗值條
            if (stats != null) _buildExperienceBar(stats),
          ],
        ),
      ),
    );
  }

  /// 排位段位徽章
  Widget _buildRankBadge(RankInfo rankInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(rankInfo.tier.colorCode).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(rankInfo.tier.colorCode),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech,
            color: Color(rankInfo.tier.colorCode),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            rankInfo.displayName,
            style: TextStyle(
              color: Color(rankInfo.tier.colorCode),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${rankInfo.points} 分',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 經驗值條
  Widget _buildExperienceBar(UserStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '經驗值',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              '${stats.experience} / ${stats.experienceToNextLevel}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stats.experiencePercent,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// 貨幣欄
  Widget _buildCurrencyBar(AccountState accountState) {
    final currency = accountState.currency;
    if (currency == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrencyItem(
            icon: Icons.monetization_on,
            color: const Color(0xFFFFD700),
            value: currency.gold,
            label: '金基尼',
          ),
          _buildCurrencyItem(
            icon: Icons.paid,
            color: const Color(0xFFC0C0C0),
            value: currency.silver,
            label: '銀先令',
          ),
          _buildCurrencyItem(
            icon: Icons.diamond,
            color: const Color(0xFF9370DB),
            value: currency.shards,
            label: '碎片',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyItem({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// 分頁欄
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFD4AF37),
        labelColor: const Color(0xFFD4AF37),
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        tabs: const [
          Tab(text: '統計'),
          Tab(text: '成就'),
          Tab(text: '戰績'),
        ],
      ),
    );
  }

  /// 統計分頁
  Widget _buildStatsTab(UserStats? stats) {
    if (stats == null) {
      return const Center(child: Text('無資料'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 總覽
          _buildSectionTitle('總覽'),
          _buildStatsGrid([
            _StatItem('總場數', '${stats.totalGames}'),
            _StatItem('總勝場', '${stats.totalWins}'),
            _StatItem('勝率', '${stats.totalWinRate.toStringAsFixed(1)}%'),
            _StatItem(
                '遊戲時間', '${(stats.totalPlayTimeMinutes / 60).toStringAsFixed(1)} 小時'),
          ]),
          const SizedBox(height: 24),

          // 單人模式
          _buildSectionTitle('單人模式'),
          _buildStatsGrid([
            _StatItem('場數', '${stats.soloStats.gamesPlayed}'),
            _StatItem('勝場', '${stats.soloStats.gamesWon}'),
            _StatItem(
                '勝率', '${stats.soloStats.winRate.toStringAsFixed(1)}%'),
            _StatItem('最高連勝', '${stats.soloStats.maxWinStreak}'),
          ]),
          const SizedBox(height: 24),

          // 多人模式
          _buildSectionTitle('多人模式'),
          _buildStatsGrid([
            _StatItem('場數', '${stats.multiplayerStats.gamesPlayed}'),
            _StatItem('勝場', '${stats.multiplayerStats.gamesWon}'),
            _StatItem(
                '勝率', '${stats.multiplayerStats.winRate.toStringAsFixed(1)}%'),
            _StatItem('最高連勝', '${stats.multiplayerStats.maxWinStreak}'),
          ]),
          const SizedBox(height: 24),

          // 排位模式
          _buildSectionTitle('排位模式'),
          _buildStatsGrid([
            _StatItem('場數', '${stats.rankedStats.gamesPlayed}'),
            _StatItem('勝場', '${stats.rankedStats.gamesWon}'),
            _StatItem(
                '勝率', '${stats.rankedStats.winRate.toStringAsFixed(1)}%'),
            _StatItem('本季最高', stats.rankInfo.peakTier.displayName),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => Column(
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  /// 成就分頁
  Widget _buildAchievementsTab(UserStats? stats) {
    if (stats == null) {
      return const Center(child: Text('無資料'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 成就進度
          Text(
            '已完成 ${stats.completedAchievements} / ${stats.achievements.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // 成就列表
          ...stats.achievements.map((achievement) => _buildAchievementCard(
                title: '成就 ${achievement.achievementId}',
                description: '完成目標',
                progress: achievement.progressPercent,
                isCompleted: achievement.isCompleted,
              )),
          if (stats.achievements.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '開始遊戲來解鎖成就！',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required double progress,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFD4AF37).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isCompleted
            ? Border.all(color: const Color(0xFFD4AF37), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFFD4AF37)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4AF37)),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 戰績分頁
  Widget _buildHistoryTab(UserStats? stats) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '戰績記錄即將推出',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

/// 設定頁面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 音效設定
                _buildSettingsSection(
                  title: '音效',
                  children: [
                    _buildSliderSetting(
                      label: '主音量',
                      value: settings.audio.masterVolume,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          audio: settings.audio.copyWith(masterVolume: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSliderSetting(
                      label: '音樂',
                      value: settings.audio.musicVolume,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          audio: settings.audio.copyWith(musicVolume: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSliderSetting(
                      label: '音效',
                      value: settings.audio.sfxVolume,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          audio: settings.audio.copyWith(sfxVolume: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSwitchSetting(
                      label: '震動',
                      value: settings.audio.vibrationEnabled,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          audio:
                              settings.audio.copyWith(vibrationEnabled: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 遊戲設定
                _buildSettingsSection(
                  title: '遊戲',
                  children: [
                    _buildSwitchSetting(
                      label: '顯示傷害數字',
                      value: settings.gameplay.showDamageNumbers,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          gameplay: settings.gameplay
                              .copyWith(showDamageNumbers: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSwitchSetting(
                      label: '快速模式',
                      value: settings.gameplay.fastMode,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          gameplay: settings.gameplay.copyWith(fastMode: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 隱私設定
                _buildSettingsSection(
                  title: '隱私',
                  children: [
                    _buildSwitchSetting(
                      label: '公開個人資料',
                      value: settings.privacy.publicProfile,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          privacy:
                              settings.privacy.copyWith(publicProfile: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSwitchSetting(
                      label: '允許好友邀請',
                      value: settings.privacy.allowFriendRequests,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          privacy: settings.privacy
                              .copyWith(allowFriendRequests: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    _buildSwitchSetting(
                      label: '顯示在線狀態',
                      value: settings.privacy.showOnlineStatus,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(
                          privacy: settings.privacy
                              .copyWith(showOnlineStatus: value),
                        );
                        ref
                            .read(accountProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 帳號操作
                _buildSettingsSection(
                  title: '帳號',
                  children: [
                    _buildButtonSetting(
                      label: '登出',
                      color: Colors.red,
                      onTap: () async {
                        await ref.read(authProvider.notifier).signOut();
                        ref.read(accountProvider.notifier).clearAccountData();
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD4AF37),
            inactiveColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSetting({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
