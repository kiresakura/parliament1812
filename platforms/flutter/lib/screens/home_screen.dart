import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../services/sound_service.dart';
import '../models/player.dart';
import 'waiting_room_screen.dart';
import 'settings_screen.dart';

/// 主選單畫面 - 維多利亞議會風格
/// 設計靈感：React MainMenu.tsx
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _hoveredButton;
  late AnimationController _glowController;

  // 國會背景圖片
  static const String backgroundImage =
      'https://images.unsplash.com/photo-1766219852821-7d27511eb836?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZW5haXNzYW5jZSUyMG9pbCUyMHBhaW50aW5nJTIwYnJpdGlzaCUyMHBhcmxpYW1lbnQlMjBpbnRlcmlvciUyMHdlc3RtaW5zdGVyfGVufDF8fHx8MTc2ODQ0NzI3N3ww&ixlib=rb-4.1.0&q=80&w=1080';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initSoundService();
  }

  Future<void> _initSoundService() async {
    try {
      await soundService.init().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // slate-950
      body: Stack(
        children: [
          // 背景圖片層
          _buildBackgroundLayer(),

          // 大氣粒子效果
          const _DustParticlesLayer(),

          // 裝飾邊框
          const _DecorativeFrame(),

          // 主內容
          SafeArea(
            child: Column(
              children: [
                // 頂部：玩家資料區
                _buildTopBar(),

                // 主內容區
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo 區域
                          _buildLogoSection(),
                          const SizedBox(height: 48),

                          // 選單按鈕
                          _buildMenuButtons(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 底部版本資訊
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 背景圖片層
  Widget _buildBackgroundLayer() {
    return Stack(
      children: [
        // 背景圖片
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: Transform.scale(
              scale: 1.05,
              child: Image.network(
                backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 備用本地圖片
                  return Image.asset(
                    'assets/images/parliament_background.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0F172A),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 漸層覆蓋
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0F172A), // slate-950/80
                  Color(0x667F1D1D), // red-950/40
                  Color(0xE50F172A), // slate-950/90
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 頂部玩家資料區
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildPlayerProfile(),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2, end: 0);
  }

  /// 玩家資料卡
  Widget _buildPlayerProfile() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A), // slate-900/80
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0x80B45309), // amber-700/50
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家名稱和等級
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '亞齊巴德勛爵',
                style: TextStyle(
                  fontFamily: 'NotoSerifTC',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFEF3C7), // amber-100
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              // 等級徽章
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x80451A03), // amber-950/50
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD97706), // amber-600
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 10,
                      color: const Color(0xFFFBBF24), // amber-400
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '等級 42',
                      style: TextStyle(
                        fontFamily: 'NotoSerifTC',
                        fontSize: 10,
                        color: Color(0xFFFBBF24), // amber-400
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 頭像
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFCD34D), // amber-300
            Color(0xFFB45309), // amber-700
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF1E293B), // slate-800
        child: const Icon(
          Icons.person,
          color: Color(0xFFFBBF24), // amber-400
          size: 24,
        ),
      ),
    );
  }

  /// Logo 區域
  Widget _buildLogoSection() {
    return Column(
      children: [
        // 皇冠 + 法槌圖標
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 皇冠
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(
                          alpha: 0.3 + _glowController.value * 0.3,
                        ),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: const Color(0xFFFBBF24), // amber-400
                  ),
                );
              },
            ),
            // 法槌
            Positioned(
              bottom: -8,
              right: -16,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  Icons.gavel,
                  size: 40,
                  color: const Color(0xFFD97706), // amber-600
                ),
              ),
            ),
          ],
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 24),

        // 標題：議會
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE68A), // amber-200
              Color(0xFFFBBF24), // amber-400
              Color(0xFFB45309), // amber-700
            ],
          ).createShader(bounds),
          child: const Text(
            '議會',
            style: TextStyle(
              fontFamily: 'NotoSerifTC',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ).animate().fadeIn(duration: 800.ms),

        // 副標題：1812
        Text(
          '1812',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFD97706).withValues(alpha: 0.9), // amber-600/90
            letterSpacing: 12,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: 12),

        // 分隔線 + 描述
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDividerLine(),
            const SizedBox(width: 12),
            Text(
              '世紀辯論',
              style: TextStyle(
                fontFamily: 'NotoSerifTC',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFDE68A).withValues(alpha: 0.8), // amber-200/80
                letterSpacing: 8,
              ),
            ),
            const SizedBox(width: 12),
            _buildDividerLine(),
          ],
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildDividerLine() {
    return Container(
      width: 48,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFFBBF24).withValues(alpha: 0.6), // amber-500
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  /// 選單按鈕區
  Widget _buildMenuButtons() {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            // 主要按鈕：建立房間
            _MenuButton(
              label: '建立房間',
              subLabel: '主持新的議程',
              variant: _MenuButtonVariant.primary,
              icon: Icons.workspace_premium,
              isHovered: _hoveredButton == 'create',
              onHover: () => setState(() => _hoveredButton = 'create'),
              onLeave: () => setState(() => _hoveredButton = null),
              onTap: () => _showCreateRoomDialog(),
            ),

            const SizedBox(height: 16),

            // 次要按鈕：加入房間
            _MenuButton(
              label: '加入房間',
              subLabel: '輸入代碼或瀏覽',
              variant: _MenuButtonVariant.secondary,
              icon: Icons.article_outlined,
              isHovered: _hoveredButton == 'join',
              onHover: () => setState(() => _hoveredButton = 'join'),
              onLeave: () => setState(() => _hoveredButton = null),
              onTap: () => _showJoinRoomDialog(),
            ),

            const SizedBox(height: 32),

            // 第三級按鈕
            _MenuButton(
              label: '遊戲說明',
              variant: _MenuButtonVariant.tertiary,
              icon: Icons.help_outline,
              isHovered: _hoveredButton == 'help',
              onHover: () => setState(() => _hoveredButton = 'help'),
              onLeave: () => setState(() => _hoveredButton = null),
              onTap: () => _showHelpDialog(),
            ),

            const SizedBox(height: 12),

            _MenuButton(
              label: '設定',
              variant: _MenuButtonVariant.tertiary,
              icon: Icons.settings_outlined,
              isHovered: _hoveredButton == 'settings',
              onHover: () => setState(() => _hoveredButton = 'settings'),
              onLeave: () => setState(() => _hoveredButton = null),
              onTap: () {
                soundService.buttonFeedback();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  /// 底部版本資訊
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Text(
        '版本 1.0.4 • 倫敦會期',
        style: TextStyle(
          fontFamily: 'NotoSerifTC',
          fontSize: 10,
          color: const Color(0xFF92400E).withValues(alpha: 0.6), // amber-800/60
          letterSpacing: 4,
        ),
      ),
    );
  }

  /// 顯示建立房間對話框
  void _showCreateRoomDialog() {
    soundService.buttonFeedback();
    final nicknameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _RoomDialog(
        title: '建立新議程',
        subtitle: 'CREATE NEW SESSION',
        nicknameController: nicknameController,
        submitLabel: '開始議程',
        onSubmit: () async {
          final nickname = nicknameController.text.trim();
          if (nickname.isEmpty) {
            _showError('請輸入您的暱稱');
            return;
          }

          Navigator.pop(context);
          await _createRoom(nickname);
        },
      ),
    );
  }

  /// 顯示加入房間對話框
  void _showJoinRoomDialog() {
    soundService.buttonFeedback();
    final nicknameController = TextEditingController();
    final roomCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _RoomDialog(
        title: '進入議事廳',
        subtitle: 'JOIN SESSION',
        nicknameController: nicknameController,
        roomCodeController: roomCodeController,
        submitLabel: '加入議程',
        onSubmit: () async {
          final nickname = nicknameController.text.trim();
          final roomCode = roomCodeController.text.trim().toUpperCase();

          if (nickname.isEmpty) {
            _showError('請輸入您的暱稱');
            return;
          }
          if (roomCode.length != 6) {
            _showError('請輸入 6 位房間碼');
            return;
          }

          Navigator.pop(context);
          await _joinRoom(nickname, roomCode);
        },
      ),
    );
  }

  /// 顯示遊戲說明
  void _showHelpDialog() {
    soundService.buttonFeedback();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.article_outlined, color: const Color(0xFFFBBF24)),
            const SizedBox(width: 12),
            const Text(
              '遊戲說明',
              style: TextStyle(
                fontFamily: 'NotoSerifTC',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFBBF24),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '📜 遊戲背景',
                '1812年英國，工業革命正改變一切。您將扮演國會議員，參與關於機器問題的激烈辯論。',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '🎭 角色分配',
                '使用 NFC 卡片掃描或手動選擇角色來獲得您的角色與秘密任務。',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '💬 遊戲流程',
                '1. 加入房間並獲得角色\n2. 研究角色與陣營策略\n3. 參與辯論與密謀\n4. 進行兩輪投票\n5. 揭曉結果與秘密任務',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '🗳️ 投票規則',
                '第一輪匿名投票只顯示比例，第二輪記名投票公開唱票。',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              soundService.buttonFeedback();
              Navigator.pop(context);
            },
            child: const Text(
              '了解了',
              style: TextStyle(
                fontFamily: 'NotoSerifTC',
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSerifTC',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFDE68A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontFamily: 'NotoSerifTC',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    soundService.haptic(HapticType.medium);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createRoom(String nickname) async {
    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final result = await roomProvider.createRoom(nickname);
    if (result != null && mounted) {
      final hostPlayer = roomProvider.players.isNotEmpty
          ? roomProvider.players.firstWhere(
              (p) => p.id == result.playerId,
              orElse: () => Player(
                id: result.playerId,
                roomId: result.roomId,
                nickname: nickname,
                isHost: true,
                joinedAt: DateTime.now(),
              ),
            )
          : Player(
              id: result.playerId,
              roomId: result.roomId,
              nickname: nickname,
              isHost: true,
              joinedAt: DateTime.now(),
            );
      playerProvider.setCurrentPlayer(hostPlayer);
      await roomProvider.connectWebSocket(result.playerId);
      soundService.play(SoundEffect.gavel);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
        );
      }
    }
  }

  Future<void> _joinRoom(String nickname, String roomCode) async {
    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final player = await roomProvider.joinRoom(roomCode, nickname);
    if (player != null && mounted) {
      playerProvider.setCurrentPlayer(player);
      await roomProvider.connectWebSocket(player.id);
      soundService.play(SoundEffect.pageTransition);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
        );
      }
    }
  }
}

