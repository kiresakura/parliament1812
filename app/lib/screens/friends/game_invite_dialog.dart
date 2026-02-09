import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';

/// 好友對戰邀請彈窗
///
/// 收到 WebSocket game_invite 事件時顯示。
/// 顯示邀請者資訊 + 接受/拒絕按鈕。
class GameInviteDialog extends StatelessWidget {
  final String fromUsername;
  final String? fromDisplayName;
  final String roomCode;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const GameInviteDialog({
    super.key,
    required this.fromUsername,
    this.fromDisplayName,
    required this.roomCode,
    this.onAccept,
    this.onDecline,
  });

  String get displayLabel => fromDisplayName ?? fromUsername;

  /// 顯示邀請彈窗的靜態方法
  ///
  /// 收到 WebSocket game_invite 時呼叫。
  static Future<bool?> show(
    BuildContext context, {
    required String fromUsername,
    String? fromDisplayName,
    required String roomCode,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameInviteDialog(
        fromUsername: fromUsername,
        fromDisplayName: fromDisplayName,
        roomCode: roomCode,
        onAccept: () {
          Navigator.pop(context, true);
          // 導航到房間
          context.go('/room/$roomCode');
        },
        onDecline: () {
          Navigator.pop(context, false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Parliament1812Theme.gold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.sports_esports,
              color: Parliament1812Theme.gold, size: 28),
          const SizedBox(width: 10),
          Text(
            '對戰邀請',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Parliament1812Theme.gold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 邀請者資訊
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Parliament1812Theme.darkRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Parliament1812Theme.darkRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Parliament1812Theme.darkRed.withValues(alpha: 0.3),
                  child: Text(
                    displayLabel[0].toUpperCase(),
                    style: const TextStyle(
                      color: Parliament1812Theme.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '邀請你加入對戰',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              Parliament1812Theme.cream.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 房間代碼
          Text(
            '房間代碼: $roomCode',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDecline,
          child: Text(
            '拒絕',
            style: TextStyle(
              color: Parliament1812Theme.cream.withValues(alpha: 0.6),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check),
          label: const Text('接受'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Parliament1812Theme.darkRed,
            foregroundColor: Parliament1812Theme.cream,
          ),
        ),
      ],
    );
  }
}

/// 好友對戰邀請通知 overlay
///
/// 在畫面頂部顯示簡短通知，點擊展開完整邀請。
class GameInviteOverlay extends StatelessWidget {
  final String fromUsername;
  final String? fromDisplayName;
  final String roomCode;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const GameInviteOverlay({
    super.key,
    required this.fromUsername,
    this.fromDisplayName,
    required this.roomCode,
    required this.onTap,
    required this.onDismiss,
  });

  String get displayLabel => fromDisplayName ?? fromUsername;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Parliament1812Theme.charcoal,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Parliament1812Theme.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_esports,
                  color: Parliament1812Theme.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$displayLabel 邀請你對戰',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '點擊查看',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Parliament1812Theme.gold.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                color: Parliament1812Theme.cream.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
