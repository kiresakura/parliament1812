import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/multiplayer_game_provider.dart';
import '../../providers/socket_provider.dart';
import 'multiplayer_game_page.dart';

/// 多人遊戲大廳頁面
class MultiplayerLobbyPage extends ConsumerStatefulWidget {
  final String? roomCode; // 如果有，則為加入房間

  const MultiplayerLobbyPage({
    super.key,
    this.roomCode,
  });

  @override
  ConsumerState<MultiplayerLobbyPage> createState() => _MultiplayerLobbyPageState();
}

class _MultiplayerLobbyPageState extends ConsumerState<MultiplayerLobbyPage> {
  final _nameController = TextEditingController(text: '玩家');
  final _roomCodeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode != null) {
      _roomCodeController.text = widget.roomCode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(multiplayerGameProvider);
    final isConnected = ref.watch(isSocketConnectedProvider);

    // 監聽遊戲開始
    ref.listen<MultiplayerPhase>(multiplayerPhaseProvider, (prev, next) {
      if (next != MultiplayerPhase.lobby && prev == MultiplayerPhase.lobby) {
        // 遊戲開始，跳轉到遊戲頁面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MultiplayerGamePage(),
          ),
        );
      }
    });

    // 如果已經在房間中，顯示房間介面
    if (gameState.roomCode != null) {
      return _buildRoomView(gameState);
    }

    // 否則顯示創建/加入介面
    return _buildEntryView(isConnected);
  }

  /// 入口介面（創建或加入房間）
  Widget _buildEntryView(bool isConnected) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('多人對戰'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 連線狀態
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? '已連線' : '離線',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 玩家名稱輸入
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '玩家名稱',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 創建房間按鈕
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isConnected && !_isCreating ? _createRoom : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          '創建房間',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 分隔線
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '或',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 24),

              // 房間代碼輸入
              TextField(
                controller: _roomCodeController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: '房間代碼',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.meeting_room, color: Color(0xFFD4AF37)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 加入房間按鈕
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: isConnected && !_isJoining ? _joinRoom : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4AF37),
                          ),
                        )
                      : const Text(
                          '加入房間',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 房間介面
  Widget _buildRoomView(MultiplayerGameState gameState) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('房間 ${gameState.roomCode}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveRoom,
        ),
        actions: [
          // 複製房間代碼
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: gameState.roomCode ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('房間代碼已複製')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 房間代碼顯示
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '房間代碼',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameState.roomCode ?? '',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),

          // 玩家列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: gameState.players.length,
              itemBuilder: (context, index) {
                final player = gameState.players[index];
                return _buildPlayerCard(player, gameState.localPlayerId);
              },
            ),
          ),

          // 等待玩家提示
          if (gameState.players.length < 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '等待更多玩家加入... (${gameState.players.length}/4)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),

          // 底部按鈕區
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 準備/取消準備按鈕
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final isReady = gameState.localPlayer?.isReady ?? false;
                        ref.read(multiplayerGameProvider.notifier).setReady(!isReady);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameState.localPlayer?.isReady == true
                            ? Colors.red
                            : const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        gameState.localPlayer?.isReady == true ? '取消準備' : '準備',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 開始遊戲按鈕（僅房主可見）
                  if (gameState.isHost) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: gameState.canStartGame
                            ? () => ref.read(multiplayerGameProvider.notifier).startGame()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '開始遊戲',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 玩家卡片
  Widget _buildPlayerCard(MultiplayerPlayer player, String? localPlayerId) {
    final isLocal = player.id == localPlayerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocal
            ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // 頭像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 玩家資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '房主',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isLocal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '你',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.characterName ?? '尚未選擇角色',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 準備狀態
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: player.isReady
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              player.isReady ? '已準備' : '未準備',
              style: TextStyle(
                color: player.isReady ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入玩家名稱')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final success = await ref
        .read(multiplayerGameProvider.notifier)
        .createRoom(_nameController.text.trim());

    setState(() => _isCreating = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('創建房間失敗')),
      );
    }
  }

  Future<void> _joinRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入玩家名稱')),
      );
      return;
    }

    if (_roomCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入房間代碼')),
      );
      return;
    }

    setState(() => _isJoining = true);

    final success = await ref.read(multiplayerGameProvider.notifier).joinRoom(
          _roomCodeController.text.trim().toUpperCase(),
          _nameController.text.trim(),
        );

    setState(() => _isJoining = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加入房間失敗')),
      );
    }
  }

  void _leaveRoom() {
    ref.read(multiplayerGameProvider.notifier).leaveRoom();
  }
}
