//! AI 單人對戰引擎
//!
//! 提供三種難度的 AI 決策系統：
//! - Easy: 隨機出牌 + 30% 次優選擇
//! - Normal: 評分函數，選最高分行動
//! - Hard: minimax 搜索 2 步，預測對手行動

use rand::prelude::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::card::{CardType, GameCard};
use crate::domain::{CharacterType, GamePhase, VoteChoice};
use crate::game::state::{EngineState, PlayerState};

/// AI 難度
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AiDifficulty {
    /// 簡單：隨機出牌，偶爾犯錯
    Easy,
    /// 普通：基本策略，評分函數選擇最佳行動
    Normal,
    /// 困難：minimax 搜索，會預測對手行動
    Hard,
}

impl std::fmt::Display for AiDifficulty {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AiDifficulty::Easy => write!(f, "簡單"),
            AiDifficulty::Normal => write!(f, "普通"),
            AiDifficulty::Hard => write!(f, "困難"),
        }
    }
}

/// AI 引擎行動
#[derive(Debug, Clone)]
pub enum AiAction {
    /// 等待
    Wait,
    /// 出牌
    PlayCard {
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

/// 行動評分
#[derive(Debug, Clone)]
struct ScoredAction {
    action: AiAction,
    score: f64,
}

/// AI 引擎
#[derive(Debug, Clone)]
pub struct AiEngine {
    /// AI 難度
    pub difficulty: AiDifficulty,
    /// 隨機數種子
    rng: StdRng,
}

impl AiEngine {
    /// 建立新的 AI 引擎
    pub fn new(difficulty: AiDifficulty) -> Self {
        Self {
            difficulty,
            rng: StdRng::from_entropy(),
        }
    }

    /// 使用指定種子建立（用於測試可重現性）
    pub fn with_seed(difficulty: AiDifficulty, seed: u64) -> Self {
        Self {
            difficulty,
            rng: StdRng::seed_from_u64(seed),
        }
    }

    /// AI 決策：根據當前遊戲狀態決定行動
    pub fn decide(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        // 檢查 AI 是否能行動
        if let Some(ai_player) = state.get_player(ai_id) {
            if !ai_player.can_act() {
                return AiAction::Wait;
            }
        } else {
            return AiAction::Wait;
        }

        match state.phase {
            GamePhase::PlayerTurn => {
                // 回合制：AI 在行動階段隨機選擇密謀或辯論策略
                if self.rng.gen_bool(0.5) {
                    self.decide_conspiracy(state, ai_id)
                } else {
                    self.decide_debate(state, ai_id)
                }
            }
            GamePhase::Voting => self.decide_voting(state, ai_id),
            _ => AiAction::Wait,
        }
    }

    // ==================== 密謀階段 ====================

    fn decide_conspiracy(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        let others = self.get_alive_others(state, ai_id);
        if others.is_empty() {
            return AiAction::Wait;
        }

        match self.difficulty {
            AiDifficulty::Easy => self.conspiracy_easy(state, ai_id, &others),
            AiDifficulty::Normal => self.conspiracy_normal(state, ai_id, &others),
            AiDifficulty::Hard => self.conspiracy_hard(state, ai_id, &others),
        }
    }

    fn conspiracy_easy(
        &mut self,
        state: &EngineState,
        ai_id: Uuid,
        others: &[&PlayerState],
    ) -> AiAction {
        // 30% 機率嘗試結盟，否則等待
        if self.rng.gen_bool(0.3) {
            let non_allies: Vec<_> = others
                .iter()
                .filter(|p| !state.are_allies(ai_id, p.id))
                .collect();
            if let Some(target) = non_allies.choose(&mut self.rng) {
                return AiAction::FormAlliance {
                    target_id: target.id,
                };
            }
        }
        AiAction::Wait
    }

    fn conspiracy_normal(
        &mut self,
        state: &EngineState,
        ai_id: Uuid,
        others: &[&PlayerState],
    ) -> AiAction {
        let my_rep = state.get_player(ai_id).map(|p| p.reputation).unwrap_or(0);

        // 評分：與聲望互補的人結盟
        let mut best: Option<ScoredAction> = None;
        for other in others {
            if state.are_allies(ai_id, other.id) {
                continue;
            }
            let score = self.score_alliance_normal(my_rep, other);
            let candidate = ScoredAction {
                action: AiAction::FormAlliance {
                    target_id: other.id,
                },
                score,
            };
            if best.as_ref().is_none_or(|b| candidate.score > b.score) {
                best = Some(candidate);
            }
        }

        if let Some(b) = best {
            if b.score > 0.4 {
                return b.action;
            }
        }
        AiAction::Wait
    }

    fn conspiracy_hard(
        &mut self,
        state: &EngineState,
        ai_id: Uuid,
        others: &[&PlayerState],
    ) -> AiAction {
        let my_rep = state.get_player(ai_id).map(|p| p.reputation).unwrap_or(0);
        let allies = state.get_allies(ai_id);

        // 困難 AI：如果自己弱，積極結盟；如果強，考慮背叛弱盟友
        if my_rep < 30 {
            // 危險，積極結盟
            let strong_non_allies: Vec<_> = others
                .iter()
                .filter(|p| !state.are_allies(ai_id, p.id) && p.reputation > 40)
                .collect();
            if let Some(target) = strong_non_allies.choose(&mut self.rng) {
                return AiAction::FormAlliance {
                    target_id: target.id,
                };
            }
        } else if my_rep > 60 {
            // 強勢，考慮背叛弱盟友以取得優勢
            for ally_id in &allies {
                if let Some(ally) = state.get_player(*ally_id) {
                    if ally.reputation < 25 && self.rng.gen_bool(0.4) {
                        return AiAction::Betray {
                            target_id: *ally_id,
                        };
                    }
                }
            }
        }

        // 正常情況：評估所有結盟選項
        let mut scored: Vec<ScoredAction> = others
            .iter()
            .filter(|p| !state.are_allies(ai_id, p.id))
            .map(|p| ScoredAction {
                score: self.score_alliance_hard(state, ai_id, p),
                action: AiAction::FormAlliance { target_id: p.id },
            })
            .collect();

        scored.sort_by(|a, b| {
            b.score
                .partial_cmp(&a.score)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        if let Some(best) = scored.first() {
            if best.score > 0.5 {
                return best.action.clone();
            }
        }

        AiAction::Wait
    }

    // ==================== 辯論階段 ====================

    fn decide_debate(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        let ai_player = match state.get_player(ai_id) {
            Some(p) => p,
            None => return AiAction::Wait,
        };

        // 如果有待反駁的質詢且目標是我
        if let Some(ref pending) = state.pending_challenge {
            if pending.target_id == ai_id {
                return self.decide_counter(ai_player);
            }
        }

        let enemies = self.get_enemies(state, ai_id);

        match self.difficulty {
            AiDifficulty::Easy => self.debate_easy(state, ai_id, ai_player, &enemies),
            AiDifficulty::Normal => self.debate_normal(state, ai_id, ai_player, &enemies),
            AiDifficulty::Hard => self.debate_hard(state, ai_id, ai_player, &enemies),
        }
    }

    fn decide_counter(&mut self, ai_player: &PlayerState) -> AiAction {
        match self.difficulty {
            AiDifficulty::Easy => {
                // Easy AI 只有 50% 機率反駁
                if self.rng.gen_bool(0.5) && ai_player.reputation >= 5 {
                    AiAction::Counter
                } else {
                    AiAction::Wait
                }
            }
            AiDifficulty::Normal => {
                // Normal AI 80% 機率反駁（如果有足夠聲望）
                if self.rng.gen_bool(0.8) && ai_player.reputation >= 5 {
                    AiAction::Counter
                } else {
                    AiAction::Wait
                }
            }
            AiDifficulty::Hard => {
                // Hard AI 除非聲望很低否則一定反駁
                if ai_player.reputation >= 5 {
                    AiAction::Counter
                } else {
                    AiAction::Wait
                }
            }
        }
    }

    fn debate_easy(
        &mut self,
        _state: &EngineState,
        _ai_id: Uuid,
        ai_player: &PlayerState,
        enemies: &[&PlayerState],
    ) -> AiAction {
        // Easy AI：隨機選擇行動，30% 次優
        if ai_player.hand.cards.is_empty() {
            return AiAction::DrawCard;
        }

        let roll: f64 = self.rng.gen();

        if roll < 0.3 {
            // 30% 次優：等待或抽牌
            if self.rng.gen_bool(0.5) {
                AiAction::DrawCard
            } else {
                AiAction::Wait
            }
        } else if roll < 0.65 {
            // 35% 出牌
            self.play_random_card(ai_player, enemies)
        } else {
            // 35% 質詢
            if let Some(target) = enemies.choose(&mut self.rng) {
                AiAction::Challenge {
                    target_id: target.id,
                }
            } else {
                AiAction::Wait
            }
        }
    }

    fn debate_normal(
        &mut self,
        _state: &EngineState,
        ai_id: Uuid,
        ai_player: &PlayerState,
        enemies: &[&PlayerState],
    ) -> AiAction {
        // Normal AI：基本評分函數
        let mut actions: Vec<ScoredAction> = Vec::new();

        // 評估出牌
        for card in &ai_player.hand.cards {
            if !ai_player.has_influence(card.influence_cost) {
                continue;
            }
            if card.gold_cost > 0 && ai_player.gold < card.gold_cost {
                continue;
            }

            match card.card_type {
                CardType::Attack => {
                    for enemy in enemies {
                        let score = self.score_attack_normal(card, enemy);
                        actions.push(ScoredAction {
                            action: AiAction::PlayCard {
                                card_id: card.id.clone(),
                                target_id: Some(enemy.id),
                            },
                            score,
                        });
                    }
                }
                CardType::Defense => {
                    // 防禦卡在辯論期間保留，不主動使用
                }
                CardType::Utility => {
                    if card.id.contains("endorse") {
                        // 治療卡：自己血量低時使用
                        let score = if ai_player.reputation < 40 { 0.8 } else { 0.2 };
                        actions.push(ScoredAction {
                            action: AiAction::PlayCard {
                                card_id: card.id.clone(),
                                target_id: Some(ai_id),
                            },
                            score,
                        });
                    }
                }
                CardType::Signature => {
                    let score = self.score_signature_card_normal(ai_player, card, enemies);
                    let target = enemies.first().map(|e| e.id);
                    if score > 0.0 {
                        actions.push(ScoredAction {
                            action: AiAction::PlayCard {
                                card_id: card.id.clone(),
                                target_id: target,
                            },
                            score,
                        });
                    }
                }
            }
        }

        // 評估質詢
        if ai_player.reputation >= 10 {
            for enemy in enemies {
                let score = self.score_challenge_normal(ai_player, enemy);
                actions.push(ScoredAction {
                    action: AiAction::Challenge {
                        target_id: enemy.id,
                    },
                    score,
                });
            }
        }

        // 評估技能
        if ai_player.can_use_skill() {
            let skill_score = self.score_skill_normal(ai_player, enemies);
            if skill_score.score > 0.0 {
                actions.push(skill_score);
            }
        }

        // 評估抽牌
        if ai_player.hand.count() < 4 {
            actions.push(ScoredAction {
                action: AiAction::DrawCard,
                score: 0.3,
            });
        }

        // 選擇最高分
        actions.sort_by(|a, b| {
            b.score
                .partial_cmp(&a.score)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        actions
            .into_iter()
            .next()
            .map(|a| a.action)
            .unwrap_or(AiAction::Wait)
    }

    fn debate_hard(
        &mut self,
        state: &EngineState,
        ai_id: Uuid,
        ai_player: &PlayerState,
        enemies: &[&PlayerState],
    ) -> AiAction {
        let my_rep = ai_player.reputation;

        // Hard AI：策略性思考

        // 1. 危機管理：血量低時優先治療
        if my_rep < 30 {
            if let Some(heal_card) = ai_player
                .hand
                .cards
                .iter()
                .find(|c| c.id.contains("endorse"))
            {
                if ai_player.has_influence(heal_card.influence_cost) {
                    return AiAction::PlayCard {
                        card_id: heal_card.id.clone(),
                        target_id: Some(ai_id),
                    };
                }
            }
        }

        // 2. 攻擊評估：用 minimax-like 邏輯
        let mut best_action: Option<ScoredAction> = None;

        // 評估所有可用攻擊
        for enemy in enemies {
            // 質詢
            if ai_player.reputation >= 10 {
                let score = self.minimax_score_attack(state, ai_id, enemy, 2);
                let candidate = ScoredAction {
                    action: AiAction::Challenge {
                        target_id: enemy.id,
                    },
                    score,
                };
                if best_action
                    .as_ref()
                    .is_none_or(|b| candidate.score > b.score)
                {
                    best_action = Some(candidate);
                }
            }

            // 攻擊卡
            for card in &ai_player.hand.cards {
                if !card.is_attack() || !ai_player.has_influence(card.influence_cost) {
                    continue;
                }
                let score = self.minimax_score_card(state, ai_id, card, enemy, 2);
                let candidate = ScoredAction {
                    action: AiAction::PlayCard {
                        card_id: card.id.clone(),
                        target_id: Some(enemy.id),
                    },
                    score,
                };
                if best_action
                    .as_ref()
                    .is_none_or(|b| candidate.score > b.score)
                {
                    best_action = Some(candidate);
                }
            }
        }

        // 3. 技能使用
        if ai_player.can_use_skill() {
            let skill_target = self.pick_best_skill_target_hard(state, ai_id, ai_player, enemies);
            if let Some((target, score)) = skill_target {
                let candidate = ScoredAction {
                    action: AiAction::UseSkill {
                        target_id: Some(target),
                    },
                    score,
                };
                if best_action
                    .as_ref()
                    .is_none_or(|b| candidate.score > b.score)
                {
                    best_action = Some(candidate);
                }
            }
        }

        // 4. 抽牌（手牌不足）
        if ai_player.hand.count() < 3 {
            let draw_score = 0.35;
            let candidate = ScoredAction {
                action: AiAction::DrawCard,
                score: draw_score,
            };
            if best_action
                .as_ref()
                .is_none_or(|b| candidate.score > b.score)
            {
                best_action = Some(candidate);
            }
        }

        best_action.map(|a| a.action).unwrap_or(AiAction::Wait)
    }

    // ==================== 投票階段 ====================

    fn decide_voting(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        match self.difficulty {
            AiDifficulty::Easy => self.vote_easy(),
            AiDifficulty::Normal => self.vote_normal(state, ai_id),
            AiDifficulty::Hard => self.vote_hard(state, ai_id),
        }
    }

    fn vote_easy(&mut self) -> AiAction {
        let choices = [VoteChoice::A, VoteChoice::B, VoteChoice::C];
        AiAction::Vote {
            choice: *choices.choose(&mut self.rng).unwrap(),
        }
    }

    fn vote_normal(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        let ai_player = match state.get_player(ai_id) {
            Some(p) => p,
            None => {
                return AiAction::Vote {
                    choice: VoteChoice::A,
                }
            }
        };

        // 根據角色傾向投票
        let choice = match ai_player.character {
            CharacterType::Thomas => VoteChoice::A,  // 工人支持改革
            CharacterType::Richard => VoteChoice::B, // 工廠主保護財產
            CharacterType::Edward => {
                // 記者根據局勢選擇
                if state.alive_player_count() > 2 {
                    VoteChoice::C
                } else {
                    VoteChoice::A
                }
            }
            CharacterType::George => VoteChoice::A, // 盧德派支持禁止機器
        };

        AiAction::Vote { choice }
    }

    fn vote_hard(&mut self, state: &EngineState, ai_id: Uuid) -> AiAction {
        let ai_player = match state.get_player(ai_id) {
            Some(p) => p,
            None => {
                return AiAction::Vote {
                    choice: VoteChoice::A,
                }
            }
        };

        let my_rep = ai_player.reputation;
        let allies = state.get_allies(ai_id);
        let alive = state.alive_player_count();

        // 複雜投票策略：
        // 1. 如果盟友多，選擇對自己陣營有利的
        // 2. 如果自己弱，選擇激進選項（可能翻盤）
        // 3. 否則選擇保守選項

        let choice = if allies.len() as f32 / alive as f32 > 0.4 && my_rep > 50 {
            // 優勢，選保守
            match ai_player.character {
                CharacterType::Thomas | CharacterType::George => VoteChoice::A,
                CharacterType::Richard => VoteChoice::B,
                CharacterType::Edward => VoteChoice::C,
            }
        } else if my_rep < 30 {
            // 劣勢，選可能翻盤的
            VoteChoice::B
        } else {
            // 中立
            VoteChoice::C
        };

        AiAction::Vote { choice }
    }

    // ==================== 評分函數 ====================

    fn score_alliance_normal(&self, my_rep: i32, other: &PlayerState) -> f64 {
        // 聲望互補（我弱他強 → 高分）
        let rep_diff = (other.reputation - my_rep) as f64;
        let base = if rep_diff > 0.0 {
            0.6 + rep_diff / 100.0
        } else {
            0.3
        };
        base.min(1.0)
    }

    fn score_alliance_hard(&self, state: &EngineState, ai_id: Uuid, other: &PlayerState) -> f64 {
        let my_rep = state.get_player(ai_id).map(|p| p.reputation).unwrap_or(0);
        let my_allies = state.get_allies(ai_id);

        // 多維度評分
        let mut score: f64 = 0.0;

        // 聲望互補
        if my_rep < 40 && other.reputation > 50 {
            score += 0.4;
        }

        // 不要有太多盟友（防止被集體背叛）
        if my_allies.len() < 2 {
            score += 0.2;
        }

        // 對方金幣多（Richard）可能有用
        if other.gold > 20 {
            score += 0.1;
        }

        // 對方角色技能互補
        let my_char = state.get_player(ai_id).map(|p| p.character);
        if let Some(my_c) = my_char {
            match (my_c, other.character) {
                (CharacterType::Thomas, CharacterType::Richard) => score += 0.15,
                (CharacterType::George, CharacterType::Thomas) => score += 0.15,
                _ => {}
            }
        }

        score.min(1.0)
    }

    fn score_attack_normal(&self, card: &GameCard, enemy: &PlayerState) -> f64 {
        // 攻擊高聲望敵人得分更高
        let rep_factor = enemy.reputation as f64 / 100.0;
        let damage_factor = card.base_value as f64 / 30.0;
        let can_kill = enemy.reputation <= card.base_value;

        let mut score = rep_factor * 0.4 + damage_factor * 0.3;
        if can_kill {
            score += 0.3; // 斬殺加成
        }
        score.min(1.0)
    }

    fn score_challenge_normal(&self, ai: &PlayerState, enemy: &PlayerState) -> f64 {
        let rep_ratio = enemy.reputation as f64 / ai.reputation.max(1) as f64;
        let mut score = rep_ratio * 0.3;
        if enemy.reputation < 20 {
            score += 0.3; // 低血敵人
        }
        score.min(0.8)
    }

    fn score_skill_normal(&self, ai: &PlayerState, enemies: &[&PlayerState]) -> ScoredAction {
        let target = enemies.first().map(|e| e.id);
        let score = match ai.character {
            CharacterType::Thomas => 0.0, // 被動技能
            CharacterType::Richard => {
                if ai.gold >= 30 {
                    0.6
                } else {
                    0.0
                }
            }
            CharacterType::Edward => 0.5,
            CharacterType::George => {
                if ai.reputation > 40 {
                    0.7
                } else {
                    0.2
                }
            }
        };

        ScoredAction {
            action: AiAction::UseSkill { target_id: target },
            score,
        }
    }

    fn score_signature_card_normal(
        &self,
        ai: &PlayerState,
        card: &GameCard,
        _enemies: &[&PlayerState],
    ) -> f64 {
        match card.id.as_str() {
            id if id.contains("thomas_unity") => {
                // 團結：防禦加成，適合有盟友時使用
                0.3
            }
            id if id.contains("richard_bribe") => {
                if ai.gold >= 30 {
                    0.7
                } else {
                    0.0
                }
            }
            id if id.contains("edward_scoop") => 0.5,
            id if id.contains("george_fury") => {
                if ai.reputation > 40 {
                    0.8
                } else {
                    0.2
                }
            }
            _ => 0.3,
        }
    }

    // ==================== Minimax 評分（Hard） ====================

    fn minimax_score_attack(
        &self,
        state: &EngineState,
        ai_id: Uuid,
        enemy: &PlayerState,
        depth: i32,
    ) -> f64 {
        if depth <= 0 {
            return self.evaluate_position(state, ai_id);
        }

        let my_rep = state.get_player(ai_id).map(|p| p.reputation).unwrap_or(0);
        let enemy_after = (enemy.reputation - 15).max(0); // 質詢基礎傷害

        // 我方評分
        let my_score = my_rep as f64 / 100.0;
        let enemy_score = enemy_after as f64 / 100.0;

        // 差值越大越好
        let advantage = my_score - enemy_score;

        // 斬殺加成
        let kill_bonus = if enemy_after <= 0 { 0.5 } else { 0.0 };

        // 考慮對手可能的反擊（depth - 1）
        let retaliation_risk = if enemy_after > 10 { 0.15 } else { 0.0 };

        (advantage * 0.5 + kill_bonus - retaliation_risk).clamp(0.0, 1.0)
    }

    fn minimax_score_card(
        &self,
        state: &EngineState,
        ai_id: Uuid,
        card: &GameCard,
        enemy: &PlayerState,
        depth: i32,
    ) -> f64 {
        if depth <= 0 {
            return self.evaluate_position(state, ai_id);
        }

        let my_rep = state.get_player(ai_id).map(|p| p.reputation).unwrap_or(0);
        let damage = card.base_value;
        let enemy_after = (enemy.reputation - damage).max(0);

        let advantage = (my_rep as f64 - enemy_after as f64) / 100.0;
        let kill_bonus = if enemy_after <= 0 { 0.5 } else { 0.0 };
        let cost_penalty = card.influence_cost as f64 / 10.0 * 0.1;

        // 怒火卡自傷懲罰
        let self_damage_penalty = if card.id.contains("george_fury") {
            0.15
        } else {
            0.0
        };

        (advantage * 0.4 + kill_bonus - cost_penalty - self_damage_penalty).clamp(0.0, 1.0)
    }

    fn evaluate_position(&self, state: &EngineState, ai_id: Uuid) -> f64 {
        let ai = match state.get_player(ai_id) {
            Some(p) => p,
            None => return 0.0,
        };

        let my_rep = ai.reputation as f64;
        let my_gold = ai.gold as f64;
        let allies = state.get_allies(ai_id).len() as f64;

        // 位置評估 = 聲望權重 + 金幣權重 + 盟友權重
        let rep_score = my_rep / 100.0 * 0.5;
        let gold_score = (my_gold / 50.0).min(1.0) * 0.2;
        let ally_score = (allies / 3.0).min(1.0) * 0.3;

        (rep_score + gold_score + ally_score).min(1.0)
    }

    fn pick_best_skill_target_hard(
        &self,
        _state: &EngineState,
        _ai_id: Uuid,
        ai_player: &PlayerState,
        enemies: &[&PlayerState],
    ) -> Option<(Uuid, f64)> {
        if enemies.is_empty() {
            return None;
        }

        match ai_player.character {
            CharacterType::Thomas => None, // 被動技能
            CharacterType::Richard => {
                if ai_player.gold < 30 {
                    return None;
                }
                // 沉默聲望最高的敵人
                let target = enemies.iter().max_by_key(|e| e.reputation)?;
                Some((target.id, 0.75))
            }
            CharacterType::Edward => {
                // 爆料聲望最高的
                let target = enemies.iter().max_by_key(|e| e.reputation)?;
                Some((target.id, 0.55))
            }
            CharacterType::George => {
                if ai_player.reputation <= 20 {
                    return None; // 太危險
                }
                // 怒火打最弱的（可能擊殺）
                let target = enemies.iter().min_by_key(|e| e.reputation)?;
                let can_kill = target.reputation <= 30;
                let score = if can_kill { 0.85 } else { 0.5 };
                Some((target.id, score))
            }
        }
    }

    // ==================== 工具方法 ====================

    fn get_alive_others<'a>(&self, state: &'a EngineState, ai_id: Uuid) -> Vec<&'a PlayerState> {
        state
            .alive_players()
            .into_iter()
            .filter(|p| p.id != ai_id)
            .collect()
    }

    fn get_enemies<'a>(&self, state: &'a EngineState, ai_id: Uuid) -> Vec<&'a PlayerState> {
        state
            .alive_players()
            .into_iter()
            .filter(|p| p.id != ai_id && !state.are_allies(ai_id, p.id))
            .collect()
    }

    fn play_random_card(&mut self, ai_player: &PlayerState, enemies: &[&PlayerState]) -> AiAction {
        let playable: Vec<_> = ai_player
            .hand
            .cards
            .iter()
            .filter(|c| {
                ai_player.has_influence(c.influence_cost)
                    && (c.gold_cost == 0 || ai_player.gold >= c.gold_cost)
            })
            .collect();

        if let Some(card) = playable.choose(&mut self.rng) {
            let target_id = if card.requires_target() {
                if card.is_attack() {
                    enemies.choose(&mut self.rng).map(|e| e.id)
                } else {
                    Some(ai_player.id)
                }
            } else {
                None
            };

            AiAction::PlayCard {
                card_id: card.id.clone(),
                target_id,
            }
        } else {
            AiAction::DrawCard
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::game::state::PlayerState;

    fn create_test_state() -> EngineState {
        let players = vec![
            PlayerState::new(
                Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
                "Human".to_string(),
                CharacterType::Thomas,
            ),
            PlayerState::new(
                Uuid::parse_str("00000000-0000-0000-0000-000000000002").unwrap(),
                "AI1".to_string(),
                CharacterType::Richard,
            ),
            PlayerState::new(
                Uuid::parse_str("00000000-0000-0000-0000-000000000003").unwrap(),
                "AI2".to_string(),
                CharacterType::Edward,
            ),
            PlayerState::new(
                Uuid::parse_str("00000000-0000-0000-0000-000000000004").unwrap(),
                "AI3".to_string(),
                CharacterType::George,
            ),
        ];
        EngineState::new("SP_TEST".to_string(), players)
    }

    fn ai1_id() -> Uuid {
        Uuid::parse_str("00000000-0000-0000-0000-000000000002").unwrap()
    }

    fn ai2_id() -> Uuid {
        Uuid::parse_str("00000000-0000-0000-0000-000000000003").unwrap()
    }

    #[test]
    fn test_ai_engine_creation() {
        let engine = AiEngine::new(AiDifficulty::Easy);
        assert_eq!(engine.difficulty, AiDifficulty::Easy);
    }

    #[test]
    fn test_ai_engine_with_seed() {
        let engine = AiEngine::with_seed(AiDifficulty::Normal, 42);
        assert_eq!(engine.difficulty, AiDifficulty::Normal);
    }

    #[test]
    fn test_easy_ai_waiting_phase() {
        let state = create_test_state();
        let mut engine = AiEngine::with_seed(AiDifficulty::Easy, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(matches!(action, AiAction::Wait));
    }

    #[test]
    fn test_easy_ai_conspiracy() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;
        let mut engine = AiEngine::with_seed(AiDifficulty::Easy, 42);

        // 多次測試，確保能生成行動
        let mut got_alliance = false;
        let mut got_wait = false;
        for seed in 0..50 {
            let mut eng = AiEngine::with_seed(AiDifficulty::Easy, seed);
            match eng.decide(&state, ai1_id()) {
                AiAction::FormAlliance { .. } => got_alliance = true,
                AiAction::Wait => got_wait = true,
                _ => {}
            }
        }
        // Easy AI 應該有時候結盟，有時候等待
        assert!(got_alliance || got_wait, "Easy AI 應該能在密謀階段產生行動");
    }

    #[test]
    fn test_normal_ai_conspiracy() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;
        // PlayerTurn 階段 AI 會隨機選擇密謀或辯論策略，驗證能產生有效行動
        let mut got_action = false;
        for seed in 0..50 {
            let mut engine = AiEngine::with_seed(AiDifficulty::Normal, seed);
            let action = engine.decide(&state, ai1_id());
            match action {
                AiAction::FormAlliance { .. }
                | AiAction::Wait
                | AiAction::Challenge { .. }
                | AiAction::PlayCard { .. }
                | AiAction::DrawCard => {
                    got_action = true;
                }
                _ => {}
            }
        }
        assert!(got_action, "Normal AI 應該在行動階段產生有效行動");
    }

    #[test]
    fn test_hard_ai_conspiracy_weak() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        // 讓 AI 血量很低
        if let Some(ai) = state.get_player_mut(ai1_id()) {
            ai.reputation = 20;
        }

        // PlayerTurn 階段 AI 會隨機選擇密謀或辯論策略，驗證弱勢 AI 能產生行動
        let mut got_action = false;
        for seed in 0..50 {
            let mut engine = AiEngine::with_seed(AiDifficulty::Hard, seed);
            let action = engine.decide(&state, ai1_id());
            match action {
                AiAction::FormAlliance { .. }
                | AiAction::Wait
                | AiAction::Challenge { .. }
                | AiAction::PlayCard { .. }
                | AiAction::DrawCard
                | AiAction::Betray { .. } => {
                    got_action = true;
                }
                _ => {}
            }
        }
        assert!(got_action, "弱勢 Hard AI 應該在行動階段產生有效行動");
    }

    #[test]
    fn test_easy_ai_voting() {
        let mut state = create_test_state();
        state.phase = GamePhase::Voting;
        let mut engine = AiEngine::with_seed(AiDifficulty::Easy, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(
            matches!(action, AiAction::Vote { .. }),
            "Easy AI 應該在投票階段投票"
        );
    }

    #[test]
    fn test_normal_ai_voting_by_character() {
        let mut state = create_test_state();
        state.phase = GamePhase::Voting;

        // Richard（工廠主）應該投 B
        let mut engine = AiEngine::with_seed(AiDifficulty::Normal, 42);
        let action = engine.decide(&state, ai1_id()); // AI1 = Richard
        assert!(matches!(
            action,
            AiAction::Vote {
                choice: VoteChoice::B
            }
        ));
    }

    #[test]
    fn test_hard_ai_voting_weak() {
        let mut state = create_test_state();
        state.phase = GamePhase::Voting;

        // 弱勢 AI 應該投 B（激進翻盤）
        if let Some(ai) = state.get_player_mut(ai1_id()) {
            ai.reputation = 20;
        }

        let mut engine = AiEngine::with_seed(AiDifficulty::Hard, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(matches!(
            action,
            AiAction::Vote {
                choice: VoteChoice::B
            }
        ));
    }

    #[test]
    fn test_easy_ai_debate_no_hand() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        // AI 沒有手牌時應該抽牌
        let mut engine = AiEngine::with_seed(AiDifficulty::Easy, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(
            matches!(
                action,
                AiAction::DrawCard | AiAction::Challenge { .. } | AiAction::Wait
            ),
            "無手牌的 AI 應該抽牌或質詢或等待"
        );
    }

    #[test]
    fn test_counter_decision_easy() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        // 設置一個針對 AI1 的質詢
        state.pending_challenge = Some(crate::game::state::PendingChallenge {
            attacker_id: Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
            target_id: ai1_id(),
            damage: 15,
            timestamp: chrono::Utc::now(),
        });

        // Easy AI 50% 反駁
        let mut countered = false;
        let mut not_countered = false;
        for seed in 0..50 {
            let mut eng = AiEngine::with_seed(AiDifficulty::Easy, seed);
            match eng.decide(&state, ai1_id()) {
                AiAction::Counter => countered = true,
                AiAction::Wait => not_countered = true,
                _ => {}
            }
        }
        assert!(countered, "Easy AI 有時應該反駁");
        assert!(not_countered, "Easy AI 有時應該不反駁");
    }

    #[test]
    fn test_counter_decision_hard() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        state.pending_challenge = Some(crate::game::state::PendingChallenge {
            attacker_id: Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
            target_id: ai1_id(),
            damage: 15,
            timestamp: chrono::Utc::now(),
        });

        // Hard AI 應該總是反駁（如果有足夠聲望）
        let mut engine = AiEngine::with_seed(AiDifficulty::Hard, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(matches!(action, AiAction::Counter));
    }

    #[test]
    fn test_dead_ai_waits() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        if let Some(ai) = state.get_player_mut(ai1_id()) {
            ai.take_damage(100);
        }

        let mut engine = AiEngine::with_seed(AiDifficulty::Hard, 42);
        let action = engine.decide(&state, ai1_id());
        assert!(matches!(action, AiAction::Wait));
    }

    #[test]
    fn test_evaluate_position() {
        let state = create_test_state();
        let engine = AiEngine::with_seed(AiDifficulty::Hard, 42);

        let score = engine.evaluate_position(&state, ai1_id());
        assert!(score > 0.0, "健康 AI 的位置評估應該 > 0");
        assert!(score <= 1.0, "位置評估應該 <= 1.0");
    }

    #[test]
    fn test_difficulty_display() {
        assert_eq!(format!("{}", AiDifficulty::Easy), "簡單");
        assert_eq!(format!("{}", AiDifficulty::Normal), "普通");
        assert_eq!(format!("{}", AiDifficulty::Hard), "困難");
    }

    #[test]
    fn test_minimax_score_attack() {
        let state = create_test_state();
        let engine = AiEngine::with_seed(AiDifficulty::Hard, 42);

        let enemy = state.get_player(ai2_id()).unwrap();
        let score = engine.minimax_score_attack(&state, ai1_id(), enemy, 2);
        assert!(score >= 0.0 && score <= 1.0);
    }

    #[test]
    fn test_minimax_kill_bonus() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        // 讓目標快死了
        if let Some(enemy) = state.get_player_mut(ai2_id()) {
            enemy.reputation = 10;
        }

        let engine = AiEngine::with_seed(AiDifficulty::Hard, 42);
        let enemy = state.get_player(ai2_id()).unwrap();
        let score = engine.minimax_score_attack(&state, ai1_id(), enemy, 2);

        // 能殺死的目標應該得到更高分
        assert!(score > 0.3, "可擊殺目標應該有高分");
    }

    #[test]
    fn test_all_difficulties_produce_vote() {
        let mut state = create_test_state();
        state.phase = GamePhase::Voting;

        for difficulty in [AiDifficulty::Easy, AiDifficulty::Normal, AiDifficulty::Hard] {
            let mut engine = AiEngine::with_seed(difficulty, 42);
            let action = engine.decide(&state, ai1_id());
            assert!(
                matches!(action, AiAction::Vote { .. }),
                "{:?} 難度應該在投票階段產生投票",
                difficulty
            );
        }
    }

    #[test]
    fn test_hard_ai_betrayal() {
        let mut state = create_test_state();
        state.phase = GamePhase::PlayerTurn;

        // 讓 AI1 很強
        if let Some(ai) = state.get_player_mut(ai1_id()) {
            ai.reputation = 80;
        }

        // 建立同盟然後讓盟友很弱
        state.form_alliance(ai1_id(), ai2_id());
        if let Some(ally) = state.get_player_mut(ai2_id()) {
            ally.reputation = 15;
        }

        let mut betrayed = false;
        for seed in 0..50 {
            let mut eng = AiEngine::with_seed(AiDifficulty::Hard, seed);
            if matches!(eng.decide(&state, ai1_id()), AiAction::Betray { .. }) {
                betrayed = true;
                break;
            }
        }
        assert!(betrayed, "強勢 Hard AI 應該有機會背叛弱盟友");
    }
}
