import 'package:flutter/material.dart';

import '../models/room.dart';
import '../config/theme.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: room.status.canJoin ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 房間標題與狀態
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  _StatusChip(status: room.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 房間資訊
              Row(
                children: [
                  // 玩家數量
                  _InfoItem(
                    icon: Icons.people,
                    label: '${room.players.length}/${room.settings.maxPlayers}',
                    color: room.isFull 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.primary,
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // 房間代碼
                  _InfoItem(
                    icon: Icons.tag,
                    label: room.code,
                    color: theme.colorScheme.secondary,
                  ),
                  
                  const Spacer(),
                  
                  // 私人房間指示
                  if (room.settings.isPrivate)
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 遊戲階段（如果在遊戲中）
              if (room.status == RoomStatus.playing) ...[
                Row(
                  children: [
                    Icon(
                      Icons.videogame_asset,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      '遊戲進行中',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      '第 ${room.round} 回合',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
              ],
              
              // 玩家陣營分佈
              if (room.players.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.group_work,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: _FactionDistribution(factionCounts: room.factionCounts),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
              ],
              
              // 創建時間
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  
                  const SizedBox(width: 6),
                  
                  Text(
                    _formatCreateTime(room.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 加入按鈕提示
                  if (room.status.canJoin && !room.isFull)
                    Text(
                      '點擊加入',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (room.isFull)
                    Text(
                      '房間已滿',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else
                    Text(
                      '無法加入',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
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

  String _formatCreateTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) {
      return '剛剛創建';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小時前';
    } else {
      return '${createdAt.month}/${createdAt.day} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final RoomStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final (color, backgroundColor) = switch (status) {
      RoomStatus.waiting => (Colors.orange.shade700, Colors.orange.shade50),
      RoomStatus.ready => (Colors.green.shade700, Colors.green.shade50),
      RoomStatus.playing => (Colors.blue.shade700, Colors.blue.shade50),
      RoomStatus.finished => (Colors.grey.shade700, Colors.grey.shade50),
      RoomStatus.cancelled => (Colors.red.shade700, Colors.red.shade50),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        
        const SizedBox(width: 4),
        
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FactionDistribution extends StatelessWidget {
  final Map<String, int> factionCounts;

  const _FactionDistribution({required this.factionCounts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (factionCounts.isEmpty) {
      return Text(
        '暫無玩家',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      children: factionCounts.entries.map((entry) {
        final faction = entry.key;
        final count = entry.value;
        final color = Parliament1812Theme.getFactionColor(faction);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count${_getFactionShortName(faction)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getFactionShortName(String faction) {
    switch (faction.toLowerCase()) {
      case 'labor':
        return '勞';
      case 'capital':
        return '資';
      case 'reform':
        return '改';
      case 'neutral':
        return '中';
      case 'crown':
        return '皇';
      default:
        return '?';
    }
  }
}