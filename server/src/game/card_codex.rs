//! 卡牌圖鑑
//!
//! 定義所有 56 張卡牌的完整 metadata，供收藏系統使用。
//! 與 cards.rs 中的可玩卡牌共用 ID，但圖鑑包含更豐富的資訊。

use serde::{Deserialize, Serialize};

/// 圖鑑稀有度
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CodexRarity {
    Common,
    Uncommon,
    Rare,
    Legendary,
}

impl CodexRarity {
    pub fn display_name(&self) -> &'static str {
        match self {
            CodexRarity::Common => "普通",
            CodexRarity::Uncommon => "稀有",
            CodexRarity::Rare => "史詩",
            CodexRarity::Legendary => "傳說",
        }
    }
}

impl std::fmt::Display for CodexRarity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.display_name())
    }
}

/// 圖鑑卡牌類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CodexCardType {
    Attack,
    Defense,
    Utility,
    Signature,
}

impl CodexCardType {
    pub fn display_name(&self) -> &'static str {
        match self {
            CodexCardType::Attack => "攻擊",
            CodexCardType::Defense => "防禦",
            CodexCardType::Utility => "功能",
            CodexCardType::Signature => "專屬",
        }
    }
}

/// 圖鑑卡牌條目
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CardCodexEntry {
    /// 卡牌唯一 ID
    pub id: String,
    /// 卡牌名稱
    pub name: String,
    /// 遊戲效果描述
    pub description: String,
    /// 卡牌類型
    pub card_type: CodexCardType,
    /// 圖鑑稀有度
    pub rarity: CodexRarity,
    /// 關聯角色（專屬卡才有）
    pub character: Option<String>,
    /// 解鎖條件描述
    pub unlock_condition: String,
    /// 風味文字
    pub flavor_text: String,
}

