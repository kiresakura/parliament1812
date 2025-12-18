import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/player_avatar.dart';
import 'scan_nfc_screen.dart';
import 'home_screen.dart';

/// 等待室畫面
class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('等待室'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showLeaveDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRoomCode(context),
            tooltip: '分享房間碼',
          ),
        ],
      ),
      body: Consumer2<RoomProvider, PlayerProvider>(
        builder: (context, roomProvider, playerProvider, _) {
          final room = roomProvider.room;
          if (room == null) return const SizedBox.shrink();

          return Column(
            children: [
              // 房間資訊
              _buildRoomInfo(context, room.code),

              // 玩家列表
              Expanded(
                child: _buildPlayerList(roomProvider.players),
              ),

              // 底部按鈕
              _buildBottomButtons(context, playerProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomInfo(BuildContext context, String roomCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '房間碼',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _copyRoomCode(context, roomCode),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  roomCode,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.copy,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊複製房間碼分享給朋友',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List players) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          '等待玩家加入...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return PlayerAvatar(
          nickname: player.nickname,
          roleType: player.roleType,
          isHost: player.isHost,
          hasRole: player.hasRole,
        );
      },
    );
  }

  Widget _buildBottomButtons(BuildContext context, PlayerProvider playerProvider) {
    final hasRole = playerProvider.hasRole;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NFC 掃卡按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasRole
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanNfcScreen(),
                          ),
                        ),
                icon: Icon(hasRole ? Icons.check_circle : Icons.nfc),
                label: Text(hasRole ? '已掃描卡片' : '掃描 NFC 卡片'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasRole ? Colors.green : AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 玩家數量提示
            Consumer<RoomProvider>(
              builder: (context, provider, _) {
                final count = provider.players.length;
                return Text(
                  '目前 $count 位玩家',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyRoomCode(BuildContext context, String roomCode) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('房間碼已複製'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareRoomCode(BuildContext context) {
    final roomCode = context.read<RoomProvider>().room?.code ?? '';
    Clipboard.setData(ClipboardData(text: '加入 1812 國會風雲！房間碼：$roomCode'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已複製分享訊息'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('離開房間'),
        content: const Text('確定要離開房間嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<RoomProvider>().leaveRoom();
              context.read<PlayerProvider>().clearPlayer();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }
}
