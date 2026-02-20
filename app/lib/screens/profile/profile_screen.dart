import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';

/// ELO 段位資訊
class _RankInfo {
  final String name;
  final String emoji;
  final Color color;

  const _RankInfo(this.name, this.emoji, this.color);
}

_RankInfo _getRankInfo(int elo) {
  if (elo >= 1800) {
    return const _RankInfo('大師', '👑', Color(0xFFFFD700));
  } else if (elo >= 1600) {
    return const _RankInfo('鑽石', '💠', Color(0xFF00BCD4));
  } else if (elo >= 1400) {
    return const _RankInfo('白金', '💎', Color(0xFFE0E0E0));
  } else if (elo >= 1200) {
    return const _RankInfo('黃金', '🥇', Color(0xFFD4AF37));
  } else if (elo >= 1000) {
    return const _RankInfo('白銀', '🥈', Color(0xFFC0C0C0));
  } else {
    return const _RankInfo('青銅', '🥉', Color(0xFFCD7F32));
  }
}

/// 可選頭像列表
class _AvatarOption {
  final String assetPath;
  final String label;
  final String avatarKey;

  const _AvatarOption({
    required this.assetPath,
    required this.label,
    required this.avatarKey,
  });
}

const _avatarOptions = [
  _AvatarOption(
    assetPath: 'assets/images/characters/portrait_george.png',
    label: '喬治三世',
    avatarKey: 'portrait_george',
  ),
  _AvatarOption(
    assetPath: 'assets/images/characters/portrait_richard.png',
    label: '理查',
    avatarKey: 'portrait_richard',
  ),
  _AvatarOption(
    assetPath: 'assets/images/characters/portrait_robert.png',
    label: '羅伯特',
    avatarKey: 'portrait_robert',
  ),
  _AvatarOption(
    assetPath: 'assets/images/characters/portrait_thomas.png',
    label: '湯瑪斯',
    avatarKey: 'portrait_thomas',
  ),
  _AvatarOption(
    assetPath: 'assets/images/characters/portrait_william.png',
    label: '威廉',
    avatarKey: 'portrait_william',
  ),
  _AvatarOption(
    assetPath: 'assets/images/characters/card_worker_thomas_char.png',
    label: '工人湯瑪斯',
    avatarKey: 'card_worker_thomas_char',
  ),
];

