// 1812 國會風雲 - 突發事件模型
//
// 定義遊戲中的各種隨機突發事件
// 包括觸發條件、效果、玩家選擇等

import 'dart:math';

import 'player.dart';
import 'role.dart';
import 'ai_player.dart';
import '../../core/constants/game_constants.dart';

/// 突發事件類型
enum RandomEventType {
  newspaperExtra,    // 📰 報紙號外
  stockMarketCrash,  // 💰 股市崩盤
  factoryFire,       // 🔥 工廠大火
  royalAttention,    // 👑 皇室關注
  frenchThreat,      // ⚔️ 法國威脅
  economicBoom,      // 📈 經濟繁榮
  workersUprising,   // 🔥 工人起義
  royalWedding,      // 💒 皇家婚禮
  spyScandal,        // 🕵️ 間諜醜聞
  enlightenmentWave, // 📚 啟蒙思潮
}

/// 事件選擇選項
class EventChoice {
  /// 選項 ID
  final String id;
  
  /// 選項標題
  final String title;
  
  /// 選項描述
  final String description;
  
  /// 選項圖標
  final String emoji;

  const EventChoice({
    required this.id,
    required this.title,
    required this.description,
    this.emoji = '➡️',
  });
}

/// 事件效果結果
class EventEffectResult {
  /// 受影響的玩家 ID
  final String? playerId;
  
  /// 聲望變化
  final int reputationChange;
  
  /// 金幣變化
  final int goldChange;
  
  /// 效果描述
  final String description;
  
  /// 特殊效果標記
  final Map<String, dynamic> specialEffects;

  const EventEffectResult({
    this.playerId,
    this.reputationChange = 0,
    this.goldChange = 0,
    required this.description,
    this.specialEffects = const {},
  });
}

/// 突發事件模型
class RandomEvent {
  /// 事件 ID
  final String id;
  
  /// 事件類型
  final RandomEventType type;
  
  /// 事件名稱
  final String name;
  
  /// 事件圖標
  final String emoji;
  
  /// 事件描述
  final String description;
  
  /// 詳細敘事
  final String narrative;
  
  /// 是否需要玩家選擇
  final bool requiresChoice;
  
  /// 可選項（如果需要選擇）
  final List<EventChoice> choices;
  
  /// 受影響的玩家 ID（事件觸發後設置）
  final String? affectedPlayerId;

  const RandomEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.narrative,
    this.requiresChoice = false,
    this.choices = const [],
    this.affectedPlayerId,
  });

  RandomEvent copyWith({
    String? id,
    RandomEventType? type,
    String? name,
    String? emoji,
    String? description,
    String? narrative,
    bool? requiresChoice,
    List<EventChoice>? choices,
    String? affectedPlayerId,
  }) {
    return RandomEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      narrative: narrative ?? this.narrative,
      requiresChoice: requiresChoice ?? this.requiresChoice,
      choices: choices ?? this.choices,
      affectedPlayerId: affectedPlayerId ?? this.affectedPlayerId,
    );
  }
}

/// 突發事件資料庫
class RandomEventDatabase {
  RandomEventDatabase._();

  // ============================================================
  // 事件 1：📰 報紙號外 (Newspaper Extra)
  // ============================================================
  static const newspaperExtra = RandomEvent(
    id: 'newspaper_extra',
    type: RandomEventType.newspaperExtra,
    name: '報紙號外',
    emoji: '📰',
    description: '《泰晤士報》頭版揭露醜聞！',
    narrative: '''
「號外！號外！」報童在街頭高聲叫賣。

《泰晤士報》今日頭版刊登了一則爆炸性新聞——
議會中聲望最高的人物被揭露了一條不為人知的秘密！

輿論嘩然，當事人必須做出回應...
''',
    requiresChoice: true,
    choices: [
      EventChoice(
        id: 'silence',
        title: '保持沉默',
        description: '接受報導，承受全部傷害（聲望 -15）',
        emoji: '🤐',
      ),
      EventChoice(
        id: 'defend',
        title: '公開辯解',
        description: '消耗 10 聲望嘗試減半懲罰（聲望 -10，傷害減半）',
        emoji: '🗣️',
      ),
    ],
  );