// ==================== 子元件 ====================

/// 選單按鈕變體
enum _MenuButtonVariant { primary, secondary, tertiary }

/// 選單按鈕元件
class _MenuButton extends StatelessWidget {
  final String label;
  final String? subLabel;
  final _MenuButtonVariant variant;
  final IconData icon;
  final bool isHovered;
  final VoidCallback onHover;
  final VoidCallback onLeave;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    this.subLabel,
    required this.variant,
    required this.icon,
    required this.isHovered,
    required this.onHover,
    required this.onLeave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == _MenuButtonVariant.primary;
    final isSecondary = variant == _MenuButtonVariant.secondary;
    final isTertiary = variant == _MenuButtonVariant.tertiary;

    return MouseRegion(
      onEnter: (_) => onHover(),
      onExit: (_) => onLeave(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isTertiary ? 12 : 14,
          ),
          decoration: BoxDecoration(
            // Primary: 金色漸層背景
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFB45309), // amber-700
                      Color(0xFF78350F), // amber-900
                    ],
                  )
                : null,
            // Secondary: 深色背景
            color: isSecondary
                ? const Color(0xCC0F172A) // slate-900/80
                : (isTertiary ? Colors.transparent : null),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isPrimary
                  ? const Color(0x80FBBF24) // amber-500/50
                  : (isSecondary
                      ? const Color(0x4DB45309) // amber-700/30
                      : (isHovered
                          ? const Color(0x4D78350F) // amber-900/30
                          : Colors.transparent)),
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // 金色光暈效果（僅 Primary）
              if (isPrimary && isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFFBBF24).withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // 內容
              Row(
                children: [
                  // 圖標容器
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? const Color(0xFF451A03) // amber-950
                          : const Color(0x80020617), // slate-950/50
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: isTertiary ? 16 : 20,
                      color: isPrimary
                          ? const Color(0xFFFBBF24) // amber-400
                          : (isHovered
                              ? const Color(0xFFFBBF24)
                              : const Color(0xB3B45309)), // amber-700/70
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'NotoSerifTC',
                            fontSize: isTertiary ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: isPrimary
                                ? const Color(0xFFFEF3C7) // amber-100
                                : (isHovered
                                    ? const Color(0xFFFDE68A) // amber-200
                                    : const Color(0xFFD6D3D1)), // stone-300
                          ),
                        ),
                        if (subLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subLabel!,
                            style: TextStyle(
                              fontFamily: 'NotoSerifTC',
                              fontSize: 10,
                              letterSpacing: 2,
                              color: const Color(0xFFFDE68A)
                                  .withValues(alpha: 0.6), // amber-200/60
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 右箭頭
                  if (!isTertiary)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isHovered ? 1.0 : 0.6,
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.only(left: isHovered ? 4 : 0),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: isPrimary
                              ? const Color(0xFFFCD34D) // amber-300
                              : const Color(0xFF78716C), // stone-500
                        ),
                      ),
                    ),
                ],
              ),

              // 懸停邊框
              if (isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0x4DFBBF24), // amber-400/30
                        width: 2,
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
}

