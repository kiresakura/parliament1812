// Historically Accurate 1812 British Parliament Characters
// Time Period: Regency Era, 1812

import 'package:flutter/material.dart';

/// 政黨枚舉
enum Party {
  tory,
  whig,
  neutral,
  royal, // 皇室 - 特殊角色
}

/// 政黨顏色
class PartyColors {
  static const Color tory = Color(0xFF1E3A5F); // Royal Blue
  static const Color whig = Color(0xFFCC7722); // Orange/Buff
  static const Color neutral = Color(0xFF8B7753); // Brown
  static const Color royal = Color(0xFF8B0000); // 深紅色 - 皇室

  static Color getColor(Party party) {
    switch (party) {
      case Party.tory:
        return tory;
      case Party.whig:
        return whig;
      case Party.neutral:
        return neutral;
      case Party.royal:
        return royal;
    }
  }
}

/// 政黨名稱
class PartyNames {
  static const Map<Party, Map<String, String>> names = {
    Party.tory: {'chinese': '托利黨', 'english': 'TORY PARTY'},
    Party.whig: {'chinese': '輝格黨', 'english': 'WHIG PARTY'},
    Party.neutral: {'chinese': '中立', 'english': 'NEUTRAL'},
    Party.royal: {'chinese': '皇室', 'english': 'THE CROWN'},
  };

  static String getChinese(Party party) => names[party]!['chinese']!;
  static String getEnglish(Party party) => names[party]!['english']!;
}

/// 角色類型 - 區分普通角色與特殊角色
enum CharacterType {
  regular,  // 一般議員
  special,  // 特殊角色（如國王）
}

/// 角色標籤 - 用於選角頁面展示
class CharacterTag {
  final String text;
  final Color color;
  
  const CharacterTag({required this.text, required this.color});
}

/// 角色模型
class Character {
  final String id;
  final String nameChinese;
  final String nameEnglish;
  final String title;
  final Party party;
  final String imageAsset;
  final String description;
  final String objective;
  final String historicalContext;
  final CharacterType type;
  final List<CharacterTag> tags;
  final String? specialAbility; // 特殊角色的能力描述

  const Character({
    required this.id,
    required this.nameChinese,
    required this.nameEnglish,
    required this.title,
    required this.party,
    required this.imageAsset,
    required this.description,
    required this.objective,
    required this.historicalContext,
    this.type = CharacterType.regular,
    this.tags = const [],
    this.specialAbility,
  });

  Color get partyColor => PartyColors.getColor(party);
  String get partyNameChinese => PartyNames.getChinese(party);
  String get partyNameEnglish => PartyNames.getEnglish(party);
  bool get isSpecial => type == CharacterType.special;
}

/// 1812 年歷史人物角色資料
class Characters1812 {
  // ═══════════════════════════════════════════════════════════════
  // 👑 SPECIAL CHARACTERS - 特殊角色
  // ═══════════════════════════════════════════════════════════════
  
  static const Character georgeIII = Character(
    id: 'george_iii',
    nameChinese: '喬治三世',
    nameEnglish: 'George III',
    title: '大不列顛國王',
    party: Party.royal,
    imageAsset: 'assets/images/characters/george_iii.png',
    description: '漢諾威王朝國王，統治大英帝國長達60年。晚年飽受精神疾病折磨，'
        '被稱為「瘋王」。在位期間經歷美國獨立戰爭、法國大革命與拿破崙戰爭。',
    objective: '維護王權威嚴，在托利黨與輝格黨的政爭中保持平衡，'
        '確保帝國在戰火中屹立不搖。',
    historicalContext: '1811年因精神疾病無法執政，由威爾斯親王攝政。'
        '喬治三世是英國在位時間最長的國王之一，見證了大英帝國的擴張與轉型。',
    type: CharacterType.special,
    tags: [
      CharacterTag(text: '帝國榮光', color: Color(0xFFFFD700)),
      CharacterTag(text: '海上霸權', color: Color(0xFF4169E1)),
      CharacterTag(text: '王室威儀', color: Color(0xFF8B008B)),
      CharacterTag(text: '瘋王', color: Color(0xFF8B0000)),
      CharacterTag(text: '精神錯亂', color: Color(0xFF696969)),
      CharacterTag(text: '統治危機', color: Color(0xFFB22222)),
    ],
    specialAbility: '【王權宣言】每場遊戲可發動一次，強制結束當前辯論並進入投票階段。',
  );

