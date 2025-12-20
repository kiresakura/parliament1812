import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/player_provider.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/secret_mission_card.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';

/// 角色卡展示畫面 - 帶有翻牌動畫和火漆蠟封效果
/// Civ6 風格 + 維多利亞時代設計
class RoleCardScreen extends StatefulWidget {
  const RoleCardScreen({super.key});

  @override
  State<RoleCardScreen> createState() => _RoleCardScreenState();
}

class _RoleCardScreenState extends State<RoleCardScreen>
    with TickerProviderStateMixin {
  bool _showSecret = false;
  bool _cardRevealed = false;
  bool _sealBroken = false;
  late AnimationController _flipController;
  late AnimationController _sealController;
  late AnimationController _glowController;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _shineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // 延遲顯示蠟封提示
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        soundService.play(SoundEffect.paperRustle);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _sealController.dispose();
    _glowController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  void _breakSeal() {
    if (_sealBroken) return;

    soundService.play(SoundEffect.sealStamp);
    soundService.haptic(HapticType.heavy);

    setState(() => _sealBroken = true);
    _sealController.forward();

    // 蠟封破碎後翻開卡片
    Future.delayed(const Duration(milliseconds: 600), () {
      _revealCard();
    });
  }

  void _revealCard() {
    if (_cardRevealed) return;

    soundService.play(SoundEffect.cardFlip);
    soundService.haptic(HapticType.medium);

    _flipController.forward();
    setState(() => _cardRevealed = true);

    // 卡片翻開後播放戲劇性音效
    Future.delayed(const Duration(milliseconds: 800), () {
      soundService.play(SoundEffect.dramatic);
    });
  }

  void _toggleSecret() {
    soundService.buttonFeedback();
    setState(() => _showSecret = !_showSecret);
    if (_showSecret) {
      soundService.play(SoundEffect.quillWriting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Civ6 風格六角形背景
          const HexagonPatternBackground(),
          // 粒子效果
          const AtmosphereParticles(particleCount: 30),
          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  AppTheme.primaryBackground.withValues(alpha: 0.95),
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // 暈影效果
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBackground.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // 主內容
          SafeArea(
            child: Consumer<PlayerProvider>(
              builder: (context, provider, _) {
                final player = provider.currentPlayer;
                final role = player?.role;
                final mission = provider.secretMission;

                if (player == null || role == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HexagonBadge(
                          size: 100,
                          glowColor: AppTheme.accentGold,
                          child: CrownIcon(size: 50),
                        ),
                        SizedBox(height: 24),
                        Text(
                          '正在準備您的身份文件...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            color: AppTheme.accentGold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Preparing your credentials...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // 自訂 AppBar
                    _buildAppBar(role),
                    // 內容
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 翻牌動畫或蠟封卡片
                            _buildRoleCard(role),
                            const SizedBox(height: 28),

                            // 秘密任務區域
                            if (_cardRevealed) ...[
                              _buildSecretToggle()
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 500.ms)
                                  .slideY(begin: 0.3, end: 0),
                              const SizedBox(height: 16),

                              // 秘密任務卡（可展開）
                              AnimatedSize(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                child: _showSecret && mission != null
                                    ? SecretMissionCard(mission: mission)
                                        .animate()
                                        .fadeIn(duration: 400.ms)
                                        .slideY(begin: 0.1, end: 0)
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 24),

                              // 提示文字
                              _buildWarningBox()
                                  .animate()
                                  .fadeIn(delay: 700.ms, duration: 500.ms),
                              const SizedBox(height: 24),

                              // 確認按鈕
                              _buildConfirmButton()
                                  .animate()
                                  .fadeIn(delay: 900.ms, duration: 500.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(role) {
    final roleColor = _getRoleColor(role.roleType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withValues(alpha: 0.95),
            AppTheme.cardBackground.withValues(alpha: 0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按鈕 - 六角形風格
          GestureDetector(
            onTap: () {
              soundService.buttonFeedback();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.accentGold,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // 標題區域
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(
                      alpha: 0.4 + (_glowController.value * 0.3),
                    ),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(
                        alpha: 0.1 + (_glowController.value * 0.1),
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HexagonIcon(
                      size: 16,
                      color: roleColor,
                      filled: true,
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      children: [
                        Text(
                          '身份證明書',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'CREDENTIALS',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    HexagonIcon(
                      size: 16,
                      color: roleColor,
                      filled: true,
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          const SizedBox(width: 40), // 平衡左側按鈕
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0);
  }

  Color _getRoleColor(String roleType) {
    // 使用 AppTheme 統一的角色顏色
    return AppTheme.getRoleColor(roleType);
  }

  Widget _buildRoleCard(role) {
    if (!_sealBroken) {
      // 顯示密封卡片
      return _buildSealedCard(role);
    }

    // 翻牌動畫
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        final angle = _flipController.value * 3.14159;
        final isBack = angle > 3.14159 / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: RoleCardWidget(role: role),
                )
              : _buildCardBack(role),
        );
      },
    );
  }

  Widget _buildSealedCard(role) {
    final roleColor = _getRoleColor(role.roleType);

    return GestureDetector(
      onTap: _breakSeal,
      child: Container(
        width: double.infinity,
        height: 420,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.parchmentColor,
              AppTheme.parchmentDark,
              AppTheme.parchmentColor.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentGold,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景紋理
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: CustomPaint(
                  painter: _ParchmentPainter(),
                ),
              ),
            ),
            // 六角形裝飾圖案
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 0.866,
                  ),
                  itemCount: 36,
                  itemBuilder: (context, index) => const Center(
                    child: HexagonIcon(
                      size: 30,
                      color: AppTheme.inkColor,
                      filled: false,
                    ),
                  ),
                ),
              ),
            ),
            // 中央蠟封
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 年份
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GearIcon(size: 24, color: AppTheme.inkColor.withValues(alpha: 0.2)),
                    const SizedBox(width: 16),
                    Text(
                      '1812',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkColor.withValues(alpha: 0.2),
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GearIcon(size: 24, color: AppTheme.inkColor.withValues(alpha: 0.2)),
                  ],
                ),
                const SizedBox(height: 24),
                // 蠟封 - 六角形風格
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            roleColor,
                            roleColor.withValues(alpha: 0.8),
                            AppTheme.waxSealColor,
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(4, 4),
                          ),
                          BoxShadow(
                            color: roleColor.withValues(
                              alpha: 0.3 + (_glowController.value * 0.3),
                            ),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: CrownIcon(
                          size: 55,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // 提示文字
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.inkColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '點擊蠟封揭示身份',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 14,
                          color: AppTheme.inkColor.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to reveal your identity',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 11,
                          color: AppTheme.inkColor.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .fadeIn()
                    .then()
                    .fadeOut(duration: 1200.ms),
              ],
            ),
            // 裝飾角落
            ..._buildCornerDecorations(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  List<Widget> _buildCornerDecorations() {
    return [
      Positioned(
        top: 15,
        left: 15,
        child: _buildCornerOrnament(),
      ),
      Positioned(
        top: 15,
        right: 15,
        child: Transform.scale(
          scaleX: -1,
          child: _buildCornerOrnament(),
        ),
      ),
      Positioned(
        bottom: 15,
        left: 15,
        child: Transform.scale(
          scaleY: -1,
          child: _buildCornerOrnament(),
        ),
      ),
      Positioned(
        bottom: 15,
        right: 15,
        child: Transform.scale(
          scaleX: -1,
          scaleY: -1,
          child: _buildCornerOrnament(),
        ),
      ),
    ];
  }

  Widget _buildCornerOrnament() {
    return SizedBox(
      width: 35,
      height: 35,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 2),
                left: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 2),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: HexagonIcon(
              size: 12,
              color: AppTheme.accentGold.withValues(alpha: 0.4),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(role) {
    final roleColor = _getRoleColor(role.roleType);

    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor.withValues(alpha: 0.4),
            AppTheme.cardBackground,
            roleColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 六角形背景圖案
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.866,
                ),
                itemCount: 25,
                itemBuilder: (context, index) => Center(
                  child: HexagonIcon(
                    size: 40,
                    color: roleColor,
                    filled: false,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 六角形徽章
                HexagonBadge(
                  size: 100,
                  glowColor: roleColor,
                  child: CrownIcon(size: 50, color: roleColor),
                ),
                const SizedBox(height: 24),
                Text(
                  '國會風雲',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const VictorianDivider(width: 150),
                const SizedBox(height: 12),
                Text(
                  'PARLIAMENT 1812',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    color: roleColor.withValues(alpha: 0.7),
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretToggle() {
    return GestureDetector(
      onTap: _toggleSecret,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _showSecret
                  ? AppTheme.waxSealColor.withValues(alpha: 0.2)
                  : AppTheme.cardBackground,
              AppTheme.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showSecret
                ? AppTheme.waxSealColor
                : AppTheme.accentGold.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: _showSecret
              ? [
                  BoxShadow(
                    color: AppTheme.waxSealColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 六角形圖示
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showSecret
                    ? AppTheme.waxSealColor.withValues(alpha: 0.2)
                    : AppTheme.accentGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: _showSecret
                      ? AppTheme.waxSealColor.withValues(alpha: 0.5)
                      : AppTheme.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                _showSecret ? Icons.lock_open : Icons.lock,
                color: _showSecret ? AppTheme.waxSealColor : AppTheme.accentGold,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showSecret ? '隱藏秘密任務' : '查看秘密任務',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _showSecret
                        ? AppTheme.waxSealColor
                        : AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _showSecret ? 'Hide Secret Mission' : 'View Secret Mission',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            HexagonIcon(
              size: 20,
              color: _showSecret ? AppTheme.waxSealColor : AppTheme.accentGold,
              filled: _showSecret,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          HexagonBadge(
            size: 50,
            glowColor: AppTheme.accentGold,
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.accentGold,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '請牢記閣下的身份與秘密任務',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '議會開議後將無法再次查閱密函',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.accentGold,
                Color(0xFFB8941F),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                soundService.buttonFeedback();
                soundService.play(SoundEffect.gavel);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HexagonIcon(
                    size: 20,
                    color: AppTheme.primaryBackground,
                    filled: true,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '吾已熟知，準備就緒',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBackground,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 光澤動畫
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    (_shineController.value * 400) - 100,
                    0,
                  ),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 羊皮紙紋理繪製器
class _ParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.inkColor.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    // 繪製細微紋理線條
    for (var i = 0; i < size.height; i += 4) {
      final offset = (i % 8 == 0) ? 1.0 : 0.0;
      canvas.drawLine(
        Offset(offset, i.toDouble()),
        Offset(size.width - offset, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
