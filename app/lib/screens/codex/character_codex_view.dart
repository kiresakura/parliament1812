import 'package:flutter/material.dart';

import '../../providers/codex_provider.dart';

// ═══════════════════════════════════════════
// 角色資料模型
// ═══════════════════════════════════════════

class CharacterData {
  final String id;
  final String name;
  final String englishName;
  final String faction;
  final String factionEnglish;
  final Color factionColor;
  final String description;
  final String backstory;
  final String skillName;
  final String skillDescription;
  final String imagePath;
  final List<String> relatedCardIds;

  const CharacterData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.faction,
    required this.factionEnglish,
    required this.factionColor,
    required this.description,
    required this.backstory,
    required this.skillName,
    required this.skillDescription,
    required this.imagePath,
    required this.relatedCardIds,
  });
}

// ═══════════════════════════════════════════
// 派系顏色常量
// ═══════════════════════════════════════════

class FactionColors {
  static const Color royal = Color(0xFFFFD700);
  static const Color tory = Color(0xFF1A237E);
  static const Color whig = Color(0xFFE65100);
  static const Color industrial = Color(0xFF37474F);
  static const Color worker = Color(0xFFB71C1C);
  static const Color luddite = Color(0xFF1B5E20);
}

// ═══════════════════════════════════════════
// 角色靜態資料
// ═══════════════════════════════════════════

const List<CharacterData> _characters = [
  CharacterData(
    id: 'george3',
    name: '喬治三世',
    englishName: 'George III',
    faction: '皇室',
    factionEnglish: 'Royal',
    factionColor: FactionColors.royal,
    description: '大英帝國國王，堅守皇室權威。專精皇家特權與軍事動員。',
    backstory:
        '喬治三世是漢諾威王朝的國王，在位期間經歷了美國獨立戰爭與拿破崙戰爭。'
        '他以堅定的意志守護皇室尊嚴，即使晚年飽受精神疾病折磨，仍堅持行使王權。'
        '他的統治象徵著舊時代秩序的最後堡壘。',
    skillName: '皇家特權',
    skillDescription: '以國王之名頒布詔令，恢復聲望並獲得金幣。可調動皇室資源影響議會投票。',
    imagePath: 'assets/images/characters/card_royal_george3_char.png',
    relatedCardIds: [
      'uncommon_royal_favor',
      'rare_martial_law',
      'rare_royal_decree',
    ],
  ),
  CharacterData(
    id: 'william',
    name: '威廉·皮特',
    englishName: 'William Pitt',
    faction: '保守黨',
    factionEnglish: 'Tory',
    factionColor: FactionColors.tory,
    description: '年輕的首相，保守主義的守護者。專精政策操控與外交手腕。',
    backstory:
        '威廉·皮特在 24 歲便成為英國最年輕的首相，以非凡的政治才能聞名。'
        '他主張穩健保守的政策路線，巧妙運用外交手腕維護大英帝國的利益。'
        '在拿破崙戰爭期間，他是抵抗法國擴張的核心人物。',
    skillName: '政策操控',
    skillDescription: '透過精密的政策佈局控制議會走向，使對手的功能卡效果減半，並強化己方聯盟的投票權重。',
    imagePath: 'assets/images/characters/card_tory_william_char.png',
    relatedCardIds: [
      'uncommon_whip',
      'rare_no_confidence',
      'rare_diplomatic_immunity',
    ],
  ),
  CharacterData(
    id: 'robert',
    name: '羅伯特',
    englishName: 'Robert',
    faction: '輝格黨',
    factionEnglish: 'Whig',
    factionColor: FactionColors.whig,
    description: '自由主義改革派領袖。專精議會辯論與民意操控。',
    backstory:
        '羅伯特是輝格黨的靈魂人物，堅信議會改革與擴大選舉權是歷史的必然。'
        '他擅長雄辯，在議會中以犀利的演說贏得支持，同時利用媒體塑造輿論。'
        '他的改革理念為日後的大改革法案奠定了基礎。',
    skillName: '議會辯論',
    skillDescription: '發起激烈的議會辯論，大幅提升攻擊卡效果。辯論獲勝時可額外恢復聲望。',
    imagePath: 'assets/images/characters/card_whig_robert_char.png',
    relatedCardIds: [
      'rare_reform_act',
      'rare_impeachment',
      'uncommon_coalition',
    ],
  ),
  CharacterData(
    id: 'richard',
    name: '理查',
    englishName: 'Richard',
    faction: '工業黨',
    factionEnglish: 'Industrial',
    factionColor: FactionColors.industrial,
    description: '工業革命的推動者。專精經濟發展與科技進步。',
    backstory:
        '理查是工業革命浪潮中崛起的新興資產階級代表，擁有數座工廠和礦場。'
        '他深信科技進步是國家繁榮的關鍵，不惜一切代價推動機械化生產。'
        '在他眼中，金錢是最強大的政治武器，任何人都有他的價格。',
    skillName: '經濟壟斷',
    skillDescription: '花費 30 金幣使目標沉默 1 回合。透過經濟優勢掌控政治局勢，以財力收買或壓制對手。',
    imagePath: 'assets/images/characters/card_industrial_richard_char.png',
    relatedCardIds: [
      'richard_bribe',
      'uncommon_embargo',
      'rare_corn_law',
    ],
  ),
  CharacterData(
    id: 'thomas',
    name: '湯瑪斯',
    englishName: 'Thomas',
    faction: '工人黨',
    factionEnglish: 'Worker',
    factionColor: FactionColors.worker,
    description: '工人階級代言人。專精群眾運動與罷工組織。',
    backstory:
        '湯瑪斯出身礦工家庭，從小見證工人在惡劣環境中被壓榨的慘狀。'
        '他組織工人互助會，逐漸成為工人運動的領袖，為爭取合理工時與工資而奮鬥。'
        '他堅信團結就是力量，工人的未來掌握在自己手中。',
    skillName: '工人團結',
    skillDescription: '每有 1 名工人盟友，防禦效果 +10。透過組織罷工和群眾運動向資方與政府施壓。',
    imagePath: 'assets/images/characters/card_worker_thomas_char.png',
    relatedCardIds: [
      'thomas_unity',
      'uncommon_strike',
      'rare_factory_act',
    ],
  ),
  CharacterData(
    id: 'george',
    name: '喬治',
    englishName: 'George',
    faction: '盧德黨',
    factionEnglish: 'Luddite',
    factionColor: FactionColors.luddite,
    description: '反機械化運動領袖。專精破壞行動與民間抵抗。',
    backstory:
        '喬治是盧德運動的核心人物，帶領手工業者反抗工廠機器對傳統生計的破壞。'
        '他以「盧德王」之名在夜間突襲工廠，砸毀紡織機器，成為工人階級的民間英雄。'
        '他的行動雖然激進，卻代表了底層人民對不公命運的絕望反抗。',
    skillName: '盧德之怒',
    skillDescription: '造成雙倍傷害（30 點），但自己也扣 10 聲望。以破壞性行動打擊對手，不惜同歸於盡。',
    imagePath: 'assets/images/characters/card_luddite_george_char.png',
    relatedCardIds: [
      'george_fury',
      'rare_revolution',
      'uncommon_crisis',
    ],
  ),
];

