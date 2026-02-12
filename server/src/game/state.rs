//! 遊戲狀態
//!
//! 定義遊戲進行中的狀態結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use super::actions::GameAction;
use crate::domain::card::{GameCard, PlayerHand};
use crate::domain::{CharacterType, GamePhase, VoteChoice};

/// 遊戲狀態
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EngineState {
    /// 房間代碼
    pub room_code: String,
    /// 當前遊戲階段
    pub phase: GamePhase,
    /// 階段開始時間
    pub phase_start_time: DateTime<Utc>,
    /// 當前回合
    pub current_round: i32,
    /// 當前議案名稱
    pub current_bill: String,
    /// 玩家狀態
    pub players: HashMap<Uuid, PlayerState>,
    /// 投票記錄（玩家 ID -> 投票選擇）
    pub votes: HashMap<Uuid, VoteChoice>,
    /// 結盟關係（玩家 A, 玩家 B）
    pub alliances: Vec<(Uuid, Uuid)>,
    /// 行動日誌
    pub action_log: Vec<GameAction>,
    /// 待處理的質詢
    pub pending_challenge: Option<PendingChallenge>,
    /// 公共卡牌池
    pub card_pool: Vec<GameCard>,
    /// 棄牌堆
    pub discard_pile: Vec<GameCard>,
}

/// 待處理的質詢
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PendingChallenge {
    /// 攻擊者 ID
    pub attacker_id: Uuid,
    /// 目標 ID
    pub target_id: Uuid,
    /// 傷害值
    pub damage: i32,
    /// 發起時間
    pub timestamp: DateTime<Utc>,
}

impl EngineState {
    /// 建立新的遊戲狀態
    pub fn new(room_code: String, players: Vec<PlayerState>) -> Self {
        let player_map: HashMap<Uuid, PlayerState> =
            players.into_iter().map(|p| (p.id, p)).collect();

        Self {
            room_code,
            phase: GamePhase::Waiting,
            phase_start_time: Utc::now(),
            current_round: 0,
            current_bill: "等待中".to_string(),
            players: player_map,
            votes: HashMap::new(),
            alliances: Vec::new(),
            action_log: Vec::new(),
            pending_challenge: None,
            card_pool: Vec::new(),
            discard_pile: Vec::new(),
        }
    }

    /// 取得玩家狀態
    pub fn get_player(&self, player_id: Uuid) -> Option<&PlayerState> {
        self.players.get(&player_id)
    }

    /// 取得可變玩家狀態
    pub fn get_player_mut(&mut self, player_id: Uuid) -> Option<&mut PlayerState> {
        self.players.get_mut(&player_id)
    }

    /// 取得存活玩家
    pub fn alive_players(&self) -> Vec<&PlayerState> {
        self.players
            .values()
            .filter(|p| !p.is_politically_dead)
            .collect()
    }

    /// 取得存活玩家數量
    pub fn alive_player_count(&self) -> usize {
        self.players
            .values()
            .filter(|p| !p.is_politically_dead)
            .count()
    }

    /// 檢查是否為盟友
    pub fn are_allies(&self, player_a: Uuid, player_b: Uuid) -> bool {
        self.alliances
            .iter()
            .any(|(a, b)| (*a == player_a && *b == player_b) || (*a == player_b && *b == player_a))
    }

    /// 取得玩家的盟友
    pub fn get_allies(&self, player_id: Uuid) -> Vec<Uuid> {
        self.alliances
            .iter()
            .filter_map(|(a, b)| {
                if *a == player_id {
                    Some(*b)
                } else if *b == player_id {
                    Some(*a)
                } else {
                    None
                }
            })
            .collect()
    }

    /// 建立聯盟
    pub fn form_alliance(&mut self, player_a: Uuid, player_b: Uuid) -> bool {
        if self.are_allies(player_a, player_b) {
            return false;
        }
        self.alliances.push((player_a, player_b));
        true
    }

    /// 解除聯盟
    pub fn break_alliance(&mut self, player_a: Uuid, player_b: Uuid) -> bool {
        let len_before = self.alliances.len();
        self.alliances.retain(|(a, b)| {
            !((*a == player_a && *b == player_b) || (*a == player_b && *b == player_a))
        });
        self.alliances.len() != len_before
    }

