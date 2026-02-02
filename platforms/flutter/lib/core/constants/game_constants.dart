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
  static const int debateDuration = 300;      // 辯論階段（5 分鐘）- 備用計時器
  static const int eventDuration = 60;        // 事件階段
  static const int votingDuration = 60;       // 投票階段

  // ===== 回合制辯論設定 =====
  static const int debateMaxRounds = 3;       // 辯論最大回合數
  static const int debateTurnTimeout = 30;    // 每回合行動時限（秒）
  static const int debateAIThinkingTime = 2;  // AI 思考時間（秒）

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

  /// 礦工約翰
  static const minerJohn = Role(
    id: 'miner_john',
    name: '礦工約翰',
    englishName: 'John the Miner',
    faction: Faction.worker,
    emoji: '⛏️',
    description: '約翰是威爾斯煤礦的工頭，一個沉默寡言的巨人。他在礦坑裡見過太多死亡，對政治辯論沒有興趣——但當工人兄弟需要他時，他會站出來擋在前面。',
    initialReputation: 85,
    initialGold: 15,
    initialIntel: 1,
    initialFavor: 5,
    baseDefense: 40,
    skills: [
      Skill(
        id: 'body_shield',
        name: '以身擋刀',
        description: '指定一名盟友，本回合所有對該盟友的攻擊轉移到自己身上',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'miners_wall',
        name: '礦工之牆',
        description: '當聲望 > 60 時，所有勞工派盟友防禦 +10',
        type: SkillType.passive,
      ),
      Skill(
        id: 'silent_rage',
        name: '沉默的憤怒',
        description: '本回合不發言，下回合攻擊傷害 +80%，且無視目標 50% 防禦',
        type: SkillType.active,
        cooldown: 3,
      ),
    ],
    traits: ['坦克', '保護'],
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

  /// 律師查爾斯
  static const lawyerCharles = Role(
    id: 'lawyer_charles',
    name: '律師查爾斯',
    englishName: 'Charles the Lawyer',
    faction: Faction.reform,
    emoji: '⚖️',
    description: '查爾斯是倫敦最著名的辯護律師，曾為窮人免費辯護，也曾為富人收取天價費用。他相信法律是改變社會的工具——只要你知道如何使用它。',
    initialReputation: 60,
    initialGold: 40,
    initialIntel: 4,
    initialFavor: 5,
    baseDefense: 25,
    skills: [
      Skill(
        id: 'legal_loophole',
        name: '法律漏洞',
        description: '取消一個正在生效的 Debuff（對任意玩家）',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'impeachment_procedure',
        name: '彈劾程序',
        description: '發起彈劾時，所需聲望 -50%（15 聲望即可發起）',
        type: SkillType.active,
        cooldown: 3,
      ),
      Skill(
        id: 'cross_examination',
        name: '交叉詰問',
        description: '質詢他人時，若對方說謊，傷害 +50%',
        type: SkillType.passive,
      ),
    ],
    traits: ['規則操控', '法律專家'],
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

  /// 銀行家亨利
  static const bankerHenry = Role(
    id: 'banker_henry',
    name: '銀行家亨利',
    englishName: 'Henry the Banker',
    faction: Faction.factory,
    emoji: '🏦',
    description: '亨利是倫敦金融城最有權勢的銀行家之一。他不在乎機器還是工人，他只在乎誰欠他錢。在他眼中，議會不過是另一個可以操控的市場。',
    initialReputation: 50,
    initialGold: 150,
    initialIntel: 2,
    initialFavor: 2,
    baseDefense: 20,
    skills: [
      Skill(
        id: 'loan',
        name: '放貸',
        description: '給予目標 30 金幣，目標獲得「負債」狀態：3 回合後若未還 40 金幣，聲望 -25',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'financial_panic',
        name: '金融恐慌',
        description: '消耗 50 金幣，所有玩家（包括自己）金幣 -30%',
        type: SkillType.active,
        usesPerGame: 1,
        goldCost: 50,
      ),
      Skill(
        id: 'interest_harvest',
        name: '利息收割',
        description: '每回合結束時，從每個「負債」狀態的玩家處獲得 5 金幣',
        type: SkillType.passive,
      ),
    ],
    traits: ['金融戰', '放貸'],
  );

  /// 紡織女工瑪莉
  static const textileMary = Role(
    id: 'textile_mary',
    name: '紡織女工瑪莉',
    englishName: 'Mary the Textile Worker',
    faction: Faction.worker,
    emoji: '🧵',
    description: '瑪莉曾是蘭開夏紡織廠的女工，親眼見證機器如何奪走她母親的工作。她識字、聰明，是工人中少數能讀報紙的人。她不像喬治那樣激進，但她的言語比刀劍更銳利。',
    initialReputation: 55,
    initialGold: 25,
    initialIntel: 4,
    initialFavor: 4,
    baseDefense: 15,
    skills: [
      Skill(
        id: 'tragic_appeal',
        name: '悲情控訴',
        description: '發言時獲得「弱者光環」：本回合受到的傷害-50%，但攻擊力也-30%',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'factory_whispers',
        name: '工廠耳語',
        description: '每回合開始時，有 30% 機率獲得一張關於資方角色的情報',
        type: SkillType.passive,
      ),
      Skill(
        id: 'sisterhood',
        name: '姐妹情誼',
        description: '指定一名女性角色，雙方本回合防禦 +20，攻擊 +15%',
        type: SkillType.active,
        cooldown: 3,
      ),
    ],
    traits: ['輔助', '控制', '情報'],
  );

  /// 間諜法蘭西斯
  static const spyFrancis = Role(
    id: 'spy_francis',
    name: '間諜法蘭西斯',
    englishName: 'Francis the Spy',
    faction: Faction.neutral,
    emoji: '🕵️',
    description: '法蘭西斯是誰？沒人知道。他可能為法國工作，可能為俄國工作，可能為英國自己的秘密部門工作。唯一確定的是——他知道每個人的秘密。',
    initialReputation: 40,
    initialGold: 50,
    initialIntel: 6,
    initialFavor: 3,
    baseDefense: 10,
    skills: [
      Skill(
        id: 'double_agent',
        name: '雙面間諜',
        description: '你的陣營對所有人顯示為「???」，直到遊戲結束才揭曉',
        type: SkillType.passive,
      ),
      Skill(
        id: 'intel_infiltration',
        name: '情報滲透',
        description: '花費 15 金幣，窺視一名玩家的秘密任務',
        type: SkillType.active,
        cooldown: 2,
        goldCost: 15,
      ),
      Skill(
        id: 'deadly_intel',
        name: '致命情報',
        description: '消耗 2 張高級情報，使目標聲望 -40',
        type: SkillType.active,
        usesPerGame: 1,
        intelCost: 2,
      ),
    ],
    traits: ['情報', '神秘', '中立'],
  );

  /// 貿易商威廉
  static const traderWilliam = Role(
    id: 'trader_william',
    name: '貿易商威廉',
    englishName: 'William the Trader',
    faction: Faction.factory,
    emoji: '🚢',
    description: '威廉是東印度公司的股東，在印度、中國、非洲都有生意。他是全球化的化身——哪裡有利潤，他就在哪裡。',
    initialReputation: 65,
    initialGold: 80,
    initialIntel: 3,
    initialFavor: 4,
    baseDefense: 20,
    skills: [
      Skill(
        id: 'trade_agreement',
        name: '貿易協定',
        description: '與目標交換任意數量的金幣/情報/人情（需雙方同意）',
        type: SkillType.active,
        cooldown: 1,
      ),
      Skill(
        id: 'overseas_news',
        name: '海外消息',
        description: '消耗 20 金幣，觸發一個「國際事件」',
        type: SkillType.active,
        cooldown: 2,
        goldCost: 20,
      ),
      Skill(
        id: 'smuggling_network',
        name: '走私網絡',
        description: '交易時，雙方獲得的資源 +20%',
        type: SkillType.passive,
      ),
    ],
    traits: ['貿易', '資源流通', '全球化'],
  );

  /// 發明家詹姆斯
  static const inventorJames = Role(
    id: 'inventor_james',
    name: '發明家詹姆斯',
    englishName: 'James the Inventor',
    faction: Faction.factory,
    emoji: '⚙️',
    description: '詹姆斯是一位天才發明家，改良了蒸汽機，正在研究火車頭。他不關心政治，只關心進步。但他逐漸意識到，沒有政治支持，他的發明無法改變世界。',
    initialReputation: 45,
    initialGold: 60,
    initialIntel: 5,
    initialFavor: 3,
    baseDefense: 15,
    skills: [
      Skill(
        id: 'technical_argument',
        name: '技術論證',
        description: '本回合攻擊傷害 +50%，且忽略對方 30% 防禦',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'invention_showcase',
        name: '發明展示',
        description: '消耗 30 金幣，隨機獲得一個增益效果（攻擊+20%/防禦+15/聲望+10 之一）',
        type: SkillType.active,
        cooldown: 2,
        goldCost: 30,
      ),
      Skill(
        id: 'experimental_spirit',
        name: '實驗精神',
        description: '每局可以取消自己上一個行動的效果並重新選擇。限用 1 次',
        type: SkillType.passive,
        usesPerGame: 1,
      ),
    ],
    traits: ['技術', '邏輯', '進步'],
  );

  /// 學者伊莉莎白
  static const scholarElizabeth = Role(
    id: 'scholar_elizabeth',
    name: '學者伊莉莎白',
    englishName: 'Elizabeth the Scholar',
    faction: Faction.reform,
    emoji: '📝',
    description: '伊莉莎白是一位女性作家，用筆名發表文章批評社會不公。她無法進入議會，但她的文章可以。輿論，是她的武器。',
    initialReputation: 55,
    initialGold: 30,
    initialIntel: 5,
    initialFavor: 4,
    baseDefense: 15,
    skills: [
      Skill(
        id: 'public_opinion_article',
        name: '輿論文章',
        description: '選擇一名玩家，對該玩家的攻擊本回合傷害 +25%（輿論壓力）',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'cite_classics',
        name: '引經據典',
        description: '使用情報攻擊時，傷害 +30%，且有 30% 機率情報不被消耗',
        type: SkillType.passive,
      ),
      Skill(
        id: 'sisterhood_bond',
        name: '姐妹情誼',
        description: '指定紡織女工瑪莉，雙方本回合防禦 +20，攻擊 +15%',
        type: SkillType.active,
        cooldown: 3,
      ),
    ],
    traits: ['輿論', '情報', '姐妹情誼'],
  );

  /// 乞丐比爾
  static const beggarBill = Role(
    id: 'beggar_bill',
    name: '乞丐比爾',
    englishName: 'Bill the Beggar',
    faction: Faction.neutral,
    emoji: '🃏',
    description: '比爾是倫敦街頭的乞丐，但他曾經是士兵、是水手、是各種你想像不到的身份。他什麼都沒有，所以他什麼都不怕。混亂？他最喜歡混亂了。',
    initialReputation: 30,
    initialGold: 5,
    initialIntel: 2,
    initialFavor: 10,
    baseDefense: 5,
    skills: [
      Skill(
        id: 'nothing_to_lose',
        name: '一無所有',
        description: '聲望低於 20 時，受到的傷害 -70%（沒什麼可失去的）',
        type: SkillType.passive,
      ),
      Skill(
        id: 'chaos_seeding',
        name: '混亂播種',
        description: '消耗 3 人情，隨機選擇一名玩家，使其下回合行動隨機化',
        type: SkillType.active,
        usesPerGame: 1,
        favorCost: 3,
      ),
      Skill(
        id: 'tavern_gossip',
        name: '酒館消息',
        description: '消耗 1 人情，獲得一張隨機情報（50% 機率是假情報）',
        type: SkillType.active,
        cooldown: 1,
        favorCost: 1,
      ),
    ],
    traits: ['混亂', '生存', '人情'],
  );


  /// 演說家派乃爾
  static const oratorParnell = Role(
    id: 'orator_parnell',
    name: '演說家派乃爾',
    englishName: 'Parnell the Orator',
    faction: Faction.reform,
    emoji: '🎤',
    description: '派乃爾是愛爾蘭自治運動的領袖，一個天生的演說家。他來到西敏寺不是為了英國的法案，而是為了愛爾蘭的自由。但如果能利用英國的混亂...',
    initialReputation: 75,
    initialGold: 25,
    initialIntel: 3,
    initialFavor: 6,
    baseDefense: 20,
    skills: [
      Skill(
        id: 'passionate_speech',
        name: '激情演說',
        description: '本回合發言後，對目標的攻擊傷害 +30%，自己聲望 +5',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'irish_agenda',
        name: '愛爾蘭議程',
        description: '你有隱藏的投票傾向：若改革派選項勝出，額外獲得 20 分',
        type: SkillType.passive,
      ),
      Skill(
        id: 'crowd_mobilization',
        name: '群眾動員',
        description: '消耗 3 人情，使一名聲望低於 25 的玩家聲望 +15',
        type: SkillType.active,
        usesPerGame: 1,
        favorCost: 3,
      ),
    ],
    traits: ['演說', '煽動', '改革派'],
  );

  /// 公爵阿瑟（威靈頓公爵）
  static const dukeArthur = Role(
    id: 'duke_arthur',
    name: '公爵阿瑟',
    englishName: 'Duke Arthur of Wellington',
    faction: Faction.royal,
    emoji: '⚔️',
    description: '阿瑟是威靈頓公爵，滑鐵盧的英雄，保守派的領袖。他鄙視改革，相信秩序。在他看來，盧德派是暴徒，改革者是瘋子，而工廠主不過是暴發戶。',
    initialReputation: 80,
    initialGold: 70,
    initialIntel: 3,
    initialFavor: 5,
    baseDefense: 35,
    skills: [
      Skill(
        id: 'iron_fist',
        name: '鐵腕鎮壓',
        description: '對聲望低於 25 的玩家造成雙倍傷害',
        type: SkillType.active,
        cooldown: 2,
      ),
      Skill(
        id: 'noble_privilege',
        name: '貴族特權',
        description: '免疫第一次針對自己的大幅攻擊（傷害減半）。每局限 1 次',
        type: SkillType.passive,
        usesPerGame: 1,
      ),
      Skill(
        id: 'military_order',
        name: '軍令如山',
        description: '指定一名盟友，該盟友下回合攻擊傷害 +40%',
        type: SkillType.active,
        cooldown: 3,
      ),
    ],
    traits: ['坦克', '保守', '軍人'],
  );

  /// 所有角色列表
  static const List<Role> allRoles = [
    workerThomas,
    factoryRichard,
    pressEdward,
    ludditeGeorge,
    minerJohn,
    reformerRobert,
    lawyerCharles,
    parliamentWilliam,
    kingGeorgeIII,
    bankerHenry,
    textileMary,
    spyFrancis,
    traderWilliam,
    inventorJames,
    scholarElizabeth,
    beggarBill,
    dukeArthur,
  ];

  /// MVP 四個角色
  static const List<Role> mvpRoles = [
    workerThomas,
    factoryRichard,
    pressEdward,
    ludditeGeorge,
  ];

  /// 擴展角色（包含礦工約翰）
  static const List<Role> expandedRoles = [
    workerThomas,
    factoryRichard,
    pressEdward,
    ludditeGeorge,
    minerJohn,
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

  /// 關稅法案（新增）
  static const tariffBill = Bill(
    id: 'tariff_bill',
    title: '關稅法案',
    description: '關於進口商品關稅的辯論',
    backstory: '''
1812 年，英國正處於工業革命的高峰期。國內製造商要求政府
提高進口關稅以保護本土產業，但貿易商和消費者則希望維持
自由貿易以降低生活成本。

議會必須在保護主義與自由貿易之間做出抉擇。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '提高關稅',
      description: '大幅提高進口商品關稅，保護國內產業，國內生產者金幣 +20%',
      benefitFaction: Faction.worker,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '自由貿易',
      description: '降低或取消關稅，促進自由貿易，所有人金幣 +10%',
      benefitFaction: Faction.factory,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '選擇性關稅',
      description: '只對特定奢侈品和競爭產業徵收關稅，平衡各方利益',
      benefitFaction: Faction.reform,
      benefitScore: 35,
    ),
  );

  /// 童工法案（新增）
  static const childLaborBill = Bill(
    id: 'child_labor_bill',
    title: '童工法案',
    description: '關於兒童勞動的規範',
    backstory: '''
1812 年，英國工廠中充斥著年幼的童工。他們每天工作超過 12 小時，
在危險的環境中操作機器，許多人因此受傷或死亡。

改革派呼籲禁止童工，但工廠主聲稱這將導致產能下降和童工家庭
失去收入。工人團體則提議限制工時作為折衷方案。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '禁止童工',
      description: '全面禁止 14 歲以下兒童在工廠工作，工廠產能 -20%',
      benefitFaction: Faction.reform,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '維持現狀',
      description: '工廠需要勞動力，不應干預市場，資方金幣 +15%',
      benefitFaction: Faction.factory,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '限制工時',
      description: '允許童工但每日工時不得超過 8 小時，折衷保障兒童健康',
      benefitFaction: Faction.worker,
      benefitScore: 35,
    ),
  );

  /// 工會合法化法案（新增）
  static const tradeUnionBill = Bill(
    id: 'trade_union_bill',
    title: '工會合法化',
    description: '關於工人結社權的辯論',
    backstory: '''
1812 年，英國的《結社禁止法》(Combination Acts) 仍然有效，工人組織
工會是非法的。但隨著工業革命的深入，工人開始秘密組織，要求改善
工作條件和工資。

資方認為工會會破壞自由市場和企業競爭力，而改革派則提議在特定
行業有限度地承認工會存在。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '合法化工會',
      description: '允許工人自由組織工會，集體談判工資和工作條件，勞工派聲望+10',
      benefitFaction: Faction.worker,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '維持禁令',
      description: '維持結社禁止法，工會組織者將被逮捕，資方金幣+20%',
      benefitFaction: Faction.factory,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '有限承認',
      description: '只允許特定行業（如礦業、紡織業）組織工會，並需政府監督',
      benefitFaction: Faction.reform,
      benefitScore: 35,
    ),
  );

  /// 選舉改革法案（新增）
  static const electoralReformBill = Bill(
    id: 'electoral_reform_bill',
    title: '選舉改革',
    description: '關於選舉制度改革的辯論',
    backstory: '''
1812 年的英國選舉制度極度不公平。只有擁有一定財產的男性才能投票，
許多新興工業城市（如曼徹斯特、伯明翰）在議會中沒有代表，
而一些「腐敗選區」只有幾個選民卻能選出議員。

改革派要求擴大選舉權，讓更多人參與政治。保守派則認為財產限制
確保了選民的「素質」和社會穩定。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '擴大選舉權',
      description: '降低財產限制，讓更多中產階級和工人獲得投票權，改革派聲望+15',
      benefitFaction: Faction.reform,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '維持現狀',
      description: '維持現有財產限制，保護傳統秩序，皇室派防禦+10',
      benefitFaction: Faction.royal,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '秘密投票',
      description: '不擴大選舉權，但實行秘密投票以防止賄選和威脅，所有人聲望+5',
      benefitFaction: Faction.reform,
      benefitScore: 35,
    ),
  );

  /// 愛爾蘭問題法案（新增）
  static const irishQuestionBill = Bill(
    id: 'irish_question_bill',
    title: '愛爾蘭問題',
    description: '關於愛爾蘭自治權的辯論',
    backstory: '''
1800 年《聯合法令》廢除了愛爾蘭議會，將愛爾蘭併入大不列顛。
但愛爾蘭人民從未接受這一安排。天主教徒被排斥在政治之外，
地主多為英國貴族，愛爾蘭農民生活困苦。

愛爾蘭民族主義者要求自治甚至獨立，皇室派則認為必須維持聯合
以保護帝國完整。資方則希望通過經濟讓步來平息不滿。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '愛爾蘭自治',
      description: '恢復愛爾蘭議會，給予內政自治權，派乃爾聲望+30',
      benefitFaction: Faction.reform,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '維持聯合',
      description: '加強鎮壓獨立運動，維護帝國統一，皇室派聲望+15',
      benefitFaction: Faction.royal,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '經濟讓步',
      description: '不給予政治自治，但提供經濟優惠和土地改革，資方派受益',
      benefitFaction: Faction.factory,
      benefitScore: 35,
    ),
  );

  /// 教育法案（新增）
  static const educationBill = Bill(
    id: 'education_bill',
    title: '教育法案',
    description: '關於國民教育制度的辯論',
    backstory: '''
1812 年，英國沒有統一的國民教育制度。富人的孩子上私立學校，
窮人的孩子要麼不識字，要麼依靠教會的慈善學校。

工業革命需要更多識字的工人，但誰應該負責教育？政府、教會、
還是工廠？教育內容應該是什麼？這些問題引發了激烈辯論。
''',
    optionA: BillOption(
      id: 'A',
      label: 'A',
      title: '普及教育',
      description: '政府建立公立學校，提供免費義務教育，所有人情報+1',
      benefitFaction: Faction.reform,
      benefitScore: 50,
    ),
    optionB: BillOption(
      id: 'B',
      label: 'B',
      title: '教會教育',
      description: '維持教會主導的教育體系，強調道德和宗教教育，皇室派人情+3',
      benefitFaction: Faction.royal,
      benefitScore: 50,
    ),
    optionC: BillOption(
      id: 'C',
      label: 'C',
      title: '技職教育',
      description: '建立技術學校，培養工業所需的技術工人，勞工派和資方派防禦+5',
      benefitFaction: Faction.factory,
      benefitScore: 35,
    ),
  );

  /// 所有議案列表
  static const List<Bill> allBills = [
    machineryBill,
    cornLawBill,
    tariffBill,
    childLaborBill,
    tradeUnionBill,
    electoralReformBill,
    irishQuestionBill,
    educationBill,
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

