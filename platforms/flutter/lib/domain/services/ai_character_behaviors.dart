// 1812 國會風雲 - AI 角色專屬行為
//
// 為 MVP 的 4 個角色定義專屬 AI 行為：
// 1. 工人湯瑪斯 - 團結勞工，攻擊資方
// 2. 工廠主理查 - 收買中立，保守防禦
// 3. 記者愛德華 - 收集情報，關鍵爆料
// 4. 盧德派喬治 - 激進攻擊，怒火燃燒

import '../models/models.dart';

// ============================================================
// MVP 角色 ID 常數
// ============================================================

/// MVP 角色 ID
class CharacterIds {
  /// 工人湯瑪斯
  static const String workerThomas = 'worker_thomas';

  /// 工廠主理查
  static const String factoryRichard = 'factory_richard';

  /// 記者愛德華
  static const String reporterEdward = 'reporter_edward';

  /// 盧德派喬治
  static const String ludditeGeorge = 'luddite_george';

  /// 律師查爾斯
  static const String lawyerCharles = 'lawyer_charles';

  /// 礦工約翰
  static const String minerJohn = 'miner_john';

  /// 喬治三世（國王）
  static const String kingGeorgeIII = 'king_george_iii';

  /// 銀行家亨利
  static const String bankerHenry = 'banker_henry';

  /// 紡織女工瑪莉
  static const String textileMary = 'textile_mary';

  /// 間諜法蘭西斯
  static const String spyFrancis = 'spy_francis';

  /// 貿易商威廉
  static const String traderWilliam = 'trader_william';

  /// 發明家詹姆斯
  static const String inventorJames = 'inventor_james';

  /// 學者伊莉莎白
  static const String scholarElizabeth = 'scholar_elizabeth';

  /// 乞丐比爾
  static const String beggarBill = 'beggar_bill';

  /// 演說家派乃爾
  static const String oratorParnell = 'orator_parnell';

  /// 公爵阿瑟
  static const String dukeArthur = 'duke_arthur';

  /// 所有 MVP 角色 ID
  static const List<String> all = [
    workerThomas,
    factoryRichard,
    reporterEdward,
    ludditeGeorge,
    lawyerCharles,
    bankerHenry,
    textileMary,
    spyFrancis,
    traderWilliam,
    inventorJames,
    scholarElizabeth,
    beggarBill,
    oratorParnell,
    dukeArthur,
  ];

  /// 擴展角色 ID（包含礦工約翰和喬治三世）
  static const List<String> expanded = [
    workerThomas,
    factoryRichard,
    reporterEdward,
    ludditeGeorge,
    lawyerCharles,
    minerJohn,
    kingGeorgeIII,
    textileMary,
    spyFrancis,
  ];
}

// ============================================================
// 角色行為修正資料
// ============================================================

/// 行為修正 - 用於調整 AI 決策的權重
class BehaviorModifier {
  /// 攻擊傾向修正 (-1.0 到 +1.0)
  final double attackModifier;

  /// 防禦傾向修正 (-1.0 到 +1.0)
  final double defenseModifier;

  /// 結盟傾向修正 (-1.0 到 +1.0)
  final double allyModifier;

  /// 背叛傾向修正 (-1.0 到 +1.0)
  final double betrayModifier;

  /// 技能使用傾向修正 (-1.0 到 +1.0)
  final double skillModifier;

  /// 風險承受度 (0.0 = 極度保守, 1.0 = 極度激進)
  final double riskTolerance;

  const BehaviorModifier({
    this.attackModifier = 0.0,
    this.defenseModifier = 0.0,
    this.allyModifier = 0.0,
    this.betrayModifier = 0.0,
    this.skillModifier = 0.0,
    this.riskTolerance = 0.5,
  });

  /// 預設（無修正）
  static const BehaviorModifier none = BehaviorModifier();

  /// 激進型
  static const BehaviorModifier aggressive = BehaviorModifier(
    attackModifier: 0.5,
    defenseModifier: -0.3,
    riskTolerance: 0.8,
  );

  /// 防禦型
  static const BehaviorModifier defensive = BehaviorModifier(
    attackModifier: -0.3,
    defenseModifier: 0.5,
    riskTolerance: 0.3,
  );

  /// 外交型
  static const BehaviorModifier diplomatic = BehaviorModifier(
    allyModifier: 0.5,
    betrayModifier: -0.5,
    riskTolerance: 0.4,
  );
}

/// 目標優先級
class TargetPriority {
  /// 目標玩家 ID
  final String playerId;

  /// 優先級分數 (越高越優先)
  final double priority;

  /// 優先原因
  final String reason;

  const TargetPriority({
    required this.playerId,
    required this.priority,
    required this.reason,
  });
}

/// 投票偏好
class VotePreference {
  /// 偏好選項 (A, B, C)
  final String preferredOption;

  /// 偏好強度 (0.0 - 1.0，越高越堅持)
  final double strength;

  /// 偏好原因
  final String reason;

  /// 是否可被說服改變
  final bool canBeSwayed;

  const VotePreference({
    required this.preferredOption,
    required this.strength,
    required this.reason,
    this.canBeSwayed = true,
  });
}

// ============================================================
// 角色行為抽象類
// ============================================================

/// 角色專屬行為 - 抽象基類
///
/// 每個 MVP 角色都有獨特的行為模式，影響：
/// 1. 目標選擇優先級
/// 2. 偏好的行動類型
/// 3. 投票傾向
/// 4. 技能使用時機
abstract class CharacterBehavior {
  /// 角色 ID
  String get characterId;

  /// 角色名稱
  String get characterName;

  /// 所屬陣營
  Faction get faction;

  /// 基礎行為修正
  BehaviorModifier get baseModifier;

  /// 獲取偏好攻擊目標
  ///
  /// 根據角色特性，對所有存活玩家進行優先級排序
  /// [ai] - AI 玩家自己
  /// [state] - 當前遊戲狀態
  /// [allPlayers] - 所有玩家（用於查詢角色資訊）
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  );

  /// 獲取偏好行動類型
  ///
  /// 根據角色特性和當前階段，返回偏好的行動類型列表（按優先級排序）
  /// [ai] - AI 玩家自己
  /// [state] - 當前遊戲狀態
  List<AIActionType> getPreferredActions(
    AIPlayer ai,
    GameState state,
  );

  /// 獲取投票偏好
  ///
  /// 根據角色陣營和利益，返回投票偏好
  /// [ai] - AI 玩家自己
  /// [state] - 當前遊戲狀態
  /// [bill] - 當前議案
  VotePreference getVotePreference(
    AIPlayer ai,
    GameState state,
    Bill bill,
  );

  /// 計算對特定行動的加成分數
  ///
  /// [action] - 要評估的行動
  /// [ai] - AI 玩家自己
  /// [state] - 當前遊戲狀態
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  );

  /// 是否應該使用角色技能
  ///
  /// [ai] - AI 玩家自己
  /// [state] - 當前遊戲狀態
  /// [situation] - 局勢分析
  bool shouldUseSkill(
    AIPlayer ai,
    GameState state,
    SituationAnalysis situation,
  );

  /// 獲取技能目標
  ///
  /// 如果技能需要目標，返回最佳目標 ID
  String? getSkillTarget(
    AIPlayer ai,
    GameState state,
  );
}

// ============================================================
// 工人湯瑪斯 AI 行為
// ============================================================

/// 工人湯瑪斯 AI 行為
///
/// 特點：
/// - 優先與其他工人/勞工派結盟
/// - 「團結」技能：當有工人盟友時，防禦 +10
/// - 傾向攻擊工廠主
/// - 投票傾向：A（禁止機器）
class WorkerThomasBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.workerThomas;

  @override
  String get characterName => '工人湯瑪斯';

  @override
  Faction get faction => Faction.worker;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.2, // 略為激進
        allyModifier: 0.4, // 重視團結
        riskTolerance: 0.5, // 中等風險承受
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50; // 基礎優先級
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 工廠主是首要攻擊目標
      if (role?.faction == Faction.factory) {
        priority += 40;
        reason = '工廠主 - 階級敵人';
      }

      // 避免攻擊勞工派同伴
      if (role?.faction == Faction.worker) {
        priority -= 50;
        reason = '勞工同伴 - 應該團結';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 60;
        reason = '盟友 - 不應攻擊';
      }

      // 聲望低的目標優先（容易擊敗）
      if (player.reputation < 30) {
        priority += 15;
        reason += '，聲望低';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 優先與其他工人結盟
    if (ai.allies.isEmpty) {
      actions.add(AIActionType.ally);
    }

    // 有盟友時更敢攻擊
    if (ai.allies.isNotEmpty) {
      actions.add(AIActionType.attack);
      actions.add(AIActionType.useSkill); // 團結技能
    }

    // 聲望低時防禦
    if (ai.reputation < 40) {
      actions.insert(0, AIActionType.defend);
    }

    actions.add(AIActionType.speak);
    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 根據不同議案返回不同的投票偏好
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止機器
          strength: 0.9,
          reason: '禁止機器可以保護工人的生計',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易，降低糧價
          strength: 0.85,
          reason: '降低關稅可以讓工人買到更便宜的麵包',
          canBeSwayed: false,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'A', // 提高關稅，保護國內產業
          strength: 0.85,
          reason: '提高關稅可以保護國內工人的工作機會',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時，折衷方案
          strength: 0.8,
          reason: '限制童工工時可以保護孩子又維持家庭收入',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 0.95,
          reason: '工會是工人團結的力量！我們必須爭取結社自由！',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 0.9,
          reason: '工人也應該有投票權！這是我們爭取權利的關鍵！',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A', // 愛爾蘭自治
          strength: 0.7,
          reason: '愛爾蘭的工人和我們一樣受壓迫，我們支持他們的自治權',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'A', // 普及教育
          strength: 0.85,
          reason: '工人的孩子也應該受教育！知識是改變命運的力量！',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.7,
          reason: '支持有利於工人的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 與勞工派結盟加分
    if (action == AIActionType.ally && targetId != null) {
      // 這裡簡化處理，實際應查詢目標角色
      bonus += 15;
    }

    // 攻擊工廠主加分
    if (action == AIActionType.attack && targetId != null) {
      // 這裡簡化處理，實際應查詢目標角色
      bonus += 10;
    }

    // 有盟友時攻擊加分（團結力量）
    if (action == AIActionType.attack && ai.allies.isNotEmpty) {
      bonus += ai.allies.length * 5;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 團結技能是被動的，有工人盟友時自動生效
    // 這裡返回 true 表示 AI 會主動尋求結盟以觸發技能
    return ai.allies.isEmpty && situation.potentialAllies.isNotEmpty;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 尋找其他工人作為結盟目標
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (!ai.allies.contains(player.id)) {
        return player.id;
      }
    }
    return null;
  }
}

// ============================================================
// 工廠主理查 AI 行為
// ============================================================

/// 工廠主理查 AI 行為
///
/// 特點：
/// - 優先使用金幣進行「收買」
/// - 會嘗試賄賂中立玩家
/// - 傾向防禦，保存實力
/// - 投票傾向：B（保護財產）
class FactoryRichardBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.factoryRichard;

  @override
  String get characterName => '工廠主理查';

  @override
  Faction get faction => Faction.factory;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: -0.2, // 偏保守
        defenseModifier: 0.4, // 重視防禦
        allyModifier: 0.3, // 會嘗試收買
        skillModifier: 0.5, // 常用技能（收買）
        riskTolerance: 0.3, // 低風險承受
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 中立玩家是收買目標
      if (role?.faction == Faction.neutral || role?.faction == Faction.press) {
        priority += 30;
        reason = '中立派 - 可收買對象';
      }

      // 工人和盧德派是威脅
      if (role?.faction == Faction.worker) {
        priority += 20;
        reason = '工人 - 潛在威脅';
      }

      // 避免與資方內鬥
      if (role?.faction == Faction.factory) {
        priority -= 40;
        reason = '資方同伴 - 應該合作';
      }

      // 盟友不攻擊
      if (ai.allies.contains(player.id)) {
        priority -= 70;
        reason = '盟友 - 已被收買';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 有金幣時優先使用收買技能
    if (ai.gold >= 10) {
      actions.add(AIActionType.useSkill);
    }

    // 優先防禦
    actions.add(AIActionType.defend);

    // 嘗試結盟（用金幣收買）
    if (ai.gold >= 5) {
      actions.add(AIActionType.ally);
    }

    // 不太主動攻擊，除非必要
    if (ai.reputation > 60) {
      actions.add(AIActionType.attack);
    }

    actions.add(AIActionType.speak);
    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 根據不同議案返回不同的投票偏好
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'B', // 保護財產
          strength: 0.95,
          reason: '必須保護工廠和機器設備',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'A', // 高關稅保護
          strength: 0.85,
          reason: '高關稅可以保護國內農業投資',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.9,
          reason: '自由貿易可以降低原料進口成本，增加利潤',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.9,
          reason: '工廠需要勞動力，禁止童工將增加成本',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持禁令
          strength: 0.95,
          reason: '工會會破壞工廠秩序，增加生產成本！必須維持結社禁令！',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.85,
          reason: '財產限制確保選民都是有產業、有教養的人',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.8,
          reason: '給愛爾蘭一些經濟好處就好，政治自治會影響我們的市場',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.9,
          reason: '技職教育能培養熟練工人，對工廠最有利！',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'B',
          strength: 0.8,
          reason: '支持有利於資方的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用收買技能加分
    if (action == AIActionType.useSkill && ai.gold >= 10) {
      bonus += 25;
    }

    // 防禦加分
    if (action == AIActionType.defend) {
      bonus += 15;
    }

    // 有足夠金幣時結盟加分
    if (action == AIActionType.ally && ai.gold >= 5) {
      bonus += 10;
    }

    // 攻擊減分（保守策略）
    if (action == AIActionType.attack) {
      bonus -= 10;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 收買技能：有足夠金幣且有可收買的目標
    if (ai.gold < 10) return false;

    // 威脅高時使用收買來消除威脅
    if (situation.threatLevel > 50) return true;

    // 有潛在盟友時嘗試收買
    return situation.potentialAllies.isNotEmpty;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 優先收買中立玩家或威脅來源
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      // 收買聲望較低的玩家（更容易成功）
      if (player.reputation < 50) {
        return player.id;
      }
    }
    return null;
  }
}

// ============================================================
// 記者愛德華 AI 行為
// ============================================================