/// 取得全部 56 張卡牌圖鑑
pub fn get_all_codex_entries() -> Vec<CardCodexEntry> {
    let mut entries = Vec::with_capacity(56);

    // ═══════════════════════════════════════════
    // Common (20 張) — 基礎議會行動
    // ═══════════════════════════════════════════

    entries.push(CardCodexEntry {
        id: "common_interrogate".into(),
        name: "質詢".into(),
        description: "對目標議員提出尖銳質詢，造成 15 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "初始擁有".into(),
        flavor_text: "「閣下，請您向議會解釋——您的良心去了哪裡？」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_rebut".into(),
        name: "反駁".into(),
        description: "抵消一次針對你的質詢攻擊。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "初始擁有".into(),
        flavor_text: "「這位議員的指控毫無根據，純屬造謠！」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_brief_speech".into(),
        name: "簡短發言".into(),
        description: "在議會中發表簡短演說，恢復 5 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 1 場對局".into(),
        flavor_text: "「簡潔是智慧的靈魂。」—— 莎士比亞".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_procedural_motion".into(),
        name: "程序動議".into(),
        description: "提出程序性動議，中斷當前辯論，使一名對手下回合無法出攻擊卡。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 2 場對局".into(),
        flavor_text: "議長的木槌敲下，一切辯論戛然而止。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_gather_intel".into(),
        name: "蒐集情報".into(),
        description: "查看目標議員的一張手牌。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 3 場對局".into(),
        flavor_text: "在議會的走廊裡，消息比法案流通得更快。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_public_appeal".into(),
        name: "公開呼籲".into(),
        description: "向公眾發表呼籲，恢復 8 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 3 場對局".into(),
        flavor_text: "「我們的事業，就是人民的事業！」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_pamphlet".into(),
        name: "政治小冊".into(),
        description: "散發攻擊性小冊子，對目標造成 8 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 5 場對局".into(),
        flavor_text: "印刷機是比劍更鋒利的武器。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_lobby".into(),
        name: "遊說".into(),
        description: "在議會大廳遊說，下次投票你的票數權重 +0.5。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 5 場對局".into(),
        flavor_text: "真正的政治不在議場之上，而在走廊之中。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_filibuster".into(),
        name: "冗長辯論".into(),
        description: "進行冗長辯論，本回合內你不會受到攻擊傷害。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 1 場對局".into(),
        flavor_text: "他已經不間斷地說了四個小時。沒有人有精力反駁了。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_point_of_order".into(),
        name: "秩序問題".into(),
        description: "提出秩序問題，抵消一張針對你的功能卡。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 1 場對局".into(),
        flavor_text: "「議長先生！這嚴重違反了議事規則！」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_withdraw".into(),
        name: "策略性退場".into(),
        description: "暫時退出辯論，減少 50% 受到的傷害持續 1 回合。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 2 場對局".into(),
        flavor_text: "有時候，不在場就是最好的策略。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_petition".into(),
        name: "請願書".into(),
        description: "提交公民請願書，恢復 10 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 3 場對局".into(),
        flavor_text: "一萬兩千人簽名的請願書，議會不能視而不見。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_compromise".into(),
        name: "妥協".into(),
        description: "與對手妥協，雙方各恢復 5 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 8 場對局".into(),
        flavor_text: "政治的藝術，就是妥協的藝術。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_rumor".into(),
        name: "散佈謠言".into(),
        description: "散佈關於目標的謠言，造成 10 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 8 場對局".into(),
        flavor_text: "倫敦的咖啡館裡，謠言比真相更有市場。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_tax_debate".into(),
        name: "稅制辯論".into(),
        description: "就稅制問題發起辯論，對所有對手造成 5 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 10 場對局".into(),
        flavor_text: "「沒有代表權就不應徵稅！」——這場爭論永遠不會結束。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_moral_appeal".into(),
        name: "道德呼籲".into(),
        description: "以道德立場呼籲支持，恢復 12 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "完成 10 場對局".into(),
        flavor_text: "「諸位同僚，我們怎能對工人的苦難視而不見？」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_backroom_deal".into(),
        name: "密室交易".into(),
        description: "與另一位議員達成密室協議，雙方各獲得 10 金幣。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 5 場對局".into(),
        flavor_text: "門關上了。沒有記錄。沒有證人。只有交易。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_call_to_order".into(),
        name: "維持秩序".into(),
        description: "要求議會恢復秩序，取消當前所有暫時效果。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 5 場對局".into(),
        flavor_text: "議長的威嚴不容挑戰。至少名義上如此。".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_quick_wit".into(),
        name: "急智".into(),
        description: "以機智的回應化解攻擊，抵消 10 點傷害。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 8 場對局".into(),
        flavor_text: "「這位紳士的邏輯，和他的髮型一樣混亂。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_opening_statement".into(),
        name: "開場白".into(),
        description: "精心準備的開場白，本回合所有你的卡牌效果 +20%。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Common,
        character: None,
        unlock_condition: "贏得 10 場對局".into(),
        flavor_text: "好的開始是成功的一半。在議會中，更是如此。".into(),
    });

    // ═══════════════════════════════════════════
    // Uncommon (15 張) — 進階議會策略
    // ═══════════════════════════════════════════

    entries.push(CardCodexEntry {
        id: "common_expose_scandal".into(),
        name: "揭露醜聞".into(),
        description: "揭露目標的不光彩過去，造成 25 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "贏得 3 場對局".into(),
        flavor_text: "「紳士們，讓我告訴你們，這位議員在約克郡的所作所為……」".into(),
    });

    entries.push(CardCodexEntry {
        id: "common_endorse".into(),
        name: "背書".into(),
        description: "公開支持目標議員，恢復 20 點聲望。可復活政治死亡的盟友。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "贏得 5 場對局".into(),
        flavor_text: "一個有力的盟友，勝過千言萬語。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_coalition".into(),
        name: "組建聯盟".into(),
        description: "與目標結成臨時聯盟，雙方本回合攻擊力 +5。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "在對局中結盟 5 次".into(),
        flavor_text: "敵人的敵人，就是朋友。至少在這場投票中如此。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_whip".into(),
        name: "黨鞭施壓".into(),
        description: "以黨紀施壓目標，若目標為盟友則造成 20 點傷害並解除聯盟。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "在對局中背叛 3 次".into(),
        flavor_text: "「記住你的立場。記住是誰把你送進這裡的。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_propaganda".into(),
        name: "宣傳攻勢".into(),
        description: "發動宣傳攻勢，對所有非盟友造成 8 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "累計造成 200 點傷害".into(),
        flavor_text: "報紙頭版的力量，不亞於議會的投票。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_double_agent".into(),
        name: "雙面間諜".into(),
        description: "窺探目標的所有手牌，並偷取其中一張。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "贏得 10 場對局".into(),
        flavor_text: "每個議員的侍從都可能被收買。問題只是價格。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_crisis".into(),
        name: "製造危機".into(),
        description: "製造政治危機，所有議員（包括自己）失去 10 點聲望。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "在一場對局中使用 5 張攻擊卡".into(),
        flavor_text: "混亂之中，才有機會翻盤。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_amnesty".into(),
        name: "大赦".into(),
        description: "宣布大赦，移除場上所有負面效果。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "累計恢復 200 點聲望".into(),
        flavor_text: "「讓過去的恩怨留在過去。今天，我們重新開始。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_royal_favor".into(),
        name: "皇室恩寵".into(),
        description: "獲得國王的關注，恢復 15 點聲望並獲得 15 金幣。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "贏得 15 場對局".into(),
        flavor_text: "喬治三世雖然精神不穩，但他的恩寵仍然價值連城。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_press_leak".into(),
        name: "新聞洩露".into(),
        description: "洩露機密文件給報社，對目標造成 18 點聲望傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "使用記者愛德華贏得 3 場".into(),
        flavor_text: "「泰晤士報」的頭版，足以毀掉一個政治生涯。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_strike".into(),
        name: "罷工".into(),
        description: "發動工人罷工，目標本回合無法使用功能卡。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "使用工人湯瑪斯贏得 3 場".into(),
        flavor_text: "工廠停擺。碼頭靜默。整個城市在等待。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_embargo".into(),
        name: "禁運".into(),
        description: "對目標實施經濟制裁，使其失去 20 金幣。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "使用工廠主理查贏得 3 場".into(),
        flavor_text: "拿破崙的大陸封鎖令讓英國學會了一課：貿易就是武器。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_charity".into(),
        name: "慈善行動".into(),
        description: "花費 20 金幣，恢復自己和一名盟友各 15 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "累計獲得 500 金幣".into(),
        flavor_text: "慈善是富人的義務——也是一種公關手段。".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_inspection".into(),
        name: "突擊檢查".into(),
        description: "對目標進行突擊檢查，揭露其一張手牌並造成 12 點傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "完成 20 場對局".into(),
        flavor_text: "「奉國王之命，打開你的帳簿。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "uncommon_war_debt".into(),
        name: "戰爭債務".into(),
        description: "以戰爭債務為由攻擊，對最富有的議員造成 20 點傷害。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Uncommon,
        character: None,
        unlock_condition: "完成 20 場對局".into(),
        flavor_text: "拿破崙戰爭的帳單終究要有人來付。".into(),
    });

    // ═══════════════════════════════════════════
    // Rare (15 張) — 強力歷史事件
    // ═══════════════════════════════════════════

    entries.push(CardCodexEntry {
        id: "rare_impeachment".into(),
        name: "彈劾".into(),
        description: "發起彈劾程序，對目標造成 30 點聲望傷害。需投票多數支持。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "贏得 20 場對局".into(),
        flavor_text: "「在上帝和國會面前，我控訴此人犯下叛國罪。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_martial_law".into(),
        name: "戒嚴令".into(),
        description: "宣布戒嚴，本回合所有玩家無法使用攻擊卡。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "贏得 25 場對局".into(),
        flavor_text: "國王陛下以國家安全之名，暫停了所有議會辯論。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_revolution".into(),
        name: "革命號召".into(),
        description: "號召革命！對聲望最高的議員造成 35 點傷害，自己恢復 15 點。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "使用盧德派喬治贏得 5 場".into(),
        flavor_text: "「自由、平等、博愛！」——法國的風暴已經吹到了英吉利海峽這邊。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_political_assassination".into(),
        name: "政治暗殺".into(),
        description: "對目標發動致命攻擊，造成 40 點聲望傷害。使用後自己也失去 20 點。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "累計造成 500 點傷害".into(),
        flavor_text: "1812 年，首相斯賓塞·珀西瓦爾在議會大廳遇刺身亡。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_reform_act".into(),
        name: "改革法案".into(),
        description: "推動改革法案，所有聲望低於 30 的議員恢復至 30。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "使用所有角色各贏一場".into(),
        flavor_text: "改革的浪潮勢不可擋。問題只是時間。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_corn_law".into(),
        name: "穀物法".into(),
        description: "推動穀物法，使所有工人角色失去 15 點聲望，資方角色獲得 15 金幣。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "使用工廠主理查贏得 5 場".into(),
        flavor_text: "麵包的價格牽動著整個國家的命運。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_factory_act".into(),
        name: "工廠法".into(),
        description: "推動工廠法，使所有資方角色失去 15 金幣，工人角色恢復 15 點聲望。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "使用工人湯瑪斯贏得 5 場".into(),
        flavor_text: "「十歲的孩子不應該在工廠裡工作十六個小時。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_habeas_corpus".into(),
        name: "人身保護令".into(),
        description: "發動人身保護令，使一名被沉默的議員立即恢復行動能力並恢復 20 點聲望。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "累計成功防禦 20 次".into(),
        flavor_text: "「任何人不得被非法拘禁。」—— 英國法律的基石。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_no_confidence".into(),
        name: "不信任投票".into(),
        description: "發起不信任投票，若超過半數支持，目標直接政治死亡。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "連勝 5 場".into(),
        flavor_text: "「本院已對閣下失去信心。請您體面地離開。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_grand_coalition".into(),
        name: "大聯合".into(),
        description: "建立大聯合，與場上所有存活議員結成臨時聯盟，持續 1 回合。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "在對局中結盟 20 次".into(),
        flavor_text: "當國家面臨危機，所有黨派必須團結一心。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_espionage".into(),
        name: "間諜活動".into(),
        description: "查看所有對手的手牌，並可選擇棄掉其中一張。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "使用記者愛德華贏得 5 場".into(),
        flavor_text: "倫敦塔裡不僅關著囚犯，也藏著整個帝國的秘密。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_public_trial".into(),
        name: "公開審判".into(),
        description: "對目標進行公開審判，造成 20 點傷害。若目標本回合使用過攻擊卡，額外造成 20 點。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "累計造成 1000 點傷害".into(),
        flavor_text: "公義必須被看見。而且要讓所有人都看見。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_royal_decree".into(),
        name: "王室詔令".into(),
        description: "以國王之名頒布詔令，自己恢復 25 點聲望並獲得 25 金幣。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "ELO 達到 1200".into(),
        flavor_text: "「奉天承運，國王詔曰——」".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_blockade".into(),
        name: "封鎖".into(),
        description: "對目標實施封鎖，使其下 2 回合無法獲得金幣和抽牌。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "贏得 50 場對局".into(),
        flavor_text: "皇家海軍的炮口，就是最好的談判籌碼。".into(),
    });

    entries.push(CardCodexEntry {
        id: "rare_diplomatic_immunity".into(),
        name: "外交豁免".into(),
        description: "獲得外交豁免，接下來 2 回合內免疫所有傷害。".into(),
        card_type: CodexCardType::Defense,
        rarity: CodexRarity::Rare,
        character: None,
        unlock_condition: "ELO 達到 1300".into(),
        flavor_text: "「我代表的是另一個主權國家。你們的法律管不了我。」".into(),
    });

    // ═══════════════════════════════════════════
    // Legendary (6 張) — 角色專屬 + 傳說事件
    // ═══════════════════════════════════════════

    entries.push(CardCodexEntry {
        id: "thomas_unity".into(),
        name: "團結".into(),
        description: "每有 1 名工人盟友，你獲得的防禦效果 +10。".into(),
        card_type: CodexCardType::Signature,
        rarity: CodexRarity::Legendary,
        character: Some("工人湯瑪斯".into()),
        unlock_condition: "使用工人湯瑪斯贏得 10 場".into(),
        flavor_text: "「工人團結起來！我們除了鎖鏈，沒有什麼可以失去的。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "richard_bribe".into(),
        name: "收買".into(),
        description: "花費 30 金幣使目標沉默 1 回合，無法發言和使用攻擊卡。".into(),
        card_type: CodexCardType::Signature,
        rarity: CodexRarity::Legendary,
        character: Some("工廠主理查".into()),
        unlock_condition: "使用工廠主理查贏得 10 場".into(),
        flavor_text: "「每個人都有他的價格。我只是比較直接。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "edward_scoop".into(),
        name: "爆料".into(),
        description: "揭露目標的秘密任務。若目標有隱藏身份，公開之。".into(),
        card_type: CodexCardType::Signature,
        rarity: CodexRarity::Legendary,
        character: Some("記者愛德華".into()),
        unlock_condition: "使用記者愛德華贏得 10 場".into(),
        flavor_text: "「真相是記者的武器。而我從不缺少彈藥。」".into(),
    });

    entries.push(CardCodexEntry {
        id: "george_fury".into(),
        name: "怒火".into(),
        description: "造成雙倍傷害（30 點），但自己也扣 10 聲望。".into(),
        card_type: CodexCardType::Signature,
        rarity: CodexRarity::Legendary,
        character: Some("盧德派喬治".into()),
        unlock_condition: "使用盧德派喬治贏得 10 場".into(),
        flavor_text: "「他們毀了我們的生計。今晚，我們毀了他們的機器！」".into(),
    });

    entries.push(CardCodexEntry {
        id: "legendary_peterloo".into(),
        name: "彼得盧屠殺".into(),
        description: "重現彼得盧慘劇，對所有對手造成 25 點傷害，但自己也失去 15 點聲望。".into(),
        card_type: CodexCardType::Attack,
        rarity: CodexRarity::Legendary,
        character: None,
        unlock_condition: "收集所有基礎卡牌".into(),
        flavor_text: "1819 年 8 月 16 日，曼徹斯特聖彼得廣場。騎兵衝進了和平集會的人群。".into(),
    });

    entries.push(CardCodexEntry {
        id: "legendary_magna_carta".into(),
        name: "大憲章精神".into(),
        description: "援引大憲章精神，所有議員恢復 20 點聲望，移除所有負面效果。".into(),
        card_type: CodexCardType::Utility,
        rarity: CodexRarity::Legendary,
        character: None,
        unlock_condition: "登上排行榜前 10 名".into(),
        flavor_text: "「任何自由人，非經合法審判，不得被逮捕、監禁或流放。」—— 1215 年".into(),
    });

    assert_eq!(entries.len(), 56, "卡牌圖鑑應有 56 張卡牌");
    entries
}

