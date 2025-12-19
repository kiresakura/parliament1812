import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/player.dart';
import '../models/character.dart';
import 'animated_widgets.dart';

/// 角色卡元件 - 1812 年英國國會風格
/// 基於 RoleCardReveal1812.tsx 設計
class RoleCardWidget extends StatelessWidget {
  final Role role;

  const RoleCardWidget({
    super.key,
    required this.role,
  });

  /// 從 Characters1812 取得對應角色資料
  Character? get character {
    if (role.index >= 0 && role.index < Characters1812.all.length) {
      return Characters1812.all[role.index];
    }
    return null;
  }

  /// 取得黨派顏色
  Color get partyColor {
    if (role.roleType == 'tory') return PartyColors.tory;
    if (role.roleType == 'whig') return PartyColors.whig;
    return PartyColors.neutral;
  }

  /// 取得黨派名稱
  String get partyNameChinese {
    if (role.roleType == 'tory') return '托利黨';
    if (role.roleType == 'whig') return '輝格黨';
    return '中立';
  }

  String get partyNameEnglish {
    if (role.roleType == 'tory') return 'TORY PARTY';
    if (role.roleType == 'whig') return 'WHIG PARTY';
    return 'NEUTRAL';
  }

  /// 取得同黨盟友
  List<String> get allies {
    final char = character;
    if (char == null) return [];

    return Characters1812.all
        .where((c) => c.party == char.party && c.id != char.id)
        .take(3)
        .map((c) => c.nameChinese)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final char = character;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.cardBackground.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: isWideScreen
            ? _buildWideLayout(char)
            : _buildNarrowLayout(char),
      ),
    );
  }

  /// 寬螢幕雙欄布局
  Widget _buildWideLayout(Character? char) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左側 - 肖像區域
        Expanded(
          flex: 4,
          child: _buildPortraitSection(char),
        ),
        // 右側 - 資訊區域
        Expanded(
          flex: 5,
          child: _buildInfoSection(char),
        ),
      ],
    );
  }

  /// 窄螢幕單欄布局
  Widget _buildNarrowLayout(Character? char) {
    return Column(
      children: [
        // 上方 - 肖像區域
        _buildPortraitSection(char),
        // 下方 - 資訊區域
        _buildInfoSection(char),
      ],
    );
  }

  /// 肖像區域 - 左側
  Widget _buildPortraitSection(Character? char) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // 六角形徽章
          HexagonBadge(
            size: 60,
            glowColor: partyColor,
            child: Icon(Icons.groups, size: 30, color: partyColor),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 16),
          // 角色肖像
          _buildPortrait(char),
          const SizedBox(height: 16),
          // 黨派徽章
          _buildPartyBadge(),
        ],
      ),
    );
  }

  /// 角色肖像
  Widget _buildPortrait(Character? char) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景漸層
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF3d2817),
                      const Color(0xFF2d1810),
                    ],
                  ),
                ),
              ),
              // 角色圖片
              if (char != null)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.393, 0.769, 0.189, 0, 0,
                    0.349, 0.686, 0.168, 0, 0,
                    0.272, 0.534, 0.131, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(
                    char.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2d1810),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  color: const Color(0xFF2d1810),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              // 暈影效果
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1d1810).withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  /// 黨派徽章
  Widget _buildPartyBadge() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            partyColor.withValues(alpha: 0.3),
            partyColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: partyColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: partyColor.withValues(alpha: 0.4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            partyNameChinese,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: partyColor,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: partyColor.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            partyNameEnglish,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 11,
              color: partyColor.withValues(alpha: 0.7),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  /// 資訊區域 - 右側
  Widget _buildInfoSection(Character? char) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名稱卡片
          _buildNameCard(char),
          const SizedBox(height: 16),
          // 描述
          _buildDescriptionCard(),
          const SizedBox(height: 16),
          // 目標
          _buildObjectiveCard(char),
          const SizedBox(height: 16),
          // 盟友
          if (allies.isNotEmpty) _buildAlliesCard(),
        ],
      ),
    );
  }

  /// 名稱卡片
  Widget _buildNameCard(Character? char) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 裝飾六角形
          Positioned(
            top: 0,
            right: 0,
            child: HexagonIcon(
              size: 24,
              color: AppTheme.accentGold.withValues(alpha: 0.2),
              filled: true,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 中文名稱
              Text(
                char?.nameChinese ?? role.name,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.parchmentColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              // 英文名稱
              Text(
                char?.nameEnglish ?? '',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              // 頭銜
              Text(
                char?.title ?? role.typeName,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

  /// 描述卡片
  Widget _buildDescriptionCard() {
    final char = character;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 羊皮紙紋理
          Positioned.fill(
            child: CustomPaint(
              painter: _ParchmentTexturePainter(),
            ),
          ),
          Text(
            char?.description ?? role.description,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              height: 1.6,
              color: AppTheme.parchmentColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

  /// 目標卡片
  Widget _buildObjectiveCard(Character? char) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 目標圖示
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.gps_fixed,
              size: 24,
              color: AppTheme.accentGold.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              Row(
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTheme.accentGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '您的目標',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Objective',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 11,
                      color: AppTheme.accentGold.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 目標內容
              Text(
                char?.objective ?? role.stance,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.parchmentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

  /// 盟友卡片
  Widget _buildAlliesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: partyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: partyColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              Icon(
                Icons.groups,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '已知盟友',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Known Allies',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 11,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 盟友列表
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allies.asMap().entries.map((entry) {
              final index = entry.key;
              final ally = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: partyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: partyColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HexagonIcon(
                      size: 12,
                      color: partyColor,
                      filled: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ally,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 13,
                        color: AppTheme.parchmentColor,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 600 + index * 100))
                  .scale(begin: const Offset(0.8, 0.8));
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

}

/// 羊皮紙紋理繪製器
class _ParchmentTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.inkColor.withValues(alpha: 0.02)
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
