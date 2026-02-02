import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/room_provider.dart';
import '../widgets/common/common_widgets.dart';

/// 首頁 - 創建/加入房間
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _nicknameController = TextEditingController();
  bool _isCreating = false;
  String? _nicknameError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// 驗證暱稱
  bool _validateNickname() {
    setState(() => _nicknameError = null);

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _nicknameError = '請輸入暱稱');
      return false;
    } else if (nickname.length < 2) {
      setState(() => _nicknameError = '暱稱至少需要 2 個字');
      return false;
    }
    return true;
  }

  /// 創建房間
  Future<void> _createRoom() async {
    if (!_validateNickname()) return;

    setState(() => _isCreating = true);

    try {
      final gameService = ref.read(gameServiceProvider);
      final playerName = _nicknameController.text.trim();

      // 呼叫後端 API 創建房間
      final roomInfo = await gameService.createRoom(playerName);

      if (roomInfo == null) {
        _showError('創建房間失敗，請檢查網路連接');
        return;
      }

      // 更新本地狀態
      final player = PlayerState(
        id: roomInfo.player?['id'] ?? '',
        name: playerName,
        isHost: true,
      );

      ref.read(localPlayerProvider.notifier).setPlayer(player);
      ref.read(roomProvider.notifier).createRoom(
            roomInfo.roomId,
            roomInfo.roomCode,
            roomInfo.player?['id'] ?? '',
            player,
          );

      if (mounted) {
        context.goNamed('lobby', pathParameters: {'roomId': roomInfo.roomId});
      }
    } catch (e) {
      _showError('創建房間失敗：$e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// 導航到加入房間頁面
  void _goToJoinRoom() {
    context.push('/join');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lora()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 監聽錯誤
    ref.listen(socketErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        _showError(next);
        // 清除錯誤
        ref.read(socketErrorProvider.notifier).state = null;
      }
    });

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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 遊戲標題
                        _buildTitle(),
                        const SizedBox(height: 48),

                        // 主要卡片區域
                        _buildMainCard(),
                      ],
                    ),
                  ),
                ),
              ),

              // 連接狀態欄
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ConnectionStatusBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // 年份裝飾
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.accent.withAlpha(128), width: 1),
              bottom: BorderSide(color: AppTheme.accent.withAlpha(128), width: 1),
            ),
          ),
          child: Text(
            '· A.D. 1812 ·',
            style: GoogleFonts.cinzel(
              fontSize: 14,
              color: AppTheme.textSecondary,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 主標題
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentLight, AppTheme.accent],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            '國會風雲',
            style: GoogleFonts.notoSerifHk(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 12,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 英文副標題
        Text(
          'PARLIAMENT STORM',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 16,
            color: AppTheme.accent,
            letterSpacing: 6,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // 描述
        Text(
          '工業革命時代的議會辯論 RPG',
          style: GoogleFonts.lora(
            fontSize: 14,
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return VictorianCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 暱稱輸入
            NicknameInput(
              controller: _nicknameController,
              errorText: _nicknameError,
            ),
            const SizedBox(height: 24),

            // 創建房間按鈕
            VictorianButton(
              text: '創建房間',
              icon: Icons.add_circle_outline,
              onPressed: _isCreating ? null : _createRoom,
              isLoading: _isCreating,
              fullWidth: true,
              type: VictorianButtonType.primary,
            ),
            const SizedBox(height: 24),

            // 分隔線
            _buildDivider(),
            const SizedBox(height: 24),

            // 加入房間按鈕
            VictorianButton(
              text: '加入房間',
              icon: Icons.login,
              onPressed: _goToJoinRoom,
              fullWidth: true,
              type: VictorianButtonType.secondary,
            ),
            const SizedBox(height: 24),

            // 分隔線
            _buildDivider(),
            const SizedBox(height: 24),

            // 單人模式按鈕
            VictorianButton(
              text: '單人模式',
              icon: Icons.person,
              onPressed: () => context.push('/solo'),
              fullWidth: true,
              type: VictorianButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.accent.withAlpha(128),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withAlpha(128),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