// ═══════════════════════════════════════════
// 角色圖鑑主視圖
// ═══════════════════════════════════════════

class CharacterCodexView extends StatelessWidget {
  const CharacterCodexView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        return _AnimatedCharacterCard(
          character: _characters[index],
          index: index,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 動畫角色卡片（fadeIn + slideUp）
// ═══════════════════════════════════════════

class _AnimatedCharacterCard extends StatefulWidget {
  final CharacterData character;
  final int index;

  const _AnimatedCharacterCard({
    required this.character,
    required this.index,
  });

  @override
  State<_AnimatedCharacterCard> createState() => _AnimatedCharacterCardState();
}

class _AnimatedCharacterCardState extends State<_AnimatedCharacterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 交錯動畫延遲
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _CharacterCard(character: widget.character),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色卡片 UI
// ═══════════════════════════════════════════

class _CharacterCard extends StatelessWidget {
  final CharacterData character;

  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCharacterDetail(context, character),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: character.factionColor.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 角色圖片
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
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
                            character.factionColor.withValues(alpha: 0.15),
                            const Color(0xFF1A1A1A),
                          ],
                        ),
                      ),
                    ),
                    // 角色圖
                    Image.asset(
                      character.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => Center(
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: character.factionColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    // 底部漸層遮罩
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xFF2F2F2F)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 角色資訊
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名稱
                    Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFF8DC),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 派系標籤
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: character.factionColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: character.factionColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        character.faction,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: character.factionColor == FactionColors.tory ||
                                  character.factionColor == FactionColors.industrial ||
                                  character.factionColor == FactionColors.worker ||
                                  character.factionColor == FactionColors.luddite
                              ? character.factionColor.withValues(alpha: 1.0).computeLuminance() < 0.5
                                  ? Colors.white
                                  : character.factionColor
                              : character.factionColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 簡短描述
                    Expanded(
                      child: Text(
                        character.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色詳情彈窗
// ═══════════════════════════════════════════

void _showCharacterDetail(BuildContext context, CharacterData character) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _CharacterDetailContent(character: character),
    ),
  );
}

class _CharacterDetailContent extends StatelessWidget {
  final CharacterData character;