/// 記者愛德華 AI 行為
///
/// 特點：
/// - 優先收集情報
/// - 會在關鍵時刻使用「爆料」技能
/// - 傾向揭露威脅最大的玩家
/// - 投票傾向：根據情報判斷
class ReporterEdwardBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.reporterEdward;

  @override
  String get characterName => '記者愛德華';

  @override
  Faction get faction => Faction.press;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.0, // 中立
        defenseModifier: 0.2, // 略保守（保護情報來源）
        skillModifier: 0.6, // 常用爆料技能
        riskTolerance: 0.4, // 謹慎
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '一般目標';

      // 記者優先揭露聲望最高的玩家（新聞價值高）
      if (player.reputation > 70) {
        priority += 30;
        reason = '高聲望 - 新聞價值高';
      }

      // 威脅最大的玩家也是爆料目標
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 25;
        reason = '對自己有敵意 - 應該揭露';
      }

      // 擁有秘密的玩家（有情報價值）
      if (player.intel > 0) {
        priority += 15;
        reason += '，有情報價值';
      }

      // 盟友作為情報來源，不攻擊
      if (ai.allies.contains(player.id)) {
        priority -= 50;
        reason = '情報來源 - 保護';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 有情報時優先使用爆料技能
    if (ai.intel >= 2) {
      actions.add(AIActionType.useSkill);
      actions.add(AIActionType.reveal);
    }

    // 收集情報（通過發言獲取資訊）
    actions.add(AIActionType.speak);

    // 中立立場，不主動攻擊
    actions.add(AIActionType.defend);

    // 必要時攻擊
    if (ai.reputation > 50) {
      actions.add(AIActionType.attack);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 記者根據情報判斷，偏向對自己有利的選項
    // 預設選擇折衷方案 C
    String preferredOption = 'C';
    double strength = 0.5;
    String reason = '根據情報分析，折衷方案最公平';

    // 根據不同議案調整偏好
    switch (bill.id) {
      case 'machinery_bill':
        preferredOption = 'C';
        reason = '折衷方案能平衡各方利益，有助於社會穩定';
        break;
      case 'corn_law_bill':
        preferredOption = 'C';
        reason = '滑動關稅是最理性的政策選擇';
        break;
      case 'tariff_bill':
        preferredOption = 'C';
        reason = '選擇性關稅能兼顧各方利益';
        break;
      case 'child_labor_bill':
        preferredOption = 'A'; // 記者傾向支持禁止童工（新聞良知）
        strength = 0.7;
        reason = '作為記者，有責任為無法發聲的孩子們發聲';
        break;
      case 'trade_union_bill':
        preferredOption = 'C'; // 有限承認
        strength = 0.6;
        reason = '有限承認工會能平衡各方利益，這是最理性的選擇';
        break;
      case 'electoral_reform_bill':
        preferredOption = 'C'; // 秘密投票
        strength = 0.75;
        reason = '秘密投票能防止選舉舞弊，這是新聞自由的基礎';
        break;
      case 'irish_question_bill':
        preferredOption = 'C'; // 經濟讓步
        strength = 0.55;
        reason = '情報顯示經濟問題是愛爾蘭動盪的根源';
        break;
      case 'education_bill':
        preferredOption = 'A'; // 普及教育
        strength = 0.8;
        reason = '普及教育能增加識字率，讓更多人讀報紙！這對新聞業有利！';
        break;
    }

    // 如果有足夠情報，可能改變投票
    if (ai.intel >= 3) {
      // 根據情報分析各方實力
      final workerCount = state.players.where((p) => p.isAlive).length ~/ 2;
      if (workerCount > 2 && bill.id != 'child_labor_bill') {
        preferredOption = 'A';
        reason = '情報顯示勞工派勢力較強';
      }
    }

    return VotePreference(
      preferredOption: preferredOption,
      strength: strength,
      reason: reason,
      canBeSwayed: true, // 可被說服
    );
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 揭露情報加分
    if (action == AIActionType.reveal && ai.intel >= 1) {
      bonus += 20;
    }

    // 使用爆料技能加分
    if (action == AIActionType.useSkill && ai.intel >= 2) {
      bonus += 25;
    }

    // 發言加分（收集情報）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 爆料技能：有足夠情報且有高價值目標
    if (ai.intel < 2) return false;

    // 威脅高時使用爆料揭露敵人
    if (situation.threatLevel > 60 && situation.mainThreats.isNotEmpty) {
      return true;
    }

    // 遊戲後期使用（關鍵時刻）
    if (state.currentRound >= state.totalRounds - 1) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 爆料目標：威脅最大的玩家
    Player? bestTarget;
    double highestThreat = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 計算威脅度
      final threat = player.reputation.toDouble() -
          ai.getRelationshipScore(player.id);

      if (threat > highestThreat) {
        highestThreat = threat;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }
}

// ============================================================
// 盧德派喬治 AI 行為
// ============================================================

/// 盧德派喬治 AI 行為
///
/// 特點：
/// - 高度 aggressive
/// - 經常使用「怒火」技能（雙倍傷害）
/// - 不太在意自己的聲望損失
/// - 投票傾向：A（禁止機器）
class LudditeGeorgeBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.ludditeGeorge;

  @override
  String get characterName => '盧德派喬治';

  @override
  Faction get faction => Faction.worker;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.7, // 非常激進
        defenseModifier: -0.4, // 不重視防禦
        skillModifier: 0.6, // 常用怒火技能
        riskTolerance: 0.9, // 極高風險承受
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 60; // 盧德派基礎攻擊慾望高
      String reason = '應該攻擊';

      final role = playerRoles[player.id];

      // 工廠主和資方是首要敵人
      if (role?.faction == Faction.factory) {
        priority += 50;
        reason = '工廠主 - 必須摧毀！';
      }

      // 也攻擊改革派（不夠激進）
      if (role?.faction == Faction.reform) {
        priority += 20;
        reason = '改革派 - 太軟弱';
      }

      // 勞工派同伴優先級降低但不會完全排除
      if (role?.faction == Faction.worker) {
        priority -= 30;
        reason = '工人同伴 - 最後考慮';
      }

      // 高聲望目標優先（更想打倒強者）
      if (player.reputation > 60) {
        priority += 15;
        reason += '，聲望高';
      }

      // 盧德派甚至可能攻擊盟友（激進本性）
      if (ai.allies.contains(player.id)) {
        priority -= 40; // 降低但不完全排除
        reason = '盟友 - 暫時放過';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用怒火技能
    if (ai.reputation > 20) {
      // 只要還有足夠聲望承受損失
      actions.add(AIActionType.useSkill);
    }

    // 攻擊優先
    actions.add(AIActionType.attack);

    // 幾乎不防禦
    // actions.add(AIActionType.defend); // 故意省略

    // 偶爾發言煽動
    actions.add(AIActionType.speak);

    // 可能背叛（激進不穩定）
    if (ai.allies.isNotEmpty && ai.reputation > 40) {
      actions.add(AIActionType.betray);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 盧德派對所有議案都持激進立場
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止機器
          strength: 1.0,
          reason: '機器是惡魔！必須全部摧毀！',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.9,
          reason: '高關稅只會讓窮人餓死！',
          canBeSwayed: false,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'A', // 提高關稅
          strength: 0.95,
          reason: '必須保護我們工人的工作！讓外國貨滾出去！',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止童工
          strength: 1.0,
          reason: '讓孩子去工廠是罪惡！資本家都是吸血鬼！',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 1.0,
          reason: '工會萬歲！團結就是力量！砸爛結社禁止法！',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 1.0,
          reason: '每個工人都應該有投票權！推翻財產限制！',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A', // 愛爾蘭自治
          strength: 0.9,
          reason: '愛爾蘭兄弟也在反抗壓迫！支持他們的自由！',
          canBeSwayed: false,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'A', // 普及教育
          strength: 0.85,
          reason: '讓工人的孩子受教育，他們就能認識到資本家的剝削！',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'A',
          strength: 1.0,
          reason: '支持最激進的改變！',
          canBeSwayed: false,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 攻擊大加分
    if (action == AIActionType.attack) {
      bonus += 30;
    }

    // 使用怒火技能大加分
    if (action == AIActionType.useSkill) {
      bonus += 35;
    }

    // 背叛加分（激進本性）
    if (action == AIActionType.betray) {
      bonus += 15;
    }

    // 防禦大減分
    if (action == AIActionType.defend) {
      bonus -= 25;
    }

    // 等待減分（不喜歡被動）
    if (action == AIActionType.wait) {
      bonus -= 30;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 怒火技能：只要有目標就想用
    // 即使會損失自己的聲望也在所不惜
    if (ai.reputation < 20) return false; // 聲望太低會死

    // 有弱勢目標時使用
    if (situation.weakTargets.isNotEmpty) return true;

    // 威脅高時也使用（同歸於盡心態）
    if (situation.threatLevel > 50) return true;

    // 預設就是想用
    return ai.reputation > 40;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 怒火目標：優先攻擊工廠主，其次是聲望最高的
    Player? bestTarget;
    double highestPriority = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = player.reputation.toDouble();

      // 非盟友優先
      if (!ai.allies.contains(player.id)) {
        priority += 20;
      }

      if (priority > highestPriority) {
        highestPriority = priority;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }
}

// ============================================================
// 律師查爾斯 AI 行為
// ============================================================

/// 律師查爾斯 AI 行為
///
/// 特點：
/// - 規則操控專家，善於利用法律漏洞
/// - 「法律漏洞」技能：取消正在生效的 Debuff
/// - 「彈劾程序」技能：降低彈劾所需聲望
/// - 「交叉詰問」被動：質詢時若對方說謊，傷害 +50%
/// - 投票傾向：C（折衷改革）
class LawyerCharlesBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.lawyerCharles;

  @override
  String get characterName => '律師查爾斯';

  @override
  Faction get faction => Faction.reform;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.2, // 適度攻擊（利用交叉詰問）
        defenseModifier: 0.3, // 重視防禦（保護自己和盟友）
        allyModifier: 0.4, // 善於外交（作為改革派調解者）
        skillModifier: 0.6, // 常用技能（法律專業）
        riskTolerance: 0.45, // 謹慎但不保守
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50; // 基礎優先級
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 優先攻擊有 debuff 記錄或不誠實的玩家（交叉詰問加成）
      // 這裡簡化為優先攻擊聲望高的玩家（可能有更多秘密）
      if (player.reputation > 60) {
        priority += 20;
        reason = '聲望高 - 可能隱藏秘密';
      }

      // 優先攻擊極端派系（工人和資方），作為改革派調解者
      if (role?.faction == Faction.worker || role?.faction == Faction.factory) {
        priority += 15;
        reason = '極端派系 - 需要被制衡';
      }

      // 避免攻擊改革派同伴
      if (role?.faction == Faction.reform) {
        priority -= 40;
        reason = '改革派同伴 - 應該合作';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 60;
        reason = '盟友 - 不應攻擊';
      }

      // 有負面狀態效果的玩家可能需要幫助（法律漏洞技能目標）
      if (player.statusEffects.any((e) => !e.isBuff)) {
        priority -= 10; // 可能是需要幫助的對象
        reason += '，有負面狀態';
      }

      // 關係分數影響
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 15;
        reason += '，關係惡劣';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 檢查是否有盟友或任何玩家有負面狀態（法律漏洞技能機會）
    final hasDebuffedAllies = state.players.any((p) =>
        p.id != ai.id &&
        p.isAlive &&
        (ai.allies.contains(p.id) || ai.getRelationshipScore(p.id) > 20) &&
        p.statusEffects.any((e) => !e.isBuff));

    if (hasDebuffedAllies) {
      actions.add(AIActionType.useSkill); // 優先使用法律漏洞幫助盟友
    }

    // 作為改革派，優先外交
    if (ai.allies.isEmpty || ai.allies.length < 2) {
      actions.add(AIActionType.ally);
    }

    // 有足夠聲望時可以攻擊（利用交叉詰問）
    if (ai.reputation > 40) {
      actions.add(AIActionType.attack);
    }

    // 聲望低時防禦
    if (ai.reputation < 50) {
      actions.add(AIActionType.defend);
    }

    // 發言以收集情報和建立關係
    actions.add(AIActionType.speak);

    // 如果聲望足夠且有技能可用，考慮使用彈劾程序
    if (ai.reputation >= 15) {
      actions.add(AIActionType.useSkill);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 改革派查爾斯傾向折衷方案，但會根據議案調整
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'C', // 折衷改革
          strength: 0.85,
          reason: '法律應該平衡各方利益，折衷方案最為公正',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'C', // 滑動關稅
          strength: 0.8,
          reason: '滑動關稅制度最能體現法律的彈性與公正',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'C', // 選擇性關稅
          strength: 0.85,
          reason: '選擇性關稅是最合理的法律框架',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時
          strength: 0.9,
          reason: '限制工時既保護兒童權益，又兼顧經濟現實，是最佳的法律折衷',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'C', // 有限承認
          strength: 0.85,
          reason: '有限承認工會是最佳的法律框架，既保障工人權益，又維持社會秩序',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'C', // 秘密投票
          strength: 0.9,
          reason: '秘密投票是程序正義的體現，能有效防止選舉舞弊和威脅',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.75,
          reason: '經濟讓步是法律上最可行的方案，能緩解矛盾而不動搖帝國根基',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.8,
          reason: '技職教育能提高社會素質，培養知法守法的公民',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'C',
          strength: 0.8,
          reason: '支持平衡各方利益的方案',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能加分（法律專業）
    if (action == AIActionType.useSkill) {
      bonus += 20;

      // 如果有盟友被 debuff，額外加分
      if (targetId != null && ai.allies.contains(targetId)) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.statusEffects.any((e) => !e.isBuff)) {
          bonus += 25; // 幫助盟友解除負面狀態
        }
      }
    }

    // 攻擊加分（交叉詰問被動）
    if (action == AIActionType.attack) {
      bonus += 10; // 交叉詰問讓攻擊更有效
    }

    // 結盟加分（改革派的外交特性）
    if (action == AIActionType.ally) {
      bonus += 15;

      // 與中立派或記者結盟額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        // 優先拉攏中間派
        if (target != null && target.reputation > 40 && target.reputation < 70) {
          bonus += 10;
        }
      }
    }

    // 防禦適度加分
    if (action == AIActionType.defend) {
      bonus += 5;
    }

    // 背叛減分（律師重視契約精神）
    if (action == AIActionType.betray) {
      bonus -= 20;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 法律漏洞技能：檢查是否有盟友或友好玩家需要解除 debuff
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 盟友或關係好的玩家有 debuff
      if ((ai.allies.contains(player.id) ||
              ai.getRelationshipScore(player.id) > 20) &&
          player.statusEffects.any((e) => !e.isBuff)) {
        return true;
      }
    }

    // 彈劾程序技能：威脅高且有強勢敵人時考慮使用
    if (situation.threatLevel > 60 && situation.strongPlayers.isNotEmpty) {
      // 檢查是否有足夠聲望發起彈劾（15 聲望，因為有 50% 減免）
      if (ai.reputation >= 15) {
        return true;
      }
    }

    // 自己有負面狀態時也使用（自救）
    if (ai.player.statusEffects.any((e) => !e.isBuff)) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 優先目標 1：有 debuff 的盟友
    for (final allyId in ai.allies) {
      final ally = state.players.where((p) => p.id == allyId).firstOrNull;
      if (ally != null &&
          ally.isAlive &&
          ally.statusEffects.any((e) => !e.isBuff)) {
        return allyId;
      }
    }

    // 優先目標 2：自己有 debuff
    if (ai.player.statusEffects.any((e) => !e.isBuff)) {
      return ai.id;
    }

    // 優先目標 3：關係好的玩家有 debuff
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.getRelationshipScore(player.id) > 20 &&
          player.statusEffects.any((e) => !e.isBuff)) {
        return player.id;
      }
    }

    // 彈劾目標：威脅最大的強勢玩家
    Player? impeachTarget;
    double highestThreat = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      // 計算威脅度
      final threat = player.reputation.toDouble() -
          ai.getRelationshipScore(player.id);

      if (player.reputation > 60 && threat > highestThreat) {
        highestThreat = threat;
        impeachTarget = player;
      }
    }

    return impeachTarget?.id;
  }
}

