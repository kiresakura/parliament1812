import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import 'waiting_room_screen.dart';

/// 首頁 - 建立或加入房間
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nicknameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  bool _isCreating = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 背景圖片
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/parliament_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.3, // 半透明讓文字更清楚
          ),
          // 漸層疊加讓上方內容更清晰
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / 標題
                  _buildHeader(),
                  const SizedBox(height: 48),
                  // 切換按鈕
                  _buildToggleButtons(),
                  const SizedBox(height: 32),
                  // 表單
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 年份標誌
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.secondaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
            // 加點背景讓文字更清楚
            color: AppTheme.darkBackground.withValues(alpha: 0.7),
          ),
          child: const Text(
            '1812',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 加陰影讓文字在背景上更清楚
        Text(
          '國會風雲',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Parliament Debates',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[300],
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('建立房間', _isCreating, () {
            setState(() => _isCreating = true);
          }),
          _buildToggleButton('加入房間', !_isCreating, () {
            setState(() => _isCreating = false);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppTheme.darkBackground : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.secondaryColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 暱稱輸入
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '您的暱稱',
                  hintText: '輸入您的暱稱',
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 20,
              ),
              const SizedBox(height: 16),
              // 房間碼輸入（僅加入房間時顯示）
              if (!_isCreating) ...[
                TextField(
                  controller: _roomCodeController,
                  decoration: const InputDecoration(
                    labelText: '房間碼',
                    hintText: '輸入 6 位房間碼',
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
              ],
              // 錯誤訊息
              if (roomProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    roomProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              // 提交按鈕
              ElevatedButton(
                onPressed: roomProvider.isLoading ? null : _submit,
                child: roomProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBackground,
                        ),
                      )
                    : Text(_isCreating ? '建立房間' : '加入房間'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入暱稱')),
      );
      return;
    }

    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    if (_isCreating) {
      // 建立房間
      final room = await roomProvider.createRoom(nickname);
      if (room != null && mounted) {
        // 主持人自動加入房間
        final player = await roomProvider.joinRoom(room.code, nickname);
        if (player != null) {
          playerProvider.setCurrentPlayer(player);
          await roomProvider.connectWebSocket(player.id);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const WaitingRoomScreen(),
              ),
            );
          }
        }
      }
    } else {
      // 加入房間
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      if (roomCode.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入 6 位房間碼')),
        );
        return;
      }

      final player = await roomProvider.joinRoom(roomCode, nickname);
      if (player != null && mounted) {
        playerProvider.setCurrentPlayer(player);
        await roomProvider.connectWebSocket(player.id);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const WaitingRoomScreen(),
            ),
          );
        }
      }
    }
  }
}