  const _CharacterDetailContent({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: character.factionColor.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部金色光條
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    character.factionColor.withValues(alpha: 0),
                    character.factionColor,
                    character.factionColor.withValues(alpha: 0),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // 角色大圖
            Center(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [
                      character.factionColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Image.asset(
                  character.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, e, s) => Icon(
                    Icons.person,
                    size: 80,
                    color: character.factionColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 名稱 + 英文名
            Center(
              child: Column(
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFF8DC),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    character.englishName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 派系標籤（居中）
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: character.factionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: character.factionColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${character.faction} (${character.factionEnglish})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _factionLabelColor(character.factionColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 背景故事
            _SectionTitle(icon: Icons.auto_stories, title: '角色背景'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: character.factionColor.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                character.backstory,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 專屬技能
            _SectionTitle(icon: Icons.flash_on, title: '專屬技能'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ ${character.skillName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    character.skillDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 相關卡牌
            _SectionTitle(icon: Icons.style, title: '相關卡牌'),
            const SizedBox(height: 8),
            _RelatedCardsList(
              cardIds: character.relatedCardIds,
              factionColor: character.factionColor,
            ),
            const SizedBox(height: 20),

            // 關閉按鈕
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                ),
                child: const Text('關閉'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 區段標題
// ═══════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFF8DC),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 相關卡牌列表
// ═══════════════════════════════════════════

/// 從靜態卡牌資料查找名稱（避免依賴 provider 狀態）
final Map<String, String> _cardNameMap = {
  'uncommon_royal_favor': '皇室恩寵',
  'rare_martial_law': '戒嚴令',
  'rare_royal_decree': '王室詔令',
  'uncommon_whip': '黨鞭施壓',
  'rare_no_confidence': '不信任投票',
  'rare_diplomatic_immunity': '外交豁免',
  'rare_reform_act': '改革法案',
  'rare_impeachment': '彈劾',
  'uncommon_coalition': '組建聯盟',
  'richard_bribe': '收買',
  'uncommon_embargo': '禁運',
  'rare_corn_law': '穀物法',
  'thomas_unity': '團結',
  'uncommon_strike': '罷工',
  'rare_factory_act': '工廠法',
  'george_fury': '怒火',
  'rare_revolution': '革命號召',
  'uncommon_crisis': '製造危機',
};

final Map<String, CodexRarity> _cardRarityMap = {
  'uncommon_royal_favor': CodexRarity.uncommon,
  'rare_martial_law': CodexRarity.rare,
  'rare_royal_decree': CodexRarity.rare,
  'uncommon_whip': CodexRarity.uncommon,
  'rare_no_confidence': CodexRarity.rare,
  'rare_diplomatic_immunity': CodexRarity.rare,
  'rare_reform_act': CodexRarity.rare,
  'rare_impeachment': CodexRarity.rare,
  'uncommon_coalition': CodexRarity.uncommon,
  'richard_bribe': CodexRarity.legendary,
  'uncommon_embargo': CodexRarity.uncommon,
  'rare_corn_law': CodexRarity.rare,
  'thomas_unity': CodexRarity.legendary,
  'uncommon_strike': CodexRarity.uncommon,
  'rare_factory_act': CodexRarity.rare,
  'george_fury': CodexRarity.legendary,
  'rare_revolution': CodexRarity.rare,
  'uncommon_crisis': CodexRarity.uncommon,
};

Color _rarityColor(CodexRarity rarity) {
  switch (rarity) {
    case CodexRarity.common:
      return Colors.white70;
    case CodexRarity.uncommon:
      return Colors.green;
    case CodexRarity.rare:
      return Colors.blue;
    case CodexRarity.legendary:
      return const Color(0xFFD4AF37);
  }
}

String _rarityLabel(CodexRarity rarity) {
  switch (rarity) {
    case CodexRarity.common:
      return '普通';
    case CodexRarity.uncommon:
      return '稀有';
    case CodexRarity.rare:
      return '史詩';
    case CodexRarity.legendary:
      return '傳說';
  }
}

class _RelatedCardsList extends StatelessWidget {
  final List<String> cardIds;
  final Color factionColor;

  const _RelatedCardsList({
    required this.cardIds,
    required this.factionColor,
  });

  @override
  Widget build(BuildContext context) {
    if (cardIds.isEmpty) {
      return Text(
        '暫無相關卡牌',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      children: cardIds.map((id) {
        final name = _cardNameMap[id] ?? id;
        final rarity = _cardRarityMap[id] ?? CodexRarity.common;
        final color = _rarityColor(rarity);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.style, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _rarityLabel(rarity),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════
// 工具方法
// ═══════════════════════════════════════════

Color _factionLabelColor(Color factionColor) {
  // 深色派系（保守黨、工業黨、工人黨、盧德黨）使用白色文字
  if (factionColor.computeLuminance() < 0.3) {
    return Colors.white;
  }
  return factionColor;
}