// ============================================================
// 礦工約翰 AI 行為
// ============================================================

/// 礦工約翰 AI 行為
///
/// 特點：
/// - 坦克型角色，高防禦、高聲望
/// - 「以身擋刀」技能：保護盟友
/// - 「礦工之牆」被動：當聲望 > 60 時，勞工派盟友防禦 +10
/// - 「沉默的憤怒」技能：本回合不發言，下回合攻擊傷害 +80%，無視目標 50% 防禦
/// - 投票傾向：A（禁止機器）- 保護工人生計
class MinerJohnBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.minerJohn;

  @override
  String get characterName => '礦工約翰';

  @override
  Faction get faction => Faction.worker;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.1, // 低攻擊傾向（沉默寡言）
        defenseModifier: 0.7, // 非常重視防禦（坦克定位）
        allyModifier: 0.6, // 重視保護盟友
        betrayModifier: -0.8, // 極低背叛傾向（忠誠可靠）
        skillModifier: 0.5, // 適度使用技能
        riskTolerance: 0.3, // 保守風險承受（保護型角色）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 40; // 基礎優先級較低（不主動攻擊）
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 只有在盟友被攻擊時才會反擊
      // 工廠主是主要威脅（但不會主動出擊）
      if (role?.faction == Faction.factory) {
        priority += 25;
        reason = '工廠主 - 工人的威脅';
      }

      // 優先攻擊已經攻擊過盟友的玩家
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -40) {
        priority += 35;
        reason = '曾經傷害工人兄弟 - 必須懲罰';
      }

      // 絕不攻擊勞工派同伴
      if (role?.faction == Faction.worker) {
        priority -= 60;
        reason = '工人兄弟 - 絕對保護';
      }

      // 絕不攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 80;
        reason = '盟友 - 用生命保護';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用技能保護盟友
    if (ai.allies.isNotEmpty) {
      actions.add(AIActionType.useSkill); // 以身擋刀
    }

    // 防禦優先（坦克定位）
    actions.add(AIActionType.defend);

    // 積極結盟（保護更多工人）
    actions.add(AIActionType.ally);

    // 沉默準備（沉默的憤怒技能）
    // 當受到攻擊時，可以選擇沉默，下回合反擊
    if (ai.getRelationshipScore(state.currentSpeakerId ?? '') < -30) {
      actions.add(AIActionType.useSkill); // 沉默的憤怒
    }

    // 只有在必要時才攻擊（報復或保護盟友）
    if (ai.reputation > 60) {
      actions.add(AIActionType.attack);
    }

    // 很少發言（沉默寡言）
    // actions.add(AIActionType.speak); // 故意省略

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 礦工約翰支持保護工人的選項，但比盧德派更溫和
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止機器
          strength: 0.85,
          reason: '機器奪走了礦工的工作和生命',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.8,
          reason: '便宜的麵包能讓礦工家庭吃飽飯',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'A', // 提高關稅
          strength: 0.8,
          reason: '保護國內產業就是保護礦工的工作',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時
          strength: 0.9,
          reason: '孩子們不應該在礦坑裡工作太久，但有些家庭需要這份收入',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 0.9,
          reason: '礦工需要工會保護，礦坑太危險了，團結才能活下去',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 0.8,
          reason: '礦工也應該有投票權，我們用命換來的煤養活了整個帝國',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.6,
          reason: '威爾斯礦工和愛爾蘭人一樣被壓迫...但政治太複雜了',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.85,
          reason: '技職教育能讓礦工的孩子學到安全的技能，不用下礦坑',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.8,
          reason: '支持保護工人的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 防禦大加分（坦克核心）
    if (action == AIActionType.defend) {
      bonus += 35;
    }

    // 使用技能加分（以身擋刀、沉默的憤怒）
    if (action == AIActionType.useSkill) {
      bonus += 25;

      // 有盟友需要保護時更高
      if (ai.allies.isNotEmpty) {
        bonus += 15;
      }
    }

    // 結盟加分（團結工人）
    if (action == AIActionType.ally) {
      bonus += 20;

      // 與勞工派結盟額外加分
      if (targetId != null) {
        // 這裡簡化處理
        bonus += 10;
      }
    }

    // 攻擊不加分也不減分（沉默但可靠）
    // 除非是報復
    if (action == AIActionType.attack && targetId != null) {
      final relationScore = ai.getRelationshipScore(targetId);
      if (relationScore < -30) {
        bonus += 20; // 報復攻擊加分
      }
    }

    // 背叛大減分（忠誠的礦工）
    if (action == AIActionType.betray) {
      bonus -= 50;
    }

    // 發言減分（沉默寡言）
    if (action == AIActionType.speak) {
      bonus -= 15;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 以身擋刀：當有盟友處於危險時
    for (final allyId in ai.allies) {
      final ally = state.players.where((p) => p.id == allyId).firstOrNull;
      if (ally != null && ally.isAlive) {
        // 盟友聲望低於 40 時使用保護
        if (ally.reputation < 40) {
          return true;
        }

        // 有玩家正在攻擊盟友時使用
        if (situation.mainThreats.isNotEmpty) {
          return true;
        }
      }
    }

    // 沉默的憤怒：當自己受到攻擊且有足夠聲望時
    if (situation.threatLevel > 60 && ai.reputation > 50) {
      return true;
    }

    // 礦工之牆：被動技能，聲望 > 60 時自動生效
    // 這裡返回 true 表示 AI 會主動維持高聲望狀態
    return ai.reputation > 60 && ai.allies.isNotEmpty;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 以身擋刀目標：優先保護聲望最低的盟友
    String? targetAlly;
    int lowestReputation = 101;

    for (final allyId in ai.allies) {
      final ally = state.players.where((p) => p.id == allyId).firstOrNull;
      if (ally != null && ally.isAlive && ally.reputation < lowestReputation) {
        lowestReputation = ally.reputation;
        targetAlly = allyId;
      }
    }

    if (targetAlly != null) {
      return targetAlly;
    }

    // 如果沒有盟友需要保護，尋找勞工派玩家保護
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (player.reputation < 40) {
        return player.id;
      }
    }

    return null;
  }
}

// ============================================================
// 銀行家亨利 AI 行為
// ============================================================

