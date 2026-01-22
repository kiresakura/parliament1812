// 1812 國會風雲 - 遊戲常數定義

import '../../domain/models/role.dart';
import '../../domain/models/bill.dart';

/// 遊戲常數
class GameConstants {
  GameConstants._();

  // ===== 遊戲設定 =====
  static const int minPlayers = 4;
  static const int maxPlayers = 8;
  static const int roomCodeLength = 6;

  // ===== 階段時間（秒）=====
  static const int preparingDuration = 60;    // 準備階段
  static const int conspiracyDuration = 120;  // 密謀階段（2 分鐘）
  static const int debateDuration = 300;      // 辯論階段（5 分鐘）
  static const int eventDuration = 60;        // 事件階段
  static const int votingDuration = 60;       // 投票階段

  // ===== 戰鬥數值 =====
  static const int queryBaseDamage = 15;      // 質詢基礎傷害
  static const int queryCost = 10;            // 質詢消耗聲望
  static const int rebutBlock = 15;           // 反駁抵擋傷害
  static const int rebutCost = 5;             // 反駁消耗聲望
  static const int intelBombDamage = 30;      // 情報炸彈傷害
  static const int betrayBonusDamage = 30;    // 背叛額外傷害
  static const int betraySelfLoss = 20;       // 背叛自損聲望

  // ===== 勝利分數 =====
  static const int billVictoryScore = 50;     // 議案勝利得分
  static const int billCompromiseScore = 30;  // 折衷方案得分

  // ===== 資源上限 =====
  static const int maxGold = 150;
  static const int maxIntel = 8;
  static const int maxFavor = 10;
  static const int maxReputation = 100;

  // ===== 投票權重 =====
  static const double voteWeightHigh = 1.5;     // 聲望 > 80
  static const double voteWeightNormal = 1.0;   // 聲望 50-80
  static const double voteWeightLow = 0.7;      // 聲望 30-50
  static const double voteWeightVeryLow = 0.5;  // 聲望 < 30
  static const double voteWeightDead = 0.0;     // 政治死亡

  // ===== 傷害計算公式 =====
  /// 計算實際傷害
  /// damage = baseDamage × rhetoricMultiplier × intelBonus × factionMultiplier - defenseReduction
  static int calculateDamage({
    required int baseDamage,
    double rhetoricMultiplier = 1.0,
    bool hasIntelSupport = false,
    Faction? attackerFaction,
    Faction? defenderFaction,
    int defenderDefense = 0,
  }) {
    double damage = baseDamage.toDouble();

    // 話術係數
    damage *= rhetoricMultiplier;

    // 情報加成
    if (hasIntelSupport) {
      damage *= 1.5;
    }

    // 陣營克制
    if (attackerFaction != null && defenderFaction != null) {
      damage *= FactionCounter.getDamageMultiplier(attackerFaction, defenderFaction);
    }

    // 防禦減免
    final defenseReduction = damage * (defenderDefense / 200);
    damage -= defenseReduction;

    return damage.round().clamp(0, 100);
  }
}

/// 預設角色資料庫
class RoleDatabase {
  RoleDatabase._();

  /// 工人湯瑪斯
  static const workerThomas = Role(
    id: 'worker_thomas',
    name: '工人湯瑪斯',
    englishName: 'Thomas the Worker',
    faction: Faction.worker,
    emoji: '🔨',
    description: '來自曼徹斯特紡織工廠的工人代表，失去了家人因工廠事故。堅決反對機器取代人力。',
    initialReputation: 70,
    initialGold: 20,
    initialIntel: 2,
    initialFavor: 4,
    baseDefense: 20,
    skills: [
      Skill(
        id: 'worker_rage',
        name: '工人之怒',
        description: '對資方角色造成 +50% 聲望傷害',
        type: SkillType.active,
        cooldown: 2,
        reputationCost: 0,
      ),
      Skill(
        id: 'unity',
        name: '團結一致',
        description: '每有 1 名勞工派盟友，防禦 +10',
        type: SkillType.passive,
      ),
      Skill(
        id: 'sympathy_card',
        name: '悲情牌',
        description: '消耗 10 聲望，獲得 20 金幣',
        type: SkillType.active,
        cooldown: 3,
        reputationCost: 10,
      ),
    ],
    traits: ['團結', '群體戰'],
  );

