import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/room_provider.dart';
import '../widgets/common/common_widgets.dart';

/// 大廳畫面 - 等待玩家加入
class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _gameStartedSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 監聽遊戲開始事件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGameStartedListener();
    });
  }

  void _setupGameStartedListener() {
    final gameService = ref.read(gameServiceProvider);
    _gameStartedSubscription = gameService.onGameStarted.listen((data) {
      if (mounted) {
        final roomState = ref.read(gameProvider);
        if (roomState != null) {
          context.goNamed('game', pathParameters: {'roomId': roomState.roomId});
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gameStartedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(gameProvider);
    final localPlayer = ref.watch(localPlayerProvider);

    // 監聽連接錯誤
    ref.listen(socketErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        showToast(context, next, isError: true);
        ref.read(socketErrorProvider.notifier).state = null;
      }
    });

    if (roomState == null) {
      return _buildNoRoomState();
    }

    final isHost = localPlayer?.isHost ?? false;
    final canStart = roomState.canStart;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 連接狀態欄
              const ConnectionStatusBar(),

              // 頂部導航列
              _buildAppBar(),

              // 內容區域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 房間代碼顯示
                      RoomCodeDisplay(
                        code: roomState.roomCode,
                        title: '分享此代碼邀請朋友',
                      ),
                      const SizedBox(height: 24),

                      // 玩家列表
                      _buildPlayerListCard(roomState.players, localPlayer?.id),
                    ],
                  ),
                ),
              ),

              // 底部按鈕區
              _buildBottomActions(isHost, canStart, roomState.players.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRoomState() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: Center(
          child: VictorianCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  '房間不存在',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '該房間可能已關閉或代碼錯誤',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                VictorianButton(
                  text: '返回首頁',
                  icon: Icons.home,
                  onPressed: () => context.go('/'),
                  type: VictorianButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accent.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按鈕
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.accent),
            onPressed: () {
              _showLeaveConfirmation();
            },
          ),
          const SizedBox(width: 8),

          // 標題
          Expanded(
            child: Text(
              '等待室',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ),

          // 連接狀態指示器
          const ConnectionStatusIndicator(),
          const SizedBox(width: 8),

          // 等待動畫
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Text(
                  '等待中...',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerListCard(List<PlayerState> players, String? localPlayerId) {
    return VictorianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '玩家列表',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: players.length >= GameConstants.minPlayers
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ),
                child: Text(
                  '${players.length}/${GameConstants.maxPlayers}',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: players.length >= GameConstants.minPlayers
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: AppTheme.accent.withAlpha(77)),
          const SizedBox(height: 8),

          // 玩家列表
          ...players.map((player) {
            final isMe = player.id == localPlayerId;
            return _buildPlayerItem(player, isMe);
          }),

          // 空位提示
          if (players.length < GameConstants.maxPlayers)
            ...List.generate(
              GameConstants.maxPlayers - players.length,
              (index) => _buildEmptySlot(players.length + index + 1),
            ).take(3), // 最多顯示 3 個空位
        ],
      ),
    );
  }

  Widget _buildPlayerItem(PlayerState player, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: PlayerListTile(
        name: player.name,
        status: player.isHost
            ? PlayerStatus.ready
            : player.isReady
                ? PlayerStatus.ready
                : PlayerStatus.online,
        isHost: player.isHost,
        isCurrentPlayer: isMe,
      ),
    );
  }

  Widget _buildEmptySlot(int slotNumber) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textSecondary.withAlpha(51),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.textSecondary.withAlpha(77),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_add_outlined,
              color: AppTheme.textSecondary.withAlpha(128),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '等待玩家加入...',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: AppTheme.textSecondary.withAlpha(128),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isHost, bool canStart, int playerCount) {
    final localPlayer = ref.watch(localPlayerProvider);
    final isReady = localPlayer?.isReady ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.accent.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 人數提示
          if (playerCount < GameConstants.minPlayers)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withAlpha(77)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '需要至少 ${GameConstants.minPlayers} 人才能開始（還差 ${GameConstants.minPlayers - playerCount} 人）',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),

          // 主按鈕
          if (isHost)
            VictorianButton(
              text: '開始遊戲',
              icon: Icons.play_arrow,
              onPressed: canStart ? _startGame : null,
              fullWidth: true,
              type: VictorianButtonType.primary,
              size: VictorianButtonSize.large,
            )
          else
            VictorianButton(
              text: isReady ? '取消準備' : '準備',
              icon: isReady ? Icons.close : Icons.check,
              onPressed: _toggleReady,
              fullWidth: true,
              type: isReady
                  ? VictorianButtonType.secondary
                  : VictorianButtonType.primary,
              size: VictorianButtonSize.large,
            ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.accent),
        ),
        title: Text(
          '離開房間',
          style: GoogleFonts.cinzel(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '確定要離開房間嗎？',
          style: GoogleFonts.lora(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: GoogleFonts.lora(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveRoom();
            },
            child: Text(
              '離開',
              style: GoogleFonts.lora(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    // 通知後端
    final gameService = ref.read(gameServiceProvider);
    gameService.leaveRoom();

    // 清除本地狀態
    ref.read(roomProvider.notifier).leaveRoom();
    ref.read(gameProvider.notifier).leaveRoom();
    ref.read(localPlayerProvider.notifier).clear();

    context.go('/');
  }

  void _toggleReady() {
    final localPlayer = ref.read(localPlayerProvider);
    if (localPlayer == null) return;

    final newReady = !localPlayer.isReady;

    // 通知後端
    final gameService = ref.read(gameServiceProvider);
    gameService.setReady(newReady);

    // 更新本地狀態
    ref.read(localPlayerProvider.notifier).setPlayer(
          localPlayer.copyWith(isReady: newReady),
        );
    ref.read(gameProvider.notifier).setPlayerReady(localPlayer.id, newReady);
  }

  void _startGame() {
    final roomState = ref.read(gameProvider);
    if (roomState == null) return;

    // 通知後端開始遊戲
    final gameService = ref.read(gameServiceProvider);
    gameService.startGame();
  }
}
