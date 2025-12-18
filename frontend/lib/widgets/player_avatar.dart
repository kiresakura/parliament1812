import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 玩家頭像元件
class PlayerAvatar extends StatelessWidget {
  final String nickname;
  final String? roleType;
  final bool isHost;
  final bool hasRole;
  final VoidCallback? onTap;
  final double size;

  const PlayerAvatar({
    super.key,
    required this.nickname,
    this.roleType,
    this.isHost = false,
    this.hasRole = false,
    this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final color = roleType != null
        ? AppTheme.getRoleColor(roleType!)
        : Colors.grey[700]!;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 頭像
          Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasRole ? color : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: hasRole ? color : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              // 主持人標誌
              if (isHost)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      size: size * 0.2,
                      color: AppTheme.darkBackground,
                    ),
                  ),
                ),
              // 已掃卡標誌
              if (hasRole)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: size * 0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 暱稱
          SizedBox(
            width: size + 16,
            child: Text(
              nickname,
              style: TextStyle(
                fontSize: 11,
                color: hasRole ? Colors.white : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