  /// 工廠主理查
  static const factoryRichard = Role(
    id: 'factory_richard',
    name: '工廠主理查',
    englishName: 'Richard the Factory Owner',
    faction: Faction.factory,
    emoji: '💰',
    description: '倫敦最大紡織廠的老闆，相信工業進步能帶來繁榮。擁有大量金幣但聲譽不佳。',
    initialReputation: 60,
    initialGold: 100,
    initialIntel: 1,
    initialFavor: 3,
    baseDefense: 15,
    skills: [
      Skill(
        id: 'bribe',
        name: '金錢攻勢',
        description: '消耗 30 金幣，使目標本回合沉默',
        type: SkillType.active,
        cooldown: 2,
        goldCost: 30,
      ),
      Skill(
        id: 'economic_argument',
        name: '經濟論述',
        description: '使用數據論點時，說服力 +30%',
        type: SkillType.passive,
      ),
      Skill(
        id: 'industry_alliance',
        name: '產業聯盟',
        description: '所有資方角色本回合獲得 +15 防禦',
        type: SkillType.active,
        cooldown: 4,
        reputationCost: 10,
      ),
    ],
    traits: ['金錢', '收買'],
  );

  /// 記者愛德華
  static const pressEdward = Role(
    id: 'press_edward',
    name: '記者愛德華',
    englishName: 'Edward the Journalist',
    faction: Faction.press,
    emoji: '📰',
    description: '《泰晤士報》的調查記者，對真相有著執著的追求。掌握大量情報但容易成為目標。',
    initialReputation: 50,
    initialGold: 20,
    initialIntel: 6,
    initialFavor: 2,
    baseDefense: 10,
    skills: [
      Skill(
        id: 'exclusive_report',
        name: '獨家報導',
        description: '免費獲得 1 張隨機情報卡',
        type: SkillType.active,
        cooldown: 3,
      ),
      Skill(
        id: 'deep_investigation',
        name: '深入調查',
        description: '指定一人，揭露其陣營',
        type: SkillType.active,
        usesPerGame: 1,
      ),
      Skill(
        id: 'public_opinion',
        name: '輿論操控',
        description: '揭露情報時，額外造成 +20% 傷害',
        type: SkillType.passive,
      ),
    ],
    traits: ['情報', '揭露'],
  );

  /// 盧德派喬治
  static const ludditeGeorge = Role(
    id: 'luddite_george',
    name: '盧德派喬治',
    englishName: 'George the Luddite',
    faction: Faction.worker,
    emoji: '🔥',
    description: '激進的機器破壞者，曾因砸毀紡織機入獄。聲望高但行事魯莽。',
    initialReputation: 80,
    initialGold: 10,
    initialIntel: 3,
    initialFavor: 3,
    baseDefense: 30,
    skills: [
      Skill(
        id: 'rage_fire',
        name: '怒火',
        description: '造成雙倍傷害，但自己也扣 10 聲望',
        type: SkillType.active,
        cooldown: 2,
        reputationCost: 10,
      ),
      Skill(
        id: 'intimidation',
        name: '威嚇',
        description: '目標下回合無法對你使用質詢',
        type: SkillType.active,
        cooldown: 3,
      ),
      Skill(
        id: 'resilience',
        name: '堅韌',
        description: '聲望低於 30 時，防禦 +20',
        type: SkillType.passive,
      ),
    ],
    traits: ['激進', '高傷害'],
  );

  /// 改革者羅伯特
  static const reformerRobert = Role(
    id: 'reformer_robert',
    name: '改革者羅伯特',
    englishName: 'Robert the Reformer',
    faction: Faction.reform,
    emoji: '⚖️',
    description: '主張漸進改革的溫和派議員，試圖在工人與資方之間尋求平衡。',
    initialReputation: 65,
    initialGold: 30,
    initialIntel: 3,
    initialFavor: 5,
    baseDefense: 20,
    skills: [
      Skill(
        id: 'mediation',
        name: '調解',
        description: '結束兩名玩家之間的敵對狀態',
        type: SkillType.active,
        cooldown: 3,
        favorCost: 2,
      ),
      Skill(
        id: 'compromise',
        name: '折衷方案',
        description: '投票給 C 選項時，額外獲得 10 分',
        type: SkillType.passive,
      ),
      Skill(
        id: 'diplomacy',
        name: '外交手腕',
        description: '結盟時雙方都獲得 +5 防禦',
        type: SkillType.passive,
      ),
    ],
    traits: ['平衡', '外交'],
  );

  /// 議員威廉
  static const parliamentWilliam = Role(
    id: 'parliament_william',
    name: '議員威廉',
    englishName: 'William the Parliament Member',
    faction: Faction.neutral,
    emoji: '🏛️',
    description: '資深下議院議員，人脈廣闘但野心勃勃。唯一關心的是自己的政治地位。',
    initialReputation: 75,
    initialGold: 50,
    initialIntel: 2,
    initialFavor: 6,
    baseDefense: 25,
    skills: [
      Skill(
        id: 'political_favor',
        name: '政治人情',
        description: '消耗 3 人情，使目標投票給指定選項',
        type: SkillType.active,
        cooldown: 0,
        favorCost: 3,
      ),
      Skill(
        id: 'filibuster',
        name: '冗長發言',
        description: '延長當前階段 30 秒',
        type: SkillType.active,
        usesPerGame: 2,
        reputationCost: 15,
      ),
      Skill(
        id: 'connections',
        name: '人脈網絡',
        description: '每回合開始時獲得 1 人情',
        type: SkillType.passive,
      ),
    ],
    traits: ['權力', '人脈'],
  );