/// 個人檔案頁面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        title: const Text('個人檔案'),
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
        child: user == null
            ? _buildGuestView(context, theme)
            : _buildProfileView(context, ref, theme, user),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 100,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '尚未登入',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '登入以查看個人檔案並保存遊戲進度',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('前往登入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    dynamic user,
  ) {
    final elo = user.eloRating ?? 1000;
    final rank = _getRankInfo(elo);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // 用戶頭像 & 名稱
            // ═══════════════════════════════════════════
            Center(
              child: Column(
                children: [
                  // 頭像
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context, ref, user),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Parliament1812Theme.gold,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Parliament1812Theme.gold
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Parliament1812Theme.charcoal,
                            backgroundImage: _getAvatarImage(user.avatarUrl),
                            child: _getAvatarImage(user.avatarUrl) == null
                                ? Text(
                                    _getInitials(
                                        user.displayName ?? user.username),
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                      color: Parliament1812Theme.gold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Parliament1812Theme.gold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Parliament1812Theme.charcoal,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Parliament1812Theme.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 顯示名稱
                  Text(
                    user.displayName ?? user.username,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Parliament1812Theme.cream,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 用戶名
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Parliament1812Theme.gold.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════
            // ELO 評分卡片
            // ═══════════════════════════════════════════
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.military_tech,
                            color: rank.color, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'ELO 評分',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rank.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$elo',
                              style:
                                  theme.textTheme.displayMedium?.copyWith(
                                color: rank.color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              rank.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: rank.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 段位進度條
                    _buildEloProgressBar(elo, rank, theme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // 戰績統計卡片
            // ═══════════════════════════════════════════
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart,
                            color: theme.colorScheme.secondary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '戰績統計',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          theme,
                          label: '勝利',
                          value: '—',
                          color: Parliament1812Theme.reputationUpColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Parliament1812Theme.lightBrown
                              .withValues(alpha: 0.3),
                        ),
                        _buildStatItem(
                          theme,
                          label: '失敗',
                          value: '—',
                          color: Parliament1812Theme.reputationDownColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Parliament1812Theme.lightBrown
                              .withValues(alpha: 0.3),
                        ),
                        _buildStatItem(
                          theme,
                          label: '平局',
                          value: '—',
                          color: Parliament1812Theme.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '戰績統計即將開放',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // 帳號資訊卡片
            // ═══════════════════════════════════════════
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: theme.colorScheme.secondary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '帳號資訊',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      theme,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email ?? '未設定',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      theme,
                      icon: Icons.badge_outlined,
                      label: '用戶 ID',
                      value: user.id.length > 8
                          ? '${user.id.substring(0, 8)}...'
                          : user.id,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // 帳號管理區塊
            // ═══════════════════════════════════════════
            const _AccountManagementSection(),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════
            // 底部按鈕
            // ═══════════════════════════════════════════
            OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context, ref, user),
              icon: const Icon(Icons.edit),
              label: const Text('編輯個人資料'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _showLogoutDialog(context);
                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('登出'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ELO 進度條
  Widget _buildEloProgressBar(int elo, _RankInfo rank, ThemeData theme) {
    // 計算在當前段位的進度
    final thresholds = [0, 1000, 1200, 1400, 1600, 1800, 2200];
    int currentTierStart = 0;
    int currentTierEnd = 1000;

    for (int i = 0; i < thresholds.length - 1; i++) {
      if (elo >= thresholds[i] && elo < thresholds[i + 1]) {
        currentTierStart = thresholds[i];
        currentTierEnd = thresholds[i + 1];
        break;
      }
    }
    // 大師段位
    if (elo >= 1800) {
      currentTierStart = 1800;
      currentTierEnd = 2200;
    }

    final progress =
        (elo - currentTierStart) / (currentTierEnd - currentTierStart);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor:
                Parliament1812Theme.lightBrown.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(rank.color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentTierStart',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '$currentTierEnd',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 戰績統計項目
  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 帳號資訊列
  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Parliament1812Theme.gold),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 取得名字縮寫
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// 取得頭像圖片（支援本地 asset 和網路圖片）
  ImageProvider? _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    // 檢查是否為本地角色頭像 key
    final match = _avatarOptions
        .where((opt) => opt.avatarKey == avatarUrl)
        .firstOrNull;
    if (match != null) {
      return AssetImage(match.assetPath);
    }

    // 檢查是否為本地 asset 路徑
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }

    // 否則當作網路圖片
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    }

    return null;
  }

  /// 編輯個人資料對話框
  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, dynamic user) {
    final controller =
        TextEditingController(text: user.displayName ?? user.username);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Parliament1812Theme.charcoal,
          title: Row(
            children: [
              Icon(Icons.edit, color: Parliament1812Theme.gold, size: 24),
              const SizedBox(width: 8),
              Text(
                '編輯顯示名稱',
                style: TextStyle(color: Parliament1812Theme.cream),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLength: 50,
            style: TextStyle(color: Parliament1812Theme.cream),
            decoration: InputDecoration(
              hintText: '輸入新的顯示名稱',
              hintStyle: TextStyle(
                color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Parliament1812Theme.gold.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Parliament1812Theme.gold),
              ),
              counterStyle: TextStyle(
                color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                '取消',
                style: TextStyle(
                  color: Parliament1812Theme.cream.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                Navigator.of(ctx).pop();
                final success = await ref
                    .read(authProvider.notifier)
                    .updateProfile(displayName: newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(success ? '顯示名稱已更新' : '更新失敗，請稍後再試'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Parliament1812Theme.gold,
                foregroundColor: Parliament1812Theme.charcoal,
              ),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  /// 頭像選擇器
  void _showAvatarPicker(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Parliament1812Theme.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              Row(
                children: [
                  Icon(Icons.face, color: Parliament1812Theme.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '選擇頭像',
                    style: TextStyle(
                      color: Parliament1812Theme.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 頭像網格
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final option = _avatarOptions[index];
                  final isSelected = user.avatarUrl == option.avatarKey;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final success = await ref
                          .read(authProvider.notifier)
                          .updateProfile(avatarUrl: option.avatarKey);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(success ? '頭像已更新' : '更新失敗，請稍後再試'),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Parliament1812Theme.gold
                                  : Parliament1812Theme.lightBrown
                                      .withValues(alpha: 0.3),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Parliament1812Theme.gold
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Parliament1812Theme.charcoal,
                            backgroundImage: AssetImage(option.assetPath),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected
                                ? Parliament1812Theme.gold
                                : Parliament1812Theme.cream
                                    .withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 登出確認對話框
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
            child: const Text('登出'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 帳號管理區塊
// ═══════════════════════════════════════════════════════════════

class _AccountManagementSection extends ConsumerStatefulWidget {
  const _AccountManagementSection();

  @override
  ConsumerState<_AccountManagementSection> createState() =>
      _AccountManagementSectionState();
}

class _AccountManagementSectionState
    extends ConsumerState<_AccountManagementSection> {
  List<LinkedAccount>? _linkedAccounts;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLinkedAccounts();
  }

  Future<void> _fetchLinkedAccounts() async {
    setState(() => _isLoading = true);
    final accounts =
        await ref.read(authProvider.notifier).fetchLinkedAccounts();
    if (mounted) {
      setState(() {
        _linkedAccounts = accounts;
        _isLoading = false;
      });
    }
  }

  bool _isProviderLinked(String provider) {
    return _linkedAccounts?.any((a) => a.provider == provider) ?? false;
  }

  LinkedAccount? _getLinkedAccount(String provider) {
    return _linkedAccounts
        ?.where((a) => a.provider == provider)
        .firstOrNull;
  }

  // ── Google 綁定 ──

  Future<void> _handleLinkGoogle() async {
    setState(() => _isActionLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '1071586546991-0v65rkt7ud4jsp77jk121ta9prjvl6ti.apps.googleusercontent.com',
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isActionLoading = false);
        return; // 使用者取消
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google 綁定失敗：無法取得 Token')),
          );
        }
        setState(() => _isActionLoading = false);
        return;
      }

      final success =
          await ref.read(authProvider.notifier).linkGoogleAccount(idToken);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Google 帳號已綁定')),
          );
          await _fetchLinkedAccounts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  ref.read(authProvider).error ?? 'Google 帳號綁定失敗'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 綁定錯誤: $e')),
        );
      }
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  // ── Apple 綁定 ──

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleLinkApple() async {
    setState(() => _isActionLoading = true);
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apple 綁定失敗：無法取得 Token')),
          );
        }
        setState(() => _isActionLoading = false);
        return;
      }

      final success = await ref
          .read(authProvider.notifier)
          .linkAppleAccount(identityToken);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Apple 帳號已綁定')),
          );
          await _fetchLinkedAccounts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  ref.read(authProvider).error ?? 'Apple 帳號綁定失敗'),
            ),
          );
        }
      }
    } on SignInWithAppleAuthorizationException {
      // 使用者取消
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple 綁定錯誤: $e')),
        );
      }
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  // ── 解綁 ──

  Future<void> _handleUnlink(String provider) async {
    final providerName = provider == 'google' ? 'Google' : 'Apple';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Parliament1812Theme.charcoal,
        title: Text(
          '解綁 $providerName',
          style: const TextStyle(color: Parliament1812Theme.cream),
        ),
        content: Text(
          '確定要解除 $providerName 帳號的綁定嗎？\n解綁後將無法使用該帳號登入。',
          style: TextStyle(
            color: Parliament1812Theme.cream.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                color: Parliament1812Theme.cream.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Parliament1812Theme.darkRed,
            ),
            child: const Text('確認解綁'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    final success =
        await ref.read(authProvider.notifier).unlinkAccount(provider);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $providerName 帳號已解綁')),
        );
        await _fetchLinkedAccounts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ref.read(authProvider).error ?? '解綁失敗，這可能是您唯一的登入方式'),
          ),
        );
      }
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                Icon(Icons.link,
                    color: theme.colorScheme.secondary, size: 28),
                const SizedBox(width: 10),
                Text(
                  '帳號管理',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              // Apple
              _buildProviderRow(
                theme,
                icon: Icons.apple,
                name: 'Apple',
                provider: 'apple',
              ),
              Divider(
                height: 24,
                color:
                    Parliament1812Theme.lightBrown.withValues(alpha: 0.2),
              ),

              // Google
              _buildProviderRow(
                theme,
                icon: Icons.g_mobiledata,
                name: 'Google',
                provider: 'google',
              ),
              Divider(
                height: 24,
                color:
                    Parliament1812Theme.lightBrown.withValues(alpha: 0.2),
              ),

              // 密碼（TODO）
              _buildPasswordRow(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderRow(
    ThemeData theme, {
    required IconData icon,
    required String name,
    required String provider,
  }) {
    final isLinked = _isProviderLinked(provider);
    final account = _getLinkedAccount(provider);

    return Row(
      children: [
        Icon(icon, size: 24, color: Parliament1812Theme.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLinked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✅ 已綁定',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '❌ 未綁定',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              if (isLinked && account?.email != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    account!.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        if (_isActionLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (isLinked)
          TextButton(
            onPressed: () => _handleUnlink(provider),
            style: TextButton.styleFrom(
              foregroundColor: Parliament1812Theme.darkRed,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('解綁'),
          )
        else
          TextButton(
            onPressed:
                provider == 'google' ? _handleLinkGoogle : _handleLinkApple,
            style: TextButton.styleFrom(
              foregroundColor: Parliament1812Theme.gold,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('綁定'),
          ),
      ],
    );
  }

  Widget _buildPasswordRow(ThemeData theme) {
    // TODO: 實作變更密碼功能
    final hasPassword =
        _linkedAccounts?.any((a) => a.provider == 'password') ?? false;

    return Row(
      children: [
        const Icon(Icons.lock_outline,
            size: 24, color: Parliament1812Theme.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                '密碼',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasPassword
                      ? Colors.green.withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasPassword ? '✅ 已設定' : '❌ 未設定',
                  style: TextStyle(
                    color: hasPassword
                        ? Colors.green
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: hasPassword ? FontWeight.w500 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: null, // TODO
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            hasPassword ? '變更' : '設定',
            style: TextStyle(
              color:
                  Parliament1812Theme.gold.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}