  // ═══════════════════════════════════════════════════════════════
  // 🔵 TORY PARTY (Government) - 托利黨（執政黨）
  // ═══════════════════════════════════════════════════════════════
  
  static const Character perceval = Character(
    id: 'perceval',
    nameChinese: '斯賓塞·珀西瓦爾',
    nameEnglish: 'Spencer Perceval',
    title: '首相',
    party: Party.tory,
    imageAsset: 'assets/images/characters/character1.png',
    description: '托利黨首相，主張維護國教會與君主權力。反對天主教解放。',
    objective: '阻止任何削弱國教會地位的改革，維持戰時政府穩定。',
    historicalContext: '1812年5月將遭暗殺（英國史上唯一被暗殺的首相）',
    tags: [
      CharacterTag(text: '首相', color: Color(0xFF1E3A5F)),
      CharacterTag(text: '保守派', color: Color(0xFF4682B4)),
    ],
  );

  static const Character liverpool = Character(
    id: 'liverpool',
    nameChinese: '利物浦伯爵',
    nameEnglish: 'Lord Liverpool',
    title: '戰爭與殖民大臣',
    party: Party.tory,
    imageAsset: 'assets/images/characters/character2.png',
    description: '托利黨保守派領袖，珀西瓦爾遇刺後將接任首相。',
    objective: '確保戰時內閣穩定，反對激進改革。',
    historicalContext: '羅伯特·詹金遜，將成為在位最長的首相之一（1812-1827）',
    tags: [
      CharacterTag(text: '內閣大臣', color: Color(0xFF1E3A5F)),
      CharacterTag(text: '繼承者', color: Color(0xFF4682B4)),
    ],
  );

  static const Character castlereagh = Character(
    id: 'castlereagh',
    nameChinese: '卡斯爾雷子爵',
    nameEnglish: 'Lord Castlereagh',
    title: '外交大臣',
    party: Party.tory,
    imageAsset: 'assets/images/characters/character3.png',
    description: '托利黨外交政策主導者，專注於對抗拿破崙。',
    objective: '維持反法同盟，確保外交政策不受內政爭議干擾。',
    historicalContext: '羅伯特·斯圖爾特，將主導維也納會議',
    tags: [
      CharacterTag(text: '外交大臣', color: Color(0xFF1E3A5F)),
      CharacterTag(text: '反法同盟', color: Color(0xFF4682B4)),
    ],
  );

  static const Character eldon = Character(
    id: 'eldon',
    nameChinese: '艾爾登勳爵',
    nameEnglish: 'Lord Eldon',
    title: '大法官',
    party: Party.tory,
    imageAsset: 'assets/images/characters/character4.png',
    description: '極端保守派，堅決反對任何改革。',
    objective: '阻止天主教解放與議會改革，維護既有秩序。',
    historicalContext: '約翰·斯科特，擔任大法官長達25年',
    tags: [
      CharacterTag(text: '大法官', color: Color(0xFF1E3A5F)),
      CharacterTag(text: '極端保守', color: Color(0xFF191970)),
    ],
  );