/// 銀行家亨利 AI 行為
///
/// 特點：
/// - 資方派，但專注金融操控而非直接攻擊
/// - 優先使用「放貸」技能給目標製造負債
/// - 會在關鍵時刻使用「金融恐慌」削弱所有人
/// - 被動收取負債玩家的利息
/// - 投票傾向：B（保護財產）但也關注金融利益
class BankerHenryBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.bankerHenry;

  @override
  String get characterName => '銀行家亨利';

  @override
  Faction get faction => Faction.factory;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: -0.1, // 不太直接攻擊
        defenseModifier: 0.2, // 略微注重防禦
        allyModifier: 0.1, // 不太重視結盟
        skillModifier: 0.7, // 非常依賴技能（放貸、金融恐慌）
        riskTolerance: 0.6, // 中高風險承受（金融家敢冒險）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 金幣多的玩家是放貸目標（他們更容易還錢，但也可能不還）
      if (player.gold > 30) {
        priority += 20;
        reason = '有錢人 - 值得放貸';
      }

      // 聲望高但金幣少的玩家是最佳放貸目標（可能還不起）
      if (player.reputation > 50 && player.gold < 20) {
        priority += 35;
        reason = '高聲望低金幣 - 理想放貸對象';
      }

      // 已有負債狀態的玩家優先級降低（已經在收利息了）
      final hasDebt = player.statusEffects.any(
        (e) => e.type == StatusEffectType.debt,
      );
      if (hasDebt) {
        priority -= 30;
        reason = '已有負債 - 繼續收利息';
      }

      // 工人和盧德派優先（讓他們欠債）
      if (role?.faction == Faction.worker) {
        priority += 15;
        reason += '，工人階級';
      }

      // 同為資方不太攻擊
      if (role?.faction == Faction.factory) {
        priority -= 20;
        reason = '資方同伴 - 保留';
      }

      // 盟友不放貸
      if (ai.allies.contains(player.id)) {
        priority -= 40;
        reason = '盟友 - 不放貸';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用放貸技能
    if (ai.gold >= 30) {
      actions.add(AIActionType.useSkill);
    }

    // 防禦優先（保護自己的金融帝國）
    actions.add(AIActionType.defend);

    // 發言影響他人
    actions.add(AIActionType.speak);

    // 必要時攻擊（但不是主要手段）
    if (ai.reputation > 40) {
      actions.add(AIActionType.attack);
    }

    // 結盟（但不太熱衷）
    if (ai.allies.isEmpty && ai.favor >= 2) {
      actions.add(AIActionType.ally);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 銀行家根據金融利益判斷投票
    int debtorsCount = 0;
    for (final player in state.players) {
      if (player.id == ai.id) continue;
      if (player.statusEffects.any((e) => e.type == StatusEffectType.debt)) {
        debtorsCount++;
      }
    }

    // 根據不同議案調整投票偏好
    switch (bill.id) {
      case 'machinery_bill':
        // 如果負債者多，傾向維持現狀
        if (debtorsCount >= 2) {
          return const VotePreference(
            preferredOption: 'C',
            strength: 0.6,
            reason: '維持金融秩序，繼續收取利息',
            canBeSwayed: true,
          );
        }
        return const VotePreference(
          preferredOption: 'B', // 保護財產
          strength: 0.8,
          reason: '保護財產權就是保護金融體系',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'A', // 高關稅
          strength: 0.75,
          reason: '高關稅保護的地主都是我的客戶',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.85,
          reason: '自由貿易促進國際金融流通，對銀行有利',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.8,
          reason: '禁止童工會降低工廠利潤，影響他們還款能力',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持禁令
          strength: 0.9,
          reason: '工會會要求加薪，這會增加我的債務人的負擔，影響還款',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.85,
          reason: '只有有財產的人才懂得如何管理經濟，窮人不該有投票權',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.75,
          reason: '經濟讓步能開拓愛爾蘭市場，有利於我的放貸業務',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.7,
          reason: '技職教育能培養更多合格的工人，提高他們的還款能力',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'B',
          strength: 0.7,
          reason: '支持有利於金融穩定的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分
    if (action == AIActionType.useSkill && ai.gold >= 30) {
      bonus += 35;
    }

    // 防禦加分
    if (action == AIActionType.defend) {
      bonus += 15;
    }

    // 攻擊略減分（不是主要手段）
    if (action == AIActionType.attack) {
      bonus -= 5;
    }

    // 發言加分（影響市場情緒）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    // 對沒有負債的目標使用技能加分
    if (action == AIActionType.useSkill && targetId != null) {
      final target = state.players.where((p) => p.id == targetId).firstOrNull;
      if (target != null) {
        final hasDebt = target.statusEffects.any(
          (e) => e.type == StatusEffectType.debt,
        );
        if (!hasDebt) {
          bonus += 20; // 新的放貸對象
        }
      }
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 有足夠金幣就考慮放貸
    if (ai.gold < 30) return false;

    // 計算已有負債的玩家數
    int debtorsCount = 0;
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (player.statusEffects.any((e) => e.type == StatusEffectType.debt)) {
        debtorsCount++;
      }
    }

    // 如果負債者少於一半的存活玩家，繼續放貸
    final aliveOthers = state.players.where((p) => p.id != ai.id && p.isAlive).length;
    if (debtorsCount < aliveOthers / 2) {
      return true;
    }

    // 遊戲後期考慮使用金融恐慌
    if (state.currentRound >= state.totalRounds - 1 && ai.gold >= 50) {
      // 如果自己金幣遠超其他人，使用金融恐慌更有利
      final avgOtherGold = state.players
          .where((p) => p.id != ai.id && p.isAlive)
          .map((p) => p.gold)
          .fold(0, (a, b) => a + b) / aliveOthers;

      if (ai.gold > avgOtherGold * 2) {
        return true;
      }
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 放貸目標：優先選擇沒有負債、聲望高但金幣少的玩家
    Player? bestTarget;
    double highestPriority = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 跳過已有負債的玩家
      final hasDebt = player.statusEffects.any(
        (e) => e.type == StatusEffectType.debt,
      );
      if (hasDebt) continue;

      // 跳過盟友
      if (ai.allies.contains(player.id)) continue;

      // 計算放貸價值
      double priority = 50.0;

      // 聲望高的玩家更有價值（負債懲罰更痛）
      priority += player.reputation * 0.3;

      // 金幣少的玩家更可能還不起
      if (player.gold < 40) {
        priority += 30;
      }

      if (priority > highestPriority) {
        highestPriority = priority;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }
}

// ============================================================
// 喬治三世 AI 行為
// ============================================================

/// 喬治三世 AI 行為
///
/// 特點：
/// - 皇室陣營，擁有最高權力
/// - 「王權宣言」技能：強制觸發突發事件（每局限用 1 次）
/// - 「皇家裁決」技能：結束辯論立即投票（每局限用 1 次）
/// - 「精神不穩」被動：每回合 10% 機率失去行動能力（負面效果）
/// - 投票傾向：視情況而定（作為仲裁者較中立）
/// - 高聲望但行為不穩定
class KingGeorgeIIIBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.kingGeorgeIII;

  @override
  String get characterName => '喬治三世';

  @override
  Faction get faction => Faction.royal;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.1, // 略傾向攻擊（王權威嚴）
        defenseModifier: 0.2, // 適度防禦
        allyModifier: -0.2, // 不太需要結盟（自視甚高）
        skillModifier: 0.7, // 經常使用技能（王權展示）
        riskTolerance: 0.6, // 中高風險承受（精神不穩導致決策大膽）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50; // 基礎優先級
      String reason = '一般臣民';

      final role = playerRoles[player.id];

      // 優先針對聲望高的玩家（挑戰王權的人）
      if (player.reputation > 70) {
        priority += 30;
        reason = '聲望過高 - 挑戰王權';
      }

      // 激進派（盧德派、極端勞工）是秩序的破壞者
      if (role?.faction == Faction.worker) {
        priority += 15;
        reason = '工人派 - 可能威脅秩序';
      }

      // 記者可能揭露皇室醜聞
      if (role?.faction == Faction.press) {
        priority += 20;
        reason = '記者 - 可能損害皇室名譽';
      }

      // 對資方略為寬容（工業帶來稅收）
      if (role?.faction == Faction.factory) {
        priority -= 10;
        reason = '資方 - 帝國的經濟支柱';
      }

      // 改革派可接受（溫和派）
      if (role?.faction == Faction.reform) {
        priority -= 5;
        reason = '改革派 - 尚可容忍';
      }

      // 避免攻擊盟友（即使不常結盟）
      if (ai.allies.contains(player.id)) {
        priority -= 50;
        reason = '盟友 - 王的恩典';
      }

      // 關係惡劣的人優先處理
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 20;
        reason += '，對王不敬';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 國王優先考慮使用強力技能
    // 王權宣言和皇家裁決都是每局一次的強力技能
    if (ai.reputation > 50) {
      actions.add(AIActionType.useSkill);
    }

    // 作為仲裁者，可能會攻擊擾亂秩序的人
    if (ai.reputation > 60) {
      actions.add(AIActionType.attack);
    }

    // 維持王權威嚴，適度防禦
    actions.add(AIActionType.defend);

    // 國王的發言有重量
    actions.add(AIActionType.speak);

    // 國王很少主動結盟（高傲）
    if (ai.allies.isEmpty && ai.reputation < 60) {
      actions.add(AIActionType.ally);
    }

    // 國王不太會背叛（除非精神不穩發作）
    // 但精神不穩可能導致不理性行為
    if (ai.reputation < 40) {
      actions.add(AIActionType.betray); // 困境中可能做出瘋狂決定
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 國王作為仲裁者，傾向維持現狀或折衷方案
    // 但精神不穩可能影響判斷

    String preferredOption = 'C';
    double strength = 0.7;
    String reason = '折衷方案最能維持帝國穩定';

    // 如果局勢動盪（聲望低），可能做出極端決定
    if (ai.reputation < 50) {
      // 精神不穩可能導致極端選擇
      if (state.currentRound % 2 == 0) {
        preferredOption = 'A';
        reason = '（精神恍惚）朕說了算！';
        strength = 0.9;
      } else {
        preferredOption = 'B';
        reason = '（精神恍惚）保護朕的利益...';
        strength = 0.9;
      }
      return VotePreference(
        preferredOption: preferredOption,
        strength: strength,
        reason: reason,
        canBeSwayed: false,
      );
    }

    // 精神穩定時根據議案做出判斷
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'C',
          strength: 0.75,
          reason: '折衷方案最能維持帝國穩定',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'C', // 滑動關稅
          strength: 0.7,
          reason: '滑動關稅能平衡地主和平民的利益',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'C', // 選擇性關稅
          strength: 0.75,
          reason: '選擇性關稅既能保護帝國工業，又不會引發貿易戰',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時
          strength: 0.8,
          reason: '限制工時展現皇室對子民的仁慈，又不至於損害經濟',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持禁令
          strength: 0.85,
          reason: '工會是危險的組織，可能威脅王權穩定，必須禁止',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.9,
          reason: '選舉制度是祖先留下的智慧，不可輕易改變',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持聯合
          strength: 0.95,
          reason: '愛爾蘭是大不列顛的一部分，任何分裂都是對王權的挑戰！',
          canBeSwayed: false,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'B', // 教會教育
          strength: 0.85,
          reason: '教會是教育的傳統守護者，宗教教育能培養忠誠的臣民',
          canBeSwayed: true,
        );
      default:
        return VotePreference(
          preferredOption: preferredOption,
          strength: strength,
          reason: reason,
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（王權展示）
    if (action == AIActionType.useSkill) {
      bonus += 35;

      // 如果辯論陷入僵局，皇家裁決更有價值
      if (state.currentRound >= state.totalRounds - 1) {
        bonus += 20; // 關鍵時刻使用技能
      }
    }

    // 攻擊加分（維護王權）
    if (action == AIActionType.attack) {
      bonus += 15;

      // 攻擊高聲望目標額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation > 60) {
          bonus += 15; // 打擊威脅王權的人
        }
      }
    }

    // 防禦適度加分
    if (action == AIActionType.defend) {
      bonus += 10;
    }

    // 發言加分（國王的話有重量）
    if (action == AIActionType.speak) {
      bonus += 5;
    }

    // 結盟減分（國王高傲）
    if (action == AIActionType.ally) {
      bonus -= 15;
    }

    // 背叛大減分（但精神不穩時可能發生）
    if (action == AIActionType.betray) {
      bonus -= 25;
      // 精神不穩時減分較少
      if (ai.reputation < 50) {
        bonus += 15; // 抵消部分減分
      }
    }

    // 等待減分（國王應該行動）
    if (action == AIActionType.wait) {
      bonus -= 10;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 王權宣言：在需要打破僵局或製造混亂時使用
    // 皇家裁決：在辯論對自己不利或需要快速結束時使用

    // 威脅高時使用技能（展示王權）
    if (situation.threatLevel > 60) {
      return true;
    }

    // 局勢有利時使用技能（鞏固優勢）
    if (situation.opportunityLevel > 70) {
      return true;
    }

    // 辯論後期使用皇家裁決
    if (state.currentRound >= state.totalRounds - 1) {
      return true;
    }

    // 自身聲望很高時展示王權
    if (ai.reputation > 80) {
      return true;
    }

    // 精神不穩可能導致衝動使用技能
    if (ai.reputation < 50 && situation.threatLevel > 40) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 王權宣言不需要目標（觸發隨機事件）
    // 皇家裁決也不需要目標（結束辯論）

    // 如果需要選擇目標，選擇威脅最大的玩家
    Player? bestTarget;
    double highestThreat = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 計算威脅度
      double threat = player.reputation.toDouble();

      // 非盟友優先
      if (!ai.allies.contains(player.id)) {
        threat += 20;
      }

      // 關係差的優先
      final relation = ai.getRelationshipScore(player.id);
      if (relation < 0) {
        threat += (-relation / 2);
      }

      if (threat > highestThreat) {
        highestThreat = threat;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }

  /// 檢查精神不穩是否發作
  ///
  /// 每回合有 10% 機率失去行動能力
  /// 這個方法由遊戲引擎在回合開始時調用
  static bool checkMadnessTriggered() {
    // 使用時間戳作為簡單的隨機源
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < 10; // 10% 機率
  }
}

// ============================================================
// 紡織女工瑪莉 AI 行為
// ============================================================

/// 紡織女工瑪莉 AI 行為
///
/// 特點：
/// - 勞工派輔助控制角色，識字聰明
/// - 「悲情控訴」技能：獲得弱者光環，受傷-50%但攻擊-30%
/// - 「工廠耳語」被動：每回合開始有30%機率獲得資方情報
/// - 「姐妹情誼」技能：與女性角色互相強化
/// - 投票傾向：A（禁止機器）但態度較溫和
/// - 情報能力強，擅長收集資方秘密
class TextileMaryBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.textileMary;

  @override
  String get characterName => '紡織女工瑪莉';

  @override
  Faction get faction => Faction.worker;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: -0.1, // 略偏防守（輔助角色）
        defenseModifier: 0.4, // 重視防禦（悲情控訴技能）
        allyModifier: 0.5, // 非常重視結盟（姐妹情誼）
        betrayModifier: -0.5, // 不太會背叛（重視情誼）
        skillModifier: 0.6, // 經常使用技能
        riskTolerance: 0.4, // 謹慎型
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 45; // 基礎優先級（輔助角色，不太主動攻擊）
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 資方是主要目標（工廠耳語技能專門針對資方）
      if (role?.faction == Faction.factory) {
        priority += 30;
        reason = '資方 - 工廠的壓迫者';
      }

      // 避免攻擊勞工派同伴
      if (role?.faction == Faction.worker) {
        priority -= 45;
        reason = '工人姐妹兄弟 - 應該團結';
      }

      // 女性角色是潛在盟友（姐妹情誼）
      // 這裡需要根據角色ID判斷性別
      // 目前只有 textileMary 是女性，未來可能有學者伊莉莎白等
      if (_isFemaleCharacter(role?.id)) {
        priority -= 30;
        reason = '姐妹 - 應該結盟';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 60;
        reason = '盟友 - 不應攻擊';
      }

      // 聲望高的資方是更好的目標（情報更有價值）
      if (role?.faction == Faction.factory && player.reputation > 60) {
        priority += 15;
        reason = '高聲望資方 - 情報價值高';
      }

      // 關係惡劣時優先處理
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 20;
        reason += '，曾傷害過我';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 優先與女性角色或勞工派結盟（姐妹情誼）
    if (ai.allies.isEmpty || ai.allies.length < 2) {
      actions.add(AIActionType.ally);
    }

    // 在危險時使用悲情控訴
    if (ai.reputation < 50) {
      actions.add(AIActionType.useSkill);
    }

    // 防禦優先（輔助角色）
    actions.add(AIActionType.defend);

    // 利用情報進行揭露
    if (ai.intel >= 2) {
      actions.add(AIActionType.reveal);
    }

    // 發言收集情報
    actions.add(AIActionType.speak);

    // 有盟友時可以攻擊
    if (ai.allies.isNotEmpty && ai.reputation > 40) {
      actions.add(AIActionType.attack);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 瑪莉支持禁止機器，但態度比盧德派溫和
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止機器
          strength: 0.75,
          reason: '機器奪走了我母親的工作，但我們也需要理性地解決問題',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.8,
          reason: '便宜的麵包能讓工人家庭吃飽飯',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'A', // 提高關稅
          strength: 0.75,
          reason: '保護國內紡織業，就是保護我們女工的工作',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止童工
          strength: 0.9,
          reason: '我從小在工廠長大，不希望其他孩子經歷同樣的苦難',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 0.85,
          reason: '女工特別需要工會保護，我們的處境比男工更艱難',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 0.7,
          reason: '雖然女性還不能投票，但擴大選舉權是正確的方向',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A', // 愛爾蘭自治
          strength: 0.65,
          reason: '愛爾蘭的女工和我們一樣受苦，支持她們的自由',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'A', // 普及教育
          strength: 0.9,
          reason: '識字改變了我的人生，每個孩子都應該有受教育的機會',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.75,
          reason: '支持有利於工人的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 結盟大加分（姐妹情誼）
    if (action == AIActionType.ally) {
      bonus += 25;

      // 與女性角色結盟額外加分
      if (targetId != null && _isFemaleCharacter(targetId)) {
        bonus += 20; // 姐妹情誼加成
      }

      // 與勞工派結盟加分
      final target = state.players.where((p) => p.id == targetId).firstOrNull;
      if (target != null) {
        bonus += 10;
      }
    }

    // 使用技能加分
    if (action == AIActionType.useSkill) {
      bonus += 20;

      // 聲望低時悲情控訴更有價值
      if (ai.reputation < 50) {
        bonus += 15;
      }
    }

    // 防禦加分（輔助角色）
    if (action == AIActionType.defend) {
      bonus += 15;
    }

    // 揭露情報加分（工廠耳語）
    if (action == AIActionType.reveal && ai.intel >= 1) {
      bonus += 15;
    }

    // 發言加分（收集情報）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    // 攻擊不加分（不是主要角色定位）
    if (action == AIActionType.attack) {
      bonus += 0;

      // 但攻擊資方時略有加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null) {
          bonus += 5;
        }
      }
    }

    // 背叛大減分（重視情誼）
    if (action == AIActionType.betray) {
      bonus -= 30;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 悲情控訴：在受到威脅時使用
    if (situation.threatLevel > 50 && ai.reputation < 60) {
      return true;
    }

    // 姐妹情誼：檢查是否有女性盟友需要增強
    for (final allyId in ai.allies) {
      if (_isFemaleCharacter(allyId)) {
        return true; // 與姐妹互相增強
      }
    }

    // 有女性角色尚未結盟時，嘗試使用姐妹情誼
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (_isFemaleCharacter(player.id) && !ai.allies.contains(player.id)) {
        // 有潛在姐妹可以結盟
        if (ai.getRelationshipScore(player.id) > 0) {
          return true;
        }
      }
    }

    // 被攻擊時使用悲情控訴（用威脅等級判斷）
    if (situation.threatLevel > 60 && situation.mainThreats.isNotEmpty) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 姐妹情誼目標：優先選擇女性角色
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (_isFemaleCharacter(player.id)) {
        // 已經是盟友的優先
        if (ai.allies.contains(player.id)) {
          return player.id;
        }
      }
    }

    // 沒有女性盟友時，選擇關係最好的玩家作為悲情控訴的展示對象
    String? bestTarget;
    int highestRelation = -100;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      final relation = ai.getRelationshipScore(player.id);
      if (relation > highestRelation) {
        highestRelation = relation;
        bestTarget = player.id;
      }
    }

    return bestTarget;
  }

  /// 判斷角色是否為女性
  /// 目前女性角色：textile_mary
  /// 未來可能添加：scholar_elizabeth（學者伊莉莎白）等
  bool _isFemaleCharacter(String? roleId) {
    const femaleCharacters = [
      'textile_mary',
      'scholar_elizabeth', // 預留給未來的女性角色
    ];
    return roleId != null && femaleCharacters.contains(roleId);
  }

  /// 檢查工廠耳語是否觸發
  ///
  /// 每回合有 30% 機率獲得關於資方的情報
  /// 這個方法由遊戲引擎在回合開始時調用
  static bool checkFactoryWhispersTriggered() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < 30; // 30% 機率
  }
}

// ============================================================
// 間諜法蘭西斯 AI 行為
// ============================================================

