import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';
import '../models/character.dart';
import 'scan_nfc_screen.dart';
import 'home_screen.dart';

/// 等待室畫面 - 維多利亞風格 + Civ6 六角形元素
class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          // 六角形紋理背景
          const HexagonPatternBackground(
            color: AppTheme.accentGold,
            opacity: 0.02,
          ),
          // 大氣粒子效果
          const AtmosphereParticles(
            particleCount: 15,
            color: AppTheme.accentGold,
          ),
          // 主內容
          SafeArea(
            child: Consumer2<RoomProvider, PlayerProvider>(
              builder: (context, roomProvider, playerProvider, _) {
                final room = roomProvider.room;
                if (room == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    // 頂部導航欄
                    _buildAppBar(context),
                    // 房間資訊卡
                    _buildRoomInfo(context, room.code),
                    // 玩家列表
                    Expanded(
                      child: _buildPlayerList(roomProvider.players),
                    ),
                    // 底部按鈕
                    _buildBottomButtons(context, playerProvider, roomProvider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按鈕 - 擴大點擊區域 (最小 48x48)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLeaveDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
            ),
          ),
          // 標題
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HexagonIcon(
                  size: 18,
                  color: AppTheme.accentGold,
                ),
                SizedBox(width: 10),
                Text(
                  '等候大廳',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(width: 10),
                HexagonIcon(
                  size: 18,
                  color: AppTheme.accentGold,
                ),
              ],
            ),
          ),
          // 分享按鈕 - 擴大點擊區域 (最小 48x48)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _shareRoomCode(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfo(BuildContext context, String roomCode) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 皇家通行證票券
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBackground,
              border: Border.all(
                color: AppTheme.accentGold,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 內框虛線邊框
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 羊皮紙紋理
                      const ParchmentTexture(),
                      // 主要內容
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            // 標題
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CrownIcon(size: 14, color: AppTheme.accentGold),
                                SizedBox(width: 8),
                                Text(
                                  '皇家通行證',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 10,
                                    color: AppTheme.textTertiary,
                                    letterSpacing: 6,
                                  ),
                                ),
                                SizedBox(width: 8),
                                CrownIcon(size: 14, color: AppTheme.accentGold),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 房間碼
                            GestureDetector(
                              onTap: () {
                                _copyRoomCode(context, roomCode);
                                soundService.buttonFeedback();
                              },
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      border: Border(
                                        top: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                                        bottom: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accentGold.withValues(
                                            alpha: 0.1 + (_pulseController.value * 0.1),
                                          ),
                                          blurRadius: 10 + (_pulseController.value * 5),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      roomCode,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 10,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.8),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 複製按鈕
                            GestureDetector(
                              onTap: () {
                                _copyRoomCode(context, roomCode);
                                soundService.buttonFeedback();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: AppTheme.accentGold,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '複製通行碼',
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 10,
                                        color: AppTheme.accentGold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 角落裝飾
                      ...[ Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight ].map((align) =>
                        Positioned(
                          left: align == Alignment.topLeft || align == Alignment.bottomLeft ? 0 : null,
                          right: align == Alignment.topRight || align == Alignment.bottomRight ? 0 : null,
                          top: align == Alignment.topLeft || align == Alignment.topRight ? 0 : null,
                          bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight ? 0 : null,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              border: Border(
                                right: align == Alignment.topLeft || align == Alignment.bottomLeft
                                    ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.5))
                                    : BorderSide.none,
                                left: align == Alignment.topRight || align == Alignment.bottomRight
                                    ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.5))
                                    : BorderSide.none,
                                bottom: align == Alignment.topLeft || align == Alignment.topRight
                                    ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.5))
                                    : BorderSide.none,
                                top: align == Alignment.bottomLeft || align == Alignment.bottomRight
                                    ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.5))
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 票券缺口
                Positioned(
                  left: -6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentGold, width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentGold, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 統計面板
          Row(
            children: [
              Expanded(
                child: Consumer<RoomProvider>(
                  builder: (context, roomProvider, _) {
                    final playerCount = roomProvider.players.length;
                    return _buildStatPanel('在席成員', '$playerCount', '/ 20');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer<RoomProvider>(
                  builder: (context, roomProvider, _) {
                    final readyCount = roomProvider.players.where((p) => p.hasRole).length;
                    final totalCount = roomProvider.players.length;
                    final allReady = readyCount == totalCount && totalCount > 0;
                    return _buildStatPanel(
                      '準備就緒',
                      '$readyCount',
                      '/ $totalCount',
                      highlight: allReady,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatPanel(String label, String value, String suffix, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 10,
              color: AppTheme.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppTheme.voteAye : AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 12,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List players) {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HexagonBadge(
              size: 64,
              child: Icon(
                Icons.hourglass_empty,
                color: AppTheme.accentGold.withValues(alpha: 0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '靜候各位議員蒞臨...',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 2000.ms,
            color: AppTheme.accentGold.withValues(alpha: 0.3),
          );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題欄 - 國會議員名單
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 1,
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '國會議員名單',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        color: AppTheme.accentGold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 1,
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'MEMBERS OF PARLIAMENT',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 9,
                    color: AppTheme.textTertiary.withValues(alpha: 0.7),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          // 分隔線
          const VictorianDivider(width: double.infinity),
          const SizedBox(height: 12),
          // 玩家網格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return _PlayerCard(
                  nickname: player.nickname,
                  roleType: player.roleType,
                  roleIndex: player.roleIndex,
                  isHost: player.isHost,
                  hasRole: player.hasRole,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    PlayerProvider playerProvider,
    RoomProvider roomProvider,
  ) {
    final hasRole = playerProvider.hasRole;
    final playerCount = roomProvider.players.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NFC 掃卡按鈕或已完成狀態
            SizedBox(
              width: double.infinity,
              child: hasRole
                  ? _buildCompletedButton()
                  : _buildScanButton(context),
            ),
            const SizedBox(height: 12),
            // 玩家數量和狀態提示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HexagonIcon(
                  size: 14,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '已有 $playerCount 位議員就座',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
                if (playerCount >= 5) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.voteAye.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppTheme.voteAye.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '可開始',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 10,
                        color: AppTheme.voteAye,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        soundService.buttonFeedback();
        Navigator.push(
          context,
          SlidePageRoute(
            page: const ScanNfcScreen(),
            direction: AxisDirection.up,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentGold,
              Color(0xFFB8941F),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc,
              color: AppTheme.primaryBackground,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              '領取身份令牌',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppTheme.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3));
  }

  Widget _buildCompletedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.voteAye.withValues(alpha: 0.15),
        border: Border.all(
          color: AppTheme.voteAye,
          width: 2,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.voteAye,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            '身份已確認',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppTheme.voteAye,
            ),
          ),
        ],
      ),
    );
  }

  void _copyRoomCode(BuildContext context, String roomCode) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentGold),
            SizedBox(width: 8),
            Text(
              '房間碼已複製',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareRoomCode(BuildContext context) {
    soundService.buttonFeedback();
    final roomCode = context.read<RoomProvider>().room?.code ?? '';
    Clipboard.setData(
      ClipboardData(text: '誠邀閣下參與 1812 國會風雲！房間代碼：$roomCode'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: AppTheme.accentGold),
            SizedBox(width: 8),
            Text(
              '分享訊息已複製',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    soundService.haptic(HapticType.medium);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.5)),
        ),
        title: const Row(
          children: [
            HexagonIcon(
              size: 20,
              color: AppTheme.accentGold,
            ),
            SizedBox(width: 10),
            Text(
              '告辭離席',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          '確定要離開議會廳嗎？',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              soundService.haptic(HapticType.light);
              Navigator.pop(context);
            },
            child: const Text(
              '留步',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppTheme.textTertiary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              soundService.buttonFeedback();
              context.read<RoomProvider>().leaveRoom();
              context.read<PlayerProvider>().clearPlayer();
              Navigator.pushAndRemoveUntil(
                context,
                FadePageRoute(page: const HomeScreen()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.voteNay,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '離席',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 玩家卡片元件 - 1812 歷史風格 (帶動畫)
class _PlayerCard extends StatefulWidget {
  final String nickname;
  final String? roleType;
  final int? roleIndex;
  final bool isHost;
  final bool hasRole;
  final int index;

  const _PlayerCard({
    required this.nickname,
    this.roleType,
    this.roleIndex,
    required this.isHost,
    required this.hasRole,
    required this.index,
  });

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _glowController;
  late AnimationController _entryController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _entryScaleAnimation;
  late Animation<double> _entryOpacityAnimation;

  Character? get character {
    if (widget.roleIndex == null) return null;
    if (widget.roleIndex! < Characters1812.all.length) {
      return Characters1812.all[widget.roleIndex!];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    // 呼吸動畫 - 頭像輕微縮放
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // 光暈動畫 - 等待玩家的脈動效果
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 進場動畫
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entryScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
    _entryOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 延遲啟動進場動畫
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) {
        _entryController.forward();
      }
    });

    // 啟動持續動畫
    _breathingController.repeat(reverse: true);
    if (!widget.hasRole) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當玩家狀態改變時，更新動畫
    if (oldWidget.hasRole != widget.hasRole) {
      if (widget.hasRole) {
        _glowController.stop();
      } else {
        _glowController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final char = character;
    final partyColor = char?.partyColor ?? AppTheme.accentGold;
    final borderColor = widget.isHost
        ? AppTheme.accentGold
        : widget.hasRole
            ? partyColor.withValues(alpha: 0.6)
            : AppTheme.textTertiary.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _breathingController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _entryScaleAnimation.value,
          child: Opacity(
            opacity: _entryOpacityAnimation.value.clamp(0.0, 1.0),
            child: Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: widget.isHost ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // 主持人金色光暈
          if (widget.isHost)
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.3 + (_glowAnimation.value * 0.2)),
              blurRadius: 16 + (_glowAnimation.value * 8),
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // 羊皮紙紋理
          const ParchmentTexture(),
          // 裝飾角落
          ...[ Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight ].map((align) =>
            Positioned(
              left: align == Alignment.topLeft || align == Alignment.bottomLeft ? 0 : null,
              right: align == Alignment.topRight || align == Alignment.bottomRight ? 0 : null,
              top: align == Alignment.topLeft || align == Alignment.topRight ? 0 : null,
              bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight ? 0 : null,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  border: Border(
                    top: align == Alignment.topLeft || align == Alignment.topRight
                        ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.4))
                        : BorderSide.none,
                    bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                        ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.4))
                        : BorderSide.none,
                    left: align == Alignment.topLeft || align == Alignment.bottomLeft
                        ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.4))
                        : BorderSide.none,
                    right: align == Alignment.topRight || align == Alignment.bottomRight
                        ? BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.4))
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          // 主要內容
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 頭像 (帶動畫)
                _buildAnimatedAvatar(char, partyColor),
                const SizedBox(height: 8),
                // 玩家暱稱
                Text(
                  widget.nickname,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                // 分隔線
                if (widget.hasRole && char != null) ...[
                  Container(
                    width: 30,
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                  ),
                  // 角色名稱（中文）
                  Text(
                    char.nameChinese,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 9,
                      color: AppTheme.accentGold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  // 角色名稱（英文）
                  Text(
                    char.nameEnglish,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 7,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textTertiary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 4),
                // 狀態標籤 (帶動畫)
                _buildStatusBadge(),
              ],
            ),
          ),
        ],
      ),
            ),
          ),
        );
      },
    );
  }

  /// 動畫頭像元件
  Widget _buildAnimatedAvatar(Character? char, Color partyColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 等待中的脈動光暈 (只有未準備好的玩家顯示)
        if (!widget.hasRole && !widget.isHost)
          Positioned.fill(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1 + (_glowAnimation.value * 0.15)),
                    blurRadius: 12 + (_glowAnimation.value * 8),
                    spreadRadius: _glowAnimation.value * 4,
                  ),
                ],
              ),
            ),
          ),
        // 旋轉方形裝飾 (帶呼吸動畫)
        Transform.scale(
          scale: _breathingAnimation.value,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.2 + (_breathingAnimation.value - 1.0) * 2),
                width: 2,
              ),
            ),
            transform: Matrix4.rotationZ(0.785398 + (_breathingAnimation.value - 1.0) * 0.1), // 45度 + 輕微旋轉
            transformAlignment: Alignment.center,
          ),
        ),
        // 圓形頭像 (帶呼吸動畫)
        Transform.scale(
          scale: _breathingAnimation.value,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isHost ? AppTheme.accentGold : (char?.partyColor ?? AppTheme.textTertiary),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                // 已準備好的玩家綠色光暈
                if (widget.hasRole)
                  BoxShadow(
                    color: AppTheme.voteAye.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                // 主持人金色光暈
                if (widget.isHost)
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.4 + (_breathingAnimation.value - 1.0) * 2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipOval(
              child: widget.hasRole && char != null
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.brown.withValues(alpha: 0.3),
                        BlendMode.saturation,
                      ),
                      child: Image.asset(
                        char.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: partyColor.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              widget.nickname.isNotEmpty ? widget.nickname[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: partyColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.primaryBackground.withValues(alpha: 0.5),
                      child: Center(
                        child: Text(
                          widget.nickname.isNotEmpty ? widget.nickname[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        // 狀態徽章 (帶彈跳動畫)
        Positioned(
          bottom: -4,
          right: -4,
          child: Transform.scale(
            scale: widget.hasRole ? 1.0 + (_breathingAnimation.value - 1.0) * 0.5 : 1.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.isHost
                    ? AppTheme.accentGold
                    : widget.hasRole
                        ? AppTheme.voteAye
                        : const Color(0xFF3D3D3D),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                  if (widget.hasRole || widget.isHost)
                    BoxShadow(
                      color: (widget.isHost ? AppTheme.accentGold : AppTheme.voteAye)
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(
                child: widget.isHost
                    ? const CrownIcon(size: 10, color: AppTheme.primaryBackground)
                    : widget.hasRole
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B8B8B),
                              shape: BoxShape.circle,
                            ),
                          ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 狀態標籤 (帶動畫效果)
  Widget _buildStatusBadge() {
    final isWaiting = !widget.hasRole && !widget.isHost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isHost
            ? AppTheme.accentGold.withValues(alpha: 0.1)
            : widget.hasRole
                ? AppTheme.voteAye.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isHost
              ? AppTheme.accentGold.withValues(alpha: 0.4)
              : widget.hasRole
                  ? AppTheme.voteAye.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1 + (_glowAnimation.value * 0.1)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 等待中的閃爍指示器
          if (isWaiting) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF717171),
                  const Color(0xFF9A9A9A),
                  _glowAnimation.value,
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            widget.isHost ? '議長' : widget.hasRole ? '已就緒' : '準備中',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: widget.isHost
                  ? AppTheme.accentGold
                  : widget.hasRole
                      ? const Color(0xFF5C8A56)
                      : const Color(0xFF717171),
            ),
          ),
        ],
      ),
    );
  }
}
