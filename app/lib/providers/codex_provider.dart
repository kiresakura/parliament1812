import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════
// 圖鑑資料模型
// ═══════════════════════════════════════════

/// 稀有度
enum CodexRarity { common, uncommon, rare, legendary }

/// 圖鑑卡牌條目
class CodexCard {
  final String id;
  final String name;
  final String description;
  final String cardType; // attack / defense / utility / signature
  final CodexRarity rarity;
  final String? character;
  final String unlockCondition;
  final String flavorText;
  final bool owned;

  const CodexCard({
    required this.id,
    required this.name,
    required this.description,
    required this.cardType,
    required this.rarity,
    this.character,
    required this.unlockCondition,
    required this.flavorText,
    this.owned = false,
  });

  CodexCard copyWith({bool? owned}) => CodexCard(
        id: id,
        name: name,
        description: description,
        cardType: cardType,
        rarity: rarity,
        character: character,
        unlockCondition: unlockCondition,
        flavorText: flavorText,
        owned: owned ?? this.owned,
      );
}

/// 收藏統計
class CodexStats {
  final int totalCards;
  final int collectedCards;
  final double collectionPercentage;

  const CodexStats({
    required this.totalCards,
    required this.collectedCards,
    required this.collectionPercentage,
  });
}

/// 圖鑑狀態
class CodexState {
  final List<CodexCard> allCards;
  final CodexStats stats;
  final bool isLoading;
  final String? error;

  const CodexState({
    this.allCards = const [],
    this.stats = const CodexStats(totalCards: 56, collectedCards: 0, collectionPercentage: 0),
    this.isLoading = false,
    this.error,
  });

  List<CodexCard> get ownedCards => allCards.where((c) => c.owned).toList();

