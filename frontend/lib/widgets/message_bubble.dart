import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/message.dart';

/// 訊息泡泡元件 - 書信風格
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMe
                ? [
                    AppTheme.secondaryColor.withValues(alpha: 0.25),
                    AppTheme.candleGlow.withValues(alpha: 0.15),
                    AppTheme.secondaryColor.withValues(alpha: 0.18),
                  ]
                : [
                    AppTheme.parchmentDark.withValues(alpha: 0.4),
                    AppTheme.cardBackground.withValues(alpha: 0.95),
                    AppTheme.parchmentDark.withValues(alpha: 0.3),
                  ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: Border.all(
            color: isMe
                ? AppTheme.secondaryColor.withValues(alpha: 0.4)
                : AppTheme.secondaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppTheme.candleGlow.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 角落裝飾（自己的訊息）
            if (isMe)
              Positioned(
                right: 8,
                top: 8,
                child: Icon(
                  Icons.edit,
                  size: 12,
                  color: AppTheme.candleGlow.withValues(alpha: 0.3),
                ),
              ),
            // 主內容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 發送者名稱（只在接收訊息時顯示）
                  if (!isMe) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.senderNickname,
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 訊息內容
                  Text(
                    message.content,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 時間和已讀狀態
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          color: isMe
                              ? AppTheme.candleGlow.withValues(alpha: 0.7)
                              : Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        _buildReadStatus(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: message.isRead
            ? AppTheme.secondaryColor.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: message.isRead
              ? AppTheme.secondaryColor.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 12,
            color: message.isRead
                ? AppTheme.secondaryColor
                : Colors.grey[500],
          ),
          if (message.isRead) ...[
            const SizedBox(width: 3),
            Text(
              '已讀',
              style: TextStyle(
                fontSize: 9,
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}

/// 訊息日期分隔元件 - 書卷風格
class MessageDateDivider extends StatelessWidget {
  final DateTime date;

  const MessageDateDivider({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          // 左側裝飾線
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.secondaryColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // 日期標籤
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.parchmentDark.withValues(alpha: 0.4),
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.secondaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // 右側裝飾線
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryColor.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今日';
    } else if (messageDate == yesterday) {
      return '昨日';
    } else {
      return DateFormat('M月d日').format(date);
    }
  }
}

/// 新訊息指示器 - 蠟封信風格
class NewMessageIndicator extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NewMessageIndicator({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.waxSealColor.withValues(alpha: 0.9),
              AppTheme.waxSealColor,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.waxSealColor.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mail,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$count 封新密函',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: 1500.ms,
        )
        .shimmer(
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }
}

/// 正在輸入指示器 - 羽毛筆書寫動畫
class TypingIndicator extends StatelessWidget {
  final String nickname;

  const TypingIndicator({
    super.key,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 羽毛筆圖示
            Icon(
              Icons.edit,
              size: 14,
              color: AppTheme.candleGlow,
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .rotate(
                  begin: -0.05,
                  end: 0.05,
                  duration: 600.ms,
                ),
            const SizedBox(width: 8),
            Text(
              '$nickname 正在提筆...',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.secondaryColor.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            // 書寫點點動畫
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.only(left: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.candleGlow,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(),
                    )
                    .fadeIn(
                      delay: Duration(milliseconds: 200 * index),
                      duration: 400.ms,
                    )
                    .then()
                    .fadeOut(
                      duration: 400.ms,
                    );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// 系統訊息元件 - 公告風格
class SystemMessage extends StatelessWidget {
  final String content;
  final IconData? icon;

  const SystemMessage({
    super.key,
    required this.content,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.parchmentDark.withValues(alpha: 0.3),
              AppTheme.cardBackground.withValues(alpha: 0.8),
              AppTheme.parchmentDark.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: AppTheme.secondaryColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              content,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
