import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/character.dart';
import '../config/theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';
import 'character_info_screen.dart';

/// 角色選擇列表頁面 - Civ6 風格
/// 展示所有可選角色，分類顯示
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  int _selectedCategory = 0; // 0: 全部, 1: 特殊, 2: 托利, 3: 輝格

  final List<String> _categories = ['全部角色', '特殊角色', '托利黨', '輝格黨'];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  List<Character> get _filteredCharacters {
    switch (_selectedCategory) {
      case 1:
        return Characters1812.specialCharacters;
      case 2:
        return Characters1812.toryMembers;
      case 3:
        return Characters1812.whigMembers;
      default:
        return Characters1812.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  AppTheme.cardBackground.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          const HexagonPatternBackground(),
          const AtmosphereParticles(particleCount: 30),
          
          // 主內容
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildCategoryTabs(),
                Expanded(
                  child: _buildCharacterGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
      ),
      child: Row(
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text(
                  '選擇角色',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'SELECT CHARACTER',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_categories.length, (index) {
            final isSelected = _selectedCategory == index;
            Color tabColor;
            switch (index) {
              case 1:
                tabColor = PartyColors.royal;
                break;
              case 2:
                tabColor = PartyColors.tory;
                break;
              case 3:
                tabColor = PartyColors.whig;
                break;
              default:
                tabColor = AppTheme.accentGold;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  soundService.buttonFeedback();
                  setState(() => _selectedCategory = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tabColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? tabColor
                          : AppTheme.textTertiary.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: isSelected ? tabColor : AppTheme.textTertiary,
                          ),
                        ),
                      Text(
                        _categories[index],
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          color: isSelected ? tabColor : AppTheme.textTertiary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildCharacterGrid() {
    final characters = _filteredCharacters;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return _buildCharacterCard(character, index);
      },
    );
  }

  Widget _buildCharacterCard(Character character, int index) {
    return GestureDetector(
      onTap: () async {
        soundService.buttonFeedback();
        final result = await Navigator.push<Character>(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CharacterInfoScreen(character: character),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );

        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final isSpecial = character.isSpecial;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSpecial
                    ? AppTheme.accentGold.withValues(
                        alpha: 0.5 + (_glowController.value * 0.5),
                      )
                    : character.partyColor.withValues(alpha: 0.5),
                width: isSpecial ? 2 : 1,
              ),
              boxShadow: [
                if (isSpecial)
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(
                      alpha: 0.2 + (_glowController.value * 0.2),
                    ),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  // 背景漸層
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          character.partyColor.withValues(alpha: 0.3),
                          AppTheme.cardBackground,
                          AppTheme.cardBackground,
                        ],
                      ),
                    ),
                  ),
                  // 角色圖片
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 70,
                    child: Image.asset(
                      character.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            isSpecial ? Icons.star : Icons.person,
                            size: 60,
                            color: character.partyColor.withValues(alpha: 0.4),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  // 特殊角色標記
                  if (isSpecial)
                    Positioned(
                      top: 25,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  // 底部資訊
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.cardBackground.withValues(alpha: 0.95),
                            AppTheme.cardBackground,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            character.nameChinese,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: character.partyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            character.title,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (index * 80)),
          duration: const Duration(milliseconds: 400),
        )
        .slideY(begin: 0.2, end: 0);
  }
}
