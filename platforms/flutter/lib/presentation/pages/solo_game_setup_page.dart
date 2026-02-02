// 1812 國會風雲 - 單人遊戲設定頁面
//
// 三步驟設定流程：
// 1. 選擇難度
// 2. 選擇角色
// 3. 確認開始

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/models.dart';
import '../../providers/solo_game_provider.dart';

// ============================================================
// 難度資料
// ============================================================

/// AI 難度等級
enum AIDifficultyLevel {
  apprentice,   // 見習議員
  junior,       // 資淺議員
  senior,       // 資深議員
  veteran,      // 老練政客
  master,       // 議會大師
}

/// 難度資訊
class DifficultyInfo {
  final AIDifficultyLevel level;
  final String name;
  final String description;
  final int stars;
  final bool isLocked;
  final String? unlockCondition;
  final String? recommendedTag;
  final Color color;

  const DifficultyInfo({
    required this.level,
    required this.name,
    required this.description,
    required this.stars,
    this.isLocked = false,
    this.unlockCondition,
    this.recommendedTag,
    required this.color,
  });
}

/// 預設難度列表
const List<DifficultyInfo> kDifficulties = [
  DifficultyInfo(
    level: AIDifficultyLevel.apprentice,
    name: '見習議員',
    description: 'AI 行動較為隨機，適合新手',
    stars: 1,
    recommendedTag: '推薦新手',
    color: Color(0xFF27AE60),
  ),
  DifficultyInfo(
    level: AIDifficultyLevel.junior,
    name: '資淺議員',
    description: 'AI 會使用基本策略',
    stars: 2,
    color: Color(0xFF3498DB),
  ),
  DifficultyInfo(
    level: AIDifficultyLevel.senior,
    name: '資深議員',
    description: 'AI 會結盟和反擊',
    stars: 3,
    color: Color(0xFFD4AF37),
  ),
  DifficultyInfo(
    level: AIDifficultyLevel.veteran,
    name: '老練政客',
    description: 'AI 會背叛和算計',
    stars: 4,
    isLocked: true,
    unlockCondition: '完成 3 場對戰解鎖',
    color: Color(0xFFE67E22),
  ),
  DifficultyInfo(
    level: AIDifficultyLevel.master,
    name: '議會大師',
    description: '完美 AI，永不失誤',
    stars: 5,
    isLocked: true,
    unlockCondition: '擊敗老練政客解鎖',
    color: Color(0xFFE74C3C),
  ),
];

// ============================================================
// 角色資料
// ============================================================

/// MVP 角色資料
class CharacterInfo {
  final String id;
  final String name;
  final String title;
  final String emoji;
  final int reputation;
  final String skillName;
  final String skillDescription;
  final Faction faction;
  final Color factionColor;

  const CharacterInfo({
    required this.id,
    required this.name,
    required this.title,
    required this.emoji,
    required this.reputation,
    required this.skillName,
    required this.skillDescription,
    required this.faction,
    required this.factionColor,
  });
}

/// MVP 角色列表
const List<CharacterInfo> kCharacters = [
  CharacterInfo(
    id: 'worker_thomas',
    name: '湯瑪斯',
    title: '工人領袖',
    emoji: '🔨',
    reputation: 70,
    skillName: '團結',
    skillDescription: '每有 1 名工人盟友，防禦 +10',
    faction: Faction.worker,
    factionColor: Color(0xFF8B4513),
  ),
  CharacterInfo(
    id: 'factory_richard',
    name: '理查',
    title: '工廠主',
    emoji: '💰',
    reputation: 60,
    skillName: '收買',
    skillDescription: '花費金幣使目標沉默 1 回合',
    faction: Faction.factory,
    factionColor: Color(0xFF4A4A4A),
  ),
  CharacterInfo(
    id: 'press_edward',
    name: '愛德華',
    title: '記者',
    emoji: '📰',
    reputation: 50,
    skillName: '爆料',
    skillDescription: '揭露目標的秘密任務',
    faction: Faction.press,
    factionColor: Color(0xFF2E86AB),
  ),
  CharacterInfo(
    id: 'luddite_george',
    name: '喬治',
    title: '盧德派',
    emoji: '🔥',
    reputation: 80,
    skillName: '怒火',
    skillDescription: '造成雙倍傷害，但自己也扣 10 聲望',
    faction: Faction.worker,
    factionColor: Color(0xFFB22222),
  ),
];

// ============================================================
// 頁面狀態
// ============================================================

/// 設定步驟
enum SetupStep {
  difficulty,
  character,
  confirm,
}

/// 單人遊戲設定頁面
class SoloGameSetupPage extends ConsumerStatefulWidget {
  const SoloGameSetupPage({super.key});

