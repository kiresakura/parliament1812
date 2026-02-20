import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/friends_provider.dart';
import 'friend_tile.dart';

/// 好友系統主畫面
///
/// TabBar: 好友列表 / 待處理請求 / 搜尋
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 載入初始資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(friendsProvider.notifier).searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    // 監聽 success/error messages
    ref.listen<FriendsState>(friendsProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Parliament1812Theme.gold.withValues(alpha: 0.9),
          ),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        title: const Text('好友'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Parliament1812Theme.gold,
          labelColor: Parliament1812Theme.gold,
          unselectedLabelColor: Parliament1812Theme.cream.withValues(alpha: 0.6),
          tabs: [
            const Tab(
              icon: Icon(Icons.people),
              text: '好友',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: state.pendingCount > 0,
                label: Text(
                  '${state.pendingCount}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.person_add),
              ),
              text: '請求',
            ),
            const Tab(
              icon: Icon(Icons.search),
              text: '搜尋',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(state: state),
          _PendingRequestsTab(state: state),
          _SearchTab(
            state: state,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 好友列表 Tab
// ============================================================

class _FriendsListTab extends ConsumerWidget {
  final FriendsState state;

  const _FriendsListTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (state.isLoading && state.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: Parliament1812Theme.cream.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '還沒有好友',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '使用搜尋功能尋找其他議員',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Parliament1812Theme.cream.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendsProvider.notifier).loadFriends(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.friends.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${state.friends.length} 位好友 · ${state.onlineCount} 在線',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Parliament1812Theme.cream.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          final friend = state.friends[index - 1];
          return FriendTile(
            userId: friend.userId,
            username: friend.username,
            displayName: friend.displayName,
            avatarUrl: friend.avatarUrl,
            eloRating: friend.eloRating,
            isOnline: friend.isOnline,
            lastSeenAt: friend.lastSeenAt,
            onInviteGame: () async {
              final roomCode = await ref
                  .read(friendsProvider.notifier)
                  .inviteToGame(friend.userId);
              if (roomCode != null && context.mounted) {
                // 導航到房間（如果需要）
              }
            },
            onRemove: () async {
              final confirmed = await _showConfirmDialog(
                context,
                '刪除好友',
                '確定要刪除 ${friend.displayLabel} 嗎？',
              );
              if (confirmed == true) {
                ref.read(friendsProvider.notifier).removeFriend(friend.userId);
              }
            },
          );
        },
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Parliament1812Theme.darkRed,
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 待處理請求 Tab
// ============================================================

class _PendingRequestsTab extends ConsumerWidget {
  final FriendsState state;

  const _PendingRequestsTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (state.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline,
                size: 64,
                color: Parliament1812Theme.cream.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '沒有待處理的好友請求',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendsProvider.notifier).loadPendingRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = state.pendingRequests[index];
          return _PendingRequestTile(request: request);
        },
      ),
    );
  }
}

class _PendingRequestTile extends ConsumerWidget {
  final FriendRequest request;

  const _PendingRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 頭像
            CircleAvatar(
              radius: 24,
              backgroundColor: Parliament1812Theme.darkRed.withValues(alpha: 0.3),
              backgroundImage: request.avatarUrl != null
                  ? NetworkImage(request.avatarUrl!)
                  : null,
              child: request.avatarUrl == null
                  ? Text(
                      request.displayLabel[0].toUpperCase(),
                      style: const TextStyle(
                        color: Parliament1812Theme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 名稱 + ELO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.displayLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (request.eloRating != null)
                    Text(
                      'ELO: ${request.eloRating}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Parliament1812Theme.gold.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            // 接受 / 拒絕按鈕
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: '接受',
              onPressed: () {
                ref
                    .read(friendsProvider.notifier)
                    .acceptFriendRequest(request.userId);
              },
            ),
            IconButton(
              icon: Icon(Icons.cancel,
                  color: Colors.red.shade400),
              tooltip: '拒絕',
              onPressed: () {
                ref
                    .read(friendsProvider.notifier)
                    .rejectFriendRequest(request.userId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 搜尋 Tab
// ============================================================

class _SearchTab extends ConsumerWidget {
  final FriendsState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _SearchTab({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 搜尋框
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '搜尋用戶名稱...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        // 搜尋結果
        Expanded(
          child: state.isSearching
              ? const Center(child: CircularProgressIndicator())
              : state.searchResults.isEmpty
                  ? Center(
                      child: Text(
                        searchController.text.isEmpty
                            ? '輸入用戶名稱開始搜尋'
                            : '找不到相關用戶',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              Parliament1812Theme.cream.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
                        return _SearchResultTile(user: user);
                      },
                    ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  final UserSearchResult user;

  const _SearchResultTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFriend = user.friendStatus == 'accepted';
    final isPending = user.friendStatus == 'pending';
    final isBlocked = user.friendStatus == 'blocked';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  Parliament1812Theme.darkRed.withValues(alpha: 0.3),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.displayLabel[0].toUpperCase(),
                      style: const TextStyle(
                        color: Parliament1812Theme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Parliament1812Theme.charcoal,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(user.displayLabel),
        subtitle: Text(
          user.eloRating != null ? 'ELO: ${user.eloRating}' : user.username,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Parliament1812Theme.cream.withValues(alpha: 0.5),
          ),
        ),
        trailing: isFriend
            ? Chip(
                label: const Text('好友'),
                backgroundColor:
                    Parliament1812Theme.gold.withValues(alpha: 0.2),
                labelStyle: const TextStyle(
                  color: Parliament1812Theme.gold,
                  fontSize: 12,
                ),
              )
            : isPending
                ? Chip(
                    label: const Text('已發送'),
                    backgroundColor:
                        Parliament1812Theme.cream.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color:
                          Parliament1812Theme.cream.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  )
                : isBlocked
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.person_add,
                            color: Parliament1812Theme.gold),
                        tooltip: '加好友',
                        onPressed: () {
                          ref
                              .read(friendsProvider.notifier)
                              .sendFriendRequest(user.id);
                        },
                      ),
      ),
    );
  }
}
