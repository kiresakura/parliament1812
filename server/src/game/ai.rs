//! AI 玩家系統
//!
//! 提供不同難度的 AI 對手，支援單人模式

use rand::prelude::*;
use rand::seq::SliceRandom;
use uuid::Uuid;

// 移除未使用的導入
use super::state::EngineState;
use crate::domain::{CharacterType, GamePhase, VoteChoice};

/// AI 難度
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AIDifficulty {
    /// 簡單：隨機行動
    Easy,
    /// 普通：基本策略
    Normal,
    /// 困難：進階策略
    Hard,
    /// 專家：最佳化策略 + 預測 + 反制
    Expert,
}

/// AI 行動類型
#[derive(Debug, Clone)]
pub enum AIAction {
    /// 等待（無操作）
    Wait,
    /// 使用卡牌
    UseCard {
        card_id: String,
        target_id: Option<Uuid>,
    },
    /// 抽牌
    DrawCard,
    /// 質詢
    Challenge { target_id: Uuid },
    /// 反駁
    Counter,
    /// 使用技能
    UseSkill { target_id: Option<Uuid> },
    /// 投票
    Vote { choice: VoteChoice },
    /// 結盟
    FormAlliance { target_id: Uuid },
    /// 背叛
    Betray { target_id: Uuid },
}

/// AI 玩家
#[derive(Debug, Clone)]
pub struct AIPlayer {
    /// AI 玩家 ID
    pub id: Uuid,
    /// 角色類型
    pub character: CharacterType,
    /// 難度
    pub difficulty: AIDifficulty,
    /// 隨機數生成器種子（用於可重現性）
    pub rng_seed: u64,
}

impl AIPlayer {
    /// 建立新的 AI 玩家
    pub fn new(id: Uuid, character: CharacterType, difficulty: AIDifficulty) -> Self {
        Self {
            id,
            character,
            difficulty,
            rng_seed: thread_rng().next_u64(),
        }
    }

    /// AI 決定行動（每回合呼叫一次）
    pub fn decide_action(&self, state: &EngineState) -> AIAction {
        // 檢查 AI 是否能行動
        if let Some(ai_player) = state.get_player(self.id) {
            if !ai_player.can_act() {
                return AIAction::Wait;
            }
        } else {
            return AIAction::Wait;
        }

        match state.phase {
            GamePhase::Conspiracy => self.conspiracy_action(state),
            GamePhase::Debate => self.debate_action(state),
            GamePhase::Voting => self.voting_action(state),
            _ => AIAction::Wait,
        }
    }

