import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// 玩家狀態
enum PlayerStatus {
  online,    // 在線
  ready,     // 已準備
  offline,   // 離線
  speaking,  // 發言中
}

/// 玩家頭像組件
class PlayerAvatar extends StatelessWidget {
  /// 玩家名稱
  final String name;

  /// 頭像 emoji（可選）
  final String? emoji;

  /// 玩家狀態
  final PlayerStatus status;

  /// 頭像大小
  final double size;

  /// 是否為房主
  final bool isHost;

  /// 是否為當前玩家
  final bool isCurrentPlayer;

  /// 點擊回調
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.emoji,
    this.status = PlayerStatus.online,
    this.size = 56,
    this.isHost = false,
    this.isCurrentPlayer = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 頭像主體
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryMid,
                  border: Border.all(
                    color: isCurrentPlayer
                        ? AppTheme.accent
                        : AppTheme.accent.withAlpha(128),
                    width: isCurrentPlayer ? 3 : 2,
                  ),
                  boxShadow: [
                    if (status == PlayerStatus.speaking)
                      BoxShadow(
                        color: AppTheme.accent.withAlpha(128),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: emoji != null
                      ? Text(
                          emoji!,
                          style: TextStyle(fontSize: size * 0.5),
                        )
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.cinzel(
                            fontSize: size * 0.4,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                ),
              ),

              // 狀態指示燈
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                    border: Border.all(
                      color: AppTheme.primaryDark,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // 房主標記
              if (isHost)
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      size: size * 0.25,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // 玩家名稱
          SizedBox(
            width: size + 16,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: isCurrentPlayer
                    ? AppTheme.accent
                    : AppTheme.textPrimary,
                fontWeight: isCurrentPlayer
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case PlayerStatus.online:
        return AppTheme.warning;
      case PlayerStatus.ready:
        return AppTheme.success;
      case PlayerStatus.offline:
        return AppTheme.textSecondary;
      case PlayerStatus.speaking:
        return AppTheme.accent;
    }
  }
}

/// 玩家列表項目
class PlayerListTile extends StatelessWidget {
  /// 玩家名稱
  final String name;

  /// 頭像 emoji
  final String? emoji;

  /// 玩家狀態
  final PlayerStatus status;

  /// 是否為房主
  final bool isHost;

  /// 是否為當前玩家
  final bool isCurrentPlayer;

  /// 角色名稱（可選）
  final String? roleName;

  /// 聲望值（可選）
  final int? reputation;

  /// 點擊回調
  final VoidCallback? onTap;

  const PlayerListTile({
    super.key,
    required this.name,
    this.emoji,
    this.status = PlayerStatus.online,
    this.isHost = false,
    this.isCurrentPlayer = false,
    this.roleName,
    this.reputation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: PlayerAvatar(
        name: name,
        emoji: emoji,
        status: status,
        size: 44,
        isHost: isHost,
        isCurrentPlayer: isCurrentPlayer,
      ),
      title: Row(
        children: [
          Text(
            name,
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCurrentPlayer
                  ? AppTheme.accent
                  : AppTheme.textPrimary,
            ),
          ),
          if (isCurrentPlayer) ...[
            const SizedBox(width: 8),
            Text(
              '(你)',
              style: GoogleFonts.lora(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
      subtitle: roleName != null
          ? Text(
              roleName!,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            )
          : Text(
              _getStatusText(),
              style: GoogleFonts.lora(
                fontSize: 12,
                color: _getStatusColor(),
              ),
            ),
      trailing: reputation != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accent.withAlpha(128),
                ),
              ),
              child: Text(
                '$reputation',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            )
          : null,
    );
  }

  String _getStatusText() {
    switch (status) {
      case PlayerStatus.online:
        return '等待中...';
      case PlayerStatus.ready:
        return '已準備';
      case PlayerStatus.offline:
        return '離線';
      case PlayerStatus.speaking:
        return '發言中';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case PlayerStatus.online:
        return AppTheme.warning;
      case PlayerStatus.ready:
        return AppTheme.success;
      case PlayerStatus.offline:
        return AppTheme.textSecondary;
      case PlayerStatus.speaking:
        return AppTheme.accent;
    }
  }
}
