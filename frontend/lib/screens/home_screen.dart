import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';
import 'waiting_room_screen.dart';
import 'settings_screen.dart';

/// 首頁 - 建立或加入房間
/// 設計風格：維多利亞時代 + 文明6六角形元素
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _nicknameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  bool _isCreating = true;
  late AnimationController _glowController;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _shineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // 初始化音效服務
    soundService.init();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _roomCodeController.dispose();
    _glowController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          // 六角形紋理背景 (Civ 6 風格) - 裝飾性元素，排除語義
          const ExcludeSemantics(
            child: HexagonPatternBackground(
              color: AppTheme.accentGold,
              opacity: 0.03,
            ),
          ),

          // 國會背景圖片 - 裝飾性元素，排除語義
          ExcludeSemantics(
            child: Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Image.asset(
                    'assets/images/parliament_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),

          // 漸層暈影效果 - 裝飾性元素，排除語義
          ExcludeSemantics(
            child: Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      AppTheme.primaryBackground.withValues(alpha: 0.6),
                      AppTheme.primaryBackground.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 大氣粒子效果 - 裝飾性元素，排除語義
          const ExcludeSemantics(
            child: AtmosphereParticles(
              particleCount: 25,
              color: AppTheme.accentGold,
            ),
          ),

          // 主內容
          SafeArea(
            child: Column(
              children: [
                // Victoria 3 風格頂部狀態欄
                _buildTopStatsBar(),

                // 主內容區 (可滾動)
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo / 標題
                              _buildHeader(),
                              const SizedBox(height: 40),
                              // 切換按鈕
                              _buildToggleButtons(),
                              const SizedBox(height: 28),
                              // 表單
                              _buildForm(),
                              const SizedBox(height: 24),
                              // 歷史引言
                              _buildQuote(),
                            ],
                          ),
                        ),
                      ),
                      // 設定按鈕
                      Positioned(
                        top: 12,
                        right: 16,
                        child: _buildSettingsButton(),
                      ),
                    ],
                  ),
                ),

                // 固定底部操作欄
                _buildFixedBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 固定底部操作欄
  Widget _buildFixedBottomBar() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        return FixedBottomBar(
          children: [
            // 幫助按鈕
            Semantics(
              button: true,
              label: '遊戲說明，點擊查看遊戲規則和流程',
              child: BottomBarButton(
                icon: Icons.help_outline,
                label: '遊戲說明',
                onTap: () {
                  soundService.buttonFeedback();
                  _showHelpDialog();
                },
              ),
            ),
            // 主要操作按鈕
            Semantics(
              button: true,
              label: _isCreating ? '建立房間，點擊建立新的遊戲房間' : '加入房間，點擊加入現有的遊戲房間',
              enabled: !roomProvider.isLoading,
              child: BottomBarButton(
                icon: _isCreating ? Icons.add_circle : Icons.login,
                label: _isCreating ? '建立房間' : '加入房間',
                isPrimary: true,
                isLoading: roomProvider.isLoading,
                onTap: roomProvider.isLoading ? null : _submit,
              ),
            ),
            // 設定按鈕
            Semantics(
              button: true,
              label: '設定，點擊開啟應用程式設定',
              child: BottomBarButton(
                icon: Icons.settings,
                label: '設定',
                onTap: () {
                  soundService.buttonFeedback();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 顯示遊戲說明對話框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
          ),
        ),
        title: const Row(
          children: [
            HexagonIcon(size: 24, color: AppTheme.accentGold),
            SizedBox(width: 12),
            Text(
              '遊戲說明',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
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
                '使用 NFC 卡片掃描或手動輸入角色代碼來獲得您的角色與秘密任務。',
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
                fontFamily: 'Georgia',
                color: AppTheme.accentGold,
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
            fontFamily: 'Georgia',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 13,
            color: AppTheme.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Victoria 3 風格頂部狀態欄
  Widget _buildTopStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.95),
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
          // 左側：攝政王時代標誌
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppTheme.accentGold,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: CrownIcon(size: 18, color: AppTheme.accentGold),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGENCY ERA',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12,
                      color: AppTheme.accentGold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '1812 • British Parliament',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // 右側：數據面板
          const Row(
            children: [
              DataPanel(
                title: '玩家在線',
                value: '847',
                icon: Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppTheme.accentGold,
                ),
                trend: 'up',
              ),
              SizedBox(width: 8),
              DataPanel(
                title: '活躍房間',
                value: '23',
                icon: Icon(
                  Icons.public,
                  size: 16,
                  color: AppTheme.accentGold,
                ),
                trend: 'neutral',
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        soundService.buttonFeedback();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withValues(
                  alpha: 0.3 + (_glowController.value * 0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(
                    alpha: 0.1 + (_glowController.value * 0.1),
                  ),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const GearIcon(
              size: 22,
              color: AppTheme.accentGold,
              spinning: false,
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 1000.ms, duration: 500.ms);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 六角形徽章 + 皇冠
        const HexagonBadge(
          size: 80,
          child: CrownIcon(
            size: 40,
            color: AppTheme.accentGold,
          ),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 20),

        // 主標題 1812 - 帶動畫
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左側齒輪裝飾
            GearIcon(
              size: 28,
              color: AppTheme.textTertiary.withValues(alpha: 0.3),
              spinning: true,
            ),
            const SizedBox(width: 16),

            // 年份標誌
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Text(
                  '1812',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 12,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentGold.withValues(
                          alpha: 0.4 + (_glowController.value * 0.2),
                        ),
                        blurRadius: 30,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(width: 16),

            // 右側齒輪裝飾
            GearIcon(
              size: 28,
              color: AppTheme.textTertiary.withValues(alpha: 0.3),
              spinning: true,
            ),
          ],
        ).animate().fadeIn(duration: 800.ms),

        const SizedBox(height: 12),

        // 中文標題
        Text(
          '國會風雲',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            color: AppTheme.textSecondary,
            letterSpacing: 18,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.9),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),

        const SizedBox(height: 8),

        // 英文副標題
        Text(
          'PARLIAMENT DEBATES',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 12,
            color: AppTheme.textTertiary.withValues(alpha: 0.6),
            letterSpacing: 8,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 20),

        // 維多利亞風格分隔線
        const VictorianDivider(width: 200)
            .animate()
            .scaleX(begin: 0, end: 1, delay: 600.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 建立房間按鈕
        _buildHexagonalToggle(
          label: '建立房間',
          subLabel: 'CREATE',
          isSelected: _isCreating,
          clipLeft: true,
          onTap: () {
            soundService.buttonFeedback();
            setState(() => _isCreating = true);
          },
        ),
        const SizedBox(width: 12),
        // 加入房間按鈕
        _buildHexagonalToggle(
          label: '加入房間',
          subLabel: 'JOIN',
          isSelected: !_isCreating,
          clipLeft: false,
          onTap: () {
            soundService.buttonFeedback();
            setState(() => _isCreating = false);
          },
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildHexagonalToggle({
    required String label,
    required String subLabel,
    required bool isSelected,
    required bool clipLeft,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGold : Colors.transparent,
          border: Border.all(
            color: AppTheme.accentGold,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        // 六角形斜切效果
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 小六角形裝飾
            Positioned(
              top: 2,
              right: clipLeft ? 2 : null,
              left: clipLeft ? null : 2,
              child: HexagonIcon(
                size: 20,
                color: isSelected
                    ? AppTheme.primaryBackground.withValues(alpha: 0.3)
                    : AppTheme.accentGold.withValues(alpha: 0.3),
                filled: isSelected,
              ),
            ),
            // 文字
            Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppTheme.primaryBackground
                        : AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: isSelected
                        ? AppTheme.primaryBackground.withValues(alpha: 0.7)
                        : AppTheme.accentGold.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
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
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 暱稱輸入
              _buildInputField(
                controller: _nicknameController,
                label: '您的暱稱',
                labelEn: 'Your Nickname',
                hint: '輸入暱稱...',
                maxLength: 20,
              ),
              const SizedBox(height: 20),
              // 房間碼輸入（僅加入房間時顯示）
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: !_isCreating
                    ? Column(
                        children: [
                          _buildInputField(
                            controller: _roomCodeController,
                            label: '房間代碼',
                            labelEn: 'Room Code',
                            hint: 'XXXXXX',
                            maxLength: 6,
                            textCapitalization: TextCapitalization.characters,
                            isRoomCode: true,
                          ),
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // 錯誤訊息
              if (roomProvider.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.voteNay.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.voteNay.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppTheme.voteNay, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          roomProvider.error!,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.voteNay,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),
              // 提交按鈕
              _buildSubmitButton(roomProvider),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 800.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String labelEn,
    required String hint,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isRoomCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HexagonIcon(
              size: 16,
              color: AppTheme.accentGold.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              labelEn,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 11,
                color: AppTheme.textTertiary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground.withValues(alpha: 0.8),
            border: Border.all(color: AppTheme.accentGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                textCapitalization: textCapitalization,
                maxLength: maxLength,
                textAlign: isRoomCode ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontFamily: isRoomCode ? 'monospace' : 'Georgia',
                  fontSize: isRoomCode ? 24 : 16,
                  color: AppTheme.textPrimary,
                  letterSpacing: isRoomCode ? 8 : 0,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppTheme.textTertiary.withValues(alpha: 0.5),
                    fontFamily: isRoomCode ? 'monospace' : 'Georgia',
                    fontSize: isRoomCode ? 24 : 16,
                    letterSpacing: isRoomCode ? 8 : 0,
                  ),
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isRoomCode ? 16 : 48,
                    vertical: 14,
                  ),
                ),
                onTap: () => soundService.haptic(HapticType.selection),
              ),
              // 右側齒輪裝飾 (非房間碼)
              if (!isRoomCode)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GearIcon(
                      size: 20,
                      color: AppTheme.textTertiary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(RoomProvider roomProvider) {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        return GestureDetector(
          onTap: roomProvider.isLoading ? null : _submit,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 閃光動畫
                Positioned.fill(
                  child: ClipRect(
                    child: Transform.translate(
                      offset: Offset(
                        ((_shineController.value * 3) - 1) * 300,
                        0,
                      ),
                      child: Container(
                        width: 100,
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
                    ),
                  ),
                ),
                // 按鈕內容
                Center(
                  child: roomProvider.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryBackground,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '請稍候...',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppTheme.primaryBackground,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const HexagonIcon(
                              size: 20,
                              color: AppTheme.primaryBackground,
                              filled: true,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isCreating ? '建立新會議' : '進入議事廳',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppTheme.primaryBackground,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuote() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 時鐘圖標
          Icon(
            Icons.access_time,
            color: AppTheme.textTertiary.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(height: 8),
          // 中文引言
          const Text(
            '「在攝政王的注視下，國會的權力鬥爭即將展開」',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          // 英文副文
          Text(
            "Under the Prince Regent's gaze...",
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 11,
              color: AppTheme.textTertiary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1200.ms, duration: 800.ms);
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              Text('請輸入您的暱稱', style: AppTheme.bodyMedium),
            ],
          ),
          backgroundColor: AppTheme.cardBackground,
          behavior: SnackBarBehavior.floating,
        ),
      );
      soundService.haptic(HapticType.medium);
      return;
    }

    soundService.buttonFeedback();

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
          soundService.play(SoundEffect.gavel);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              FadePageRoute(page: const WaitingRoomScreen()),
            );
          }
        }
      }
    } else {
      // 加入房間
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      if (roomCode.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppTheme.accentGold),
                const SizedBox(width: 8),
                Text('請輸入 6 位房間碼', style: AppTheme.bodyMedium),
              ],
            ),
            backgroundColor: AppTheme.cardBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
        soundService.haptic(HapticType.medium);
        return;
      }

      final player = await roomProvider.joinRoom(roomCode, nickname);
      if (player != null && mounted) {
        playerProvider.setCurrentPlayer(player);
        await roomProvider.connectWebSocket(player.id);
        soundService.play(SoundEffect.pageTransition);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            FadePageRoute(page: const WaitingRoomScreen()),
          );
        }
      }
    }
  }
}
