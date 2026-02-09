import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/room.dart';
import '../models/player.dart';
import '../widgets/player_avatar.dart';
import '../widgets/connection_indicator.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const RoomScreen({
    super.key,
    required this.roomCode,
  });

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  late Room _room;
  bool _isLoading = true;
  CharacterType? _selectedCharacter;
  
  // 獲取已被選擇的角色
  Set<CharacterType> get _selectedCharacters {
    return _room.players.map((p) => p.character).whereType<CharacterType>().toSet();
  }

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    // TODO: 從 API 載入房間資料
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _room = _getMockRoom();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isHost = _room.isHost('current_player_id'); // TODO: 取得實際玩家 ID

    return Scaffold(
      appBar: AppBar(
        title: Text(_room.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveRoom(),
        ),
        actions: [
          const ConnectionIndicator(),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRoom(),
          ),
          if (isHost)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('房間設定'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'kick',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove),
                      SizedBox(width: 8),
                      Text('踢出玩家'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    _showRoomSettings();
                    break;
                  case 'kick':
                    _showKickPlayerDialog();
                    break;
                }
              },
            ),
        ],
      ),
      
      body: Column(
        children: [
          // 房間資訊區
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '房間代碼',
                            style: theme.textTheme.bodySmall,
                          ),
                          
                          Row(
                            children: [
                              Text(
                                widget.roomCode,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              IconButton(
                                icon: const Icon(Icons.copy),
                                iconSize: 20,
                                onPressed: () => _copyRoomCode(),
                                tooltip: '複製房間代碼',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '玩家',
                          style: theme.textTheme.bodySmall,
                        ),
                        
                        Text(
                          '${_room.players.length}/${_room.settings.maxPlayers}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _getStatusColor(_room.status),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      _room.status.displayName,
                      style: theme.textTheme.bodyMedium,
                    ),
                    
                    const Spacer(),
                    
                    if (_room.canStartGame && isHost)
                      Text(
                        '可以開始遊戲',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // 玩家列表
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '玩家列表',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _room.settings.maxPlayers,
                      itemBuilder: (context, index) {
                        if (index < _room.players.length) {
                          final player = _room.players[index];
                          return _PlayerSlot(
                            player: player,
                            isHost: player.id == _room.hostId,
                            onKick: isHost && player.id != _room.hostId
                                ? () => _kickPlayer(player)
                                : null,
                          );
                        } else {
                          return _EmptyPlayerSlot(
                            onInvite: () => _shareRoom(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 底部操作區
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _leaveRoom(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('離開房間'),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                if (isHost)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _room.canStartGame ? () => _startGame() : null,
                      child: const Text('開始遊戲'),
                    ),
                  )
                else
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _toggleReady(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCurrentPlayerReady() 
                            ? theme.colorScheme.secondary
                            : null,
                      ),
                      child: Text(_isCurrentPlayerReady() ? '取消準備' : '準備'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.waiting:
        return Colors.orange;
      case RoomStatus.ready:
        return Colors.green;
      case RoomStatus.playing:
        return Colors.blue;
      case RoomStatus.finished:
        return Colors.grey;
      case RoomStatus.cancelled:
        return Colors.red;
    }
  }

  bool _isCurrentPlayerReady() {
    // TODO: 檢查實際當前玩家狀態
    return false;
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('房間代碼已複製到剪貼簿'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRoom() {
    // TODO: 實現分享功能
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀請好友'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分享房間代碼給好友：'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.roomCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
          ElevatedButton(
            onPressed: () {
              _copyRoomCode();
              Navigator.of(context).pop();
            },
            child: const Text('複製'),
          ),
        ],
      ),
    );
  }

  void _showRoomSettings() {
    // TODO: 實現房間設定
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('房間設定功能將在後續版本實現'),
      ),
    );
  }

  void _showKickPlayerDialog() {
    // TODO: 實現踢出玩家
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('踢出玩家功能將在後續版本實現'),
      ),
    );
  }

  void _kickPlayer(Player player) {
    // TODO: 實現踢出玩家
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('踢出玩家'),
        content: Text('確定要踢出 ${player.name} 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 實際踢出邏輯
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('踢出'),
          ),
        ],
      ),
    );
  }

  void _toggleReady() {
    // TODO: 實現準備/取消準備
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('準備功能將在後續版本實現'),
      ),
    );
  }

  void _startGame() {
    // TODO: 實際開始遊戲
    context.go('/game/${widget.roomCode}');
  }

  void _leaveRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('離開房間'),
        content: const Text('確定要離開房間嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/rooms');
            },
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }

  // Mock 資料
  Room _getMockRoom() {
    return RoomFactory.createRoom(
      name: '測試房間',
      hostPlayerId: 'player1',
    ).copyWith(
      code: widget.roomCode,
      players: [
        PlayerFactory.createPlayer(
          name: '房主',
          character: CharacterType.thomasWorker,
          isHost: true,
        ).copyWith(id: 'player1'),
        PlayerFactory.createPlayer(
          name: '玩家2',
          character: CharacterType.richardFactory,
        ).copyWith(id: 'player2', isReady: true),
        PlayerFactory.createPlayer(
          name: '玩家3',
          character: CharacterType.georgeLuddite,
        ).copyWith(id: 'player3'),
      ],
    );
  }

  Widget _buildCharacterSelection(ThemeData theme) {
    // 獲取當前玩家選中的角色
    final currentPlayer = _room.players.where((p) => p.id == _getCurrentUserId()).firstOrNull;
    final selectedCharacter = currentPlayer?.character;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: CharacterType.values.map((character) {
        final isSelected = selectedCharacter == character;
        final isAlreadyTaken = _selectedCharacters.contains(character) && !isSelected;
        
        return _buildCharacterCard(character, isSelected, isAlreadyTaken, theme);
      }).toList(),
    );
  }

  Widget _buildCharacterCard(
    CharacterType character,
    bool isSelected,
    bool isAlreadyTaken,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: isAlreadyTaken ? null : () => _selectCharacter(character),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.secondary 
                : isAlreadyTaken 
                    ? theme.colorScheme.outline.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 3 : 1,
          ),
          color: isAlreadyTaken 
              ? theme.colorScheme.surface.withValues(alpha: 0.5)
              : isSelected 
                  ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCharacterColor(character),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCharacterIcon(character),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    )
                  else if (isAlreadyTaken)
                    Icon(
                      Icons.block,
                      color: theme.colorScheme.outline,
                      size: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _getCharacterName(character),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAlreadyTaken 
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                _getCharacterDescription(character),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAlreadyTaken 
                      ? theme.colorScheme.outline.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (isAlreadyTaken)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '已被選擇',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCharacter(CharacterType character) {
    setState(() {
      _selectedCharacter = character;
    });
    
    // TODO: 發送角色選擇到服務器
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('選擇了角色：${_getCharacterName(character)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getCharacterColor(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return const Color(0xFFE53935); // 勞工紅
      case CharacterType.richardFactory:
        return const Color(0xFF43A047); // 工廠綠
      case CharacterType.edwardJournalist:
        return const Color(0xFF1E88E5); // 記者藍
      case CharacterType.georgeLuddite:
        return const Color(0xFF8E24AA); // 盧德紫
      default:
        return Colors.grey;
    }
  }

  IconData _getCharacterIcon(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return Icons.groups;
      case CharacterType.richardFactory:
        return Icons.business;
      case CharacterType.edwardJournalist:
        return Icons.edit;
      case CharacterType.georgeLuddite:
        return Icons.whatshot;
      default:
        return Icons.person;
    }
  }

  String _getCharacterName(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return '湯瑪斯';
      case CharacterType.richardFactory:
        return '理查';
      case CharacterType.edwardJournalist:
        return '愛德華';
      case CharacterType.georgeLuddite:
        return '喬治';
      default:
        return '未知';
    }
  }

  String _getCharacterDescription(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return '工人領袖\n團結技能：盟友越多，防禦越強';
      case CharacterType.richardFactory:
        return '工廠主\n收買技能：用金幣讓對手沉默';
      case CharacterType.edwardJournalist:
        return '記者\n爆料技能：揭露對手秘密';
      case CharacterType.georgeLuddite:
        return '盧德派\n怒火技能：造成雙倍傷害';
      default:
        return '未知角色';
    }
  }

  String _getCurrentUserId() {
    return 'current_player_id'; // TODO: 從認證服務取得實際玩家 ID
  }
}

class _PlayerSlot extends StatelessWidget {
  final Player player;
  final bool isHost;
  final VoidCallback? onKick;

  const _PlayerSlot({
    required this.player,
    required this.isHost,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                PlayerAvatar(
                  character: player.character,
                  size: 40,
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          if (isHost) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ],
                      ),
                      
                      Text(
                        player.character?.displayName ?? "未選角色",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (onKick != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onKick,
                    tooltip: '踢出玩家',
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  player.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: player.isReady 
                      ? theme.colorScheme.secondary 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                
                const SizedBox(width: 4),
                
                Text(
                  player.isReady ? '已準備' : '未準備',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: player.isReady 
                        ? theme.colorScheme.secondary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _EmptyPlayerSlot extends StatelessWidget {
  final VoidCallback onInvite;

  const _EmptyPlayerSlot({
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onInvite,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '邀請好友',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