  /// 喬治三世（國王）
  static const kingGeorgeIII = Role(
    id: 'king_george_iii',
    name: '喬治三世',
    englishName: 'King George III',
    faction: Faction.royal,
    emoji: '👑',
    description: '大不列顛國王，擁有最高權力但精神不穩。可以改變遊戲規則，但也可能失控。',
    initialReputation: 90,
    initialGold: 80,
    initialIntel: 4,
    initialFavor: 2,
    baseDefense: 35,
    skills: [
      Skill(
        id: 'royal_decree',
        name: '王權宣言',
        description: '強制觸發一個新的突發事件',
        type: SkillType.active,
        usesPerGame: 1,
      ),
      Skill(
        id: 'royal_judgement',
        name: '皇家裁決',
        description: '結束當前辯論，立即進入投票',
        type: SkillType.active,
        usesPerGame: 1,
        reputationCost: 30,
      ),
      Skill(
        id: 'madness',
        name: '精神不穩',
        description: '每回合 10% 機率失去行動能力（負面被動）',
        type: SkillType.passive,
      ),
    ],
    traits: ['特權', '不穩定'],
  );

  /// 所有角色列表
  static const List<Role> allRoles = [
    workerThomas,
    factoryRichard,
    pressEdward,
    ludditeGeorge,
    reformerRobert,
    parliamentWilliam,
    kingGeorgeIII,
  ];

  /// MVP 四個角色
  static const List<Role> mvpRoles = [
    workerThomas,
    factoryRichard,
    pressEdward,
    ludditeGeorge,
  ];

  /// 根據 ID 取得角色
  static Role? getRoleById(String roleId) {
    try {
      return allRoles.firstWhere((role) => role.id == roleId);
    } catch (e) {
      return null;
    }
  }

  /// 根據陣營取得角色列表
  static List<Role> getRolesByFaction(Faction faction) {
    return allRoles.where((role) => role.faction == faction).toList();
  }
}

/// 預設議案資料庫
class BillDatabase {
  BillDatabase._();

  /// 機器法案
  static const machineryBill = Bill(
    id: 'machinery_bill',
    title: '機器法案',
    description: '關於工業機器的使用與規範',
    backstory: '''
1812 年，英國工業革命如火如荼。紡織機的普及讓工廠產能倍增，
但也導致大量工人失業。盧德運動興起，工人砸毀機器以示抗議。

議會必須決定：是禁止機器保護工人，還是保護財產權利？
抑或尋求一個折衷的改革方案？
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '禁止機器',
      description: '立法全面禁止工廠使用省力機器，保障工人就業權',
      benefitFaction: Faction.worker,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '保護財產',
      description: '嚴懲破壞機器者，保障工廠主的財產權與創新權',
      benefitFaction: Faction.factory,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '折衷改革',
      description: '允許機器使用，但立法保障工人最低工資與工作環境',
      benefitFaction: null,
      benefitScore: 30,
    ),
  );

  /// 穀物法案（擴充用）
  static const cornLawBill = Bill(
    id: 'corn_law_bill',
    title: '穀物法案',
    description: '關於穀物進口關稅的辯論',
    backstory: '''
1815 年拿破崙戰爭結束後，穀物價格大跌。地主階級提議徵收
高額進口關稅以保護國內農業，但這將導致麵包價格上漲，
加重工人階級的生活負擔。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '高關稅保護',
      description: '徵收高額關稅保護本國農業與地主利益',
      benefitFaction: Faction.factory,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '自由貿易',
      description: '取消關稅，讓市場自由競爭，降低糧食價格',
      benefitFaction: Faction.worker,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '滑動關稅',
      description: '根據國內穀物價格調整關稅，平衡各方利益',
      benefitFaction: null,
      benefitScore: 30,
    ),
  );

  /// 所有議案列表
  static const List<Bill> allBills = [
    machineryBill,
    cornLawBill,
  ];

  /// MVP 使用的議案
  static const Bill mvpBill = machineryBill;

  /// 根據 ID 取得議案
  static Bill? getBillById(String billId) {
    try {
      return allBills.firstWhere((bill) => bill.id == billId);
    } catch (e) {
      return null;
    }
  }
}

