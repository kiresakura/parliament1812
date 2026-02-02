import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/matchmaking_provider.dart';
import '../../providers/auth_provider.dart';
import 'multiplayer_lobby_page.dart';

/// 配對頁面
class MatchmakingPage extends ConsumerStatefulWidget {
  const MatchmakingPage({super.key});

  @override
  ConsumerState<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends ConsumerState<MatchmakingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchmakingProvider);
    final authState = ref.watch(authProvider);

    // 監聽配對成功
    ref.listen<MatchmakingStatus>(matchmakingStatusProvider, (prev, next) {
      if (next == MatchmakingStatus.found) {
        _showMatchFoundDialog();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('多人對戰'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (matchState.isSearching) {
              _showCancelConfirmDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: matchState.isSearching
            ? _buildSearchingView(matchState)
            : _buildModeSelectionView(matchState, authState),
      ),
    );
  }

  /// 模式選擇畫面
  Widget _buildModeSelectionView(MatchmakingState matchState, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題
          const Text(
            '選擇遊戲模式',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 模式卡片
          Expanded(
            child: ListView(
              children: [
                _buildModeCard(
                  mode: GameMode.casual,
                  icon: Icons.sports_esports,
                  isSelected: matchState.selectedMode == GameMode.casual,
                ),
                const SizedBox(height: 16),
                _buildModeCard(
                  mode: GameMode.ranked,
                  icon: Icons.military_tech,
                  isSelected: matchState.selectedMode == GameMode.ranked,
                  isLocked: authState.isGuest, // 訪客無法玩排位
                  lockReason: '需要綁定帳號才能遊玩排位賽',
                ),
                const SizedBox(height: 16),
                _buildModeCard(
                  mode: GameMode.custom,
                  icon: Icons.group,
                  isSelected: matchState.selectedMode == GameMode.custom,
                  onTap: () {
                    // 直接跳轉到自訂房間頁面
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MultiplayerLobbyPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 開始配對按鈕
          if (matchState.selectedMode != GameMode.custom)
            ElevatedButton(
              onPressed: () => _startMatchmaking(authState),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '開始配對',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 模式卡片
  Widget _buildModeCard({
    required GameMode mode,
    required IconData icon,
    required bool isSelected,
    bool isLocked = false,
    String? lockReason,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLocked
          ? () => _showLockedMessage(lockReason ?? '此模式暫時無法使用')
          : onTap ?? () => ref.read(matchmakingProvider.notifier).selectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : isLocked
                    ? Colors.grey
                    : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 圖示
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.withValues(alpha: 0.3)
                    : (isSelected
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLocked ? Icons.lock : icon,
                color: isLocked
                    ? Colors.grey
                    : (isSelected ? const Color(0xFFD4AF37) : Colors.white),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? (lockReason ?? '暫時無法使用') : mode.description,
                    style: TextStyle(
                      color: isLocked
                          ? Colors.grey
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mode.minPlayers}-${mode.maxPlayers} 人',
                    style: TextStyle(
                      color: isLocked
                          ? Colors.grey
                          : const Color(0xFFD4AF37),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 選中標記
            if (isSelected && !isLocked)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFD4AF37),
              ),
          ],
        ),
      ),
    );
  }

  /// 搜尋中畫面
  Widget _buildSearchingView(MatchmakingState matchState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 搜尋動畫
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.search,
                color: Color(0xFFD4AF37),
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 搜尋狀態
          Text(
            '正在尋找對手...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            matchState.selectedMode.displayName,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // 等待時間
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatWaitingTime(matchState.waitingTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 佇列資訊
          Text(
            '佇列中：${matchState.playersInQueue} 人',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          if (matchState.estimatedWaitTime > 0)
            Text(
              '預估等待：約 ${matchState.estimatedWaitTime} 秒',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 48),

          // 取消按鈕
          OutlinedButton(
            onPressed: _cancelMatchmaking,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '取消配對',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWaitingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startMatchmaking(AuthState authState) {
    final playerName = authState.user?.effectiveDisplayName ?? '玩家';
    ref.read(matchmakingProvider.notifier).startMatchmaking(playerName);
  }

  void _cancelMatchmaking() {
    ref.read(matchmakingProvider.notifier).cancelMatchmaking();
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('取消配對', style: TextStyle(color: Colors.white)),
          content: const Text(
            '確定要取消配對嗎？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('繼續等待'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelMatchmaking();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('取消配對'),
            ),
          ],
        );
      },
    );
  }

  void _showMatchFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('找到對手！', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            '已找到合適的對手，準備開始遊戲！',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final roomCode =
                    await ref.read(matchmakingProvider.notifier).confirmMatch();
                if (roomCode != null && context.mounted) {
                  Navigator.pop(context); // 關閉對話框
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MultiplayerLobbyPage(roomCode: roomCode),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('進入遊戲'),
            ),
          ],
        );
      },
    );
  }

  void _showLockedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