/// 間諜法蘭西斯 AI 行為
///
/// 特點：
/// - 中立派，陣營對外顯示為「???」（雙面間諜被動）
/// - 不主動攻擊，除非有利可圖
/// - 喜歡收集和交易情報
/// - 投票偏好不固定，根據當前局勢決定
/// - 「情報滲透」技能：窺視玩家的秘密任務
/// - 「致命情報」技能：消耗情報造成大傷害
class SpyFrancisBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.spyFrancis;

  @override
  String get characterName => '間諜法蘭西斯';

  @override
  Faction get faction => Faction.neutral;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: -0.2, // 不主動攻擊
        defenseModifier: 0.2, // 適度防禦
        allyModifier: 0.1, // 不太重視結盟（神秘感）
        skillModifier: 0.7, // 非常依賴技能（情報操控）
        riskTolerance: 0.5, // 中等風險承受（冷靜計算）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '潛在情報來源';

      final role = playerRoles[player.id];
      // 使用 role 來避免 unused variable 警告
      final _ = role?.faction;

      // 情報豐富的玩家是優先目標（可以交易或竊取情報）
      if (player.intel > 3) {
        priority += 25;
        reason = '情報豐富 - 有價值的目標';
      }

      // 聲望高的玩家是「致命情報」的好目標
      if (player.reputation > 60) {
        priority += 20;
        reason = '聲望高 - 致命情報的理想目標';
      }

      // 觀察各派系的秘密任務來決定站隊
      // 對領先者施加壓力
      if (player.reputation > 70 && !ai.allies.contains(player.id)) {
        priority += 15;
        reason += '，領先者需要被制衡';
      }

      // 對弱者保持距離（沒有利用價值）
      if (player.reputation < 30) {
        priority -= 20;
        reason = '聲望低 - 利用價值有限';
      }

      // 盟友暫時不攻擊（但間諜的盟友關係不穩定）
      if (ai.allies.contains(player.id)) {
        priority -= 30;
        reason = '暫時的盟友 - 觀察中';
      }

      // 關係分數影響
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -40) {
        priority += 20;
        reason += '，曾經得罪過我';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用情報相關技能
    if (ai.gold >= 15 || ai.intel >= 2) {
      actions.add(AIActionType.useSkill);
    }

    // 揭露情報（核心能力）
    if (ai.intel >= 1) {
      actions.add(AIActionType.reveal);
    }

    // 防禦優先（保持低調）
    actions.add(AIActionType.defend);

    // 發言收集情報
    actions.add(AIActionType.speak);

    // 只有在有明確利益時才攻擊
    if (ai.intel >= 2 && ai.reputation > 30) {
      actions.add(AIActionType.attack);
    }

    // 間諜可能結盟，但也可能隨時背叛
    if (ai.allies.isEmpty && state.currentRound > 1) {
      actions.add(AIActionType.ally);
    }

    // 如果有盟友且對方不再有利用價值，可能背叛
    if (ai.allies.isNotEmpty && ai.reputation > 35) {
      actions.add(AIActionType.betray);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 間諜根據當前局勢決定投票
    // 分析各派系的實力和自己的利益

    // 計算各派系存活玩家數量和平均聲望
    int workerCount = 0;
    int factoryCount = 0;

    for (final player in state.players) {
      if (!player.isAlive || player.id == ai.id) continue;

      // 這裡簡化處理，實際應該根據已知情報判斷
      // 假設間諜能觀察到部分陣營資訊
      if (player.reputation > 60) {
        // 高聲望玩家可能是資方
        factoryCount++;
      } else {
        // 其他可能是勞工派
        workerCount++;
      }
    }

    // 選擇對自己最有利的選項（站在弱勢方以獲取人情）
    String preferredOption;
    double strength;
    String reason;

    if (workerCount > factoryCount) {
      // 勞工派勢力較強，支持資方以平衡
      preferredOption = 'B';
      strength = 0.4;
      reason = '支持弱勢方以獲取人情...或者只是為了混亂';
    } else if (factoryCount > workerCount) {
      // 資方勢力較強，支持勞工派以平衡
      preferredOption = 'A';
      strength = 0.4;
      reason = '情報顯示資方過於強大...需要平衡';
    } else {
      // 勢均力敵，選擇折衷方案
      preferredOption = 'C';
      strength = 0.5;
      reason = '折衷方案對我最安全...目前是這樣';
    }

    // 針對特定議案的偏好
    switch (bill.id) {
      case 'trade_union_bill':
        preferredOption = 'C'; // 有限承認
        strength = 0.5;
        reason = '有限承認能讓我在各方之間遊走獲取情報...';
        break;
      case 'electoral_reform_bill':
        preferredOption = 'C'; // 秘密投票
        strength = 0.6;
        reason = '秘密投票...有趣，這會讓收買選票更困難，但情報更有價值';
        break;
      case 'irish_question_bill':
        preferredOption = 'A'; // 愛爾蘭自治
        strength = 0.4;
        reason = '愛爾蘭的混亂對情報工作很有利...誰知道呢？';
        break;
      case 'education_bill':
        preferredOption = 'C'; // 技職教育
        strength = 0.5;
        reason = '教育？我更關心誰在教什麼...';
        break;
    }

    // 如果自己聲望很低，選擇對自己最安全的選項
    if (ai.reputation < 30) {
      preferredOption = 'C';
      strength = 0.7;
      reason = '在這種情況下，保持低調最重要';
    }

    return VotePreference(
      preferredOption: preferredOption,
      strength: strength,
      reason: reason,
      canBeSwayed: true, // 間諜總是可以被說服（如果價碼合適）
    );
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（情報操控核心）
    if (action == AIActionType.useSkill) {
      bonus += 30;

      // 有足夠金幣使用情報滲透
      if (ai.gold >= 15) {
        bonus += 15;
      }

      // 有足夠情報使用致命情報
      if (ai.intel >= 2) {
        bonus += 20;
      }
    }

    // 揭露情報加分
    if (action == AIActionType.reveal && ai.intel >= 1) {
      bonus += 25;
    }

    // 防禦加分（保持神秘）
    if (action == AIActionType.defend) {
      bonus += 15;
    }

    // 發言加分（收集情報）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    // 攻擊不加分也不減分（除非有情報支持）
    if (action == AIActionType.attack) {
      if (ai.intel >= 2) {
        bonus += 10; // 有情報支持的攻擊更有效
      } else {
        bonus -= 10; // 無情報支持的攻擊風險高
      }
    }

    // 結盟略減分（間諜不太重視長期關係）
    if (action == AIActionType.ally) {
      bonus -= 5;
    }

    // 背叛不減分（間諜特性）
    if (action == AIActionType.betray) {
      // 如果背叛能帶來利益，甚至可以加分
      if (ai.allies.isNotEmpty) {
        bonus += 5;
      }
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 情報滲透：有足夠金幣且想了解其他玩家的秘密任務
    if (ai.gold >= 15) {
      // 有潛在威脅時使用
      if (situation.mainThreats.isNotEmpty) {
        return true;
      }

      // 有強勢玩家時使用（了解他們的計畫）
      if (situation.strongPlayers.isNotEmpty) {
        return true;
      }
    }

    // 致命情報：有足夠情報且有高價值目標
    if (ai.intel >= 2) {
      // 威脅高時使用
      if (situation.threatLevel > 60) {
        return true;
      }

      // 有機會一擊致命時使用
      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;
        // 如果目標聲望在 40-80 之間，致命情報可以造成致命傷害
        if (player.reputation >= 40 && player.reputation <= 80) {
          return true;
        }
      }

      // 遊戲後期使用（關鍵時刻）
      if (state.currentRound >= state.totalRounds - 1) {
        return true;
      }
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 選擇最有價值的目標

    // 優先目標 1：威脅最大的玩家（使用致命情報）
    if (ai.intel >= 2) {
      Player? bestTarget;
      double highestValue = 0;

      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;

        // 計算目標價值（聲望高且不是盟友）
        double value = player.reputation.toDouble();

        if (!ai.allies.contains(player.id)) {
          value += 20;
        }

        // 關係差的優先
        final relation = ai.getRelationshipScore(player.id);
        if (relation < 0) {
          value += (-relation / 3);
        }

        if (value > highestValue) {
          highestValue = value;
          bestTarget = player;
        }
      }

      if (bestTarget != null) {
        return bestTarget.id;
      }
    }

    // 優先目標 2：情報豐富的玩家（情報滲透）
    if (ai.gold >= 15) {
      Player? intelTarget;
      int highestIntel = 0;

      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;

        if (player.intel > highestIntel) {
          highestIntel = player.intel;
          intelTarget = player;
        }
      }

      if (intelTarget != null) {
        return intelTarget.id;
      }
    }

    // 預設：選擇聲望最高的非盟友玩家
    Player? defaultTarget;
    int highestReputation = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      if (player.reputation > highestReputation) {
        highestReputation = player.reputation;
        defaultTarget = player;
      }
    }

    return defaultTarget?.id;
  }
}

// ============================================================
// 貿易商威廉 AI 行為
// ============================================================

/// 貿易商威廉 AI 行為
///
/// 特點：
/// - 資方派，專注資源流通和交易
/// - 「貿易協定」技能：與目標交換資源（金幣/情報/人情）
/// - 「海外消息」技能：消耗金幣觸發國際事件
/// - 「走私網絡」被動：交易時雙方資源 +20%
/// - 投票傾向：B（自由貿易）
/// - 喜歡進行資源交易，會主動提出交易請求
/// - 利用金幣優勢影響局勢
class TraderWilliamBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.traderWilliam;

  @override
  String get characterName => '貿易商威廉';

  @override
  Faction get faction => Faction.factory;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: -0.1, // 不太主動攻擊
        defenseModifier: 0.2, // 適度防禦
        allyModifier: 0.6, // 非常重視結盟（貿易夥伴）
        betrayModifier: -0.2, // 不太會背叛（商譽重要）
        skillModifier: 0.7, // 非常依賴技能（貿易操控）
        riskTolerance: 0.55, // 中等偏高風險承受（商人敢冒險）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '潛在交易夥伴';

      final role = playerRoles[player.id];

      // 資源豐富的玩家是優先交易目標
      final totalResources = player.gold + player.intel * 10 + player.favor * 8;
      if (totalResources > 50) {
        priority += 25;
        reason = '資源豐富 - 理想的交易對象';
      }

      // 情報多的玩家是好目標（可以用金幣換情報）
      if (player.intel >= 3) {
        priority += 20;
        reason = '情報豐富 - 可以用金幣交換';
      }

      // 人情多的玩家也是好目標
      if (player.favor >= 4) {
        priority += 15;
        reason = '人脈廣闊 - 可以建立貿易關係';
      }

      // 資方同伴是潛在盟友
      if (role?.faction == Faction.factory) {
        priority -= 15;
        reason = '資方同伴 - 應該合作而非競爭';
      }

      // 勞工派是潛在的交易對象（他們需要金幣）
      if (role?.faction == Faction.worker) {
        priority += 10;
        reason = '工人派 - 可能需要金幣';
      }

      // 盟友不攻擊（商譽重要）
      if (ai.allies.contains(player.id)) {
        priority -= 50;
        reason = '貿易夥伴 - 信任是商業的基礎';
      }

      // 關係好的玩家優先交易
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore > 20) {
        priority += 15;
        reason += '，關係良好';
      } else if (relationScore < -20) {
        priority += 10;
        reason += '，也許可以用交易修復關係';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用貿易技能
    actions.add(AIActionType.useSkill);

    // 積極尋求結盟（建立貿易網絡）
    if (ai.allies.length < 3) {
      actions.add(AIActionType.ally);
    }

    // 發言推廣自由貿易理念
    actions.add(AIActionType.speak);

    // 適度防禦（保護商業利益）
    actions.add(AIActionType.defend);

    // 有足夠資源時可以攻擊（維護市場秩序）
    if (ai.reputation > 50 && ai.gold > 40) {
      actions.add(AIActionType.attack);
    }

    // 商人不太會背叛（商譽重要）
    // actions.add(AIActionType.betray); // 故意省略

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 貿易商威廉強烈支持自由貿易
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'B', // 保護財產（機器是資產）
          strength: 0.8,
          reason: '機器是促進貿易的工具，必須保護財產權',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.95,
          reason: '自由貿易是商業繁榮的基石！取消所有關稅！',
          canBeSwayed: false,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 1.0,
          reason: '自由貿易萬歲！這是我的核心信念，不可動搖！',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時（折衷）
          strength: 0.6,
          reason: '完全禁止會影響貿易產能，但也要維持社會穩定',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'C', // 有限承認
          strength: 0.7,
          reason: '有限承認工會能維持勞資平衡，不影響貿易運作',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.7,
          reason: '商人需要穩定的政治環境來做生意',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.85,
          reason: '經濟讓步能開拓愛爾蘭市場，對貿易最有利！',
          canBeSwayed: false,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.8,
          reason: '技職教育能培養船員、會計等貿易人才！',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'B',
          strength: 0.85,
          reason: '支持有利於自由貿易的選項',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（貿易核心）
    if (action == AIActionType.useSkill) {
      bonus += 35;

      // 有足夠金幣使用海外消息
      if (ai.gold >= 20) {
        bonus += 15;
      }
    }

    // 結盟大加分（建立貿易網絡）
    if (action == AIActionType.ally) {
      bonus += 30;

      // 與資源豐富的玩家結盟額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null) {
          final targetResources = target.gold + target.intel * 10 + target.favor * 8;
          if (targetResources > 50) {
            bonus += 20; // 資源豐富的貿易夥伴
          }
        }
      }
    }

    // 發言加分（推廣貿易理念）
    if (action == AIActionType.speak) {
      bonus += 15;
    }

    // 防禦適度加分
    if (action == AIActionType.defend) {
      bonus += 10;
    }

    // 攻擊不加分（商人不好戰）
    if (action == AIActionType.attack) {
      bonus -= 5;
    }

    // 背叛大減分（商譽是商人的生命）
    if (action == AIActionType.betray) {
      bonus -= 35;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 貿易協定：只要有潛在交易夥伴就想用
    // 尋找可以交易的對象
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 對方有我們想要的資源
      final weWantIntel = ai.intel < 3 && player.intel >= 2;
      final weWantFavor = ai.favor < 4 && player.favor >= 2;
      final theyWantGold = player.gold < 30 && ai.gold >= 30;

      // 互利交易的條件存在
      if ((weWantIntel || weWantFavor) && theyWantGold) {
        return true;
      }
    }

    // 海外消息：有足夠金幣且想製造局勢變化時
    if (ai.gold >= 20) {
      // 威脅高時觸發國際事件打亂局勢
      if (situation.threatLevel > 60) {
        return true;
      }

      // 局勢膠著時觸發事件
      if (situation.opportunityLevel > 50 && situation.opportunityLevel < 70) {
        return true;
      }

      // 遊戲後期使用
      if (state.currentRound >= state.totalRounds - 1) {
        return true;
      }
    }

    // 主動提出交易（核心特色）
    return ai.gold >= 20 && situation.potentialAllies.isNotEmpty;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 貿易協定目標：尋找最佳交易夥伴

    Player? bestTradePartner;
    double highestTradeValue = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 計算交易價值
      double tradeValue = 0;

      // 對方的情報對我們有價值
      if (player.intel > 0 && ai.intel < 5) {
        tradeValue += player.intel * 15;
      }

      // 對方的人情對我們有價值
      if (player.favor > 0 && ai.favor < 6) {
        tradeValue += player.favor * 12;
      }

      // 對方缺金幣，我們可以提供
      if (player.gold < 30 && ai.gold >= 40) {
        tradeValue += 20; // 交易機會
      }

      // 盟友優先（走私網絡加成更有利）
      if (ai.allies.contains(player.id)) {
        tradeValue += 25;
      }

      // 關係好的優先（更容易達成協議）
      final relation = ai.getRelationshipScore(player.id);
      if (relation > 0) {
        tradeValue += relation / 3;
      }

      if (tradeValue > highestTradeValue) {
        highestTradeValue = tradeValue;
        bestTradePartner = player;
      }
    }

    return bestTradePartner?.id;
  }

  /// 計算走私網絡加成
  ///
  /// 交易時雙方獲得的資源 +20%
  /// 這個方法由遊戲引擎在處理交易時調用
  static int calculateSmugglingBonus(int baseAmount) {
    return (baseAmount * 1.2).round();
  }

  /// 生成交易提案
  ///
  /// 根據雙方資源狀況生成合理的交易提案
  static Map<String, int> generateTradeProposal(
    AIPlayer trader,
    Player target,
  ) {
    final proposal = <String, int>{};

    // 如果對方缺金幣，我們提供金幣
    if (target.gold < 30 && trader.gold >= 40) {
      proposal['offerGold'] = 20;
    }

    // 如果我們缺情報，希望獲得情報
    if (trader.intel < 3 && target.intel >= 2) {
      proposal['wantIntel'] = 1;
    }

    // 如果我們缺人情，希望獲得人情
    if (trader.favor < 4 && target.favor >= 2) {
      proposal['wantFavor'] = 1;
    }

    return proposal;
  }
}