    /// 檢查遊戲是否結束
    pub fn is_game_over(&self) -> bool {
        self.alive_player_count() <= 1 || self.phase == GamePhase::Finished
    }

    /// 結束遊戲
    pub fn finish_game(&mut self) {
        self.phase = GamePhase::Finished;
    }

    /// 初始化卡牌池
    pub fn initialize_card_pool(&mut self) {
        use super::cards::get_common_cards;
        self.card_pool = get_common_cards();
        // 洗牌
        use rand::seq::SliceRandom;
        let mut rng = rand::thread_rng();
        self.card_pool.shuffle(&mut rng);
    }

    /// 從卡牌池抽取卡牌
    pub fn draw_card_from_pool(&mut self) -> Option<GameCard> {
        if self.card_pool.is_empty() {
            // 如果卡牌池空了，將棄牌堆洗牌後重新加入
            if !self.discard_pile.is_empty() {
                self.card_pool.append(&mut self.discard_pile);
                use rand::seq::SliceRandom;
                let mut rng = rand::thread_rng();
                self.card_pool.shuffle(&mut rng);
            }
        }
        self.card_pool.pop()
    }

    /// 將卡牌加入棄牌堆
    pub fn discard_card(&mut self, card: GameCard) {
        self.discard_pile.push(card);
    }
}

/// 玩家狀態
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerState {
    /// 玩家 ID
    pub id: Uuid,
    /// 玩家名稱
    pub name: String,
    /// 角色類型
    pub character: CharacterType,
    /// 聲望值
    pub reputation: i32,
    /// 金幣
    pub gold: i32,
    /// 手牌
    pub hand: PlayerHand,
    /// 影響力
    pub influence: i32,
    /// 是否政治死亡
    pub is_politically_dead: bool,
    /// 是否已使用技能
    pub has_used_skill: bool,
    /// 是否被沉默
    pub is_silenced: bool,
}

impl PlayerState {
    /// 建立新的玩家狀態
    pub fn new(id: Uuid, name: String, character: CharacterType) -> Self {
        let reputation = character.initial_reputation();
        let gold = character.initial_gold();

        Self {
            id,
            name,
            character,
            reputation,
            gold,
            hand: PlayerHand::new(),
            influence: 10, // 初始影響力
            is_politically_dead: false,
            has_used_skill: false,
            is_silenced: false,
        }
    }

    /// 受到傷害
    pub fn take_damage(&mut self, damage: i32) -> i32 {
        let actual_damage = damage.min(self.reputation);
        self.reputation -= actual_damage;

        if self.reputation <= 0 {
            self.reputation = 0;
            self.is_politically_dead = true;
        }

        actual_damage
    }

    /// 恢復聲望
    pub fn heal(&mut self, amount: i32) {
        self.reputation += amount;
        // 最高 100 聲望
        self.reputation = self.reputation.min(100);
    }

    /// 計算投票權重
    pub fn vote_weight(&self) -> i32 {
        if self.is_politically_dead {
            0
        } else {
            // 每 10 聲望 = 1 票權重
            (self.reputation / 10).max(1)
        }
    }

    /// 花費金幣
    pub fn spend_gold(&mut self, amount: i32) -> bool {
        if self.gold >= amount {
            self.gold -= amount;
            true
        } else {
            false
        }
    }

    /// 獲得金幣
    pub fn earn_gold(&mut self, amount: i32) {
        self.gold += amount;
    }

    /// 沉默玩家
    pub fn silence(&mut self) {
        self.is_silenced = true;
    }

    /// 標記已使用技能
    pub fn mark_skill_used(&mut self) {
        self.has_used_skill = true;
    }

    /// 檢查是否可以行動
    pub fn can_act(&self) -> bool {
        !self.is_politically_dead && !self.is_silenced
    }

    /// 檢查是否可以使用技能
    pub fn can_use_skill(&self) -> bool {
        self.can_act() && !self.has_used_skill
    }

    /// 檢查是否有足夠的影響力
    pub fn has_influence(&self, cost: i32) -> bool {
        self.influence >= cost
    }

    /// 消耗影響力
    pub fn spend_influence(&mut self, cost: i32) -> bool {
        if self.has_influence(cost) {
            self.influence -= cost;
            true
        } else {
            false
        }
    }