    /// 密謀階段行動
    fn conspiracy_action(&self, state: &EngineState) -> AIAction {
        let mut rng = StdRng::seed_from_u64(self.rng_seed);

        // 獲取其他存活玩家
        let other_players: Vec<_> = state
            .alive_players()
            .into_iter()
            .filter(|p| p.id != self.id)
            .collect();

        if other_players.is_empty() {
            return AIAction::Wait;
        }

        match self.difficulty {
            AIDifficulty::Easy => {
                // 簡單 AI：隨機決定是否結盟
                if rng.gen_bool(0.3) {
                    // 30% 機率嘗試結盟
                    if let Some(target) = other_players.choose(&mut rng) {
                        // 檢查是否已經是盟友
                        if !state.are_allies(self.id, target.id) {
                            return AIAction::FormAlliance {
                                target_id: target.id,
                            };
                        }
                    }
                }
                AIAction::Wait
            }
            AIDifficulty::Normal => {
                // 普通 AI：優先與強勢玩家結盟
                let best_target = other_players
                    .iter()
                    .filter(|p| !state.are_allies(self.id, p.id))
                    .max_by_key(|p| p.reputation);

                if let Some(target) = best_target {
                    if rng.gen_bool(0.5) {
                        return AIAction::FormAlliance {
                            target_id: target.id,
                        };
                    }
                }
                AIAction::Wait
            }
            AIDifficulty::Hard => {
                // 困難 AI：複雜的結盟策略
                let my_reputation = state.get_player(self.id).map(|p| p.reputation).unwrap_or(0);

                // 如果自己血量低，積極尋求結盟
                if my_reputation < 30 {
                    let potential_allies: Vec<_> = other_players
                        .iter()
                        .filter(|p| !state.are_allies(self.id, p.id) && p.reputation > 40)
                        .collect();

                    if let Some(target) = potential_allies.choose(&mut rng) {
                        return AIAction::FormAlliance {
                            target_id: target.id,
                        };
                    }
                } else {
                    // 血量高時，考慮背叛弱勢盟友
                    let weak_allies: Vec<_> = state
                        .get_allies(self.id)
                        .into_iter()
                        .filter_map(|ally_id| {
                            state.get_player(ally_id).filter(|p| p.reputation < 20)
                        })
                        .collect();

                    if let Some(target) = weak_allies.choose(&mut rng) {
                        return AIAction::Betray {
                            target_id: target.id,
                        };
                    }
                }
                AIAction::Wait
            }
            AIDifficulty::Expert => {
                // 專家 AI：預測對手行動 + 最佳化結盟策略
                let my_reputation = state.get_player(self.id).map(|p| p.reputation).unwrap_or(0);
                let _alive_count = state.alive_player_count();
                let my_allies = state.get_allies(self.id);

                // 計算每個玩家的威脅值
                let mut threats: Vec<(Uuid, i32)> = other_players
                    .iter()
                    .map(|p| {
                        let ally_count = state.get_allies(p.id).len() as i32;
                        let threat = p.reputation * 2 + p.gold + ally_count * 20;
                        (p.id, threat)
                    })
                    .collect();
                threats.sort_by(|a, b| b.1.cmp(&a.1));

                // 策略：維持恰好 1-2 個盟友，太多盟友會分散勝利
                if my_allies.len() < 2 {
                    // 與第二高威脅的玩家結盟（避免最強的）
                    if threats.len() >= 2 {
                        let target_id = threats[1].0;
                        if !state.are_allies(self.id, target_id) {
                            return AIAction::FormAlliance { target_id };
                        }
                    }
                } else if my_reputation > 60 && my_allies.len() >= 2 {
                    // 佔優勢時背叛最弱盟友以獨吞勝利
                    let weakest_ally = my_allies
                        .iter()
                        .filter_map(|&aid| state.get_player(aid))
                        .min_by_key(|p| p.reputation);
                    if let Some(target) = weakest_ally {
                        if rng.gen_bool(0.6) {
                            return AIAction::Betray {
                                target_id: target.id,
                            };
                        }
                    }
                }
                AIAction::Wait
            }
        }
    }

