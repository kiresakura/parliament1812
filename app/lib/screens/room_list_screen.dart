import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/room.dart';
import '../widgets/room_card.dart';
import '../widgets/connection_indicator.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // TODO: 載入房間列表
    _refreshRooms();
  }

  Future<void> _refreshRooms() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // TODO: 實際從 API 載入房間列表
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO: 從 Provider 取得實際房間列表
    final mockRooms = _getMockRooms();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('房間列表'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        actions: [
          const ConnectionIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshRooms,
          ),
        ],
      ),
      
      body: Column(
        children: [
          // 快速操作區
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateRoomDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('創建房間'),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showJoinRoomDialog(),
                        icon: const Icon(Icons.login),
                        label: const Text('加入房間'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 房間篩選
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '狀態篩選',
                          isDense: true,
                        ),
                        value: 'all',
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('全部')),
                          DropdownMenuItem(value: 'waiting', child: Text('等待中')),
                          DropdownMenuItem(value: 'playing', child: Text('遊戲中')),
                        ],
                        onChanged: (value) {
                          // TODO: 實現篩選邏輯
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: '搜尋房間',
                          suffixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          // TODO: 實現搜尋邏輯
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 房間列表
          Expanded(
            child: _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : mockRooms.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshRooms,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: mockRooms.length,
                          itemBuilder: (context, index) {
                            final room = mockRooms[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RoomCard(
                                room: room,
                                onTap: () => _joinRoom(room),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '尚無可用房間',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '創建一個新房間開始遊戲吧！',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () => _showCreateRoomDialog(),
            icon: const Icon(Icons.add),
            label: const Text('創建房間'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateRoomDialog(),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _JoinRoomDialog(),
    );
  }

  void _joinRoom(Room room) {
    if (!room.status.canJoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無法加入：${room.status.displayName}'),
        ),
      );
      return;
    }
    
    if (room.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('房間已滿'),
        ),
      );
      return;
    }

    // TODO: 實際加入房間邏輯
    context.go('/room/${room.code}');
  }

  // Mock 資料
  List<Room> _getMockRooms() {
    return [
      RoomFactory.createRoom(
        name: '新手友善房',
        hostPlayerId: 'host1',
        settings: const RoomSettings(maxPlayers: 4, minPlayers: 3),
      ).copyWith(
        players: [
          // Mock 玩家資料
        ],
      ),
      RoomFactory.createRoom(
        name: '高手對決',
        hostPlayerId: 'host2',
        settings: const RoomSettings(maxPlayers: 6),
      ).copyWith(
        status: RoomStatus.playing,
        players: [
          // Mock 玩家資料
        ],
      ),
      RoomFactory.createRoom(
        name: '歷史愛好者聚會',
        hostPlayerId: 'host3',
      ).copyWith(
        players: [
          // Mock 玩家資料
        ],
      ),
    ];
  }
}

class _CreateRoomDialog extends StatefulWidget {
  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  int _maxPlayers = 7;
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('創建房間'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: '房間名稱',
                hintText: '輸入房間名稱',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '請輸入房間名稱';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text('最大玩家數：'),
                const Spacer(),
                DropdownButton<int>(
                  value: _maxPlayers,
                  items: List.generate(5, (index) => index + 3)
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text('$i 人'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _maxPlayers = value!;
                    });
                  },
                ),
              ],
            ),
            
            SwitchListTile(
              title: const Text('私人房間'),
              subtitle: const Text('需要密碼才能加入'),
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
            
            if (_isPrivate)
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '房間密碼',
                  hintText: '輸入房間密碼',
                ),
                obscureText: true,
                validator: (value) {
                  if (_isPrivate && (value == null || value.isEmpty)) {
                    return '請輸入房間密碼';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => _createRoom(),
          child: const Text('創建'),
        ),
      ],
    );
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      // TODO: 實際創建房間
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('房間創建功能將在後續版本實現'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _JoinRoomDialog extends StatefulWidget {
  @override
  State<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<_JoinRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入房間'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: '房間代碼',
                hintText: '輸入 6 位房間代碼',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.length != 6) {
                  return '請輸入 6 位房間代碼';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密碼（如需要）',
                hintText: '輸入房間密碼',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => _joinRoom(),
          child: const Text('加入'),
        ),
      ],
    );
  }

  void _joinRoom() {
    if (_formKey.currentState!.validate()) {
      final roomCode = _roomCodeController.text.toUpperCase();
      // TODO: 實際加入房間
      Navigator.of(context).pop();
      context.go('/room/$roomCode');
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}