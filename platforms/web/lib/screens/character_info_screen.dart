import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/character.dart';
import '../config/theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';

/// 角色選擇資訊頁面 - Civ6 風格
/// 展示角色詳細資料與標籤
class CharacterInfoScreen extends StatefulWidget {
  final Character character;

  const CharacterInfoScreen({
    super.key,
    required this.character,
  });

  @override
  State<CharacterInfoScreen> createState() => _CharacterInfoScreenState();
}

class _CharacterInfoScreenState extends State<CharacterInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 進場音效
    Future.delayed(const Duration(milliseconds: 300), () {
      soundService.play(SoundEffect.dramatic);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    final isSpecial = character.isSpecial;

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          _buildBackground(character),
          // 粒子效果
          const AtmosphereParticles(particleCount: 40),
          // 主內容
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(character),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 角色肖像區
                        _buildPortraitSection(character)
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 24),
                        
                        // 角色名稱與頭銜
                        _buildNameSection(character)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                        
                        // 角色標籤
                        if (character.tags.isNotEmpty)
                          _buildTagsSection(character)
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 600.ms),
                        const SizedBox(height: 24),
                        
                        // 特殊能力（僅特殊角色）
                        if (isSpecial && character.specialAbility != null)
                          _buildSpecialAbilityCard(character)
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 600.ms)
                              .slideX(begin: -0.1, end: 0),
                        if (isSpecial) const SizedBox(height: 20),
                        
                        // 角色描述
                        _buildDescriptionCard(character)
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms),
                        const SizedBox(height: 16),
                        
                        // 遊戲目標
                        _buildObjectiveCard(character)
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 600.ms),
                        const SizedBox(height: 16),
                        
                        // 歷史背景
                        _buildHistoryCard(character)
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 600.ms),
                        const SizedBox(height: 32),
                        
                        // 確認按鈕
                        _buildConfirmButton()
                            .animate()
                            .fadeIn(delay: 900.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 20),
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
  }

  Widget _buildBackground(Character character) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            character.partyColor.withValues(alpha: 0.3),
            AppTheme.primaryBackground,
            AppTheme.cardBackground.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 六角形圖案
          const HexagonPatternBackground(),
          // 暈影
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  character.partyColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Character character) {
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
            color: character.partyColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按鈕
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
                  color: character.partyColor.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                color: character.partyColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // 標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: character.partyColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (character.isSpecial) ...[
                  Icon(Icons.star, color: AppTheme.accentGold, size: 18),
                  const SizedBox(width: 8),
                ],
                Column(
                  children: [
                    Text(
                      '角色資訊',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: character.partyColor,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'CHARACTER INFO',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                if (character.isSpecial) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: AppTheme.accentGold, size: 18),
                ],
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildPortraitSection(Character character) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: character.partyColor.withValues(
                alpha: 0.6 + (_glowController.value * 0.4),
              ),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: character.partyColor.withValues(
                  alpha: 0.3 + (_glowController.value * 0.3),
                ),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // 背景漸層
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        character.partyColor.withValues(alpha: 0.2),
                        AppTheme.cardBackground,
                      ],
                    ),
                  ),
                ),
                // 角色圖片
                Positioned.fill(
                  child: Image.asset(
                    character.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              character.isSpecial ? Icons.star : Icons.person,
                              size: 80,
                              color: character.partyColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              character.nameChinese,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 20,
                                color: character.partyColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // 頂部政黨標籤
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          character.partyColor.withValues(alpha: 0.9),
                          character.partyColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Text(
                      character.partyNameEnglish,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                // 特殊角色皇冠標記
                if (character.isSpecial)
                  Positioned(
                    top: 30,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameSection(Character character) {
    return Column(
      children: [
        // 中文名
        Text(
          character.nameChinese,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: character.partyColor,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: character.partyColor.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 英文名
        Text(
          character.nameEnglish.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 14,
            color: AppTheme.textSecondary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        // 頭銜分隔線
        VictorianDivider(width: 200, color: character.partyColor),
        const SizedBox(height: 12),
        // 頭銜
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: character.partyColor.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HexagonIcon(
                size: 14,
                color: character.partyColor,
                filled: true,
              ),
              const SizedBox(width: 10),
              Text(
                character.title,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  color: character.partyColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 10),
              HexagonIcon(
                size: 14,
                color: character.partyColor,
                filled: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 政黨
        Text(
          character.partyNameChinese,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 14,
            color: character.partyColor.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(Character character) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: character.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: tag.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tag.color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 12,
                  color: tag.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                tag.text,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 13,
                  color: tag.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialAbilityCard(Character character) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.15),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '特殊能力',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                  ),
                  Text(
                    'SPECIAL ABILITY',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            character.specialAbility!,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String titleChinese,
    required String titleEnglish,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleChinese,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    titleEnglish,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 9,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Character character) {
    return _buildInfoCard(
      titleChinese: '角色簡介',
      titleEnglish: 'DESCRIPTION',
      content: character.description,
      icon: Icons.person_outline,
      color: character.partyColor,
    );
  }

  Widget _buildObjectiveCard(Character character) {
    return _buildInfoCard(
      titleChinese: '遊戲目標',
      titleEnglish: 'OBJECTIVE',
      content: character.objective,
      icon: Icons.flag_outlined,
      color: AppTheme.accentGold,
    );
  }

  Widget _buildHistoryCard(Character character) {
    return _buildInfoCard(
      titleChinese: '歷史背景',
      titleEnglish: 'HISTORICAL CONTEXT',
      content: character.historicalContext,
      icon: Icons.history_edu,
      color: const Color(0xFF8B7753),
    );
  }

  Widget _buildConfirmButton() {
    final character = widget.character;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            character.partyColor,
            character.partyColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: character.partyColor.withValues(alpha: 0.4),
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
            Navigator.pop(context, character);
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                '選擇此角色',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