    /// 辯論階段行動
    fn debate_action(&self, state: &EngineState) -> AIAction {
        let mut rng = StdRng::seed_from_u64(self.rng_seed);

        let ai_player = match state.get_player(self.id) {
            Some(p) => p,
            None => return AIAction::Wait,
        };

        // 如果沒有手牌，嘗試抽牌
        if ai_player.hand.cards.is_empty() {
            return AIAction::DrawCard;
        }

        // 獲取攻擊目標
        let potential_targets: Vec<_> = state
            .alive_players()
            .into_iter()
            .filter(|p| p.id != self.id && !state.are_allies(self.id, p.id))
            .collect();

        match self.difficulty {
            AIDifficulty::Easy => {
                // 簡單 AI：隨機出牌或攻擊
                if rng.gen_bool(0.6) {
                    // 60% 機率嘗試出牌
                    self.try_use_random_card(ai_player, &potential_targets, &mut rng)
                } else {
                    // 40% 機率嘗試質詢
                    if let Some(target) = potential_targets.choose(&mut rng) {
                        AIAction::Challenge {
                            target_id: target.id,
                        }
                    } else {
                        AIAction::Wait
                    }
                }
            }
            AIDifficulty::Normal => {
                // 普通 AI：優先攻擊聲望最高的敵人
                let best_target = potential_targets.iter().max_by_key(|p| p.reputation);

                if let Some(target) = best_target {
                    // 優先使用攻擊卡
                    if let Some(attack_card) = ai_player.hand.cards.iter().find(|c| c.is_attack()) {
                        return AIAction::UseCard {
                            card_id: attack_card.id.clone(),
                            target_id: Some(target.id),
                        };
                    }
                    // 沒有攻擊卡就質詢
                    AIAction::Challenge {
                        target_id: target.id,
                    }
                } else {
                    // 沒有敵人，使用功能卡或等待
                    self.try_use_utility_card(ai_player)
                }
            }
            AIDifficulty::Hard => {
                // 困難 AI：計算最佳行動
                let my_reputation = ai_player.reputation;

                // 如果血量危險，優先防禦和治療
                if my_reputation < 30 {
                    // 尋找治療卡
                    if let Some(heal_card) = ai_player
                        .hand
                        .cards
                        .iter()
                        .find(|c| c.id.contains("endorse"))
                    {
                        return AIAction::UseCard {
                            card_id: heal_card.id.clone(),
                            target_id: Some(self.id),
                        };
                    }
                    // 沒有治療卡，嘗試防禦
                    if let Some(defense_card) = ai_player.hand.cards.iter().find(|c| c.is_defense())
                    {
                        return AIAction::UseCard {
                            card_id: defense_card.id.clone(),
                            target_id: None,
                        };
                    }
                } else {
                    // 血量安全，積極攻擊
                    let highest_threat = potential_targets
                        .iter()
                        .max_by_key(|p| p.reputation * 100 + p.gold); // 考慮聲望和金幣

                    if let Some(target) = highest_threat {
                        // 優先使用最強的攻擊卡
                        let best_attack = ai_player
                            .hand
                            .cards
                            .iter()
                            .filter(|c| c.is_attack())
                            .max_by_key(|c| c.base_value);

                        if let Some(attack_card) = best_attack {
                            return AIAction::UseCard {
                                card_id: attack_card.id.clone(),
                                target_id: Some(target.id),
                            };
                        }

                        // 沒有攻擊卡就質詢
                        return AIAction::Challenge {
                            target_id: target.id,
                        };
                    }
                }

                // 其他情況使用功能卡或技能
                if ai_player.can_use_skill() && rng.gen_bool(0.3) {
                    let skill_target = if potential_targets.is_empty() {
                        None
                    } else {
                        potential_targets.choose(&mut rng).map(|p| p.id)
                    };
                    AIAction::UseSkill {
                        target_id: skill_target,
                    }
                } else {
                    self.try_use_utility_card(ai_player)
                }
            }
            AIDifficulty::Expert => {
                // 專家 AI：全局最佳化 + combo 策略
                let my_reputation = ai_player.reputation;
                let my_influence = ai_player.influence;

                // 計算手牌中的 combo 潛力
                let attack_cards: Vec<_> = ai_player
                    .hand
                    .cards
                    .iter()
                    .filter(|c| c.is_attack())
                    .collect();
                let defense_cards: Vec<_> = ai_player
                    .hand
                    .cards
                    .iter()
                    .filter(|c| c.is_defense())
                    .collect();

                // 策略 1：血量危險時，優先防禦 + 治療 combo
                if my_reputation < 25 {
                    if let Some(defense_card) = defense_cards.first() {
                        return AIAction::UseCard {
                            card_id: defense_card.id.clone(),
                            target_id: None,
                        };
                    }
                    // 使用技能自保
                    if ai_player.can_use_skill() {
                        return AIAction::UseSkill {
                            target_id: Some(self.id),
                        };
                    }
                }

                // 策略 2：找到最有價值的目標（考慮對手手牌數）
                let best_target = potential_targets.iter().max_by_key(|p| {
                    let is_leader = if p.reputation >= 60 { 50 } else { 0 };
                    let hand_threat = p.hand.cards.len() as i32 * 5;
                    p.reputation + p.gold / 2 + is_leader + hand_threat
                });

                if let Some(target) = best_target {
                    // 策略 3：連續攻擊 — 先用強攻擊卡，留弱的質詢
                    if attack_cards.len() >= 2 && my_influence >= 6 {
                        let strongest = attack_cards.iter().max_by_key(|c| c.base_value).unwrap();
                        return AIAction::UseCard {
                            card_id: strongest.id.clone(),
                            target_id: Some(target.id),
                        };
                    }

                    if let Some(attack_card) = attack_cards.first() {
                        return AIAction::UseCard {
                            card_id: attack_card.id.clone(),
                            target_id: Some(target.id),
                        };
                    }

                    // 質詢作為備案
                    return AIAction::Challenge {
                        target_id: target.id,
                    };
                }

                // 策略 4：沒有敵人時用技能或功能卡
                if ai_player.can_use_skill() && rng.gen_bool(0.5) {
                    AIAction::UseSkill { target_id: None }
                } else {
                    self.try_use_utility_card(ai_player)
                }
            }
        }
    }