  // ============================================================
  // 事件 2：💰 股市崩盤 (Stock Market Crash)
  // ============================================================
  static const stockMarketCrash = RandomEvent(
    id: 'stock_market_crash',
    type: RandomEventType.stockMarketCrash,
    name: '股市崩盤',
    emoji: '💰',
    description: '倫敦證券交易所發生恐慌性拋售！',
    narrative: '''
「賣！全部賣掉！」交易所內一片混亂。

南海公司的股價一夜之間暴跌，連帶影響整個金融市場。
恐慌情緒蔓延，投資者紛紛拋售手中的股票。

所有人的財富都受到了衝擊...

（銀行家亨利若在場，將趁機低價收購，額外獲利）
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 3：🔥 工廠大火 (Factory Fire)
  // ============================================================
  static const factoryFire = RandomEvent(
    id: 'factory_fire',
    type: RandomEventType.factoryFire,
    name: '工廠大火',
    emoji: '🔥',
    description: '曼徹斯特紡織廠發生嚴重火災！',
    narrative: '''
火光沖天！曼徹斯特最大的紡織工廠陷入火海。

工人們驚慌失措地逃離現場，許多人受傷。
調查顯示，工廠缺乏基本的安全措施是主要原因。

輿論譴責資方罔顧工人生命安全，
同時勞工派的呼聲得到了更多支持...
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 4：👑 皇室關注 (Royal Attention)
  // ============================================================
  static const royalAttention = RandomEvent(
    id: 'royal_attention',
    type: RandomEventType.royalAttention,
    name: '皇室關注',
    emoji: '👑',
    description: '國王陛下對議會事務表示關注！',
    narrative: '''
「國王陛下降臨議會！」傳令官高聲宣布。

喬治三世國王親自出席今日的議會辯論。
他的目光掃視全場，所有人都屏息以待。

國王的意見將在下一回合獲得雙倍的影響力...

（若國王精神狀態不穩，可能發生意想不到的事情）
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 5：⚔️ 法國威脅 (French Threat)
  // ============================================================
  static const frenchThreat = RandomEvent(
    id: 'french_threat',
    type: RandomEventType.frenchThreat,
    name: '法國威脅',
    emoji: '⚔️',
    description: '拿破崙的軍隊在海峽對岸集結！',
    narrative: '''
「緊急軍情！」傳令兵衝入議會大廳。

情報顯示，拿破崙正在加萊港集結大軍，
英吉利海峽對岸的法軍隨時可能發動入侵。

議會必須立即表態：是否支持增加軍費？

支持者將獲得皇室派的好感，
反對者則會得到改革派的支持...
''',
    requiresChoice: true,
    choices: [
      EventChoice(
        id: 'support_military',
        title: '支持增加軍費',
        description: '保衛國家！（皇室派好感 +10）',
        emoji: '⚔️',
      ),
      EventChoice(
        id: 'oppose_military',
        title: '反對增加軍費',
        description: '優先民生！（改革派好感 +10）',
        emoji: '🕊️',
      ),
    ],
  );

  // ============================================================
  // 事件 6：📈 經濟繁榮 (Economic Boom)
  // ============================================================
  static const economicBoom = RandomEvent(
    id: 'economic_boom',
    type: RandomEventType.economicBoom,
    name: '經濟繁榮',
    emoji: '📈',
    description: '工業革命帶來空前繁榮！',
    narrative: '''
「黃金時代來臨！」商人們歡呼雀躍。

紡織業、鋼鐵業、航運業全面起飛，
倫敦股市連續上漲，財富湧入每個人的口袋。

資本家們趁勢擴張，獲取最大利益。
所有人都享受到了經濟成長的果實！

（全員金幣 +20%，資方派額外 +10%）
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 7：🔥 工人起義 (Workers' Uprising)
  // ============================================================
  static const workersUprising = RandomEvent(
    id: 'workers_uprising',
    type: RandomEventType.workersUprising,
    name: '工人起義',
    emoji: '🔥',
    description: '被壓迫的工人走上街頭抗議！',
    narrative: '''
「麵包！工作！尊嚴！」

曼徹斯特的街頭湧現大批憤怒的工人。
他們揮舞著鐵鎚和旗幟，高喊口號。

長期的低薪、惡劣的工作環境，終於引爆了這場風暴。
群眾衝向工廠主的宅邸，資方驚慌失措...

勞工的聲音終於被聽見了！
（勞工派聲望 +20，資方派聲望 -15）
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 8：💒 皇家婚禮 (Royal Wedding)
  // ============================================================
  static const royalWedding = RandomEvent(
    id: 'royal_wedding',
    type: RandomEventType.royalWedding,
    name: '皇家婚禮',
    emoji: '💒',
    description: '皇室婚禮帶來短暫和平！',
    narrative: '''
「天佑吾王！」民眾夾道歡呼。

威斯敏斯特教堂鐘聲齊鳴，
皇室婚禮的喜慶氣氛感染了整個倫敦。

即使是最針鋒相對的政敵，
在這樣的日子裡也暫時放下了成見。

和諧的氛圍籠罩議會，每個人都收到了祝福...
（全員人情 +2，皇室派聲望 +10）
''',
    requiresChoice: false,
  );

  // ============================================================
  // 事件 9：🕵️ 間諜醜聞 (Spy Scandal)
  // ============================================================
  static const spyScandal = RandomEvent(
    id: 'spy_scandal',
    type: RandomEventType.spyScandal,
    name: '間諜醜聞',
    emoji: '🕵️',
    description: '有人被懷疑是法國間諜！',
    narrative: '''
「叛國者就在我們之中！」

一封被截獲的密信揭露了驚人內幕——
議會中有人正在向法國傳遞情報！

所有人的目光都充滿懷疑，
流言蜚語如野火般蔓延...

法蘭西斯，這位消息靈通的記者，
似乎知道些什麼。他會選擇揭露真相，還是保持沉默？
''',
    requiresChoice: true,
    choices: [
      EventChoice(
        id: 'expose',
        title: '揭露真相',
        description: '公開指認嫌疑人（目標聲望 -10）',
        emoji: '📢',
      ),
      EventChoice(
        id: 'stay_silent',
        title: '保持沉默',
        description: '明哲保身，不參與這場風波',
        emoji: '🤐',
      ),
    ],
  );

  // ============================================================
  // 事件 10：📚 啟蒙思潮 (Enlightenment Wave)
  // ============================================================
  static const enlightenmentWave = RandomEvent(
    id: 'enlightenment_wave',
    type: RandomEventType.enlightenmentWave,
    name: '啟蒙思潮',
    emoji: '📚',
    description: '知識份子的文章引發社會討論！',
    narrative: '''
「理性之光照亮黑暗！」

伊莉莎白在《愛丁堡評論》發表的文章引發轟動。
她呼籲以科學和理性取代迷信與偏見，
主張每個人都應享有教育和自由的權利。

這些激進的思想在知識份子間廣為流傳，
改革的呼聲越來越高...

（改革派聲望 +10，所有人情報 +1）
''',
    requiresChoice: false,
  );

  /// 所有突發事件
  static const List<RandomEvent> allEvents = [
    newspaperExtra,
    stockMarketCrash,
    factoryFire,
    royalAttention,
    frenchThreat,
    economicBoom,
    workersUprising,
    royalWedding,
    spyScandal,
    enlightenmentWave,
  ];

  /// 根據 ID 取得事件
  static RandomEvent? getEventById(String eventId) {
    try {
      return allEvents.firstWhere((e) => e.id == eventId);
    } catch (e) {
      return null;
    }
  }

  /// 根據類型取得事件
  static RandomEvent? getEventByType(RandomEventType type) {
    try {
      return allEvents.firstWhere((e) => e.type == type);
    } catch (e) {
      return null;
    }
  }
}

/// 突發事件系統 - 處理事件觸發條件和效果
class RandomEventSystem {
  final Random _random;

  RandomEventSystem({Random? random}) : _random = random ?? Random();

  /// 檢查並觸發事件
  /// 
  /// [currentRound] - 當前回合數
  /// [players] - 所有玩家列表（人類 + AI）
  /// [aiPlayers] - AI 玩家列表（用於檢查角色）
  /// 
  /// 返回觸發的事件，若無事件觸發則返回 null
  RandomEvent? checkAndTriggerEvent({
    required int currentRound,
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    // 收集所有可觸發的事件
    final eligibleEvents = <RandomEvent>[];

    // 1. 報紙號外 - 回合 2+
    if (currentRound >= 2) {
      eligibleEvents.add(RandomEventDatabase.newspaperExtra);
    }

    // 2. 股市崩盤 - 20% 機率
    if (_random.nextDouble() < 0.2) {
      eligibleEvents.add(RandomEventDatabase.stockMarketCrash);
    }

    // 3. 工廠大火 - 有資方角色時
    final hasFactoryOwner = _hasPlayerWithFaction(players, aiPlayers, Faction.factory);
    if (hasFactoryOwner) {
      eligibleEvents.add(RandomEventDatabase.factoryFire);
    }

    // 4. 皇室關注 - 喬治三世在場時
    final hasKingGeorge = _hasPlayerWithRoleId(players, aiPlayers, 'king_george_iii');
    if (hasKingGeorge) {
      eligibleEvents.add(RandomEventDatabase.royalAttention);
    }

    // 5. 法國威脅 - 回合 3+
    if (currentRound >= 3) {
      eligibleEvents.add(RandomEventDatabase.frenchThreat);
    }

    // 6. 經濟繁榮 - 資方派總聲望 > 150
    final factoryTotalReputation = _getFactionTotalReputation(players, aiPlayers, Faction.factory);
    if (factoryTotalReputation > 150) {
      eligibleEvents.add(RandomEventDatabase.economicBoom);
    }

    // 7. 工人起義 - 勞工派總聲望 < 100
    final workerTotalReputation = _getFactionTotalReputation(players, aiPlayers, Faction.worker);
    if (workerTotalReputation < 100) {
      eligibleEvents.add(RandomEventDatabase.workersUprising);
    }

    // 8. 皇家婚禮 - 喬治三世在場且聲望 > 50
    final hasKingForWedding = _hasPlayerWithRoleId(players, aiPlayers, 'king_george_iii');
    if (hasKingForWedding) {
      final kingReputation = _getPlayerReputationByRoleId(players, aiPlayers, 'king_george_iii');
      if (kingReputation > 50) {
        eligibleEvents.add(RandomEventDatabase.royalWedding);
      }
    }

    // 9. 間諜醜聞 - 法蘭西斯在場
    final hasFrancis = _hasPlayerWithRoleId(players, aiPlayers, 'journalist_francis');
    if (hasFrancis) {
      eligibleEvents.add(RandomEventDatabase.spyScandal);
    }

    // 10. 啟蒙思潮 - 伊莉莎白在場
    final hasElizabeth = _hasPlayerWithRoleId(players, aiPlayers, 'scholar_elizabeth');
    if (hasElizabeth) {
      eligibleEvents.add(RandomEventDatabase.enlightenmentWave);
    }

    // 如果沒有可觸發的事件，返回 null
    if (eligibleEvents.isEmpty) {
      return null;
    }

    // 隨機選擇一個事件觸發
    return eligibleEvents[_random.nextInt(eligibleEvents.length)];
  }

  /// 處理報紙號外事件
  /// 
  /// [players] - 所有玩家
  /// [choiceId] - 被點名玩家的選擇（silence 或 defend）
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processNewspaperExtra({
    required List<Player> players,
    required String choiceId,
  }) {
    final results = <EventEffectResult>[];

    // 找出聲望最高的存活玩家
    final alivePlayers = players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return results;

    alivePlayers.sort((a, b) => b.reputation.compareTo(a.reputation));
    final target = alivePlayers.first;

    if (choiceId == 'silence') {
      // 沉默：接受全部傷害
      results.add(EventEffectResult(
        playerId: target.id,
        reputationChange: -15,
        description: '${target.name} 選擇保持沉默，承受了報導帶來的全部傷害。聲望 -15',
      ));
    } else if (choiceId == 'defend') {
      // 辯解：消耗聲望減半傷害
      results.add(EventEffectResult(
        playerId: target.id,
        reputationChange: -10 - 7, // -10 消耗 + -7 減半傷害（約 15/2）
        description: '${target.name} 公開辯解，消耗 10 聲望，傷害減半。聲望 -17',
        specialEffects: {'defended': true},
      ));
    }

    return results;
  }

  /// 處理股市崩盤事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processStockMarketCrash({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    // 所有玩家金幣 -30%
    for (final player in players) {
      if (!player.isAlive) continue;

      final goldLoss = (player.gold * 0.3).round();
      results.add(EventEffectResult(
        playerId: player.id,
        goldChange: -goldLoss,
        description: '${player.name} 在股災中損失了 $goldLoss 金幣',
      ));
    }

    // 銀行家亨利特殊效果
    final hasBankerHenry = _hasPlayerWithRoleId(players, aiPlayers, 'banker_henry');
    if (hasBankerHenry) {
      final henryId = _getPlayerIdByRoleId(players, aiPlayers, 'banker_henry');
      if (henryId != null) {
        results.add(EventEffectResult(
          playerId: henryId,
          goldChange: 20,
          description: '銀行家亨利趁機低價收購，額外獲得 20 金幣！',
          specialEffects: {'banker_bonus': true},
        ));
      }
    }

    return results;
  }

  /// 處理工廠大火事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processFactoryFire({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    // 找出所有資方角色
    final factoryOwners = _getPlayersWithFaction(players, aiPlayers, Faction.factory);
    
    if (factoryOwners.isNotEmpty) {
      // 隨機選一名資方角色受罰
      final target = factoryOwners[_random.nextInt(factoryOwners.length)];
      results.add(EventEffectResult(
        playerId: target.id,
        reputationChange: -20,
        description: '${target.name} 的工廠安全措施不足，被輿論譴責！聲望 -20',
      ));
    }

    // 所有勞工派獲得加成
    final workers = _getPlayersWithFaction(players, aiPlayers, Faction.worker);
    for (final worker in workers) {
      results.add(EventEffectResult(
        playerId: worker.id,
        reputationChange: 5,
        description: '${worker.name} 的立場獲得更多支持。聲望 +5',
      ));
    }

    return results;
  }

  /// 處理皇室關注事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processRoyalAttention({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    // 找到喬治三世
    final kingId = _getPlayerIdByRoleId(players, aiPlayers, 'king_george_iii');
    if (kingId == null) return results;

    final kingPlayer = players.firstWhere(
      (p) => p.id == kingId,
      orElse: () => players.first,
    );

    // 檢查精神不穩（10% 機率觸發）
    if (_random.nextDouble() < 0.1) {
      // 精神不穩：隨機效果
      final randomEffects = [
        EventEffectResult(
          playerId: kingId,
          reputationChange: -10,
          description: '喬治三世精神不穩發作！開始胡言亂語，聲望 -10',
          specialEffects: {'madness': true, 'speechWeight': 0.5},
        ),
        EventEffectResult(
          playerId: kingId,
          reputationChange: 10,
          description: '喬治三世突然清醒，發表了一番激勵人心的演說！聲望 +10',
          specialEffects: {'madness': false, 'speechWeight': 3.0},
        ),
      ];
      results.add(randomEffects[_random.nextInt(randomEffects.length)]);
    } else {
      // 正常效果：發言權重 ×2
      results.add(EventEffectResult(
        playerId: kingId,
        description: '${kingPlayer.name} 獲得皇室關注，下回合發言權重 ×2',
        specialEffects: {'speechWeight': 2.0},
      ));
    }

    return results;
  }

  /// 處理法國威脅事件
  /// 
  /// [players] - 所有玩家
  /// [playerChoices] - 玩家選擇 Map（playerId -> choiceId）
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processFrenchThreat({
    required List<Player> players,
    required Map<String, String> playerChoices,
  }) {
    final results = <EventEffectResult>[];

    for (final player in players) {
      if (!player.isAlive) continue;

      final choice = playerChoices[player.id] ?? 'support_military';

      if (choice == 'support_military') {
        results.add(EventEffectResult(
          playerId: player.id,
          description: '${player.name} 支持增加軍費，獲得皇室派好感 +10',
          specialEffects: {'royalFavor': 10},
        ));
      } else {
        results.add(EventEffectResult(
          playerId: player.id,
          description: '${player.name} 反對增加軍費，獲得改革派好感 +10',
          specialEffects: {'reformFavor': 10},
        ));
      }
    }

    return results;
  }

  /// 處理經濟繁榮事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processEconomicBoom({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    for (final player in players) {
      if (!player.isAlive) continue;

      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      final isFactory = role?.faction == Faction.factory;
      
      // 基礎 +20%
      var goldGain = (player.gold * 0.2).round();
      
      // 資方派額外 +10%
      if (isFactory) {
        goldGain += (player.gold * 0.1).round();
        results.add(EventEffectResult(
          playerId: player.id,
          goldChange: goldGain,
          description: '${player.name} 作為資方派，在經濟繁榮中大賺一筆！金幣 +$goldGain（+30%）',
          specialEffects: {'factoryBonus': true},
        ));
      } else {
        results.add(EventEffectResult(
          playerId: player.id,
          goldChange: goldGain,
          description: '${player.name} 在經濟繁榮中獲益。金幣 +$goldGain（+20%）',
        ));
      }
    }

    return results;
  }

  /// 處理工人起義事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processWorkersUprising({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    for (final player in players) {
      if (!player.isAlive) continue;

      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      
      if (role?.faction == Faction.worker) {
        // 勞工派聲望 +20
        results.add(EventEffectResult(
          playerId: player.id,
          reputationChange: 20,
          description: '${player.name} 的聲音在起義中被聽見！聲望 +20',
        ));
      } else if (role?.faction == Faction.factory) {
        // 資方派聲望 -15
        results.add(EventEffectResult(
          playerId: player.id,
          reputationChange: -15,
          description: '${player.name} 被工人指控剝削！聲望 -15',
        ));
      }
    }

    return results;
  }

  /// 處理皇家婚禮事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processRoyalWedding({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    for (final player in players) {
      if (!player.isAlive) continue;

      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      final isRoyal = role?.faction == Faction.royal;

      if (isRoyal) {
        // 皇室派聲望 +10
        results.add(EventEffectResult(
          playerId: player.id,
          reputationChange: 10,
          description: '${player.name} 在皇家婚禮中備受矚目！聲望 +10，人情 +2',
          specialEffects: {'favorChange': 2},
        ));
      } else {
        // 全員人情 +2
        results.add(EventEffectResult(
          playerId: player.id,
          description: '${player.name} 收到皇室的祝福禮物。人情 +2',
          specialEffects: {'favorChange': 2},
        ));
      }
    }

    return results;
  }

  /// 處理間諜醜聞事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// [choiceId] - 法蘭西斯的選擇（expose 或 stay_silent）
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processSpyScandal({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
    required String choiceId,
  }) {
    final results = <EventEffectResult>[];

    // 找到法蘭西斯
    final francisId = _getPlayerIdByRoleId(players, aiPlayers, 'journalist_francis');
    
    if (choiceId == 'expose') {
      // 隨機選一名非法蘭西斯玩家作為嫌疑人
      final suspects = players.where((p) => 
        p.isAlive && p.id != francisId
      ).toList();
      
      if (suspects.isNotEmpty) {
        final suspect = suspects[_random.nextInt(suspects.length)];
        results.add(EventEffectResult(
          playerId: suspect.id,
          reputationChange: -10,
          description: '${suspect.name} 被指控為法國間諜！聲望 -10',
          specialEffects: {'suspected': true},
        ));
        
        if (francisId != null) {
          results.add(EventEffectResult(
            playerId: francisId,
            description: '法蘭西斯揭露了「間諜」的身份！',
            specialEffects: {'exposed': true},
          ));
        }
      }
    } else {
      // 保持沉默
      if (francisId != null) {
        results.add(EventEffectResult(
          playerId: francisId,
          description: '法蘭西斯選擇保持沉默，明哲保身。',
          specialEffects: {'silent': true},
        ));
      }
    }

    return results;
  }

  /// 處理啟蒙思潮事件
  /// 
  /// [players] - 所有玩家
  /// [aiPlayers] - AI 玩家列表
  /// 
  /// 返回事件效果結果列表
  List<EventEffectResult> processEnlightenmentWave({
    required List<Player> players,
    required List<AIPlayer> aiPlayers,
  }) {
    final results = <EventEffectResult>[];

    for (final player in players) {
      if (!player.isAlive) continue;

      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      
      if (role?.faction == Faction.reform) {
        // 改革派聲望 +10
        results.add(EventEffectResult(
          playerId: player.id,
          reputationChange: 10,
          description: '${player.name} 的改革理念獲得廣泛支持！聲望 +10，情報 +1',
          specialEffects: {'intelChange': 1},
        ));
      } else {
        // 所有人情報 +1
        results.add(EventEffectResult(
          playerId: player.id,
          description: '${player.name} 從啟蒙文章中獲得啟發。情報 +1',
          specialEffects: {'intelChange': 1},
        ));
      }
    }

    return results;
  }

  // ============================================================
  // 輔助方法
  // ============================================================

  /// 檢查是否有特定陣營的玩家
  bool _hasPlayerWithFaction(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    Faction faction,
  ) {
    for (final player in players) {
      if (!player.isAlive) continue;
      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      if (role?.faction == faction) return true;
    }
    return false;
  }

  /// 檢查是否有特定角色 ID 的玩家
  bool _hasPlayerWithRoleId(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    String roleId,
  ) {
    for (final player in players) {
      if (!player.isAlive) continue;
      if (player.roleId == roleId) return true;
    }
    return false;
  }

  /// 取得特定角色 ID 的玩家 ID
  String? _getPlayerIdByRoleId(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    String roleId,
  ) {
    for (final player in players) {
      if (!player.isAlive) continue;
      if (player.roleId == roleId) return player.id;
    }
    return null;
  }

  /// 取得特定陣營的所有玩家
  List<Player> _getPlayersWithFaction(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    Faction faction,
  ) {
    final result = <Player>[];
    for (final player in players) {
      if (!player.isAlive) continue;
      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      if (role?.faction == faction) {
        result.add(player);
      }
    }
    return result;
  }

  /// 計算特定陣營的總聲望
  int _getFactionTotalReputation(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    Faction faction,
  ) {
    int total = 0;
    for (final player in players) {
      if (!player.isAlive) continue;
      final role = RoleDatabase.getRoleById(player.roleId ?? '');
      if (role?.faction == faction) {
        total += player.reputation;
      }
    }
    return total;
  }

  /// 取得特定角色 ID 的玩家聲望
  int _getPlayerReputationByRoleId(
    List<Player> players,
    List<AIPlayer> aiPlayers,
    String roleId,
  ) {
    for (final player in players) {
      if (!player.isAlive) continue;
      if (player.roleId == roleId) return player.reputation;
    }
    return 0;
  }
}
