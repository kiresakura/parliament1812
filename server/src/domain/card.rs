//! 卡牌領域模型
//!
//! 定義卡牌相關的資料結構 - MVP Version

use serde::{Deserialize, Serialize};

/// 卡牌類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CardType {
    /// 攻擊卡
    Attack,
    /// 防禦卡
    Defense,
    /// 功能卡
    Utility,
    /// 角色專屬卡
    Signature,
}

/// 卡牌稀有度（遊戲內機制用）
///
/// 用於遊戲對局中的卡牌效果分級（Normal / Rare / SuperRare / Legendary）。
/// 注意：與 `CodexRarity`（圖鑑收藏用）是不同概念。
/// - `CardRarity` → 對局卡牌的強度分級（N / R / SR / SSR）
/// - `CodexRarity` → 圖鑑收藏品的稀有度分級（Common / Uncommon / Rare / Legendary）
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CardRarity {
    /// 普通 (N)
    Normal,
    /// 稀有 (R)
    Rare,
    /// 超稀有 (SR)
    SuperRare,
    /// 傳說 (SSR)
    Legendary,
}

/// 目標類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TargetType {
    /// 自己
    #[serde(rename = "self")]
    SelfTarget,
    /// 單一敵人
    SingleEnemy,
    /// 單一盟友
    SingleAlly,
    /// 任意單一玩家
    SingleAny,
    /// 所有敵人
    AllEnemies,
    /// 所有玩家
    AllPlayers,
    /// 無目標
    None,
}

/// 遊戲卡牌
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameCard {
    /// 卡牌唯一識別碼
    pub id: String,
    /// 卡牌名稱
    pub name: String,
    /// 卡牌描述
    pub description: String,
    /// 卡牌類型
    pub card_type: CardType,
    /// 稀有度
    pub rarity: CardRarity,
    /// 目標類型
    pub target_type: TargetType,
    /// 影響力消耗
    pub influence_cost: i32,
    /// 金幣消耗
    pub gold_cost: i32,
    /// 基礎傷害/效果值
    pub base_value: i32,
    /// 所屬角色 ID（專屬卡才有）
    pub role_id: Option<String>,
}

impl GameCard {
    /// 是否為攻擊卡
    pub fn is_attack(&self) -> bool {
        matches!(self.card_type, CardType::Attack)
    }

    /// 是否為防禦卡
    pub fn is_defense(&self) -> bool {
        matches!(self.card_type, CardType::Defense)
    }

    /// 是否需要選擇目標
    pub fn requires_target(&self) -> bool {
        matches!(
            self.target_type,
            TargetType::SingleEnemy | TargetType::SingleAlly | TargetType::SingleAny
        )
    }
}

/// 玩家手牌
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PlayerHand {
    /// 持有的卡牌
    pub cards: Vec<GameCard>,
    /// 手牌上限
    pub max_cards: usize,
}

impl PlayerHand {
    pub fn new() -> Self {
        Self {
            cards: Vec::new(),
            max_cards: 10,
        }
    }

    /// 手牌數量
    pub fn count(&self) -> usize {
        self.cards.len()
    }

    /// 是否已滿
    pub fn is_full(&self) -> bool {
        self.count() >= self.max_cards
    }

    /// 添加卡牌
    pub fn add_card(&mut self, card: GameCard) -> bool {
        if self.is_full() {
            return false;
        }
        self.cards.push(card);
        true
    }

    /// 移除卡牌
    pub fn remove_card(&mut self, card_id: &str) -> Option<GameCard> {
        if let Some(pos) = self.cards.iter().position(|c| c.id == card_id) {
            Some(self.cards.remove(pos))
        } else {
            None
        }
    }
}

/// 玩家資源
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerResources {
    /// 聲望（生命值）
    pub reputation: i32,
    /// 聲望上限
    pub max_reputation: i32,
    /// 影響力
    pub influence: i32,
    /// 影響力上限
    pub max_influence: i32,
    /// 金幣
    pub gold: i32,
    /// 金幣上限
    pub max_gold: i32,
    /// 防禦值
    pub defense: i32,
}

impl Default for PlayerResources {
    fn default() -> Self {
        Self {
            reputation: 50,
            max_reputation: 100,
            influence: 10,
            max_influence: 15,
            gold: 0,
            max_gold: 150,
            defense: 0,
        }
    }
}

impl PlayerResources {
    /// 根據角色建立初始資源
    pub fn for_role(role_id: &str) -> Self {
        match role_id {
            "thomas" => Self {
                reputation: 70,
                gold: 10,
                ..Default::default()
            },
            "richard" => Self {
                reputation: 60,
                gold: 100,
                ..Default::default()
            },
            "edward" => Self {
                reputation: 50,
                gold: 30,
                ..Default::default()
            },
            "george" => Self {
                reputation: 80,
                gold: 5,
                ..Default::default()
            },
            _ => Self::default(),
        }
    }

    /// 是否政治死亡
    pub fn is_politically_dead(&self) -> bool {
        self.reputation <= 0
    }

    /// 是否有足夠影響力
    pub fn has_influence(&self, cost: i32) -> bool {
        self.influence >= cost
    }

    /// 是否有足夠金幣
    pub fn has_gold(&self, cost: i32) -> bool {
        self.gold >= cost
    }

    /// 消耗影響力
    pub fn spend_influence(&mut self, cost: i32) {
        self.influence = (self.influence - cost).max(0);
    }

    /// 消耗金幣
    pub fn spend_gold(&mut self, cost: i32) {
        self.gold = (self.gold - cost).max(0);
    }

    /// 受到傷害
    pub fn take_damage(&mut self, damage: i32) {
        let reduction = self.defense as f32 / 200.0;
        let actual_damage = (damage as f32 * (1.0 - reduction)).ceil() as i32;
        self.reputation = (self.reputation - actual_damage).max(0);
    }

    /// 恢復聲望
    pub fn heal(&mut self, amount: i32) {
        self.reputation = (self.reputation + amount).min(self.max_reputation);
    }

    /// 回合結束回復
    pub fn on_turn_end(&mut self) {
        self.influence = (self.influence + 3).min(self.max_influence);
        self.defense = 0;
    }

    /// 投票權重
    pub fn vote_weight(&self) -> f32 {
        if self.is_politically_dead() {
            return 0.0;
        }
        if self.reputation > 80 {
            1.5
        } else if self.reputation >= 50 {
            1.0
        } else if self.reputation >= 30 {
            0.7
        } else {
            0.5
        }
    }
}

/// 卡牌使用請求
#[derive(Debug, Clone, Deserialize)]
pub struct UseCardRequest {
    /// 卡牌 ID
    pub card_id: String,
    /// 目標玩家 ID（如果需要）
    pub target_id: Option<String>,
}

/// 卡牌使用結果
#[derive(Debug, Clone, Serialize)]
pub struct UseCardResult {
    /// 是否成功
    pub success: bool,
    /// 錯誤訊息
    pub error: Option<String>,
    /// 造成的傷害
    pub damage_dealt: i32,
    /// 恢復的聲望
    pub healing_done: i32,
    /// 使用的卡牌
    pub card_used: Option<GameCard>,
}

impl UseCardResult {
    pub fn success(card: GameCard, damage: i32, healing: i32) -> Self {
        Self {
            success: true,
            error: None,
            damage_dealt: damage,
            healing_done: healing,
            card_used: Some(card),
        }
    }

    pub fn failed(error: &str) -> Self {
        Self {
            success: false,
            error: Some(error.to_string()),
            damage_dealt: 0,
            healing_done: 0,
            card_used: None,
        }
    }
}
