import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';
import 'role_card_screen.dart';

/// NFC 掃描畫面 - 維多利亞風格 + 手動輸入備用
class ScanNfcScreen extends StatefulWidget {
  const ScanNfcScreen({super.key});

  @override
  State<ScanNfcScreen> createState() => _ScanNfcScreenState();
}

class _ScanNfcScreenState extends State<ScanNfcScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  bool _isScanning = false;
  bool _showManualInput = false;
  final _manualCodeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 自動開始掃描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _manualCodeController.dispose();
    _focusNode.dispose();
    // 取消掃描
    if (mounted) {
      context.read<PlayerProvider>().cancelNfcScan();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final roomCode = roomProvider.room?.code;
    if (roomCode == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final player = await playerProvider.scanNfcCard(roomCode);

    if (mounted) {
      setState(() => _isScanning = false);

      if (player != null && player.hasRole) {
        // 掃描成功，跳轉到角色卡頁面
        soundService.play(SoundEffect.cardFlip);
        soundService.haptic(HapticType.medium);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleCardScreen()),
        );
      } else if (playerProvider.error != null) {
        soundService.haptic(HapticType.heavy);
      }
    }
  }

  Future<void> _submitManualCode() async {
    final code = _manualCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              Text('請輸入角色代碼', style: AppTheme.bodyMedium),
            ],
          ),
          backgroundColor: AppTheme.cardBackground,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    soundService.buttonFeedback();

    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final roomCode = roomProvider.room?.code;
    if (roomCode == null) {
      Navigator.pop(context);
      return;
    }

    // 使用手動代碼分配角色
    final player = await playerProvider.assignRoleManually(roomCode, code);

    if (mounted) {
      if (player != null && player.hasRole) {
        soundService.play(SoundEffect.cardFlip);
        soundService.haptic(HapticType.medium);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleCardScreen()),
        );
      } else if (playerProvider.error != null) {
        soundService.haptic(HapticType.heavy);
      }
    }
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
            child: Column(
              children: [
                // 頂部導航欄
                _buildAppBar(context),
                // 主內容區
                Expanded(
                  child: Consumer<PlayerProvider>(
                    builder: (context, provider, _) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // NFC 動畫
                            _buildNfcAnimation(),
                            const SizedBox(height: 32),
                            // 提示文字
                            _buildInstructions(),
                            const SizedBox(height: 24),
                            // 錯誤訊息
                            if (provider.error != null) _buildErrorMessage(provider.error!),
                            // 按鈕區
                            const SizedBox(height: 24),
                            _buildActionButtons(provider),
                            // 手動輸入區
                            if (_showManualInput) ...[
                              const SizedBox(height: 32),
                              _buildManualInputSection(),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
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
              onTap: () {
                soundService.haptic(HapticType.light);
                Navigator.pop(context);
              },
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
                  Icons.close,
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
                Icon(
                  Icons.nfc,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  '領取身份令牌',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // 佔位空間保持標題居中
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNfcAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外圈旋轉六角形裝飾
            Transform.rotate(
              angle: _rotationController.value * 6.28,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Positioned(
                        left: 100 + 90 * (i % 2 == 0 ? 0.866 : -0.866) * (i < 3 ? 1 : -1) - 8,
                        top: 100 + 90 * (i % 3 == 0 ? 0 : (i < 3 ? -0.5 : 0.5)) * (i == 1 || i == 4 ? 1.7 : 1) - 8,
                        child: HexagonIcon(
                          size: 16,
                          color: AppTheme.accentGold.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 脈動波紋
            for (var i = 0; i < 3; i++)
              Transform.scale(
                scale: 1 + ((_pulseController.value + i * 0.33) % 1) * 0.4,
                child: Opacity(
                  opacity: (1 - ((_pulseController.value + i * 0.33) % 1)) * 0.6,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentGold,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            // 中心圖示容器
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBackground,
                border: Border.all(
                  color: AppTheme.accentGold,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(
                      alpha: 0.2 + (_pulseController.value * 0.2),
                    ),
                    blurRadius: 20 + (_pulseController.value * 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 皇冠圖示
                  const CrownIcon(size: 36, color: AppTheme.accentGold),
                  // NFC 圖示
                  Positioned(
                    bottom: 20,
                    child: Icon(
                      Icons.nfc,
                      size: 24,
                      color: AppTheme.accentGold.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        // 維多利亞風格分隔線
        const VictorianDivider(width: 200),
        const SizedBox(height: 20),
        // 主要提示
        Text(
          _isScanning ? '請將卡片靠近手機背面' : '準備掃描身份令牌',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        // 副標題
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HexagonIcon(
                size: 16,
                color: AppTheme.textTertiary,
              ),
              SizedBox(width: 12),
              Text(
                '每張卡片對應獨特的角色和秘密任務',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 維多利亞風格分隔線
        const VictorianDivider(width: 200),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.voteNay.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.voteNay.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.voteNay.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.voteNay,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '掃描失敗',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.voteNay,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shake(hz: 2, duration: 400.ms);
  }

  Widget _buildActionButtons(PlayerProvider provider) {
    return Column(
      children: [
        // 重新掃描按鈕
        if (!_isScanning && provider.error != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _startScan,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
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
                      Icons.refresh,
                      color: AppTheme.primaryBackground,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '重新掃描',
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
            ),
          ).animate().fadeIn(duration: 300.ms),

        // 載入指示器
        if (provider.isLoading) ...[
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentGold,
                ),
              ),
              SizedBox(width: 16),
              Text(
                '正在驗證卡片...',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],

        // 手動輸入選項
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            soundService.haptic(HapticType.light);
            setState(() => _showManualInput = !_showManualInput);
            if (_showManualInput) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _focusNode.requestFocus();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showManualInput ? Icons.nfc : Icons.keyboard,
                  color: AppTheme.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _showManualInput ? '使用 NFC 掃描' : 'NFC 無法使用？手動輸入',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInputSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          const Row(
            children: [
              HexagonIcon(
                size: 18,
                color: AppTheme.accentGold,
              ),
              SizedBox(width: 10),
              Text(
                '手動輸入角色代碼',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '請輸入卡片上的角色代碼（例如：W01, F02, G01）',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          // 輸入框
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBackground.withValues(alpha: 0.8),
              border: Border.all(color: AppTheme.accentGold, width: 2),
            ),
            child: TextField(
              controller: _manualCodeController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 28,
                color: AppTheme.textPrimary,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: 'W01',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  color: AppTheme.textTertiary.withValues(alpha: 0.4),
                  letterSpacing: 8,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onSubmitted: (_) => _submitManualCode(),
            ),
          ),
          const SizedBox(height: 20),
          // 提交按鈕
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitManualCode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryBackground,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '確認代碼',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

/// 大寫文字格式化器
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