  @override
  ConsumerState<SoloGameSetupPage> createState() => _SoloGameSetupPageState();
}

class _SoloGameSetupPageState extends ConsumerState<SoloGameSetupPage>
    with SingleTickerProviderStateMixin {
  SetupStep _currentStep = SetupStep.difficulty;
  AIDifficultyLevel? _selectedDifficulty;
  String? _selectedCharacterId;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PageController _difficultyPageController = PageController(
    viewportFraction: 0.75,
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _difficultyPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 進度指示器
            _buildProgressIndicator(),

            // 主要內容
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(),
              ),
            ),

            // 底部按鈕
            _buildBottomButtons(),
          ],
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
        onPressed: _handleBack,
      ),
      title: Text(
        _getStepTitle(),
        style: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.accent,
        ),
      ),
      centerTitle: true,
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case SetupStep.difficulty:
        return '選擇難度';
      case SetupStep.character:
        return '選擇角色';
      case SetupStep.confirm:
        return '確認對戰';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          _buildProgressDot(SetupStep.difficulty),
          _buildProgressLine(SetupStep.difficulty),
          _buildProgressDot(SetupStep.character),
          _buildProgressLine(SetupStep.character),
          _buildProgressDot(SetupStep.confirm),
        ],
      ),
    );
  }

  Widget _buildProgressDot(SetupStep step) {
    final isActive = _currentStep.index >= step.index;
    final isCurrent = _currentStep == step;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 16 : 12,
      height: isCurrent ? 16 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppTheme.accent : AppTheme.primaryMid,
        border: Border.all(
          color: isActive
              ? AppTheme.accent
              : AppTheme.textSecondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildProgressLine(SetupStep afterStep) {
    final isActive = _currentStep.index > afterStep.index;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent
              : AppTheme.textSecondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case SetupStep.difficulty:
        return _buildDifficultySelection();
      case SetupStep.character:
        return _buildCharacterSelection();
      case SetupStep.confirm:
        return _buildConfirmation();
    }
  }

  // ============================================================
  // 難度選擇
  // ============================================================

  Widget _buildDifficultySelection() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // 標題說明
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '選擇你的對手強度',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 32),

        // 難度卡片（橫向滾動）
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _difficultyPageController,
            itemCount: kDifficulties.length,
            onPageChanged: (index) {
              final difficulty = kDifficulties[index];
              if (!difficulty.isLocked) {
                setState(() {
                  _selectedDifficulty = difficulty.level;
                });
              }
            },
            itemBuilder: (context, index) {
              final difficulty = kDifficulties[index];
              final isSelected = _selectedDifficulty == difficulty.level;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isSelected ? 0 : 16,
                ),
                child: _DifficultyCard(
                  info: difficulty,
                  isSelected: isSelected,
                  onTap: difficulty.isLocked
                      ? null
                      : () {
                          setState(() {
                            _selectedDifficulty = difficulty.level;
                          });
                          _difficultyPageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // 頁面指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(kDifficulties.length, (index) {
            final difficulty = kDifficulties[index];
            final isSelected = _selectedDifficulty == difficulty.level;

            return Container(
              width: isSelected ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? difficulty.color
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // 角色選擇
  // ============================================================

  Widget _buildCharacterSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 標題說明
          Text(
            '選擇你的角色',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 2x2 角色網格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: kCharacters.length,
            itemBuilder: (context, index) {
              final character = kCharacters[index];
              final isSelected = _selectedCharacterId == character.id;

              return _CharacterCard(
                info: character,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCharacterId = character.id;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 確認頁面
  // ============================================================

  Widget _buildConfirmation() {
    final difficulty = kDifficulties.firstWhere(
      (d) => d.level == _selectedDifficulty,
      orElse: () => kDifficulties.first,
    );
    final character = kCharacters.firstWhere(
      (c) => c.id == _selectedCharacterId,
      orElse: () => kCharacters.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 標題
          Text(
            '準備好了嗎？',
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),

          const SizedBox(height: 32),

          // 難度預覽
          _buildConfirmSection(
            title: '難度',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 星星
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < difficulty.stars ? Icons.star : Icons.star_border,
                      color: difficulty.color,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Text(
                  difficulty.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: difficulty.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 角色預覽
          _buildConfirmSection(
            title: '角色',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 頭像
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: character.factionColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: character.factionColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      character.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      character.title,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: character.factionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppTheme.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${character.reputation}',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 技能提醒
          _buildConfirmSection(
            title: '你的技能',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.skillName,
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          character.skillDescription,
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 提示文字
          Text(
            '「議會之門已為你敞開」',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryMid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  // ============================================================
  // 底部按鈕
  // ============================================================

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.accent.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep != SetupStep.difficulty)
            Expanded(
              child: OutlinedButton(
                onPressed: _handlePrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '上一步',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep != SetupStep.difficulty) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == SetupStep.difficulty ? 1 : 2,
            child: ElevatedButton(
              onPressed: (_canProceed() && !_isLoading) ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == SetupStep.confirm
                    ? AppTheme.success
                    : AppTheme.accent,
                foregroundColor: AppTheme.primaryDark,
                disabledBackgroundColor: AppTheme.primaryMid,
                disabledForegroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryDark,
                        ),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case SetupStep.difficulty:
        return '選擇角色';
      case SetupStep.character:
        return '確認設定';
      case SetupStep.confirm:
        return '開始對戰';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case SetupStep.difficulty:
        return _selectedDifficulty != null;
      case SetupStep.character:
        return _selectedCharacterId != null;
      case SetupStep.confirm:
        return true;
    }
  }

  // ============================================================
  // 導航處理
  // ============================================================

  void _handleBack() {
    if (_currentStep == SetupStep.difficulty) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/solo');
      }
    } else {
      _handlePrevious();
    }
  }

  void _handlePrevious() {
    setState(() {
      if (_currentStep == SetupStep.character) {
        _currentStep = SetupStep.difficulty;
      } else if (_currentStep == SetupStep.confirm) {
        _currentStep = SetupStep.character;
      }
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _handleNext() {
    if (_currentStep == SetupStep.difficulty) {
      setState(() {
        _currentStep = SetupStep.character;
      });
      _animationController.reset();
      _animationController.forward();
    } else if (_currentStep == SetupStep.character) {
      setState(() {
        _currentStep = SetupStep.confirm;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _startGame();
    }
  }

  Future<void> _startGame() async {
    if (_selectedCharacterId == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 將 UI 難度轉換為 Provider 的難度
      final difficulty = _mapDifficulty(_selectedDifficulty);

      // 顯示載入動畫的最小時間
      await Future.delayed(const Duration(milliseconds: 500));

      // 開始遊戲
      final success = await ref.read(soloGameProvider.notifier).startNewGame(
            difficulty: difficulty,
            humanCharacterId: _selectedCharacterId!,
            humanPlayerName: '玩家',
          );

      if (success && mounted) {
        context.go('/solo/game');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('開始遊戲失敗，請重試')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 將 UI 難度映射到 Provider 難度
  AIDifficulty _mapDifficulty(AIDifficultyLevel? level) {
    switch (level) {
      case AIDifficultyLevel.apprentice:
        return AIDifficulty.beginner;
      case AIDifficultyLevel.junior:
        return AIDifficulty.intermediate;
      case AIDifficultyLevel.senior:
        return AIDifficulty.advanced;
      case AIDifficultyLevel.veteran:
        return AIDifficulty.expert;
      case AIDifficultyLevel.master:
        return AIDifficulty.master;
      default:
        return AIDifficulty.beginner;
    }
  }
}

// ============================================================
// 難度卡片元件
// ============================================================

class _DifficultyCard extends StatelessWidget {
  final DifficultyInfo info;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DifficultyCard({
    required this.info,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: info.isLocked
              ? AppTheme.primaryMid.withValues(alpha: 0.5)
              : AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? info.color
                : info.isLocked
                    ? AppTheme.textSecondary.withValues(alpha: 0.2)
                    : AppTheme.accent.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // 主要內容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 星星
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final isFilled = i < info.stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: info.isLocked
                              ? AppTheme.textSecondary.withValues(alpha: 0.3)
                              : isFilled
                                  ? info.color
                                  : AppTheme.textSecondary.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // 名稱
                  Text(
                    info.name,
                    style: GoogleFonts.cinzel(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: info.isLocked
                          ? AppTheme.textSecondary.withValues(alpha: 0.5)
                          : AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 描述
                  Text(
                    info.description,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: info.isLocked
                          ? AppTheme.textSecondary.withValues(alpha: 0.4)
                          : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // 鎖定條件
                  if (info.isLocked && info.unlockCondition != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            info.unlockCondition!,
                            style: GoogleFonts.lora(
                              fontSize: 11,
                              color: AppTheme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 推薦標籤
            if (info.recommendedTag != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info.recommendedTag!,
                    style: GoogleFonts.lora(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 角色卡片元件
// ============================================================

class _CharacterCard extends StatelessWidget {
  final CharacterInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 頭像
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: info.factionColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: info.factionColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        info.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 名稱
                  Text(
                    info.name,
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  // 稱號
                  Text(
                    info.title,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: info.factionColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 聲望
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: AppTheme.danger,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${info.reputation}',
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 技能
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      info.skillName,
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 技能描述
                  Text(
                    info.skillDescription,
                    style: GoogleFonts.lora(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 選中指示器
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.primaryDark,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