  static const Character vansittart = Character(
    id: 'vansittart',
    nameChinese: '范西塔特',
    nameEnglish: 'Nicholas Vansittart',
    title: '財政大臣',
    party: Party.tory,
    imageAsset: 'assets/images/characters/character5.png',
    description: '托利黨財政官員，管理戰時經濟。',
    objective: '確保戰爭經費充足，控制政府開支。',
    historicalContext: '尼古拉斯·范西塔特，將於1812年接任財政大臣',
    tags: [
      CharacterTag(text: '財政大臣', color: Color(0xFF1E3A5F)),
      CharacterTag(text: '戰時經濟', color: Color(0xFF4682B4)),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 🟠 WHIG PARTY (Opposition) - 輝格黨（在野黨）
  // ═══════════════════════════════════════════════════════════════
  
  static const Character grey = Character(
    id: 'grey',
    nameChinese: '格雷伯爵',
    nameEnglish: 'Earl Grey',
    title: '輝格黨領袖',
    party: Party.whig,
    imageAsset: 'assets/images/characters/character1.png',
    description: '輝格黨領袖，主張議會改革與天主教解放。',
    objective: '推動改革法案，爭取中立議員支持。',
    historicalContext: '查爾斯·格雷，將於1832年推動通過《大改革法案》',
    tags: [
      CharacterTag(text: '黨魁', color: Color(0xFFCC7722)),
      CharacterTag(text: '改革派', color: Color(0xFFDAA520)),
    ],
  );

  static const Character holland = Character(
    id: 'holland',
    nameChinese: '霍蘭勳爵',
    nameEnglish: 'Lord Holland',
    title: '輝格黨元老',
    party: Party.whig,
    imageAsset: 'assets/images/characters/character2.png',
    description: '輝格黨顯赫貴族，支持宗教寬容政策。',
    objective: '推動天主教解放，維護輝格黨傳統價值。',
    historicalContext: '亨利·瓦瑟爾·福克斯，霍蘭府為輝格黨政治沙龍中心',
    tags: [
      CharacterTag(text: '元老', color: Color(0xFFCC7722)),
      CharacterTag(text: '宗教寬容', color: Color(0xFFDAA520)),
    ],
  );

  static const Character whitbread = Character(
    id: 'whitbread',
    nameChinese: '塞繆爾·惠特布雷德',
    nameEnglish: 'Samuel Whitbread',
    title: '激進派議員',
    party: Party.whig,
    imageAsset: 'assets/images/characters/character3.png',
    description: '輝格黨激進派，批評政府戰爭政策與社會不公。',
    objective: '揭露政府腐敗，推動社會改革。',
    historicalContext: '富有的啤酒商，積極支持廢奴運動與勞工權益',
    tags: [
      CharacterTag(text: '激進派', color: Color(0xFFCC7722)),
      CharacterTag(text: '社會改革', color: Color(0xFFDAA520)),
    ],
  );

  static const Character brougham = Character(
    id: 'brougham',
    nameChinese: '亨利·布魯厄姆',
    nameEnglish: 'Henry Brougham',
    title: '改革派律師',
    party: Party.whig,
    imageAsset: 'assets/images/characters/character4.png',
    description: '輝格黨改革派，雄辯的議會演說家。',
    objective: '通過雄辯說服議員支持改革。',
    historicalContext: '蘇格蘭律師，將成為大法官並推動法律改革',
    tags: [
      CharacterTag(text: '律師', color: Color(0xFFCC7722)),
      CharacterTag(text: '雄辯家', color: Color(0xFFDAA520)),
    ],
  );

  static const Character grenville = Character(
    id: 'grenville',
    nameChinese: '格倫維爾勳爵',
    nameEnglish: 'Lord Grenville',
    title: '前首相',
    party: Party.whig,
    imageAsset: 'assets/images/characters/character5.png',
    description: '前托利黨人，因支持天主教解放而轉投輝格黨。',
    objective: '利用經驗與聲望推動漸進改革。',
    historicalContext: '威廉·格倫維爾，1806-1807年擔任首相的「賢能內閣」',
    tags: [
      CharacterTag(text: '前首相', color: Color(0xFFCC7722)),
      CharacterTag(text: '叛黨者', color: Color(0xFFDAA520)),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 📋 角色列表與查詢方法
  // ═══════════════════════════════════════════════════════════════

  /// 特殊角色列表
  static const List<Character> specialCharacters = [
    georgeIII,
  ];

  /// 一般角色列表
  static const List<Character> regularCharacters = [
    // Tory Party
    perceval,
    liverpool,
    castlereagh,
    eldon,
    vansittart,
    // Whig Party
    grey,
    holland,
    whitbread,
    brougham,
    grenville,
  ];

  /// 所有角色列表（包含特殊角色）
  static const List<Character> all = [
    // Special Characters
    georgeIII,
    // Tory Party
    perceval,
    liverpool,
    castlereagh,
    eldon,
    vansittart,
    // Whig Party
    grey,
    holland,
    whitbread,
    brougham,
    grenville,
  ];

  /// 取得托利黨角色
  static List<Character> get toryMembers =>
      all.where((c) => c.party == Party.tory).toList();

  /// 取得輝格黨角色
  static List<Character> get whigMembers =>
      all.where((c) => c.party == Party.whig).toList();

  /// 取得皇室角色
  static List<Character> get royalMembers =>
      all.where((c) => c.party == Party.royal).toList();

  /// 根據 ID 取得角色
  static Character? getById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
