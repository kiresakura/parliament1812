import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/animated_widgets.dart';

/// 設定頁面 - 1812 年風格
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, child) {
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Stack(
            children: [
              // 背景粒子效果
              const ParticleBackground(
                particleCount: 20,
                particleColor: AppTheme.secondaryColor,
              ),
              // 主內容
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 無障礙設定區塊
                            _buildAccessibilitySection(accessibility),
                            const SizedBox(height: 24),
                            // 字體大小設定
                            _buildFontSizeSection(accessibility),
                            const SizedBox(height: 24),
                            // 顯示設定區塊
                            _buildDisplaySection(accessibility),
                            const SizedBox(height: 24),
                            // 動畫設定區塊
                            _buildAnimationSection(accessibility),
                            const SizedBox(height: 24),
                            // 重設按鈕
                            _buildResetButton(accessibility),
                            const SizedBox(height: 40),
                            // 版本資訊
                            _buildVersionInfo(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground.withValues(alpha: 0.95),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.secondaryColor.withValues(
                  alpha: 0.3 + (_glowController.value * 0.2),
                ),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 返回按鈕
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 標題
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '偏好設定',
                      style: AppTheme.headlineSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'PREFERENCES',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                        letterSpacing: 2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // 齒輪圖示
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondaryColor.withValues(alpha: 0.2),
                      AppTheme.secondaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  color: AppTheme.secondaryColor,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(AccessibilityProvider accessibility) {
    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '無障礙設定',
            'Accessibility',
            Icons.accessibility_new,
          ),
          const SizedBox(height: 20),
          // 大字體模式
          _buildSwitchTile(
            title: '大字體模式',
            subtitle: '放大所有文字以便閱讀',
            icon: Icons.text_fields,
            value: accessibility.largeText,
            onChanged: (value) => accessibility.setLargeText(value),
          ),
          _buildDivider(),
          // 粗體文字
          _buildSwitchTile(
            title: '粗體文字',
            subtitle: '使用較粗的字體重量',
            icon: Icons.format_bold,
            value: accessibility.boldText,
            onChanged: (value) => accessibility.setBoldText(value),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFontSizeSection(AccessibilityProvider accessibility) {
    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '字體大小',
            'Font Size',
            Icons.format_size,
          ),
          const SizedBox(height: 20),
          // 字體大小顯示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '當前大小',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  accessibility.fontSizeLabel,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 滑桿
          Row(
            children: [
              Text(
                'A',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.secondaryColor,
                    inactiveTrackColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    thumbColor: AppTheme.candleGlow,
                    overlayColor: AppTheme.candleGlow.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: accessibility.fontScale,
                    min: AccessibilityProvider.minFontScale,
                    max: AccessibilityProvider.maxFontScale,
                    divisions: 7,
                    onChanged: (value) => accessibility.setFontScale(value),
                  ),
                ),
              ),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 快捷按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickButton(
                label: '縮小',
                icon: Icons.remove,
                onTap: () => accessibility.decreaseFontSize(),
              ),
              _buildQuickButton(
                label: '重設',
                icon: Icons.refresh,
                onTap: () => accessibility.resetFontSize(),
                isAccent: true,
              ),
              _buildQuickButton(
                label: '放大',
                icon: Icons.add,
                onTap: () => accessibility.increaseFontSize(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 預覽文字
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '預覽效果',
                  style: AppTheme.labelMedium.copyWith(
                    fontSize: 11,
                    color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1812年，國會議事堂裡的辯論正如火如荼...',
                  style: accessibility.scaleTextStyle(
                    AppTheme.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDisplaySection(AccessibilityProvider accessibility) {
    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '顯示設定',
            'Display',
            Icons.contrast,
          ),
          const SizedBox(height: 20),
          // 高對比模式
          _buildSwitchTile(
            title: '高對比模式',
            subtitle: '增強色彩對比度，適合視力不佳者',
            icon: Icons.invert_colors,
            value: accessibility.highContrast,
            onChanged: (value) => accessibility.setHighContrast(value),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAnimationSection(AccessibilityProvider accessibility) {
    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '動畫設定',
            'Animation',
            Icons.animation,
          ),
          const SizedBox(height: 20),
          // 減少動畫
          _buildSwitchTile(
            title: '減少動畫',
            subtitle: '降低畫面動態效果，減少眼睛疲勞',
            icon: Icons.motion_photos_off,
            value: accessibility.reduceMotion,
            onChanged: (value) => accessibility.setReduceMotion(value),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResetButton(AccessibilityProvider accessibility) {
    return Center(
      child: GestureDetector(
        onTap: () => _showResetConfirmDialog(accessibility),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.ludditeColor.withValues(alpha: 0.3),
                AppTheme.ludditeColor.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.ludditeColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restart_alt,
                color: AppTheme.ludditeColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '重設所有設定',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.ludditeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '1812 國會風雲 v1.0.0',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 Parliament 1812',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[700],
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.cardBackground.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                  : AppTheme.darkBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.secondaryColor : Colors.grey[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.candleGlow,
            activeTrackColor: AppTheme.secondaryColor.withValues(alpha: 0.4),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.secondaryColor.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAccent
              ? AppTheme.secondaryColor.withValues(alpha: 0.2)
              : AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAccent
                ? AppTheme.secondaryColor.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isAccent ? AppTheme.secondaryColor : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                fontSize: 12,
                color: isAccent ? AppTheme.secondaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog(AccessibilityProvider accessibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.candleGlow,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '確認重設',
              style: AppTheme.headlineSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          '確定要將所有設定恢復為預設值嗎？',
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              accessibility.resetAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '設定已重設',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.cardBackground,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.ludditeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '確認重設',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