// ============================================================
// 學者伊莉莎白 AI 行為
// ============================================================

/// 學者伊莉莎白 AI 行為
///
/// 特點：
/// - 改革派，專注輿論操控
/// - 「輿論文章」技能：選擇一名玩家，對該玩家的攻擊本回合傷害 +25%
/// - 「引經據典」被動：使用情報攻擊時，傷害 +30%，且有 30% 機率情報不被消耗
/// - 「姐妹情誼」技能：與紡織女工瑪莉互相強化
/// - 投票傾向：改革派選項（C 折衷方案或改革選項）
/// - 重視情報收集和使用
class ScholarElizabethBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.scholarElizabeth;

  @override
  String get characterName => '學者伊莉莎白';

  @override
  Faction get faction => Faction.reform;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.2, // 適度攻擊（輿論戰）
        defenseModifier: 0.2, // 適度防禦
        allyModifier: 0.5, // 重視結盟（姐妹情誼）
        betrayModifier: -0.4, // 不太會背叛
        skillModifier: 0.7, // 經常使用技能（輿論文章、引經據典）
        riskTolerance: 0.45, // 謹慎但不保守
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50; // 基礎優先級
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 優先用輿論攻擊資方（社會不公的代表）
      if (role?.faction == Faction.factory) {
        priority += 35;
        reason = '資方 - 輿論批評的目標';
      }

      // 皇室也是批評對象（權力腐敗）
      if (role?.faction == Faction.royal) {
        priority += 25;
        reason = '皇室 - 權力監督的對象';
      }

      // 避免攻擊改革派同伴
      if (role?.faction == Faction.reform) {
        priority -= 40;
        reason = '改革派同伴 - 應該合作';
      }

      // 對勞工派友好但不完全排除（可能觀點不同）
      if (role?.faction == Faction.worker) {
        priority -= 20;
        reason = '勞工派 - 應該支持但可批評';
      }

      // 紡織女工瑪莉是姐妹，絕不攻擊
      if (role?.id == CharacterIds.textileMary) {
        priority -= 60;
        reason = '瑪莉姐妹 - 姐妹情誼';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 55;
        reason = '盟友 - 不應攻擊';
      }

      // 聲望高的目標更值得批評（輿論價值高）
      if (player.reputation > 60) {
        priority += 15;
        reason += '，聲望高';
      }

      // 有情報支持的攻擊更有效（引經據典）
      if (ai.intel >= 2 && player.reputation > 40) {
        priority += 10;
        reason += '，可用情報';
      }

      // 關係分數影響
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 15;
        reason += '，曾批評過我';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 優先與瑪莉結盟（姐妹情誼）
    final maryExists = state.players.any(
      (p) => p.isAlive && p.id != ai.id && _isTextileMary(p.id, state),
    );
    if (maryExists && !ai.allies.contains(CharacterIds.textileMary)) {
      actions.add(AIActionType.ally);
    }

    // 有情報時優先使用（引經據典被動加成）
    if (ai.intel >= 2) {
      actions.add(AIActionType.useSkill); // 可觸發引經據典
      actions.add(AIActionType.reveal);
    }

    // 使用輿論文章技能
    if (ai.reputation > 40) {
      actions.add(AIActionType.useSkill);
    }

    // 攻擊（利用輿論文章和引經據典）
    if (ai.reputation > 35) {
      actions.add(AIActionType.attack);
    }

    // 發言收集情報和發表觀點
    actions.add(AIActionType.speak);

    // 防禦
    actions.add(AIActionType.defend);

    // 結盟其他改革派
    if (ai.allies.length < 2) {
      actions.add(AIActionType.ally);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 改革派伊莉莎白傾向支持改革和進步的選項
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'C', // 折衷改革
          strength: 0.8,
          reason: '機器本身不是問題，問題是如何保護工人的權益。折衷方案最為明智。',
          canBeSwayed: true,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.75,
          reason: '降低關稅可以讓窮人買到更便宜的麵包，這是社會正義的體現。',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'C', // 選擇性關稅
          strength: 0.8,
          reason: '選擇性關稅能平衡各方利益，這是理性改革的典範。',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'A', // 禁止童工
          strength: 0.95,
          reason: '孩子們應該在學校裡讀書，而不是在工廠裡勞動。這是我用筆名寫過無數文章的議題。',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 0.85,
          reason: '結社自由是公民權利的基礎，我的文章一直在呼籲這一點',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 0.9,
          reason: '擴大選舉權是邁向真正民主的第一步，這是啟蒙思想的核心！',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A', // 愛爾蘭自治
          strength: 0.8,
          reason: '自治是愛爾蘭人民應得的權利，正如我在文章中所寫的',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'A', // 普及教育
          strength: 1.0,
          reason: '普及教育是社會進步的根本！這是我用生命倡導的事業！',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'C',
          strength: 0.75,
          reason: '理性的改革需要平衡各方利益。',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能加分（輿論文章、姐妹情誼）
    if (action == AIActionType.useSkill) {
      bonus += 25;

      // 如果目標是瑪莉，姐妹情誼加分
      if (targetId == CharacterIds.textileMary) {
        bonus += 20;
      }
    }

    // 攻擊加分（輿論戰）
    if (action == AIActionType.attack) {
      bonus += 10;

      // 有情報支持時額外加分（引經據典）
      if (ai.intel >= 1) {
        bonus += 15;
      }

      // 對資方攻擊額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation > 50) {
          bonus += 10; // 高聲望目標更值得批評
        }
      }
    }

    // 揭露情報加分（引經據典被動）
    if (action == AIActionType.reveal && ai.intel >= 1) {
      bonus += 20;
    }

    // 結盟加分（重視合作）
    if (action == AIActionType.ally) {
      bonus += 15;

      // 與瑪莉結盟額外加分
      if (targetId == CharacterIds.textileMary) {
        bonus += 25; // 姐妹情誼
      }
    }

    // 發言加分（知識分子本色）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    // 防禦適度加分
    if (action == AIActionType.defend) {
      bonus += 5;
    }

    // 背叛減分（重視信義）
    if (action == AIActionType.betray) {
      bonus -= 25;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 輿論文章：當有強勢敵人時使用，增加對其的攻擊傷害
    if (situation.strongPlayers.isNotEmpty || situation.mainThreats.isNotEmpty) {
      return true;
    }

    // 姐妹情誼：檢查瑪莉是否存在且需要幫助
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (_isTextileMary(player.id, state)) {
        // 瑪莉聲望低時使用姐妹情誼
        if (player.reputation < 50) {
          return true;
        }
        // 瑪莉是盟友時也使用
        if (ai.allies.contains(player.id)) {
          return true;
        }
      }
    }

    // 有足夠情報時使用（觸發引經據典被動）
    if (ai.intel >= 3 && situation.weakTargets.isNotEmpty) {
      return true;
    }

    // 威脅高時使用輿論文章製造壓力
    if (situation.threatLevel > 50) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 優先目標 1：紡織女工瑪莉（姐妹情誼）
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (_isTextileMary(player.id, state)) {
        return player.id;
      }
    }

    // 優先目標 2：輿論文章目標 - 選擇最需要被批評的玩家
    Player? bestTarget;
    double highestPriority = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      // 計算目標價值（聲望高且是資方的優先）
      double priority = player.reputation.toDouble();

      // 非盟友優先
      if (!ai.allies.contains(player.id)) {
        priority += 20;
      }

      // 關係差的優先
      final relation = ai.getRelationshipScore(player.id);
      if (relation < 0) {
        priority += (-relation / 3);
      }

      if (priority > highestPriority) {
        highestPriority = priority;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }

  /// 判斷玩家是否為紡織女工瑪莉
  bool _isTextileMary(String playerId, GameState state) {
    // 通過玩家 ID 或角色判斷
    // 這裡簡化處理，實際應該查詢角色數據
    return playerId == CharacterIds.textileMary ||
        playerId.contains('textile_mary');
  }

  /// 檢查引經據典是否觸發情報保留
  ///
  /// 使用情報攻擊時，有 30% 機率情報不被消耗
  /// 這個方法由遊戲引擎在處理情報消耗時調用
  static bool checkCiteClassicsTriggered() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < 30; // 30% 機率
  }

  /// 計算引經據典傷害加成
  ///
  /// 使用情報攻擊時，傷害 +30%
  static double getCiteClassicsDamageMultiplier() {
    return 1.3; // 30% 加成
  }

  /// 計算輿論文章傷害加成
  ///
  /// 對被標記玩家的攻擊傷害 +25%
  static double getPublicOpinionDamageMultiplier() {
    return 1.25; // 25% 加成
  }
}

// ============================================================
// 乞丐比爾 AI 行為
// ============================================================

/// 乞丐比爾 AI 行為
///
/// 特點：
/// - 中立派，混亂製造者
/// - 最低聲望但有獨特生存能力
/// - 「一無所有」被動：聲望低於 20 時受傷 -70%
/// - 「混亂播種」技能：消耗人情使目標行動隨機化（每局 1 次）
/// - 「酒館消息」技能：消耗人情獲得情報（50% 假情報）
/// - 投票傾向：不固定，隨機或站在少數派
/// - 會利用人情優勢製造混亂
class BeggarBillBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.beggarBill;

  @override
  String get characterName => '乞丐比爾';

  @override
  Faction get faction => Faction.neutral;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.0, // 不主動攻擊（沒有攻擊力）
        defenseModifier: -0.3, // 不太防禦（反正有被動）
        allyModifier: 0.2, // 適度結盟（利用人情）
        betrayModifier: 0.4, // 較高背叛傾向（混亂本性）
        skillModifier: 0.8, // 非常依賴技能
        riskTolerance: 0.9, // 極高風險承受（沒什麼可失去的）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '潛在混亂目標';

      // 乞丐比爾喜歡對聲望高的人搞破壞
      if (player.reputation > 70) {
        priority += 35;
        reason = '高聲望 - 最適合製造混亂';
      }

      // 領先者是最好的混亂播種目標
      if (player.reputation > 60 && !ai.allies.contains(player.id)) {
        priority += 20;
        reason = '領先者 - 需要被拖下水';
      }

      // 資方通常很有趣
      final role = playerRoles[player.id];
      if (role?.faction == Faction.factory) {
        priority += 15;
        reason = '有錢人 - 看他們出糗很有趣';
      }

      // 對弱者沒什麼興趣（已經夠慘了）
      if (player.reputation < 30) {
        priority -= 25;
        reason = '窮光蛋 - 都是難兄難弟';
      }

      // 盟友...暫時放過
      if (ai.allies.contains(player.id)) {
        priority -= 20;
        reason = '暫時的夥伴 - 等等再說';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用混亂播種（如果還沒用過且有人情）
    if (ai.favor >= 3) {
      actions.add(AIActionType.useSkill);
    }

    // 使用酒館消息收集情報
    if (ai.favor >= 1) {
      actions.add(AIActionType.useSkill);
    }

    // 發言（亂說一通也是一種樂趣）
    actions.add(AIActionType.speak);

    // 偶爾結盟（用人情交朋友）
    if (ai.allies.isEmpty && ai.favor >= 2) {
      actions.add(AIActionType.ally);
    }

    // 背叛很有趣
    if (ai.allies.isNotEmpty && ai.reputation > 20) {
      actions.add(AIActionType.betray);
    }

    // 攻擊不是強項，但偶爾也行
    if (ai.reputation > 25 && ai.intel >= 1) {
      actions.add(AIActionType.attack);
    }

    // 聲望低時等著看戲就好
    if (ai.reputation < 20) {
      actions.add(AIActionType.wait);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 乞丐比爾的投票邏輯：站在少數派那邊製造混亂
    // 或者完全隨機

    // 計算各選項的預期支持者
    int supportA = 0;
    int supportB = 0;

    for (final player in state.players) {
      if (!player.isAlive || player.id == ai.id) continue;

      // 簡單估計：聲望高的可能支持 B（資方），低的支持 A（勞工）
      if (player.reputation > 60) {
        supportB++;
      } else {
        supportA++;
      }
    }

    // 特殊議案的偏好（製造混亂）
    switch (bill.id) {
      case 'trade_union_bill':
        // 工會合法化 - 支持能製造最多混亂的選項
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.4,
          reason: '工會？哈哈，讓他們鬧起來，我好趁亂...嘿嘿',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.5,
          reason: '讓窮人也能投票？有意思！這會讓有錢人很頭痛！',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A',
          strength: 0.6,
          reason: '愛爾蘭獨立？哇，那會很熱鬧！我喜歡熱鬧！',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C',
          strength: 0.3,
          reason: '讀書？我在街頭學到的比任何學校都多...隨便吧',
          canBeSwayed: true,
        );
    }

    // 站在少數派那邊
    String preferredOption;
    String reason;

    if (supportA > supportB + 1) {
      preferredOption = 'B';
      reason = '嘿嘿，大家都選 A？那我偏要選 B！';
    } else if (supportB > supportA + 1) {
      preferredOption = 'A';
      reason = '有錢人都選 B？那我就選 A 添亂！';
    } else {
      // 勢均力敵時隨機
      final random = DateTime.now().millisecondsSinceEpoch % 3;
      switch (random) {
        case 0:
          preferredOption = 'A';
          reason = '今天心情好，站工人這邊！';
          break;
        case 1:
          preferredOption = 'B';
          reason = '誰給我酒喝我就投誰...好吧投 B！';
          break;
        default:
          preferredOption = 'C';
          reason = '折衷？哈！最無聊的選擇，但也最混亂！';
      }
    }

    return VotePreference(
      preferredOption: preferredOption,
      strength: 0.3, // 很容易被說服改變
      reason: reason,
      canBeSwayed: true, // 給點酒就能改變
    );
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（核心能力）
    if (action == AIActionType.useSkill) {
      bonus += 35;

      // 有足夠人情時更傾向用技能
      if (ai.favor >= 3) {
        bonus += 20; // 混亂播種
      }
    }

    // 發言加分（亂講話也是樂趣）
    if (action == AIActionType.speak) {
      bonus += 15;
    }

    // 背叛加分（混亂本性）
    if (action == AIActionType.betray) {
      bonus += 25;
    }

    // 等待在聲望低時加分（一無所有被動生效）
    if (action == AIActionType.wait && ai.reputation < 20) {
      bonus += 20;
    }

    // 攻擊不加分（不是強項）
    if (action == AIActionType.attack) {
      bonus -= 10;
    }

    // 防禦減分（有被動保護，不需要主動防禦）
    if (action == AIActionType.defend) {
      if (ai.reputation < 20) {
        bonus -= 20; // 一無所有生效時不需要防禦
      }
    }

    // 結盟略加分
    if (action == AIActionType.ally) {
      bonus += 5;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 混亂播種：有足夠人情且有高聲望目標
    if (ai.favor >= 3 && situation.strongPlayers.isNotEmpty) {
      return true;
    }

    // 酒館消息：人情充足且情報不足時
    if (ai.favor >= 1 && ai.intel < 3) {
      return true;
    }

    // 局勢混亂時更想搞事
    if (situation.threatLevel > 50 || situation.opportunityLevel > 50) {
      return ai.favor >= 1;
    }

    // 遊戲後期使用混亂播種
    if (state.currentRound >= state.totalRounds - 1 && ai.favor >= 3) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 混亂播種目標：優先選擇領先者
    Player? bestTarget;
    int highestReputation = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      // 不對自己的盟友使用...算了，對盟友也行！
      if (player.reputation > highestReputation) {
        highestReputation = player.reputation;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }

  /// 檢查一無所有被動是否生效
  ///
  /// 聲望低於 20 時，受到的傷害 -70%
  static bool isNothingToLoseActive(int reputation) {
    return reputation < 20;
  }

  /// 計算一無所有的傷害減免
  static double getNothingToLoseDamageReduction(int reputation) {
    if (reputation < 20) {
      return 0.7; // 70% 減免
    }
    return 0.0;
  }

  /// 檢查酒館消息是否產生假情報
  ///
  /// 50% 機率是假情報
  static bool isTavernGossipFake() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < 50;
  }
}


