// 1812 國會風雲 - 單人模式入口頁面
//
// 提供三種單人遊戲選項：
// 1. 快速對戰 - 與 AI 進行完整對局
// 2. 練習模式 - 學習遊戲機制
// 3. 每日挑戰 - 即將推出

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// 單人模式頁面
class SoloModePage extends ConsumerStatefulWidget {
  const SoloModePage({super.key});

  @override
  ConsumerState<SoloModePage> createState() => _SoloModePageState();
}

class _SoloModePageState extends ConsumerState<SoloModePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.accent),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Text(
        '單人模式',
        style: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.accent,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 頁面標題描述
          _buildHeader(),
          const SizedBox(height: 32),

          // 選項卡片
          _buildOptionCard(
            index: 0,
            icon: '⚔️',
            title: '快速對戰',
            description: '與 AI 議員進行一場完整對局',
            onTap: _onQuickBattleTap,
            isLocked: false,
          ),
          const SizedBox(height: 16),

          _buildOptionCard(
            index: 1,
            icon: '📚',
            title: '練習模式',
            description: '學習遊戲機制，無壓力練習',
            onTap: _onPracticeModeTap,
            isLocked: false,
          ),
          const SizedBox(height: 16),

          _buildOptionCard(
            index: 2,
            icon: '🏆',
            title: '每日挑戰',
            description: '特殊條件挑戰，全球排行',
            onTap: null,
            isLocked: true,
            comingSoonText: '即將推出',
          ),

          const SizedBox(height: 40),

          // 底部裝飾
          _buildFooterDecoration(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 裝飾線
        Row(
          children: [
            Expanded(child: _buildDecorativeLine()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.account_balance,
                color: AppTheme.accent.withValues(alpha: 0.6),
                size: 28,
              ),
            ),
            Expanded(child: _buildDecorativeLine()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '選擇你的挑戰',
          style: GoogleFonts.lora(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeLine() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0),
            AppTheme.accent.withValues(alpha: 0.5),
            AppTheme.accent.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required String icon,
    required String title,
    required String description,
    required VoidCallback? onTap,
    required bool isLocked,
    String? comingSoonText,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _SoloModeOptionCard(
        icon: icon,
        title: title,
        description: description,
        onTap: onTap,
        isLocked: isLocked,
        comingSoonText: comingSoonText,
      ),
    );
  }

  Widget _buildFooterDecoration() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallDecoration(),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accent.withValues(alpha: 0.3),
              size: 16,
            ),
            const SizedBox(width: 8),
            _buildSmallDecoration(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '「議會的榮耀，等待你來書寫」',
          style: GoogleFonts.lora(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSmallDecoration() {
    return Container(
      width: 40,
      height: 1,
      color: AppTheme.accent.withValues(alpha: 0.3),
    );
  }

  // ============================================================
  // 導航處理
  // ============================================================

  void _onQuickBattleTap() {
    // 導航到設定頁面
    context.push('/solo/setup');
  }

  void _onPracticeModeTap() {
    // 導航到設定頁面（練習模式）
    context.push('/solo/setup');
  }
}

// ============================================================
// 選項卡片元件
// ============================================================

class _SoloModeOptionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLocked;
  final String? comingSoonText;

  const _SoloModeOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isLocked,
    this.comingSoonText,
  });

  @override
  State<_SoloModeOptionCard> createState() => _SoloModeOptionCardState();
}

class _SoloModeOptionCardState extends State<_SoloModeOptionCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = !widget.isLocked && widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isActive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isActive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isActive ? () => setState(() => _isPressed = false) : null,
        onTap: isActive ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isLocked
                  ? AppTheme.primaryMid.withValues(alpha: 0.5)
                  : AppTheme.primaryMid,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isLocked
                    ? AppTheme.textSecondary.withValues(alpha: 0.2)
                    : _isHovered
                        ? AppTheme.accent
                        : AppTheme.accent.withValues(alpha: 0.4),
                width: _isHovered && !widget.isLocked ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isLocked
                      ? Colors.black.withValues(alpha: 0.2)
                      : _isHovered
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.3),
                  blurRadius: _isHovered && !widget.isLocked ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
            children: [
              // 主要內容
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // 圖標
                    _buildIconSection(),
                    const SizedBox(width: 16),

                    // 文字內容
                    Expanded(
                      child: _buildTextSection(),
                    ),

                    // 箭頭
                    if (!widget.isLocked)
                      Icon(
                        Icons.chevron_right,
                        color: _isHovered
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 28,
                      ),
                  ],
                ),
              ),

              // 鎖定/即將推出標籤
              if (widget.isLocked && widget.comingSoonText != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildComingSoonBadge(),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: widget.isLocked
            ? AppTheme.primaryDark.withValues(alpha: 0.5)
            : AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isLocked
              ? AppTheme.textSecondary.withValues(alpha: 0.2)
              : AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          widget.icon,
          style: TextStyle(
            fontSize: 28,
            color: widget.isLocked ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isLocked
                ? AppTheme.textSecondary.withValues(alpha: 0.5)
                : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.description,
          style: GoogleFonts.lora(
            fontSize: 14,
            color: widget.isLocked
                ? AppTheme.textSecondary.withValues(alpha: 0.4)
                : AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            widget.comingSoonText!,
            style: GoogleFonts.lora(
              fontSize: 11,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 難度選擇底部彈窗
// ============================================================

class _DifficultySelectionSheet extends StatefulWidget {
  const _DifficultySelectionSheet();

  @override
  State<_DifficultySelectionSheet> createState() =>
      _DifficultySelectionSheetState();
}

class _DifficultySelectionSheetState extends State<_DifficultySelectionSheet> {
  int _selectedDifficulty = 1; // 0: 新手, 1: 普通, 2: 困難, 3: 大師

  static const List<_DifficultyOption> _difficulties = [
    _DifficultyOption(
      id: 0,
      name: '新手',
      description: 'AI 會放水，適合學習',
      icon: '🌱',
      color: Color(0xFF27AE60),
    ),
    _DifficultyOption(
      id: 1,
      name: '普通',
      description: '平衡的對戰體驗',
      icon: '⚖️',
      color: Color(0xFFD4AF37),
    ),
    _DifficultyOption(
      id: 2,
      name: '困難',
      description: 'AI 會認真對抗',
      icon: '🔥',
      color: Color(0xFFE67E22),
    ),
    _DifficultyOption(
      id: 3,
      name: '大師',
      description: '最強 AI，毫不留情',
      icon: '👑',
      color: Color(0xFFE74C3C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖動指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 標題
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '選擇難度',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ),

          // 難度選項
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _difficulties.map((difficulty) {
                final isSelected = _selectedDifficulty == difficulty.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDifficultyOption(difficulty, isSelected),
                );
              }).toList(),
            ),
          ),

          // 開始按鈕
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '開始對戰',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 安全區域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(
    _DifficultyOption difficulty,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? difficulty.color.withValues(alpha: 0.15)
              : AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? difficulty.color
                : AppTheme.textSecondary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 圖標
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: difficulty.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  difficulty.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.name,
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? difficulty.color
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.description,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 選中指示器
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: difficulty.color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    Navigator.of(context).pop();
    // 導航到設定頁面
    context.push('/solo/setup');
  }
}

/// 難度選項資料
class _DifficultyOption {
  final int id;
  final String name;
  final String description;
  final String icon;
  final Color color;

  const _DifficultyOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