    /// 恢復影響力（回合結束時）
    pub fn restore_influence(&mut self, amount: i32) {
        self.influence += amount;
        self.influence = self.influence.min(15); // 最大影響力
    }

    /// 添加卡牌到手牌
    pub fn add_card_to_hand(&mut self, card: crate::domain::card::GameCard) -> bool {
        self.hand.add_card(card)
    }

    /// 從手牌移除卡牌
    pub fn remove_card_from_hand(
        &mut self,
        card_id: &str,
    ) -> Option<crate::domain::card::GameCard> {
        self.hand.remove_card(card_id)
    }

    /// 檢查手牌中是否有指定卡牌
    pub fn has_card(&self, card_id: &str) -> bool {
        self.hand.cards.iter().any(|c| c.id == card_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_players() -> Vec<PlayerState> {
        vec![
            PlayerState::new(Uuid::new_v4(), "Thomas".to_string(), CharacterType::Thomas),
            PlayerState::new(
                Uuid::new_v4(),
                "Richard".to_string(),
                CharacterType::Richard,
            ),
            PlayerState::new(Uuid::new_v4(), "Edward".to_string(), CharacterType::Edward),
            PlayerState::new(Uuid::new_v4(), "George".to_string(), CharacterType::George),
        ]
    }

    #[test]
    fn test_game_state_creation() {
        let players = create_test_players();
        let state = EngineState::new("ABC123".to_string(), players);

        assert_eq!(state.room_code, "ABC123");
        assert_eq!(state.phase, GamePhase::Waiting);
        assert_eq!(state.current_round, 0);
        assert_eq!(state.players.len(), 4);
    }

    #[test]
    fn test_player_damage() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::Thomas);
        let initial_rep = player.reputation;

        let damage = player.take_damage(20);
        assert_eq!(damage, 20);
        assert_eq!(player.reputation, initial_rep - 20);
        assert!(!player.is_politically_dead);
    }

    #[test]
    fn test_player_political_death() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::Edward);

        // Edward starts with 50 reputation
        player.take_damage(60);
        assert_eq!(player.reputation, 0);
        assert!(player.is_politically_dead);
    }

    #[test]
    fn test_alliance() {
        let players = create_test_players();
        let mut state = EngineState::new("ABC123".to_string(), players);

        let player_ids: Vec<Uuid> = state.players.keys().cloned().collect();
        let player_a = player_ids[0];
        let player_b = player_ids[1];

        assert!(!state.are_allies(player_a, player_b));

        state.form_alliance(player_a, player_b);
        assert!(state.are_allies(player_a, player_b));

        let allies = state.get_allies(player_a);
        assert_eq!(allies.len(), 1);
        assert_eq!(allies[0], player_b);

        state.break_alliance(player_a, player_b);
        assert!(!state.are_allies(player_a, player_b));
    }

    #[test]
    fn test_vote_weight() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::George);

        // George starts with 80 reputation -> 8 votes
        assert_eq!(player.vote_weight(), 8);

        player.take_damage(30);
        // Now 50 reputation -> 5 votes
        assert_eq!(player.vote_weight(), 5);

        // Political death -> 0 votes
        player.take_damage(50);
        assert_eq!(player.vote_weight(), 0);
    }

    #[test]
    fn test_player_gold() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::Richard);

        // Richard starts with 30 gold
        assert_eq!(player.gold, 30);

        // Spend 20 gold
        assert!(player.spend_gold(20));
        assert_eq!(player.gold, 10);

        // Try to spend more than available
        assert!(!player.spend_gold(20));
        assert_eq!(player.gold, 10);

        // Earn gold
        player.earn_gold(15);
        assert_eq!(player.gold, 25);
    }

    #[test]
    fn test_player_silence() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::Thomas);

        assert!(player.can_act());
        assert!(player.can_use_skill());

        player.silence();
        assert!(!player.can_act());
        assert!(!player.can_use_skill());
    }

    #[test]
    fn test_skill_usage() {
        let mut player =
            PlayerState::new(Uuid::new_v4(), "Test".to_string(), CharacterType::Edward);

        assert!(player.can_use_skill());

        player.mark_skill_used();
        assert!(!player.can_use_skill());
        assert!(player.can_act()); // Still can act, just not use skill
    }
}