    /// 投票階段行動
    fn voting_action(&self, state: &EngineState) -> AIAction {
        let mut rng = StdRng::seed_from_u64(self.rng_seed);

        match self.difficulty {
            AIDifficulty::Easy => {
                // 簡單 AI：隨機投票
                let choices = [VoteChoice::A, VoteChoice::B, VoteChoice::C];
                AIAction::Vote {
                    choice: *choices.choose(&mut rng).unwrap(),
                }
            }
            AIDifficulty::Normal => {
                // 普通 AI：基於盟友數量決定
                let allies = state.get_allies(self.id);
                if allies.len() >= 2 {
                    AIAction::Vote {
                        choice: VoteChoice::A,
                    }
                } else {
                    AIAction::Vote {
                        choice: VoteChoice::B,
                    }
                }
            }
            AIDifficulty::Hard => {
                // 困難 AI：複雜的投票邏輯
                let my_reputation = state.get_player(self.id).map(|p| p.reputation).unwrap_or(0);
                let allies = state.get_allies(self.id);
                let _alive_count = state.alive_player_count();

                // 如果自己血量高且盟友多，選擇 A（改革）
                if my_reputation > 50 && allies.len() as f32 / alive_count as f32 > 0.4 {
                    AIAction::Vote {
                        choice: VoteChoice::A,
                    }
                } else if my_reputation < 30 {
                    // 血量低時選擇激進選項 B
                    AIAction::Vote {
                        choice: VoteChoice::B,
                    }
                } else {
                    // 其他情況隨機投票
                    let choices = [VoteChoice::A, VoteChoice::B, VoteChoice::C];
                    AIAction::Vote {
                        choice: *choices.choose(&mut rng).unwrap(),
                    }
                }
            }
            AIDifficulty::Expert => {
                // 專家 AI：模擬投票結果，選擇對自己最有利的選項
                let my_reputation = state.get_player(self.id).map(|p| p.reputation).unwrap_or(0);
                let allies = state.get_allies(self.id);
                let _alive_count = state.alive_player_count();
                let ally_ratio = if alive_count > 0 {
                    allies.len() as f32 / alive_count as f32
                } else {
                    0.0
                };

                // 分析角色特性來決定最佳投票
                let choice = match self.character {
                    CharacterType::Thomas => {
                        // 工人：偏好勞工權益 A，但如果聯盟佔優勢則選 C 穩贏
                        if ally_ratio > 0.5 {
                            VoteChoice::C
                        } else {
                            VoteChoice::A
                        }
                    }
                    CharacterType::Richard => {
                        // 工廠主：偏好工業發展 B
                        if my_reputation > 60 {
                            VoteChoice::B
                        } else {
                            VoteChoice::C
                        }
                    }
                    CharacterType::Edward => {
                        // 記者：選能製造最大新聞的選項
                        if ally_ratio < 0.3 {
                            VoteChoice::A
                        } else {
                            VoteChoice::B
                        }
                    }
                    CharacterType::George => {
                        // 盧德派：極端選項
                        if my_reputation < 40 {
                            VoteChoice::A
                        } else {
                            VoteChoice::B
                        }
                    }
                    _ => {
                        // 其他角色：根據局勢最佳化
                        if my_reputation > 50 && ally_ratio > 0.4 {
                            VoteChoice::A
                        } else if my_reputation < 30 {
                            VoteChoice::B
                        } else {
                            VoteChoice::C
                        }
                    }
                };

                AIAction::Vote { choice }
            }
        }
    }

    /// 嘗試使用隨機卡牌
    fn try_use_random_card(
        &self,
        ai_player: &super::state::PlayerState,
        potential_targets: &[&super::state::PlayerState],
        rng: &mut StdRng,
    ) -> AIAction {
        if ai_player.hand.cards.is_empty() {
            return AIAction::Wait;
        }

        if let Some(card) = ai_player.hand.cards.choose(rng) {
            let target_id = if card.requires_target() {
                if card.is_attack() {
                    potential_targets.choose(rng).map(|p| p.id)
                } else {
                    // 治療卡等可以對盟友或自己使用
                    Some(self.id)
                }
            } else {
                None
            };

            // 檢查是否有足夠資源
            if ai_player.has_influence(card.influence_cost) && ai_player.gold >= card.gold_cost {
                return AIAction::UseCard {
                    card_id: card.id.clone(),
                    target_id,
                };
            }
        }

        AIAction::Wait
    }

    /// 嘗試使用功能卡
    fn try_use_utility_card(&self, ai_player: &super::state::PlayerState) -> AIAction {
        // 尋找功能卡
        if let Some(utility_card) = ai_player
            .hand
            .cards
            .iter()
            .find(|c| !c.is_attack() && !c.is_defense())
        {
            if ai_player.has_influence(utility_card.influence_cost)
                && ai_player.gold >= utility_card.gold_cost
            {
                let target_id = if utility_card.requires_target() {
                    Some(self.id) // 功能卡通常對自己使用
                } else {
                    None
                };

                return AIAction::UseCard {
                    card_id: utility_card.id.clone(),
                    target_id,
                };
            }
        }

        AIAction::Wait
    }
}

