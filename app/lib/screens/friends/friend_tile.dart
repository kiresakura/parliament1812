import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// 單個好友 widget
///
/// 顯示：頭像 | 名稱 | 在線狀態 | ELO | 操作按鈕
class FriendTile extends StatelessWidget {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int? eloRating;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final VoidCallback? onInviteGame;
  final VoidCallback? onRemove;

  const FriendTile({
    super.key,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.eloRating,
    this.isOnline = false,
    this.lastSeenAt,
    this.onInviteGame,
    this.onRemove,
  });

  String get displayLabel => displayName ?? username;

  String get lastSeenLabel {
    if (isOnline) return '在線';
    if (lastSeenAt == null) return '離線';

    final diff = DateTime.now().difference(lastSeenAt!);
    if (diff.inMinutes < 1) return '剛剛離線';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '超過一週前';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // 可擴展：查看好友檔案
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 頭像 + 在線狀態
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Parliament1812Theme.darkRed.withValues(alpha: 0.3),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            displayLabel[0].toUpperCase(),
                            style: const TextStyle(
                              color: Parliament1812Theme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  // 在線狀態指示器
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Parliament1812Theme.charcoal,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // 名稱 + 狀態 + ELO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // 在線狀態
                        Text(
                          lastSeenLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOnline
                                ? Colors.green
                                : Parliament1812Theme.cream
                                    .withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        // ELO
                        if (eloRating != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '⚔ $eloRating',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Parliament1812Theme.gold
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 操作按鈕
              if (isOnline && onInviteGame != null)
                IconButton(
                  icon: const Icon(Icons.sports_esports,
                      color: Parliament1812Theme.gold),
                  tooltip: '邀請對戰',
                  onPressed: onInviteGame,
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Parliament1812Theme.cream.withValues(alpha: 0.5),
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'remove':
                      onRemove?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('刪除好友'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