/// 根據 ID 取得圖鑑條目
pub fn get_codex_entry(card_id: &str) -> Option<CardCodexEntry> {
    get_all_codex_entries().into_iter().find(|e| e.id == card_id)
}

/// 取得各稀有度數量統計
pub fn get_rarity_counts() -> (usize, usize, usize, usize) {
    let entries = get_all_codex_entries();
    let common = entries.iter().filter(|e| e.rarity == CodexRarity::Common).count();
    let uncommon = entries.iter().filter(|e| e.rarity == CodexRarity::Uncommon).count();
    let rare = entries.iter().filter(|e| e.rarity == CodexRarity::Rare).count();
    let legendary = entries.iter().filter(|e| e.rarity == CodexRarity::Legendary).count();
    (common, uncommon, rare, legendary)
}

/// 取得所有卡牌 ID 列表
pub fn get_all_card_ids() -> Vec<String> {
    get_all_codex_entries().into_iter().map(|e| e.id).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_codex_has_56_cards() {
        let entries = get_all_codex_entries();
        assert_eq!(entries.len(), 56);
    }

    #[test]
    fn test_rarity_distribution() {
        let (common, uncommon, rare, legendary) = get_rarity_counts();
        assert_eq!(common, 20, "Common 應有 20 張");
        assert_eq!(uncommon, 15, "Uncommon 應有 15 張");
        assert_eq!(rare, 15, "Rare 應有 15 張");
        assert_eq!(legendary, 6, "Legendary 應有 6 張");
    }

    #[test]
    fn test_unique_ids() {
        let entries = get_all_codex_entries();
        let mut ids: Vec<&str> = entries.iter().map(|e| e.id.as_str()).collect();
        ids.sort();
        ids.dedup();
        assert_eq!(ids.len(), 56, "所有卡牌 ID 應該唯一");
    }

    #[test]
    fn test_get_codex_entry() {
        let entry = get_codex_entry("common_interrogate");
        assert!(entry.is_some());
        assert_eq!(entry.unwrap().name, "質詢");
    }

    #[test]
    fn test_signature_cards_have_character() {
        let entries = get_all_codex_entries();
        for entry in &entries {
            if entry.card_type == CodexCardType::Signature {
                assert!(entry.character.is_some(), "專屬卡 {} 應有關聯角色", entry.id);
            }
        }
    }

    #[test]
    fn test_existing_game_cards_in_codex() {
        // 確認現有遊戲卡牌都在圖鑑中
        let existing_ids = [
            "common_interrogate",
            "common_rebut",
            "common_expose_scandal",
            "common_endorse",
            "thomas_unity",
            "richard_bribe",
            "edward_scoop",
            "george_fury",
        ];
        for id in &existing_ids {
            assert!(
                get_codex_entry(id).is_some(),
                "現有遊戲卡 {} 應在圖鑑中",
                id
            );
        }
    }
}