/// 塵埃粒子層
class _DustParticlesLayer extends StatelessWidget {
  const _DustParticlesLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(
            20,
            (index) => _DustParticle(delay: index * 0.5),
          ),
        ),
      ),
    );
  }
}

/// 單個塵埃粒子
class _DustParticle extends StatefulWidget {
  final double delay;

  const _DustParticle({required this.delay});

  @override
  State<_DustParticle> createState() => _DustParticleState();
}

class _DustParticleState extends State<_DustParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _startX;
  late double _startY;
  late double _endX;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _startX = random.nextDouble();
    _startY = random.nextDouble();
    _endX = _startX + (random.nextBool() ? 0.1 : -0.1);

    _controller = AnimationController(
      duration: Duration(seconds: 5 + random.nextInt(5)),
      vsync: this,
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final opacity = value < 0.5 ? value * 1.2 : (1 - value) * 1.2;

        return Positioned(
          left: MediaQuery.of(context).size.width *
              (_startX + (_endX - _startX) * value),
          top: MediaQuery.of(context).size.height * (_startY + (1 - value) * 0.3),
          child: Opacity(
            opacity: opacity.clamp(0.0, 0.6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A).withValues(alpha: 0.4), // amber-200/40
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFDE68A).withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 裝飾邊框
class _DecorativeFrame extends StatelessWidget {
  const _DecorativeFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0x4D78350F), // amber-900/30
            width: 2,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0x33FBBF24), // amber-500/20
            ),
          ),
          child: Stack(
            children: [
              // 四個角落裝飾
              Positioned(top: 0, left: 0, child: _CornerOrnament()),
              Positioned(
                top: 0,
                right: 0,
                child: Transform.rotate(
                  angle: math.pi / 2,
                  child: _CornerOrnament(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Transform.rotate(
                  angle: math.pi,
                  child: _CornerOrnament(),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Transform.rotate(
                  angle: -math.pi / 2,
                  child: _CornerOrnament(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 角落裝飾圖案
class _CornerOrnament extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _CornerOrnamentPainter(),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCCFBBF24) // amber-500/80
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.4, 0)
      ..quadraticBezierTo(
        size.width * 0.2, 0,
        size.width * 0.1, size.height * 0.3,
      )
      ..lineTo(size.width * 0.1, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.8, size.height * 0.1,
        size.width * 0.7, size.height * 0.4,
      )
      ..lineTo(0, size.height * 0.4)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // 小圓點裝飾
    final dotPaint = Paint()
      ..color = const Color(0xFFFCD34D) // amber-300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 房間對話框
class _RoomDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController nicknameController;
  final TextEditingController? roomCodeController;
  final String submitLabel;
  final VoidCallback onSubmit;

  const _RoomDialog({
    required this.title,
    required this.subtitle,
    required this.nicknameController,
    this.roomCodeController,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xF21E293B), // slate-800/95
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x66FBBF24), // amber-400/40
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'NotoSerifTC',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 11,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 24),

            // 暱稱輸入
            _buildInputField(
              controller: nicknameController,
              label: '您的暱稱',
              hint: '輸入暱稱...',
            ),

            // 房間碼輸入（如果需要）
            if (roomCodeController != null) ...[
              const SizedBox(height: 16),
              _buildInputField(
                controller: roomCodeController!,
                label: '房間代碼',
                hint: 'XXXXXX',
                isRoomCode: true,
              ),
            ],

            const SizedBox(height: 24),

            // 提交按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                ),
                child: Text(
                  submitLabel,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifTC',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 取消按鈕
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  fontFamily: 'NotoSerifTC',
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRoomCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSerifTC',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFBBF24),
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            textCapitalization:
                isRoomCode ? TextCapitalization.characters : TextCapitalization.none,
            maxLength: isRoomCode ? 6 : 20,
            textAlign: isRoomCode ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: isRoomCode ? 'monospace' : 'NotoSerifTC',
              fontSize: isRoomCode ? 22 : 15,
              color: Colors.white,
              letterSpacing: isRoomCode ? 6 : 0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontFamily: isRoomCode ? 'monospace' : 'NotoSerifTC',
                fontSize: isRoomCode ? 22 : 15,
                letterSpacing: isRoomCode ? 6 : 0,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isRoomCode ? 12 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