// ============================================================
// 發明家詹姆斯 AI 行為
// ============================================================

/// 發明家詹姆斯 AI 行為
///
/// 特點：
/// - 資方派，但專注技術而非金錢
/// - 「技術論證」技能：本回合攻擊傷害 +50%，忽略對方 30% 防禦
/// - 「發明展示」技能：消耗 30 金幣獲得隨機增益
/// - 「實驗精神」被動：每局可以取消上一個行動並重新選擇
/// - 偏好使用數據和邏輯論證
/// - 不善社交，較少結盟
/// - 投票傾向：保護財產(B) 以保護發明專利
class InventorJamesBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.inventorJames;

  @override
  String get characterName => '發明家詹姆斯';

  @override
  Faction get faction => Faction.factory;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.3, // 使用技術論證攻擊較多
        defenseModifier: 0.1, // 略微注重防禦
        allyModifier: -0.3, // 不善社交，很少結盟
        skillModifier: 0.7, // 非常依賴技能
        riskTolerance: 0.55, // 中等偏高風險承受（實驗精神）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 盧德派是首要敵人（他們要破壞機器！）
      if (role?.id == CharacterIds.ludditeGeorge) {
        priority += 45;
        reason = '盧德派 - 科技的敵人！';
      }

      // 工人派是潛在威脅（他們反對機器）
      if (role?.faction == Faction.worker) {
        priority += 25;
        reason = '工人派 - 可能阻礙進步';
      }

      // 對資方同伴友好
      if (role?.faction == Faction.factory) {
        priority -= 30;
        reason = '資方同伴 - 理解進步的重要性';
      }

      // 記者可能報導發明
      if (role?.faction == Faction.press) {
        priority -= 10;
        reason = '記者 - 可能幫助宣傳發明';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 60;
        reason = '盟友 - 不應攻擊';
      }

      // 聲望高的反科技派是優先目標
      if (player.reputation > 60 && role?.faction == Faction.worker) {
        priority += 20;
        reason += '，高聲望威脅';
      }

      // 關係惡劣的優先處理
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 15;
        reason += '，對我有敵意';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用技術論證技能攻擊
    actions.add(AIActionType.useSkill);

    // 有足夠金幣時使用發明展示
    if (ai.gold >= 30) {
      actions.add(AIActionType.useSkill);
    }

    // 攻擊是主要手段（使用技術論證）
    if (ai.reputation > 35) {
      actions.add(AIActionType.attack);
    }

    // 防禦
    actions.add(AIActionType.defend);

    // 發言（用數據和邏輯）
    actions.add(AIActionType.speak);

    // 很少主動結盟（不善社交）
    if (ai.allies.isEmpty && ai.reputation < 40) {
      actions.add(AIActionType.ally);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 詹姆斯傾向保護財產權以保護發明專利
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'B', // 保護財產（保護機器和專利）
          strength: 0.95,
          reason: '機器是進步的象徵，必須受到保護。數據顯示，機器提高了生產效率 300%。',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.7,
          reason: '自由貿易促進技術交流和原料進口，有利於工業發展。',
          canBeSwayed: true,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'B', // 自由貿易
          strength: 0.8,
          reason: '降低關稅有利於進口機械零件和新技術，促進創新。',
          canBeSwayed: true,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時
          strength: 0.75,
          reason: '技術進步最終會減少對童工的需求，但目前需要漸進式改革。',
          canBeSwayed: true,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'C', // 有限承認
          strength: 0.7,
          reason: '有限承認工會不會阻礙技術進步，還能提高工人效率',
          canBeSwayed: true,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'C', // 秘密投票
          strength: 0.65,
          reason: '秘密投票是一種技術改進，能提高選舉的效率和公正性',
          canBeSwayed: true,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'C', // 經濟讓步
          strength: 0.6,
          reason: '經濟發展能促進技術傳播，對愛爾蘭的投資也能受益',
          canBeSwayed: true,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'C', // 技職教育
          strength: 0.95,
          reason: '技職教育能培養工程師和技術工人！這是工業進步的基礎！',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'B',
          strength: 0.8,
          reason: '支持有利於技術進步和專利保護的選項。',
          canBeSwayed: true,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（技術優勢）
    if (action == AIActionType.useSkill) {
      bonus += 35;

      // 有足夠金幣時發明展示更有價值
      if (ai.gold >= 30) {
        bonus += 15;
      }
    }

    // 攻擊加分（使用技術論證）
    if (action == AIActionType.attack) {
      bonus += 20;

      // 攻擊反科技派額外加分
      if (targetId != null) {
        // 這裡簡化處理
        bonus += 5;
      }
    }

    // 發言適度加分（數據和邏輯論證）
    if (action == AIActionType.speak) {
      bonus += 10;
    }

    // 防禦略加分
    if (action == AIActionType.defend) {
      bonus += 5;
    }

    // 結盟減分（不善社交）
    if (action == AIActionType.ally) {
      bonus -= 20;
    }

    // 背叛不太減分（對社交關係不敏感）
    if (action == AIActionType.betray) {
      bonus -= 5;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 技術論證：有攻擊目標時使用
    if (situation.weakTargets.isNotEmpty || situation.mainThreats.isNotEmpty) {
      return true;
    }

    // 發明展示：有足夠金幣且需要增益時使用
    if (ai.gold >= 30) {
      // 聲望低時需要增益
      if (ai.reputation < 50) {
        return true;
      }

      // 威脅高時需要增益
      if (situation.threatLevel > 50) {
        return true;
      }

      // 有機會時使用
      if (situation.opportunityLevel > 60) {
        return true;
      }
    }

    // 實驗精神：這是被動技能，由遊戲引擎處理

    return ai.reputation > 40; // 有一定聲望時主動使用技術論證
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 技術論證目標：優先攻擊反科技派
    Player? bestTarget;
    double highestPriority = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      double priority = 50.0;

      // 非盟友優先
      priority += 20;

      // 聲望高的目標優先（影響力大）
      priority += player.reputation * 0.3;

      // 關係差的優先
      final relation = ai.getRelationshipScore(player.id);
      if (relation < 0) {
        priority += (-relation / 3);
      }

      if (priority > highestPriority) {
        highestPriority = priority;
        bestTarget = player;
      }
    }

    return bestTarget?.id;
  }
}

// ============================================================
// 演說家派乃爾 AI 行為
// ============================================================

/// 演說家派乃爾 AI 行為
///
/// 特點：
/// - 改革派，愛爾蘭自治運動領袖
/// - 「激情演說」技能：發言後攻擊傷害 +30%，自己聲望 +5
/// - 「愛爾蘭議程」被動：改革派選項勝出時額外獲得 20 分
/// - 「群眾動員」技能：消耗 3 人情，使聲望低於 25 的玩家聲望 +15
/// - 投票傾向：強烈支持改革派選項（C）
/// - 會幫助弱勢玩家，製造混亂以獲利
class OratorParnellBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.oratorParnell;

  @override
  String get characterName => '演說家派乃爾';

  @override
  Faction get faction => Faction.reform;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.4, // 善於演說攻擊
        defenseModifier: 0.1, // 適度防禦
        allyModifier: 0.5, // 重視拉攏弱勢玩家
        skillModifier: 0.7, // 經常使用技能
        riskTolerance: 0.6, // 中高風險承受（煽動家敢於冒險）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50; // 基礎優先級
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 優先攻擊反對改革的勢力（資方和保守派）
      if (role?.faction == Faction.factory) {
        priority += 30;
        reason = '資方 - 改革的阻礙';
      }

      // 對皇室也有敵意（愛爾蘭自治運動）
      if (role?.faction == Faction.royal) {
        priority += 25;
        reason = '皇室 - 壓迫愛爾蘭的象徵';
      }

      // 改革派同伴是盟友
      if (role?.faction == Faction.reform) {
        priority -= 40;
        reason = '改革派同伴 - 應該合作';
      }

      // 對勞工派友好（同屬改革陣營）
      if (role?.faction == Faction.worker) {
        priority -= 20;
        reason = '勞工派 - 潛在盟友';
      }

      // 弱勢玩家是幫助對象，不是攻擊目標
      if (player.reputation < 25) {
        priority -= 30;
        reason = '弱勢玩家 - 應該幫助';
      }

      // 高聲望的對手是演說攻擊的好目標
      if (player.reputation > 70 && !ai.allies.contains(player.id)) {
        priority += 20;
        reason += '，聲望高可以打擊';
      }

      // 避免攻擊盟友
      if (ai.allies.contains(player.id)) {
        priority -= 60;
        reason = '盟友 - 不應攻擊';
      }

      // 關係惡劣的優先處理
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -30) {
        priority += 15;
        reason += '，關係惡劣';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 最優先：使用激情演說技能增強攻擊
    if (ai.reputation > 40) {
      actions.add(AIActionType.useSkill);
    }

    // 檢查是否有弱勢玩家需要幫助（群眾動員）
    final hasWeakPlayer = state.players.any((p) =>
        p.id != ai.id && p.isAlive && p.reputation < 25);
    if (hasWeakPlayer && ai.favor >= 3) {
      actions.add(AIActionType.useSkill); // 群眾動員
    }

    // 善於演說攻擊
    if (ai.reputation > 50) {
      actions.add(AIActionType.attack);
    }

    // 積極結盟（拉攏弱勢玩家和改革派）
    if (ai.allies.length < 2) {
      actions.add(AIActionType.ally);
    }

    // 發言是核心能力
    actions.add(AIActionType.speak);

    // 適度防禦
    if (ai.reputation < 50) {
      actions.add(AIActionType.defend);
    }

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 派乃爾強烈支持改革派選項（愛爾蘭議程被動）
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'C', // 折衷改革
          strength: 0.95,
          reason: '改革是愛爾蘭的希望！漸進改革能為愛爾蘭爭取更多權利！',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'C', // 滑動關稅
          strength: 0.9,
          reason: '愛爾蘭人民需要公平的政策，折衷方案最能保護我們！',
          canBeSwayed: false,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'C', // 選擇性關稅
          strength: 0.9,
          reason: '選擇性關稅能讓愛爾蘭的農產品有出路！',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'C', // 限制工時
          strength: 0.9,
          reason: '愛爾蘭的孩子們需要保護，但我們也需要工作機會！',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'A', // 合法化工會
          strength: 0.95,
          reason: '工會是愛爾蘭工人爭取權利的武器！團結才能贏得自由！',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'A', // 擴大選舉權
          strength: 0.95,
          reason: '擴大選舉權讓愛爾蘭人民有更多發言權！這是我們的戰場！',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'A', // 愛爾蘭自治
          strength: 1.0,
          reason: '愛爾蘭自治是我畢生的事業！這是愛爾蘭人民應得的權利！',
          canBeSwayed: false,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'A', // 普及教育
          strength: 0.85,
          reason: '愛爾蘭的孩子需要用英語和愛爾蘭語學習，了解自己的歷史！',
          canBeSwayed: true,
        );
      default:
        return const VotePreference(
          preferredOption: 'C', // 改革派選項
          strength: 0.9,
          reason: '支持改革就是支持愛爾蘭的未來！',
          canBeSwayed: false,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 使用技能大加分（激情演說、群眾動員）
    if (action == AIActionType.useSkill) {
      bonus += 30;

      // 如果有弱勢玩家需要幫助，群眾動員更有價值
      final hasWeakPlayer = state.players.any((p) =>
          p.id != ai.id && p.isAlive && p.reputation < 25);
      if (hasWeakPlayer && ai.favor >= 3) {
        bonus += 20; // 群眾動員加分
      }
    }

    // 攻擊加分（善於演說攻擊）
    if (action == AIActionType.attack) {
      bonus += 20;

      // 攻擊高聲望目標額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation > 60) {
          bonus += 15; // 打擊強勢對手
        }
      }
    }

    // 結盟加分（善於拉攏弱勢玩家）
    if (action == AIActionType.ally) {
      bonus += 15;

      // 與弱勢玩家結盟額外加分
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation < 40) {
          bonus += 20; // 拉攏弱勢玩家
        }
      }
    }

    // 發言加分（核心能力）
    if (action == AIActionType.speak) {
      bonus += 15;
    }

    // 防禦適度加分
    if (action == AIActionType.defend) {
      bonus += 5;
    }

    // 背叛減分（演說家重視聲譽）
    if (action == AIActionType.betray) {
      bonus -= 15;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 激情演說：準備攻擊時使用
    if (situation.opportunityLevel > 60 && ai.reputation > 50) {
      return true;
    }

    // 群眾動員：有弱勢玩家需要幫助時使用
    if (ai.favor >= 3) {
      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;
        if (player.reputation < 25) {
          // 優先幫助盟友或關係好的玩家
          if (ai.allies.contains(player.id) ||
              ai.getRelationshipScore(player.id) > 0) {
            return true;
          }
        }
      }
    }

    // 威脅高時使用激情演說反擊
    if (situation.threatLevel > 60 && situation.mainThreats.isNotEmpty) {
      return true;
    }

    // 自身聲望高時展示演說能力
    if (ai.reputation > 70) {
      return true;
    }

    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 群眾動員目標：優先選擇聲望低於 25 的盟友或友好玩家
    if (ai.favor >= 3) {
      // 優先幫助盟友
      for (final allyId in ai.allies) {
        final ally = state.players.where((p) => p.id == allyId).firstOrNull;
        if (ally != null && ally.isAlive && ally.reputation < 25) {
          return allyId;
        }
      }

      // 其次幫助關係好的玩家
      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;
        if (player.reputation < 25 && ai.getRelationshipScore(player.id) > 0) {
          return player.id;
        }
      }

      // 最後幫助任何弱勢玩家
      for (final player in state.players) {
        if (player.id == ai.id || !player.isAlive) continue;
        if (player.reputation < 25) {
          return player.id;
        }
      }
    }

    // 激情演說目標：威脅最大的敵人
    Player? attackTarget;
    double highestThreat = 0;

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      // 計算威脅度
      double threat = player.reputation.toDouble();
      
      // 非改革派優先
      final relation = ai.getRelationshipScore(player.id);
      if (relation < 0) {
        threat += (-relation / 2);
      }

      if (threat > highestThreat) {
        highestThreat = threat;
        attackTarget = player;
      }
    }

    return attackTarget?.id;
  }
}