  CodexState copyWith({
    List<CodexCard>? allCards,
    CodexStats? stats,
    bool? isLoading,
    String? error,
  }) =>
      CodexState(
        allCards: allCards ?? this.allCards,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ═══════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════

final codexProvider = StateNotifierProvider<CodexNotifier, CodexState>((ref) {
  return CodexNotifier();
});

class CodexNotifier extends StateNotifier<CodexState> {
  CodexNotifier() : super(const CodexState(isLoading: true)) {
    _loadLocalData();
  }

  /// 從本地靜態資料載入（離線模式 / 開發用）
  void _loadLocalData() {
    final cards = _buildAllCards();
    // 模擬：初始擁有前 8 張（MVP 卡牌）
    final ownedIds = {
      'common_interrogate',
      'common_rebut',
      'common_expose_scandal',
      'common_endorse',
      'thomas_unity',
      'richard_bribe',
      'edward_scoop',
      'george_fury',
    };
    final cardsWithOwnership = cards.map((c) {
      return c.copyWith(owned: ownedIds.contains(c.id));
    }).toList();

    final owned = cardsWithOwnership.where((c) => c.owned).length;
    state = CodexState(
      allCards: cardsWithOwnership,
      stats: CodexStats(
        totalCards: cardsWithOwnership.length,
        collectedCards: owned,
        collectionPercentage:
            cardsWithOwnership.isEmpty ? 0 : (owned / cardsWithOwnership.length * 100).roundToDouble(),
      ),
      isLoading: false,
    );
  }

  /// TODO: 從 API 載入
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    // 目前使用本地資料
    _loadLocalData();
  }
}

// ═══════════════════════════════════════════
// 靜態卡牌資料（與 Rust card_codex.rs 同步）
// ═══════════════════════════════════════════

List<CodexCard> _buildAllCards() {
  return [
    // ── Common (20) ──
    const CodexCard(id: 'common_interrogate', name: '質詢', description: '對目標議員提出尖銳質詢，造成 15 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.common, unlockCondition: '初始擁有', flavorText: '「閣下，請您向議會解釋——您的良心去了哪裡？」'),
    const CodexCard(id: 'common_rebut', name: '反駁', description: '抵消一次針對你的質詢攻擊。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '初始擁有', flavorText: '「這位議員的指控毫無根據，純屬造謠！」'),
    const CodexCard(id: 'common_brief_speech', name: '簡短發言', description: '在議會中發表簡短演說，恢復 5 點聲望。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 1 場對局', flavorText: '「簡潔是智慧的靈魂。」—— 莎士比亞'),
    const CodexCard(id: 'common_procedural_motion', name: '程序動議', description: '提出程序性動議，中斷當前辯論，使一名對手下回合無法出攻擊卡。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 2 場對局', flavorText: '議長的木槌敲下，一切辯論戛然而止。'),
    const CodexCard(id: 'common_gather_intel', name: '蒐集情報', description: '查看目標議員的一張手牌。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 3 場對局', flavorText: '在議會的走廊裡，消息比法案流通得更快。'),
    const CodexCard(id: 'common_public_appeal', name: '公開呼籲', description: '向公眾發表呼籲，恢復 8 點聲望。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 3 場對局', flavorText: '「我們的事業，就是人民的事業！」'),
    const CodexCard(id: 'common_pamphlet', name: '政治小冊', description: '散發攻擊性小冊子，對目標造成 8 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.common, unlockCondition: '完成 5 場對局', flavorText: '印刷機是比劍更鋒利的武器。'),
    const CodexCard(id: 'common_lobby', name: '遊說', description: '在議會大廳遊說，下次投票你的票數權重 +0.5。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 5 場對局', flavorText: '真正的政治不在議場之上，而在走廊之中。'),
    const CodexCard(id: 'common_filibuster', name: '冗長辯論', description: '進行冗長辯論，本回合內你不會受到攻擊傷害。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '贏得 1 場對局', flavorText: '他已經不間斷地說了四個小時。沒有人有精力反駁了。'),
    const CodexCard(id: 'common_point_of_order', name: '秩序問題', description: '提出秩序問題，抵消一張針對你的功能卡。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '贏得 1 場對局', flavorText: '「議長先生！這嚴重違反了議事規則！」'),
    const CodexCard(id: 'common_withdraw', name: '策略性退場', description: '暫時退出辯論，減少 50% 受到的傷害持續 1 回合。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '贏得 2 場對局', flavorText: '有時候，不在場就是最好的策略。'),
    const CodexCard(id: 'common_petition', name: '請願書', description: '提交公民請願書，恢復 10 點聲望。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '贏得 3 場對局', flavorText: '一萬兩千人簽名的請願書，議會不能視而不見。'),
    const CodexCard(id: 'common_compromise', name: '妥協', description: '與對手妥協，雙方各恢復 5 點聲望。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 8 場對局', flavorText: '政治的藝術，就是妥協的藝術。'),
    const CodexCard(id: 'common_rumor', name: '散佈謠言', description: '散佈關於目標的謠言，造成 10 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.common, unlockCondition: '完成 8 場對局', flavorText: '倫敦的咖啡館裡，謠言比真相更有市場。'),
    const CodexCard(id: 'common_tax_debate', name: '稅制辯論', description: '就稅制問題發起辯論，對所有對手造成 5 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.common, unlockCondition: '完成 10 場對局', flavorText: '「沒有代表權就不應徵稅！」——這場爭論永遠不會結束。'),
    const CodexCard(id: 'common_moral_appeal', name: '道德呼籲', description: '以道德立場呼籲支持，恢復 12 點聲望。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '完成 10 場對局', flavorText: '「諸位同僚，我們怎能對工人的苦難視而不見？」'),
    const CodexCard(id: 'common_backroom_deal', name: '密室交易', description: '與另一位議員達成密室協議，雙方各獲得 10 金幣。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '贏得 5 場對局', flavorText: '門關上了。沒有記錄。沒有證人。只有交易。'),
    const CodexCard(id: 'common_call_to_order', name: '維持秩序', description: '要求議會恢復秩序，取消當前所有暫時效果。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '贏得 5 場對局', flavorText: '議長的威嚴不容挑戰。至少名義上如此。'),
    const CodexCard(id: 'common_quick_wit', name: '急智', description: '以機智的回應化解攻擊，抵消 10 點傷害。', cardType: 'defense', rarity: CodexRarity.common, unlockCondition: '贏得 8 場對局', flavorText: '「這位紳士的邏輯，和他的髮型一樣混亂。」'),
    const CodexCard(id: 'common_opening_statement', name: '開場白', description: '精心準備的開場白，本回合所有你的卡牌效果 +20%。', cardType: 'utility', rarity: CodexRarity.common, unlockCondition: '贏得 10 場對局', flavorText: '好的開始是成功的一半。在議會中，更是如此。'),

    // ── Uncommon (15) ──
    const CodexCard(id: 'common_expose_scandal', name: '揭露醜聞', description: '揭露目標的不光彩過去，造成 25 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '贏得 3 場對局', flavorText: '「紳士們，讓我告訴你們，這位議員在約克郡的所作所為……」'),
    const CodexCard(id: 'common_endorse', name: '背書', description: '公開支持目標議員，恢復 20 點聲望。可復活政治死亡的盟友。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '贏得 5 場對局', flavorText: '一個有力的盟友，勝過千言萬語。'),
    const CodexCard(id: 'uncommon_coalition', name: '組建聯盟', description: '與目標結成臨時聯盟，雙方本回合攻擊力 +5。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '在對局中結盟 5 次', flavorText: '敵人的敵人，就是朋友。至少在這場投票中如此。'),
    const CodexCard(id: 'uncommon_whip', name: '黨鞭施壓', description: '以黨紀施壓目標，若目標為盟友則造成 20 點傷害並解除聯盟。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '在對局中背叛 3 次', flavorText: '「記住你的立場。記住是誰把你送進這裡的。」'),
    const CodexCard(id: 'uncommon_propaganda', name: '宣傳攻勢', description: '發動宣傳攻勢，對所有非盟友造成 8 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '累計造成 200 點傷害', flavorText: '報紙頭版的力量，不亞於議會的投票。'),
    const CodexCard(id: 'uncommon_double_agent', name: '雙面間諜', description: '窺探目標的所有手牌，並偷取其中一張。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '贏得 10 場對局', flavorText: '每個議員的侍從都可能被收買。問題只是價格。'),
    const CodexCard(id: 'uncommon_crisis', name: '製造危機', description: '製造政治危機，所有議員（包括自己）失去 10 點聲望。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '在一場對局中使用 5 張攻擊卡', flavorText: '混亂之中，才有機會翻盤。'),
    const CodexCard(id: 'uncommon_amnesty', name: '大赦', description: '宣布大赦，移除場上所有負面效果。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '累計恢復 200 點聲望', flavorText: '「讓過去的恩怨留在過去。今天，我們重新開始。」'),
    const CodexCard(id: 'uncommon_royal_favor', name: '皇室恩寵', description: '獲得國王的關注，恢復 15 點聲望並獲得 15 金幣。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '贏得 15 場對局', flavorText: '喬治三世雖然精神不穩，但他的恩寵仍然價值連城。'),
    const CodexCard(id: 'uncommon_press_leak', name: '新聞洩露', description: '洩露機密文件給報社，對目標造成 18 點聲望傷害。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '使用記者愛德華贏得 3 場', flavorText: '「泰晤士報」的頭版，足以毀掉一個政治生涯。'),
    const CodexCard(id: 'uncommon_strike', name: '罷工', description: '發動工人罷工，目標本回合無法使用功能卡。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '使用工人湯瑪斯贏得 3 場', flavorText: '工廠停擺。碼頭靜默。整個城市在等待。'),
    const CodexCard(id: 'uncommon_embargo', name: '禁運', description: '對目標實施經濟制裁，使其失去 20 金幣。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '使用工廠主理查贏得 3 場', flavorText: '拿破崙的大陸封鎖令讓英國學會了一課：貿易就是武器。'),
    const CodexCard(id: 'uncommon_charity', name: '慈善行動', description: '花費 20 金幣，恢復自己和一名盟友各 15 點聲望。', cardType: 'utility', rarity: CodexRarity.uncommon, unlockCondition: '累計獲得 500 金幣', flavorText: '慈善是富人的義務——也是一種公關手段。'),
    const CodexCard(id: 'uncommon_inspection', name: '突擊檢查', description: '對目標進行突擊檢查，揭露其一張手牌並造成 12 點傷害。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '完成 20 場對局', flavorText: '「奉國王之命，打開你的帳簿。」'),
    const CodexCard(id: 'uncommon_war_debt', name: '戰爭債務', description: '以戰爭債務為由攻擊，對最富有的議員造成 20 點傷害。', cardType: 'attack', rarity: CodexRarity.uncommon, unlockCondition: '完成 20 場對局', flavorText: '拿破崙戰爭的帳單終究要有人來付。'),

    // ── Rare (15) ──
    const CodexCard(id: 'rare_impeachment', name: '彈劾', description: '發起彈劾程序，對目標造成 30 點聲望傷害。需投票多數支持。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '贏得 20 場對局', flavorText: '「在上帝和國會面前，我控訴此人犯下叛國罪。」'),
    const CodexCard(id: 'rare_martial_law', name: '戒嚴令', description: '宣布戒嚴，本回合所有玩家無法使用攻擊卡。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '贏得 25 場對局', flavorText: '國王陛下以國家安全之名，暫停了所有議會辯論。'),
    const CodexCard(id: 'rare_revolution', name: '革命號召', description: '號召革命！對聲望最高的議員造成 35 點傷害，自己恢復 15 點。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '使用盧德派喬治贏得 5 場', flavorText: '「自由、平等、博愛！」——法國的風暴已經吹到了英吉利海峽這邊。'),
    const CodexCard(id: 'rare_political_assassination', name: '政治暗殺', description: '對目標發動致命攻擊，造成 40 點聲望傷害。使用後自己也失去 20 點。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '累計造成 500 點傷害', flavorText: '1812 年，首相斯賓塞·珀西瓦爾在議會大廳遇刺身亡。'),
    const CodexCard(id: 'rare_reform_act', name: '改革法案', description: '推動改革法案，所有聲望低於 30 的議員恢復至 30。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '使用所有角色各贏一場', flavorText: '改革的浪潮勢不可擋。問題只是時間。'),
    const CodexCard(id: 'rare_corn_law', name: '穀物法', description: '推動穀物法，使所有工人角色失去 15 點聲望，資方角色獲得 15 金幣。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '使用工廠主理查贏得 5 場', flavorText: '麵包的價格牽動著整個國家的命運。'),
    const CodexCard(id: 'rare_factory_act', name: '工廠法', description: '推動工廠法，使所有資方角色失去 15 金幣，工人角色恢復 15 點聲望。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '使用工人湯瑪斯贏得 5 場', flavorText: '「十歲的孩子不應該在工廠裡工作十六個小時。」'),
    const CodexCard(id: 'rare_habeas_corpus', name: '人身保護令', description: '發動人身保護令，使一名被沉默的議員立即恢復行動能力並恢復 20 點聲望。', cardType: 'defense', rarity: CodexRarity.rare, unlockCondition: '累計成功防禦 20 次', flavorText: '「任何人不得被非法拘禁。」—— 英國法律的基石。'),
    const CodexCard(id: 'rare_no_confidence', name: '不信任投票', description: '發起不信任投票，若超過半數支持，目標直接政治死亡。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '連勝 5 場', flavorText: '「本院已對閣下失去信心。請您體面地離開。」'),
    const CodexCard(id: 'rare_grand_coalition', name: '大聯合', description: '建立大聯合，與場上所有存活議員結成臨時聯盟，持續 1 回合。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '在對局中結盟 20 次', flavorText: '當國家面臨危機，所有黨派必須團結一心。'),
    const CodexCard(id: 'rare_espionage', name: '間諜活動', description: '查看所有對手的手牌，並可選擇棄掉其中一張。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: '使用記者愛德華贏得 5 場', flavorText: '倫敦塔裡不僅關著囚犯，也藏著整個帝國的秘密。'),
    const CodexCard(id: 'rare_public_trial', name: '公開審判', description: '對目標進行公開審判，造成 20 點傷害。若目標本回合使用過攻擊卡，額外造成 20 點。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '累計造成 1000 點傷害', flavorText: '公義必須被看見。而且要讓所有人都看見。'),
    const CodexCard(id: 'rare_royal_decree', name: '王室詔令', description: '以國王之名頒布詔令，自己恢復 25 點聲望並獲得 25 金幣。', cardType: 'utility', rarity: CodexRarity.rare, unlockCondition: 'ELO 達到 1200', flavorText: '「奉天承運，國王詔曰——」'),
    const CodexCard(id: 'rare_blockade', name: '封鎖', description: '對目標實施封鎖，使其下 2 回合無法獲得金幣和抽牌。', cardType: 'attack', rarity: CodexRarity.rare, unlockCondition: '贏得 50 場對局', flavorText: '皇家海軍的炮口，就是最好的談判籌碼。'),
    const CodexCard(id: 'rare_diplomatic_immunity', name: '外交豁免', description: '獲得外交豁免，接下來 2 回合內免疫所有傷害。', cardType: 'defense', rarity: CodexRarity.rare, unlockCondition: 'ELO 達到 1300', flavorText: '「我代表的是另一個主權國家。你們的法律管不了我。」'),

    // ── Legendary (6) ──
    const CodexCard(id: 'thomas_unity', name: '團結', description: '每有 1 名工人盟友，你獲得的防禦效果 +10。', cardType: 'signature', rarity: CodexRarity.legendary, character: '工人湯瑪斯', unlockCondition: '使用工人湯瑪斯贏得 10 場', flavorText: '「工人團結起來！我們除了鎖鏈，沒有什麼可以失去的。」'),
    const CodexCard(id: 'richard_bribe', name: '收買', description: '花費 30 金幣使目標沉默 1 回合，無法發言和使用攻擊卡。', cardType: 'signature', rarity: CodexRarity.legendary, character: '工廠主理查', unlockCondition: '使用工廠主理查贏得 10 場', flavorText: '「每個人都有他的價格。我只是比較直接。」'),
    const CodexCard(id: 'edward_scoop', name: '爆料', description: '揭露目標的秘密任務。若目標有隱藏身份，公開之。', cardType: 'signature', rarity: CodexRarity.legendary, character: '記者愛德華', unlockCondition: '使用記者愛德華贏得 10 場', flavorText: '「真相是記者的武器。而我從不缺少彈藥。」'),
    const CodexCard(id: 'george_fury', name: '怒火', description: '造成雙倍傷害（30 點），但自己也扣 10 聲望。', cardType: 'signature', rarity: CodexRarity.legendary, character: '盧德派喬治', unlockCondition: '使用盧德派喬治贏得 10 場', flavorText: '「他們毀了我們的生計。今晚，我們毀了他們的機器！」'),
    const CodexCard(id: 'legendary_peterloo', name: '彼得盧屠殺', description: '重現彼得盧慘劇，對所有對手造成 25 點傷害，但自己也失去 15 點聲望。', cardType: 'attack', rarity: CodexRarity.legendary, unlockCondition: '收集所有基礎卡牌', flavorText: '1819 年 8 月 16 日，曼徹斯特聖彼得廣場。騎兵衝進了和平集會的人群。'),
    const CodexCard(id: 'legendary_magna_carta', name: '大憲章精神', description: '援引大憲章精神，所有議員恢復 20 點聲望，移除所有負面效果。', cardType: 'utility', rarity: CodexRarity.legendary, unlockCondition: '登上排行榜前 10 名', flavorText: '「任何自由人，非經合法審判，不得被逮捕、監禁或流放。」—— 1215 年'),
  ];
}
