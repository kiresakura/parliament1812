// Historically Accurate 1812 British Parliament Characters
// Time Period: Regency Era, 1812

import 'package:flutter/material.dart';

/// 政黨枚舉
enum Party {
  tory,
  whig,
  neutral,
}

/// 政黨顏色
class PartyColors {
  static const Color tory = Color(0xFF1E3A5F); // Royal Blue
  static const Color whig = Color(0xFFCC7722); // Orange/Buff
  static const Color neutral = Color(0xFF8B7753); // Brown

  static Color getColor(Party party) {
    switch (party) {
      case Party.tory:
        return tory;
      case Party.whig:
        return whig;
      case Party.neutral:
        return neutral;
    }
  }
}

/// 政黨名稱
class PartyNames {
  static const Map<Party, Map<String, String>> names = {
    Party.tory: {'chinese': '托利黨', 'english': 'TORY PARTY'},
    Party.whig: {'chinese': '輝格黨', 'english': 'WHIG PARTY'},
    Party.neutral: {'chinese': '中立', 'english': 'NEUTRAL'},
  };

  static String getChinese(Party party) => names[party]!['chinese']!;
  static String getEnglish(Party party) => names[party]!['english']!;
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
  });

  Color get partyColor => PartyColors.getColor(party);
  String get partyNameChinese => PartyNames.getChinese(party);
  String get partyNameEnglish => PartyNames.getEnglish(party);
}

/// 1812 年歷史人物角色資料
class Characters1812 {
  // TORY PARTY (Government)
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
  );

  // WHIG PARTY (Opposition)
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
  );

  /// 所有角色列表
  static const List<Character> all = [
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

  /// 根據 ID 取得角色
  static Character? getById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