// ============================================================
// 公爵阿瑟 AI 行為
// ============================================================

/// 公爵阿瑟 AI 行為
///
/// 特點：
/// - 皇室派，保守派領袖（威靈頓公爵）
/// - 高聲望高防禦的坦克型角色
/// - 「鐵腕鎮壓」技能：對聲望低於 25 的玩家造成雙倍傷害
/// - 「貴族特權」被動：免疫第一次大幅攻擊（傷害減半）
/// - 「軍令如山」技能：指定盟友，該盟友下回合攻擊傷害 +40%
/// - 投票傾向：B（維持現狀）
/// - 會保護皇室派盟友，對勞工派和改革派有敵意
class DukeArthurBehavior extends CharacterBehavior {
  @override
  String get characterId => CharacterIds.dukeArthur;

  @override
  String get characterName => '公爵阿瑟';

  @override
  Faction get faction => Faction.royal;

  @override
  BehaviorModifier get baseModifier => const BehaviorModifier(
        attackModifier: 0.3, // 適度攻擊（軍人作風）
        defenseModifier: 0.6, // 非常重視防禦（坦克定位）
        allyModifier: 0.5, // 重視保護盟友
        betrayModifier: -0.7, // 極低背叛傾向（軍人榮譽）
        skillModifier: 0.5, // 適度使用技能
        riskTolerance: 0.35, // 保守風險承受（維護秩序）
      );

  @override
  List<TargetPriority> getPreferredTargets(
    AIPlayer ai,
    GameState state,
    Map<String, Role?> playerRoles,
  ) {
    final targets = <TargetPriority>[];

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;

      double priority = 50;
      String reason = '一般目標';

      final role = playerRoles[player.id];

      // 盧德派是首要敵人（暴徒！）
      if (role?.id == CharacterIds.ludditeGeorge) {
        priority += 50;
        reason = '盧德派暴徒 - 必須鎮壓！';
      }

      // 勞工派是威脅（不守規矩的刁民）
      if (role?.faction == Faction.worker) {
        priority += 35;
        reason = '勞工派 - 破壞秩序的刁民';
      }

      // 改革派是瘋子（試圖動搖傳統）
      if (role?.faction == Faction.reform) {
        priority += 25;
        reason = '改革派 - 危險的空想家';
      }

      // 資方是暴發戶（但至少不是威脅）
      if (role?.faction == Faction.factory) {
        priority -= 10;
        reason = '資方 - 暴發戶，但無害';
      }

      // 皇室派是盟友（絕不攻擊）
      if (role?.faction == Faction.royal) {
        priority -= 60;
        reason = '皇室派 - 效忠對象';
      }

      // 聲望低於 25 的玩家是鐵腕鎮壓的好目標
      if (player.reputation < 25) {
        priority += 30;
        reason += '，聲望極低 - 鐵腕鎮壓目標！';
      }

      // 盟友絕不攻擊（軍人榮譽）
      if (ai.allies.contains(player.id)) {
        priority -= 80;
        reason = '盟友 - 以命相護';
      }

      // 對自己有敵意的玩家優先反擊
      final relationScore = ai.getRelationshipScore(player.id);
      if (relationScore < -40) {
        priority += 20;
        reason += '，曾攻擊過我';
      }

      targets.add(TargetPriority(
        playerId: player.id,
        priority: priority.clamp(0, 100),
        reason: reason,
      ));
    }

    // 按優先級排序
    targets.sort((a, b) => b.priority.compareTo(a.priority));
    return targets;
  }

  @override
  List<AIActionType> getPreferredActions(AIPlayer ai, GameState state) {
    final actions = <AIActionType>[];

    // 檢查是否有盟友需要加強（軍令如山）
    if (ai.allies.isNotEmpty) {
      actions.add(AIActionType.useSkill);
    }

    // 防禦優先（坦克定位）
    actions.add(AIActionType.defend);

    // 檢查是否有低聲望目標可以鎮壓
    final hasLowReputationTarget = state.players.any((p) =>
        p.id != ai.id &&
        p.isAlive &&
        p.reputation < 25 &&
        !ai.allies.contains(p.id));
    if (hasLowReputationTarget) {
      actions.add(AIActionType.useSkill); // 鐵腕鎮壓
      actions.add(AIActionType.attack);
    }

    // 積極結盟（保護皇室派）
    if (ai.allies.length < 2) {
      actions.add(AIActionType.ally);
    }

    // 有足夠聲望時可以攻擊
    if (ai.reputation > 60) {
      actions.add(AIActionType.attack);
    }

    // 發言維護秩序
    actions.add(AIActionType.speak);

    return actions;
  }

  @override
  VotePreference getVotePreference(AIPlayer ai, GameState state, Bill bill) {
    // 公爵阿瑟堅決維護現狀，反對任何改革
    switch (bill.id) {
      case 'machinery_bill':
        return const VotePreference(
          preferredOption: 'B', // 保護財產（維持秩序）
          strength: 0.95,
          reason: '破壞機器就是破壞私有財產，必須嚴懲暴徒！滑鐵盧的紀律在這裡同樣適用。',
          canBeSwayed: false,
        );
      case 'corn_law_bill':
        return const VotePreference(
          preferredOption: 'A', // 高關稅保護（保守派立場）
          strength: 0.9,
          reason: '我們必須保護英國的土地和傳統，高關稅是維護地主利益的堡壘。',
          canBeSwayed: false,
        );
      case 'tariff_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.85,
          reason: '任何改變都可能動搖帝國的根基，維持現狀是最安全的選擇。',
          canBeSwayed: false,
        );
      case 'child_labor_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 0.9,
          reason: '工廠的事務不需要議會干預，市場自有其秩序。改革只會帶來混亂。',
          canBeSwayed: false,
        );
      case 'trade_union_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持禁令
          strength: 1.0,
          reason: '工會就是叛亂的溫床！在滑鐵盧，我們不會容忍任何形式的集結！',
          canBeSwayed: false,
        );
      case 'electoral_reform_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持現狀
          strength: 1.0,
          reason: '選舉制度是祖先的智慧，暴民不配有投票權！維持現狀是唯一選擇！',
          canBeSwayed: false,
        );
      case 'irish_question_bill':
        return const VotePreference(
          preferredOption: 'B', // 維持聯合
          strength: 1.0,
          reason: '愛爾蘭是大不列顛的一部分！任何分裂都是叛國！我會像在滑鐵盧一樣鎮壓叛亂！',
          canBeSwayed: false,
        );
      case 'education_bill':
        return const VotePreference(
          preferredOption: 'B', // 教會教育
          strength: 0.9,
          reason: '教會教育能培養敬畏上帝、忠於國王的臣民。這是維持秩序的基礎。',
          canBeSwayed: false,
        );
      default:
        return const VotePreference(
          preferredOption: 'B',
          strength: 0.9,
          reason: '維持現狀是最明智的選擇。改革？在滑鐵盧，我們用鐵與血維護秩序。',
          canBeSwayed: false,
        );
    }
  }

  @override
  double getActionBonus(
    AIActionType action,
    AIPlayer ai,
    GameState state,
    String? targetId,
  ) {
    double bonus = 0;

    // 防禦大加分（坦克核心）
    if (action == AIActionType.defend) {
      bonus += 35;
    }

    // 使用技能加分（鐵腕鎮壓、軍令如山）
    if (action == AIActionType.useSkill) {
      bonus += 25;

      // 有低聲望目標時鐵腕鎮壓更有價值
      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation < 25) {
          bonus += 30; // 鐵腕鎮壓雙倍傷害
        }
      }

      // 有盟友需要強化時軍令如山更有價值
      if (ai.allies.isNotEmpty) {
        bonus += 15;
      }
    }

    // 攻擊加分（對低聲望目標特別有效）
    if (action == AIActionType.attack) {
      bonus += 10;

      if (targetId != null) {
        final target = state.players.where((p) => p.id == targetId).firstOrNull;
        if (target != null && target.reputation < 25) {
          bonus += 25; // 對弱者特別有效
        }
      }
    }

    // 結盟加分（重視盟友）
    if (action == AIActionType.ally) {
      bonus += 20;

      // 與皇室派結盟額外加分
      if (targetId != null) {
        // 這裡簡化處理
        bonus += 10;
      }
    }

    // 發言適度加分
    if (action == AIActionType.speak) {
      bonus += 5;
    }

    // 背叛大減分（軍人榮譽）
    if (action == AIActionType.betray) {
      bonus -= 50;
    }

    // 等待減分（軍人不會被動等待）
    if (action == AIActionType.wait) {
      bonus -= 15;
    }

    return bonus;
  }

  @override
  bool shouldUseSkill(AIPlayer ai, GameState state, SituationAnalysis situation) {
    // 鐵腕鎮壓：有低聲望目標時使用
    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      // 聲望低於 25 是鎮壓目標
      if (player.reputation < 25) {
        return true;
      }
    }

    // 軍令如山：當有盟友且局勢需要進攻時
    if (ai.allies.isNotEmpty) {
      // 威脅高時強化盟友反擊
      if (situation.threatLevel > 50) {
        return true;
      }

      // 有機會時強化盟友進攻
      if (situation.opportunityLevel > 60) {
        return true;
      }

      // 遊戲後期使用
      if (state.currentRound >= state.totalRounds - 1) {
        return true;
      }
    }

    // 貴族特權是被動，不需要主動觸發
    return false;
  }

  @override
  String? getSkillTarget(AIPlayer ai, GameState state) {
    // 鐵腕鎮壓目標：優先選擇聲望最低的非盟友
    Player? suppressTarget;
    int lowestReputation = 25; // 只攻擊 25 以下的

    for (final player in state.players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue;

      if (player.reputation < lowestReputation) {
        lowestReputation = player.reputation;
        suppressTarget = player;
      }
    }

    if (suppressTarget != null) {
      return suppressTarget.id;
    }

    // 軍令如山目標：選擇最需要強化的盟友
    if (ai.allies.isNotEmpty) {
      // 優先選擇聲望最高的盟友（讓強者更強）
      String? bestAlly;
      int highestReputation = 0;

      for (final allyId in ai.allies) {
        final ally = state.players.where((p) => p.id == allyId).firstOrNull;
        if (ally != null && ally.isAlive && ally.reputation > highestReputation) {
          highestReputation = ally.reputation;
          bestAlly = allyId;
        }
      }

      if (bestAlly != null) {
        return bestAlly;
      }
    }

    // 沒有特定目標
    return null;
  }

  /// 檢查貴族特權是否可用
  ///
  /// 每局限用 1 次，免疫第一次大幅攻擊（傷害減半）
  static bool isNoblePrivilegeAvailable = true;

  /// 觸發貴族特權
  static void triggerNoblePrivilege() {
    isNoblePrivilegeAvailable = false;
  }

  /// 重置貴族特權（新局開始時）
  static void resetNoblePrivilege() {
    isNoblePrivilegeAvailable = true;
  }

  /// 計算鐵腕鎮壓傷害
  ///
  /// 對聲望低於 25 的玩家造成雙倍傷害
  static int calculateIronFistDamage(int baseDamage, int targetReputation) {
    if (targetReputation < 25) {
      return baseDamage * 2; // 雙倍傷害
    }
    return baseDamage;
  }

  /// 計算軍令如山加成
  ///
  /// 盟友下回合攻擊傷害 +40%
  static double getMilitaryOrderDamageMultiplier() {
    return 1.4; // 40% 加成
  }
}

// ============================================================
// 角色行為管理器
// ============================================================

/// 角色行為管理器
///
/// 統一管理所有角色的專屬行為
class CharacterBehaviorManager {
  /// 角色行為映射表
  static final Map<String, CharacterBehavior> _behaviors = {
    CharacterIds.workerThomas: WorkerThomasBehavior(),
    CharacterIds.factoryRichard: FactoryRichardBehavior(),
    CharacterIds.reporterEdward: ReporterEdwardBehavior(),
    CharacterIds.ludditeGeorge: LudditeGeorgeBehavior(),
    CharacterIds.lawyerCharles: LawyerCharlesBehavior(),
    CharacterIds.minerJohn: MinerJohnBehavior(),
    CharacterIds.bankerHenry: BankerHenryBehavior(),
    CharacterIds.kingGeorgeIII: KingGeorgeIIIBehavior(),
    CharacterIds.textileMary: TextileMaryBehavior(),
    CharacterIds.spyFrancis: SpyFrancisBehavior(),
    CharacterIds.traderWilliam: TraderWilliamBehavior(),
    CharacterIds.scholarElizabeth: ScholarElizabethBehavior(),
    CharacterIds.beggarBill: BeggarBillBehavior(),
    CharacterIds.inventorJames: InventorJamesBehavior(),
    CharacterIds.oratorParnell: OratorParnellBehavior(),
    CharacterIds.dukeArthur: DukeArthurBehavior(),
  };

  /// 獲取角色行為
  ///
  /// [roleId] - 角色 ID
  /// 如果找不到對應行為，返回 null
  static CharacterBehavior? getBehavior(String? roleId) {
    if (roleId == null) return null;
    return _behaviors[roleId];
  }

  /// 檢查是否有對應的角色行為
  static bool hasBehavior(String? roleId) {
    return roleId != null && _behaviors.containsKey(roleId);
  }

  /// 獲取所有已註冊的角色 ID
  static List<String> get registeredCharacters => _behaviors.keys.toList();

  /// 獲取預設行為修正
  ///
  /// 當角色沒有專屬行為時使用
  static BehaviorModifier getDefaultModifier(AIPersonality personality) {
    switch (personality) {
      case AIPersonality.aggressive:
        return BehaviorModifier.aggressive;
      case AIPersonality.defensive:
        return BehaviorModifier.defensive;
      case AIPersonality.diplomatic:
        return BehaviorModifier.diplomatic;
      case AIPersonality.cunning:
        return const BehaviorModifier(
          betrayModifier: 0.4,
          riskTolerance: 0.6,
        );
    }
  }
}