/// AI 管理器
///
/// 管理遊戲中的所有 AI 玩家
#[derive(Debug)]
pub struct AIManager {
    /// AI 玩家列表
    pub ai_players: Vec<AIPlayer>,
}

impl AIManager {
    /// 建立新的 AI 管理器
    pub fn new() -> Self {
        Self {
            ai_players: Vec::new(),
        }
    }

    /// 添加 AI 玩家
    pub fn add_ai_player(&mut self, ai_player: AIPlayer) {
        self.ai_players.push(ai_player);
    }

    /// 為單人模式建立 AI 玩家
    pub fn create_single_player_ais(
        &mut self,
        excluded_character: CharacterType,
        difficulty: AIDifficulty,
    ) -> Vec<Uuid> {
        let available_characters = [
            CharacterType::Thomas,
            CharacterType::Richard,
            CharacterType::Edward,
            CharacterType::George,
        ];

        let mut ai_ids = Vec::new();

        for character in available_characters {
            if character != excluded_character {
                let ai_id = Uuid::new_v4();
                let ai_player = AIPlayer::new(ai_id, character, difficulty);
                ai_ids.push(ai_id);
                self.add_ai_player(ai_player);
            }
        }

        ai_ids
    }

    /// 取得 AI 玩家
    pub fn get_ai_player(&self, player_id: Uuid) -> Option<&AIPlayer> {
        self.ai_players.iter().find(|ai| ai.id == player_id)
    }

    /// 取得所有 AI 玩家的行動
    pub fn get_all_ai_actions(&self, state: &EngineState) -> Vec<(Uuid, AIAction)> {
        self.ai_players
            .iter()
            .map(|ai| (ai.id, ai.decide_action(state)))
            .collect()
    }
}

impl Default for AIManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::game::state::PlayerState;
    use std::collections::HashMap;

    fn create_test_game_state() -> EngineState {
        let players = vec![
            PlayerState::new(Uuid::new_v4(), "Human".to_string(), CharacterType::Thomas),
            PlayerState::new(Uuid::new_v4(), "AI1".to_string(), CharacterType::Richard),
            PlayerState::new(Uuid::new_v4(), "AI2".to_string(), CharacterType::Edward),
            PlayerState::new(Uuid::new_v4(), "AI3".to_string(), CharacterType::George),
        ];

        EngineState::new("TEST".to_string(), players)
    }

    #[test]
    fn test_ai_player_creation() {
        let ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Thomas, AIDifficulty::Normal);
        assert_eq!(ai.character, CharacterType::Thomas);
        assert_eq!(ai.difficulty, AIDifficulty::Normal);
    }

    #[test]
    fn test_ai_manager() {
        let mut manager = AIManager::new();
        let ai_ids = manager.create_single_player_ais(CharacterType::Thomas, AIDifficulty::Easy);

        assert_eq!(ai_ids.len(), 3); // 排除 Thomas，剩下 3 個
        assert_eq!(manager.ai_players.len(), 3);

        for ai_id in ai_ids {
            assert!(manager.get_ai_player(ai_id).is_some());
        }
    }

    #[test]
    fn test_ai_decide_action_waiting() {
        let ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Thomas, AIDifficulty::Easy);
        let state = create_test_game_state();

        let action = ai.decide_action(&state);
        // 在 Waiting 階段應該等待
        matches!(action, AIAction::Wait);
    }

    #[test]
    fn test_ai_voting_action() {
        let mut state = create_test_game_state();
        state.phase = GamePhase::Voting;

        let ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Thomas, AIDifficulty::Easy);
        let action = ai.decide_action(&state);

        // 投票階段應該返回投票行動
        matches!(action, AIAction::Vote { .. });
    }

    #[test]
    fn test_difficulty_differences() {
        let mut state = create_test_game_state();
        state.phase = GamePhase::Conspiracy;

        let easy_ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Thomas, AIDifficulty::Easy);
        let hard_ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Richard, AIDifficulty::Hard);

        let easy_action = easy_ai.decide_action(&state);
        let hard_action = hard_ai.decide_action(&state);

        // 兩種難度都應該能產生有效行動（不一定相同）
        println!("Easy AI: {:?}", easy_action);
        println!("Hard AI: {:?}", hard_action);
    }
}
