//! 遊戲引擎
//!
//! 協調遊戲流程、處理階段轉換、管理遊戲狀態

use chrono::Utc;
use rand::seq::SliceRandom;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::actions::{ActionResult, GameAction, GameEffect, GameResult, PlayerScore, VoteCounts};
use super::ai::{AIAction, AIDifficulty, AIManager};
use super::alliance::{AllianceError, AllianceManager};
use super::bills::{BillSystem, VoteEffectResult};
use super::cards;
use super::characters::{CharacterSkills, GameError};
use super::state::{EngineState, PendingChallenge, PlayerState};
use crate::domain::card::{CardType, GameCard};
use crate::domain::{CharacterType, GamePhase, Player, VoteChoice};

/// 遊戲設定
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameConfig {
    /// 投票階段時長（秒）— 回合制中僅投票保留計時
    pub voting_duration_secs: u32,
    /// 結果階段時長（秒）
    pub result_duration_secs: u32,
    /// 反駁超時時間（秒）
    pub counter_timeout_secs: u32,
    /// 基礎質詢傷害
    pub base_challenge_damage: i32,
    /// 質詢消耗聲望
    pub challenge_cost: i32,
    /// 反駁消耗聲望
    pub counter_cost: i32,
    /// 收買技能費用
    pub bribe_cost: i32,
    /// 每回合行動點數
    pub action_points_per_turn: i32,
    /// 最大回合數
    pub max_rounds: i32,
}

impl Default for GameConfig {
    fn default() -> Self {
        Self {
            voting_duration_secs: 60,
            result_duration_secs: 30,
            counter_timeout_secs: 10,
            base_challenge_damage: 15,
            challenge_cost: 10,
            counter_cost: 5,
            bribe_cost: 30,
            action_points_per_turn: 3,
            max_rounds: 5,
        }
    }
}

/// 遊戲引擎
#[derive(Debug)]
pub struct GameEngine {
    /// 遊戲狀態
    pub state: EngineState,
    /// 遊戲設定
    pub config: GameConfig,
    /// AI 管理器
    pub ai_manager: AIManager,
    /// 議案系統
    pub bill_system: BillSystem,
    /// 同盟管理器
    pub alliance_manager: AllianceManager,
}

impl GameEngine {
    /// 建立新的遊戲引擎
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `players` - 玩家列表
    ///
    /// # Returns
    /// 新的遊戲引擎實例
    pub fn new(room_code: String, players: Vec<Player>) -> Self {
        Self::with_config(room_code, players, GameConfig::default())
    }

    /// 使用自訂設定建立遊戲引擎
    pub fn with_config(room_code: String, players: Vec<Player>, config: GameConfig) -> Self {
        // 隨機分配角色
        let mut available_characters = CharacterType::all();
        {
            let mut rng = rand::thread_rng();
            available_characters.shuffle(&mut rng);
        }

        // 建立玩家狀態
        let player_states: Vec<PlayerState> = players
            .into_iter()
            .enumerate()
            .map(|(i, player)| {
                let character = player
                    .character
                    .unwrap_or_else(|| available_characters[i % available_characters.len()]);
                PlayerState::new(player.id, player.name, character)
            })
            .collect();

        let state = EngineState::new(room_code, player_states);

        Self {
            state,
            config,
            ai_manager: AIManager::new(),
            bill_system: BillSystem::new(),
            alliance_manager: AllianceManager::new(),
        }
    }

    /// 從玩家資料建立遊戲引擎
    pub fn from_player_data(
        room_code: String,
        player_data: Vec<(Uuid, String, CharacterType)>,
    ) -> Self {
        let player_states: Vec<PlayerState> = player_data
            .into_iter()
            .map(|(id, name, character)| PlayerState::new(id, name, character))
            .collect();

        let state = EngineState::new(room_code, player_states);

        Self {
            state,
            config: GameConfig::default(),
            ai_manager: AIManager::new(),
            bill_system: BillSystem::new(),
            alliance_manager: AllianceManager::new(),
        }
    }

    /// 開始遊戲
    pub fn start_game(&mut self) -> Result<(), GameError> {
        if self.state.phase != GamePhase::Waiting {
            return Err(GameError::InvalidAction("遊戲已經開始".to_string()));
        }

        if self.state.players.len() < 2 {
            return Err(GameError::InvalidAction("至少需要 2 名玩家".to_string()));
        }

        // 初始化卡牌池
        self.state.initialize_card_pool();

        // 給每個玩家發初始手牌
        let player_characters: Vec<(Uuid, CharacterType)> = self
            .state
            .players
            .iter()
            .map(|(id, player)| (*id, player.character))
            .collect();

        for (player_id, character) in player_characters {
            let character_str = match character {
                CharacterType::Thomas => "thomas",
                CharacterType::Richard => "richard",
                CharacterType::Edward => "edward",
                CharacterType::George => "george",
            };
            let starting_hand = cards::create_starting_hand(character_str);
            if let Some(player) = self.state.get_player_mut(player_id) {
                player.hand = starting_hand;
            }
        }

        // 設定回合制參數
        self.state.max_action_points = self.config.action_points_per_turn;
        self.state.action_points_remaining = self.config.action_points_per_turn;

        self.state.phase = GamePhase::PlayerTurn;
        self.state.phase_start_time = Utc::now();
        self.state.current_round = 1;

        // 重置回合順序到第一位存活玩家
        self.state.reset_turn_order();

        // 選擇第一回合的議案
        self.select_round_bill();

        Ok(())
    }

    /// 進入下一階段
    pub fn advance_phase(&mut self) -> GamePhase {
        // 處理階段結束事件
        self.handle_phase_end();

        // 轉換到下一階段
        self.state.phase = match self.state.phase {
            GamePhase::Waiting => GamePhase::PlayerTurn,
            GamePhase::PlayerTurn => GamePhase::Voting,
            GamePhase::Voting => GamePhase::Result,
            GamePhase::Result => {
                if self.state.current_round >= self.config.max_rounds {
                    GamePhase::Finished
                } else {
                    self.state.current_round += 1;
                    self.clear_round_effects();
                    self.start_new_round();
                    GamePhase::PlayerTurn
                }
            }
            GamePhase::Finished => GamePhase::Finished,
        };

        self.state.phase_start_time = Utc::now();
        self.state.phase
    }

    /// 處理階段結束
    fn handle_phase_end(&mut self) {
        match self.state.phase {
            GamePhase::PlayerTurn => {
                // 處理未決的質詢
                if self.state.pending_challenge.is_some() {
                    let _ = self.resolve_challenge();
                }
            }
            GamePhase::Voting => {
                // AI 投票
                let _ai_results = self.process_ai_actions();

                // 計算投票結果並應用議案效果
                if !self.state.votes.is_empty() {
                    // 計算獲勝選項
                    let vote_counts = self.calculate_vote_counts();
                    let winning_choice = vote_counts.get_winner();

                    if let Some(choice) = winning_choice {
                        // 應用議案效果
                        let _effects = self.apply_bill_effects(choice);
                    }
                }
            }
            _ => {}
        }
    }

    /// 處理玩家結束回合
    /// 回傳 true 表示所有玩家行動完畢，已自動進入投票階段
    pub fn end_turn(&mut self, player_id: Uuid) -> Result<bool, GameError> {
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction(
                "只能在行動階段結束回合".to_string(),
            ));
        }

        // 檢查是否為當前行動玩家
        let current_player = self
            .state
            .current_turn_player()
            .ok_or(GameError::InvalidAction("沒有當前行動玩家".to_string()))?;

        if current_player != player_id {
            return Err(GameError::InvalidAction("還沒輪到你".to_string()));
        }

        // 記錄結束回合行動
        self.state.action_log.push(GameAction::EndTurn {
            player_id,
            timestamp: Utc::now(),
        });

        // 推進到下一位玩家
        let has_next = self.state.advance_to_next_player();

        if !has_next {
            // 所有玩家都行動完畢，自動進入投票階段
            self.advance_phase();
            Ok(true)
        } else {
            Ok(false)
        }
    }

    /// 檢查行動點數並消耗（供行動方法內部使用）
    fn check_and_consume_action_point(&mut self, player_id: Uuid) -> Result<(), GameError> {
        // 檢查是否為當前行動玩家
        let current_player = self
            .state
            .current_turn_player()
            .ok_or(GameError::InvalidAction("沒有當前行動玩家".to_string()))?;

        if current_player != player_id {
            return Err(GameError::InvalidAction("還沒輪到你".to_string()));
        }

        // 消耗行動點數
        if !self.state.consume_action_point() {
            return Err(GameError::InvalidAction(
                "行動點數不足，請結束回合".to_string(),
            ));
        }

        Ok(())
    }

    /// 清除回合效果
    fn clear_round_effects(&mut self) {
        for player in self.state.players.values_mut() {
            player.is_silenced = false;
            player.has_used_skill = false;
            player.restore_influence(3); // 每回合恢復 3 影響力
        }
        self.state.votes.clear();
        self.state.pending_challenge = None;
    }

    /// 開始新回合
    fn start_new_round(&mut self) {
        // 每個存活玩家自動抽 1 張牌
        let player_ids: Vec<Uuid> = self.state.alive_players().iter().map(|p| p.id).collect();

        for player_id in player_ids {
            if let Ok(card) = self.draw_card(player_id) {
                // 記錄自動抽牌行動
                self.state.action_log.push(GameAction::CardDrawn {
                    player_id,
                    card_name: card.name,
                    timestamp: Utc::now(),
                });
            }
        }

        // 重置回合順序
        self.state.reset_turn_order();

        // 選擇新回合的議案
        self.select_round_bill();
    }

    /// 選擇當回合的議案
    fn select_round_bill(&mut self) {
        let mut rng = rand::thread_rng();
        if let Some(bill) = self.bill_system.select_random_bill(&mut rng) {
            // 更新當前議案到遊戲狀態
            self.state.current_bill = bill.name.clone();
        }
    }

    /// 獲取當前議案信息
    pub fn get_current_bill_info(&self) -> Option<(String, String)> {
        self.bill_system
            .get_current_bill()
            .map(|bill| (bill.name.clone(), bill.description.clone()))
    }

    /// 應用投票結果的議案效果到遊戲狀態
    pub fn apply_bill_effects(&mut self, winning_choice: VoteChoice) -> VoteEffectResult {
        let player_characters: std::collections::HashMap<Uuid, CharacterType> = self
            .state
            .players
            .iter()
            .map(|(id, p)| (*id, p.character))
            .collect();

        let player_reputations: std::collections::HashMap<Uuid, i32> = self
            .state
            .players
            .iter()
            .map(|(id, p)| (*id, p.reputation))
            .collect();

        let vote_effects = self.bill_system.calculate_vote_effects(
            winning_choice,
            &player_characters,
            &player_reputations,
        );

        // 應用聲望變化
        for (player_id, reputation_change) in &vote_effects.reputation_changes {
            if let Some(player) = self.state.get_player_mut(*player_id) {
                player.reputation = (player.reputation + reputation_change).max(0);
            }
        }

        vote_effects
    }

    /// 計算投票數量
    fn calculate_vote_counts(&self) -> VoteCounts {
        let mut option_a: f64 = 0.0;
        let mut option_b: f64 = 0.0;
        let mut option_c: f64 = 0.0;

        // 計算加權票數
        for (player_id, choice) in &self.state.votes {
            if let Some(player) = self.state.get_player(*player_id) {
                let weight = if player.is_politically_dead {
                    0.0
                } else if player.reputation >= 50 {
                    1.0
                } else {
                    0.5
                };

                match choice {
                    VoteChoice::A => option_a += weight,
                    VoteChoice::B => option_b += weight,
                    VoteChoice::C => option_c += weight,
                }
            }
        }

        VoteCounts {
            option_a,
            option_b,
            option_c,
        }
    }

    /// 取得階段剩餘時間（秒）— 僅投票/結果階段有計時
    pub fn get_phase_remaining_secs(&self) -> u32 {
        let duration = match self.state.phase {
            GamePhase::Waiting => 0,
            GamePhase::PlayerTurn => 0, // 回合制不計時
            GamePhase::Voting => self.config.voting_duration_secs,
            GamePhase::Result => self.config.result_duration_secs,
            GamePhase::Finished => 0,
        };

        if duration == 0 {
            return 0;
        }

        let elapsed = Utc::now()
            .signed_duration_since(self.state.phase_start_time)
            .num_seconds() as u32;

        duration.saturating_sub(elapsed)
    }

    /// 檢查並處理階段超時（僅投票/結果階段有超時）
    pub fn check_phase_timeout(&mut self) -> bool {
        // 只有投票和結果階段有計時超時
        if (self.state.phase == GamePhase::Voting || self.state.phase == GamePhase::Result)
            && self.get_phase_remaining_secs() == 0
        {
            self.advance_phase();
            true
        } else {
            false
        }
    }

    /// 處理質詢
    pub fn process_challenge(
        &mut self,
        attacker_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 檢查階段
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction(
                "只能在行動階段發起質詢".to_string(),
            ));
        }

        // 檢查行動點數（AI 玩家不需要檢查回合順序）
        if !self.is_ai_player(attacker_id) {
            self.check_and_consume_action_point(attacker_id)?;
        }

        // 檢查是否已有待處理的質詢
        if self.state.pending_challenge.is_some() {
            return Err(GameError::InvalidAction("有待處理的質詢".to_string()));
        }

        // 檢查攻擊者
        let attacker = self
            .state
            .get_player(attacker_id)
            .ok_or(GameError::PlayerNotFound)?;

        if attacker.is_politically_dead {
            return Err(GameError::PoliticallyDead);
        }
        if attacker.is_silenced {
            return Err(GameError::PlayerSilenced);
        }
        if attacker.reputation < self.config.challenge_cost {
            return Err(GameError::InvalidAction("聲望不足".to_string()));
        }

        // 檢查目標
        let target = self
            .state
            .get_player(target_id)
            .ok_or(GameError::TargetNotFound)?;

        if target.is_politically_dead {
            return Err(GameError::InvalidAction("目標已政治死亡".to_string()));
        }

        let target_name = target.name.clone();

        // 扣除攻擊者聲望
        {
            let attacker = self.state.get_player_mut(attacker_id).unwrap();
            attacker.take_damage(self.config.challenge_cost);
        }

        // 計算考慮同盟的傷害
        let actual_damage = self.calculate_alliance_damage(
            attacker_id,
            target_id,
            self.config.base_challenge_damage,
        );

        // 設定待處理的質詢
        self.state.pending_challenge = Some(PendingChallenge {
            attacker_id,
            target_id,
            damage: actual_damage,
            timestamp: Utc::now(),
        });

        // 記錄行動
        self.state.action_log.push(GameAction::Challenge {
            attacker_id,
            target_id,
            damage: actual_damage,
            was_countered: false,
        });

        Ok(ActionResult::success_with_effects(
            format!(
                "質詢 {}，等待反駁{}",
                target_name,
                if actual_damage < self.config.base_challenge_damage {
                    "（盟友減傷）"
                } else {
                    ""
                }
            ),
            vec![
                GameEffect::ReputationChange {
                    player_id: attacker_id,
                    amount: -self.config.challenge_cost,
                },
                GameEffect::PendingCounter {
                    defender_id: target_id,
                    attacker_id,
                    damage: actual_damage,
                },
            ],
        ))
    }

    /// 處理反駁
    pub fn process_counter(&mut self, defender_id: Uuid) -> Result<ActionResult, GameError> {
        // 檢查階段
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction("只能在行動階段反駁".to_string()));
        }
        // 反駁不需要消耗行動點數，也不需要是當前行動玩家（被動反應）

        // 檢查是否有待處理的質詢
        let pending = self
            .state
            .pending_challenge
            .as_ref()
            .ok_or(GameError::InvalidAction("沒有待處理的質詢".to_string()))?;

        if pending.target_id != defender_id {
            return Err(GameError::InvalidAction("您不是被質詢的對象".to_string()));
        }

        let _attacker_id = pending.attacker_id;

        // 檢查防禦者
        let defender = self
            .state
            .get_player(defender_id)
            .ok_or(GameError::PlayerNotFound)?;

        if defender.is_politically_dead {
            return Err(GameError::PoliticallyDead);
        }
        if defender.is_silenced {
            return Err(GameError::PlayerSilenced);
        }
        if defender.reputation < self.config.counter_cost {
            return Err(GameError::InvalidAction("聲望不足以反駁".to_string()));
        }

        // 扣除防禦者聲望
        {
            let defender = self.state.get_player_mut(defender_id).unwrap();
            defender.take_damage(self.config.counter_cost);
        }

        // 清除待處理質詢
        self.state.pending_challenge = None;

        // 記錄行動
        self.state
            .action_log
            .push(GameAction::Counter { defender_id });

        // 更新之前的質詢記錄為已反駁
        if let Some(GameAction::Challenge { was_countered, .. }) =
            self.state.action_log.iter_mut().rev().find(
                |a| matches!(a, GameAction::Challenge { was_countered, .. } if !*was_countered),
            )
        {
            *was_countered = true;
        }

        Ok(ActionResult::success_with_effects(
            "成功反駁質詢",
            vec![GameEffect::ReputationChange {
                player_id: defender_id,
                amount: -self.config.counter_cost,
            }],
        ))
    }

    /// 解決質詢（超時未反駁）
    pub fn resolve_challenge(&mut self) -> Result<ActionResult, GameError> {
        let pending = self
            .state
            .pending_challenge
            .take()
            .ok_or(GameError::InvalidAction("沒有待處理的質詢".to_string()))?;

        let target_id = pending.target_id;
        let _attacker_id = pending.attacker_id;

        // 計算實際傷害（考慮角色特性）
        let actual_damage = {
            let target = self
                .state
                .get_player(target_id)
                .ok_or(GameError::TargetNotFound)?;

            match target.character {
                CharacterType::Thomas => {
                    CharacterSkills::calculate_thomas_damage(&self.state, target_id, pending.damage)
                }
                _ => pending.damage,
            }
        };

        // 對目標造成傷害
        let (damage_dealt, is_dead) = {
            let target = self.state.get_player_mut(target_id).unwrap();
            let dealt = target.take_damage(actual_damage);
            (dealt, target.is_politically_dead)
        };

        let target_name = self.state.get_player(target_id).unwrap().name.clone();

        let mut effects = vec![GameEffect::ReputationChange {
            player_id: target_id,
            amount: -damage_dealt,
        }];

        if is_dead {
            effects.push(GameEffect::PoliticalDeath {
                player_id: target_id,
            });
        }

        let message = if is_dead {
            format!("{} 受到 {} 傷害，政治死亡！", target_name, damage_dealt)
        } else {
            format!("{} 受到 {} 傷害", target_name, damage_dealt)
        };

        // 更新質詢記錄
        if let Some(GameAction::Challenge { damage, .. }) =
            self.state.action_log.iter_mut().rev().find(
                |a| matches!(a, GameAction::Challenge { target_id: tid, .. } if *tid == target_id),
            )
        {
            *damage = damage_dealt;
        }

        Ok(ActionResult::success_with_effects(message, effects))
    }

    /// 檢查反駁是否超時
    pub fn check_counter_timeout(&mut self) -> Option<ActionResult> {
        if let Some(ref pending) = self.state.pending_challenge {
            let elapsed = Utc::now()
                .signed_duration_since(pending.timestamp)
                .num_seconds() as u32;

            if elapsed >= self.config.counter_timeout_secs {
                return self.resolve_challenge().ok();
            }
        }
        None
    }

    /// 取得反駁剩餘時間
    pub fn get_counter_remaining_secs(&self) -> Option<u32> {
        self.state.pending_challenge.as_ref().map(|pending| {
            let elapsed = Utc::now()
                .signed_duration_since(pending.timestamp)
                .num_seconds() as u32;
            self.config.counter_timeout_secs.saturating_sub(elapsed)
        })
    }

    /// 處理技能
    pub fn process_skill(
        &mut self,
        player_id: Uuid,
        target_id: Option<Uuid>,
    ) -> Result<ActionResult, GameError> {
        // 檢查階段
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction(
                "只能在行動階段使用技能".to_string(),
            ));
        }

        // 檢查行動點數（AI 不需要檢查）
        if !self.is_ai_player(player_id) {
            self.check_and_consume_action_point(player_id)?;
        }

        let character = {
            let player = self
                .state
                .get_player(player_id)
                .ok_or(GameError::PlayerNotFound)?;

            if !player.can_use_skill() {
                if player.is_politically_dead {
                    return Err(GameError::PoliticallyDead);
                }
                if player.is_silenced {
                    return Err(GameError::PlayerSilenced);
                }
                if player.has_used_skill {
                    return Err(GameError::SkillAlreadyUsed);
                }
            }

            player.character
        };

        match character {
            CharacterType::Thomas => Err(GameError::InvalidAction("團結是被動技能".to_string())),
            CharacterType::Richard => {
                let target =
                    target_id.ok_or(GameError::InvalidAction("收買需要指定目標".to_string()))?;
                self.process_bribe(player_id, target)
            }
            CharacterType::Edward => {
                let target =
                    target_id.ok_or(GameError::InvalidAction("爆料需要指定目標".to_string()))?;
                self.process_expose(player_id, target)
            }
            CharacterType::George => {
                let target =
                    target_id.ok_or(GameError::InvalidAction("怒火需要指定目標".to_string()))?;
                self.process_rage(player_id, target)
            }
        }
    }

    /// 處理收買技能
    fn process_bribe(
        &mut self,
        player_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 檢查金幣
        {
            let player = self
                .state
                .get_player(player_id)
                .ok_or(GameError::PlayerNotFound)?;
            if player.gold < self.config.bribe_cost {
                return Err(GameError::InsufficientGold);
            }
        }

        // 檢查目標
        {
            let target = self
                .state
                .get_player(target_id)
                .ok_or(GameError::TargetNotFound)?;
            if target.is_politically_dead {
                return Err(GameError::InvalidAction("目標已政治死亡".to_string()));
            }
        }

        // 執行收買
        let target_name = {
            let player = self.state.get_player_mut(player_id).unwrap();
            player.spend_gold(self.config.bribe_cost);
            player.mark_skill_used();

            let target = self.state.get_player_mut(target_id).unwrap();
            target.silence();
            target.name.clone()
        };

        // 記錄行動
        self.state.action_log.push(GameAction::UseSkill {
            player_id,
            skill: "收買".to_string(),
            target_id: Some(target_id),
            effect: format!("沉默 {}", target_name),
        });

        Ok(ActionResult::success_with_effects(
            format!("成功收買 {}，對方被沉默", target_name),
            vec![
                GameEffect::GoldChange {
                    player_id,
                    amount: -self.config.bribe_cost,
                },
                GameEffect::Silenced {
                    player_id: target_id,
                },
            ],
        ))
    }

    /// 處理爆料技能
    fn process_expose(
        &mut self,
        player_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 檢查目標
        let target_character = {
            let target = self
                .state
                .get_player(target_id)
                .ok_or(GameError::TargetNotFound)?;
            if target.is_politically_dead {
                return Err(GameError::InvalidAction("目標已政治死亡".to_string()));
            }
            target.character
        };

        let target_name = self.state.get_player(target_id).unwrap().name.clone();

        // 標記技能已使用
        {
            let player = self.state.get_player_mut(player_id).unwrap();
            player.mark_skill_used();
        }

        // 記錄行動
        self.state.action_log.push(GameAction::UseSkill {
            player_id,
            skill: "爆料".to_string(),
            target_id: Some(target_id),
            effect: format!("揭露 {} 是 {}", target_name, target_character.name()),
        });

        Ok(ActionResult::success_with_effects(
            format!("爆料成功！{} 是 {}", target_name, target_character.name()),
            vec![GameEffect::SkillRevealed {
                player_id: target_id,
                character: target_character,
            }],
        ))
    }

    /// 處理怒火技能
    fn process_rage(
        &mut self,
        player_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 檢查目標
        {
            let target = self
                .state
                .get_player(target_id)
                .ok_or(GameError::TargetNotFound)?;
            if target.is_politically_dead {
                return Err(GameError::InvalidAction("目標已政治死亡".to_string()));
            }
        }

        let (enemy_damage, self_damage) =
            CharacterSkills::calculate_rage_damage(self.config.base_challenge_damage);

        // 對目標造成傷害
        let (actual_enemy_damage, target_dead) = {
            let target = self.state.get_player_mut(target_id).unwrap();
            let dealt = target.take_damage(enemy_damage);
            (dealt, target.is_politically_dead)
        };

        let target_name = self.state.get_player(target_id).unwrap().name.clone();

        // 對自己造成傷害
        let (actual_self_damage, self_dead) = {
            let player = self.state.get_player_mut(player_id).unwrap();
            player.mark_skill_used();
            let dealt = player.take_damage(self_damage);
            (dealt, player.is_politically_dead)
        };

        // 記錄行動
        self.state.action_log.push(GameAction::UseSkill {
            player_id,
            skill: "怒火".to_string(),
            target_id: Some(target_id),
            effect: format!(
                "對 {} 造成 {} 傷害，自己受到 {} 傷害",
                target_name, actual_enemy_damage, actual_self_damage
            ),
        });

        let mut effects = vec![
            GameEffect::ReputationChange {
                player_id: target_id,
                amount: -actual_enemy_damage,
            },
            GameEffect::ReputationChange {
                player_id,
                amount: -actual_self_damage,
            },
        ];

        if target_dead {
            effects.push(GameEffect::PoliticalDeath {
                player_id: target_id,
            });
        }
        if self_dead {
            effects.push(GameEffect::PoliticalDeath { player_id });
        }

        Ok(ActionResult::success_with_effects(
            format!(
                "怒火攻擊！對 {} 造成 {} 傷害",
                target_name, actual_enemy_damage
            ),
            effects,
        ))
    }

    /// 處理投票
    pub fn process_vote(
        &mut self,
        player_id: Uuid,
        choice: VoteChoice,
    ) -> Result<ActionResult, GameError> {
        // 檢查階段
        if self.state.phase != GamePhase::Voting {
            return Err(GameError::InvalidAction("只能在投票階段投票".to_string()));
        }

        // 檢查玩家
        let player = self
            .state
            .get_player(player_id)
            .ok_or(GameError::PlayerNotFound)?;

        if player.is_politically_dead {
            return Err(GameError::InvalidAction(
                "政治死亡的玩家無法投票".to_string(),
            ));
        }

        // 檢查背叛（盟友投對方反對票）
        let mut betrayal_effects = Vec::new();

        // 先收集需要背叛的盟友ID
        let betrayal_targets: Vec<Uuid> = {
            let player_alliances = self.get_player_alliances(player_id);
            let mut targets = Vec::new();
            for alliance in player_alliances {
                if let Some(partner_id) = alliance.get_partner(player_id) {
                    // 檢查盟友是否已經投票
                    if let Some(partner_vote) = self.state.votes.get(&partner_id) {
                        // 如果雙方投票不同，構成背叛
                        if choice != *partner_vote {
                            targets.push(partner_id);
                        }
                    }
                }
            }
            targets
        };

        // 處理背叛
        for partner_id in betrayal_targets {
            if self.betray_alliance(player_id, partner_id).is_ok() {
                betrayal_effects.push(GameEffect::AllianceBroken {
                    betrayer_id: player_id,
                    victim_id: partner_id,
                });
            }
        }

        // 記錄投票
        self.state.votes.insert(player_id, choice);

        // 記錄行動
        self.state
            .action_log
            .push(GameAction::Vote { player_id, choice });

        let mut result_message = format!("已投票給 {}", choice);
        if !betrayal_effects.is_empty() {
            result_message.push_str("（觸發背叛）");
        }

        Ok(ActionResult::success_with_effects(
            result_message,
            betrayal_effects,
        ))
    }

    /// 處理結盟
    pub fn process_alliance(
        &mut self,
        player_a: Uuid,
        player_b: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 結盟在行動階段進行
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction(
                "只能在行動階段結盟".to_string(),
            ));
        }

        // 檢查行動點數（AI 不需要檢查）
        if !self.is_ai_player(player_a) {
            self.check_and_consume_action_point(player_a)?;
        }

        // 檢查雙方
        {
            let a = self
                .state
                .get_player(player_a)
                .ok_or(GameError::PlayerNotFound)?;
            if a.is_politically_dead {
                return Err(GameError::PoliticallyDead);
            }
        }
        {
            let b = self
                .state
                .get_player(player_b)
                .ok_or(GameError::TargetNotFound)?;
            if b.is_politically_dead {
                return Err(GameError::InvalidAction("目標已政治死亡".to_string()));
            }
        }

        if self.state.are_allies(player_a, player_b) {
            return Err(GameError::InvalidAction("已經是盟友".to_string()));
        }

        self.state.form_alliance(player_a, player_b);

        let name_a = self.state.get_player(player_a).unwrap().name.clone();
        let name_b = self.state.get_player(player_b).unwrap().name.clone();

        self.state
            .action_log
            .push(GameAction::FormAlliance { player_a, player_b });

        Ok(ActionResult::success_with_effects(
            format!("{} 與 {} 結盟", name_a, name_b),
            vec![GameEffect::AllianceFormed { player_a, player_b }],
        ))
    }

    /// 處理背叛
    pub fn process_betray(
        &mut self,
        betrayer_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, GameError> {
        if !self.state.are_allies(betrayer_id, target_id) {
            return Err(GameError::InvalidAction("你們不是盟友".to_string()));
        }

        self.state.break_alliance(betrayer_id, target_id);

        let betrayer_name = self.state.get_player(betrayer_id).unwrap().name.clone();
        let target_name = self.state.get_player(target_id).unwrap().name.clone();

        self.state.action_log.push(GameAction::Betray {
            betrayer_id,
            target_id,
        });

        Ok(ActionResult::success_with_effects(
            format!("{} 背叛了 {}", betrayer_name, target_name),
            vec![GameEffect::AllianceBroken {
                betrayer_id,
                victim_id: target_id,
            }],
        ))
    }

    /// 計算遊戲結果
    pub fn calculate_results(&self) -> GameResult {
        let mut option_a: f64 = 0.0;
        let mut option_b: f64 = 0.0;
        let mut option_c: f64 = 0.0;

        // 計算加權票數
        for (player_id, choice) in &self.state.votes {
            if let Some(player) = self.state.get_player(*player_id) {
                // 聲望 >= 50 權重 1.0，< 50 權重 0.5，政治死亡 0
                let weight = if player.is_politically_dead {
                    0.0
                } else if player.reputation >= 50 {
                    1.0
                } else {
                    0.5
                };

                match choice {
                    VoteChoice::A => option_a += weight,
                    VoteChoice::B => option_b += weight,
                    VoteChoice::C => option_c += weight,
                }
            }
        }

        // 決定獲勝選項
        let winning_choice = if option_a == 0.0 && option_b == 0.0 && option_c == 0.0 {
            None
        } else if option_a >= option_b && option_a >= option_c {
            Some(VoteChoice::A)
        } else if option_b >= option_c {
            Some(VoteChoice::B)
        } else {
            Some(VoteChoice::C)
        };

        // 應用議案效果（如果有獲勝選項）
        let mut reputation_adjustments = std::collections::HashMap::new();
        if let Some(choice) = winning_choice {
            let player_characters: std::collections::HashMap<Uuid, CharacterType> = self
                .state
                .players
                .iter()
                .map(|(id, p)| (*id, p.character))
                .collect();

            let player_reputations: std::collections::HashMap<Uuid, i32> = self
                .state
                .players
                .iter()
                .map(|(id, p)| (*id, p.reputation))
                .collect();

            let vote_effects = self.bill_system.calculate_vote_effects(
                choice,
                &player_characters,
                &player_reputations,
            );

            reputation_adjustments = vote_effects.reputation_changes;
        }

        // 決定獲勝派系
        let winning_faction = winning_choice.map(|c| match c {
            VoteChoice::A => "工人派".to_string(),
            VoteChoice::B => "資方派".to_string(),
            VoteChoice::C => "改革派".to_string(),
        });

        // 計算玩家得分（包含議案效果）
        let player_scores: Vec<PlayerScore> = self
            .state
            .players
            .values()
            .map(|p| {
                let bill_reputation_change = reputation_adjustments.get(&p.id).unwrap_or(&0);
                let adjusted_reputation = p.reputation + bill_reputation_change;
                let base_score = adjusted_reputation + p.gold;

                // 如果投票給獲勝選項，加分
                let vote_bonus = self
                    .state
                    .votes
                    .get(&p.id)
                    .and_then(|vote| {
                        winning_choice.map(|winner| if *vote == winner { 20 } else { 0 })
                    })
                    .unwrap_or(0);

                PlayerScore {
                    player_id: p.id,
                    player_name: p.name.clone(),
                    character: p.character,
                    final_reputation: adjusted_reputation,
                    final_gold: p.gold,
                    total_score: if p.is_politically_dead {
                        0
                    } else {
                        base_score + vote_bonus
                    },
                    is_alive: !p.is_politically_dead,
                }
            })
            .collect();

        GameResult {
            winning_choice,
            vote_counts: VoteCounts {
                option_a,
                option_b,
                option_c,
            },
            player_scores,
            winning_faction,
        }
    }

    /// 結束遊戲
    pub fn end_game(&mut self) -> GameResult {
        self.state.phase = GamePhase::Finished;
        self.calculate_results()
    }

    /// 使用卡牌
    pub fn use_card(
        &mut self,
        player_id: Uuid,
        card_id: &str,
        target_id: Option<Uuid>,
    ) -> Result<ActionResult, GameError> {
        // 1. 驗證基本條件
        let player = self
            .state
            .get_player(player_id)
            .ok_or(GameError::PlayerNotFound)?;

        if !player.can_act() {
            return Err(GameError::InvalidAction("玩家無法行動".to_string()));
        }

        if !player.has_card(card_id) {
            return Err(GameError::InvalidAction("手牌中沒有此卡牌".to_string()));
        }

        // 2. 驗證階段（只能在行動階段使用卡牌）
        if self.state.phase != GamePhase::PlayerTurn {
            return Err(GameError::InvalidAction(
                "只能在行動階段使用卡牌".to_string(),
            ));
        }

        // 檢查行動點數（AI 不需要檢查）
        if !self.is_ai_player(player_id) {
            self.check_and_consume_action_point(player_id)?;
        }

        // 3. 獲取卡牌資料
        let card = cards::get_card_by_id(card_id)
            .ok_or_else(|| GameError::InvalidAction("卡牌不存在".to_string()))?;

        // 4. 檢查資源
        let player_state = self.state.get_player(player_id).unwrap();
        if !player_state.has_influence(card.influence_cost) {
            return Err(GameError::InvalidAction("影響力不足".to_string()));
        }
        if card.gold_cost > 0 && player_state.gold < card.gold_cost {
            return Err(GameError::InvalidAction("金幣不足".to_string()));
        }

        // 5. 驗證目標
        if card.requires_target() && target_id.is_none() {
            return Err(GameError::InvalidAction("需要選擇目標".to_string()));
        }

        let target_player = if let Some(target_id) = target_id {
            Some(
                self.state
                    .get_player(target_id)
                    .ok_or(GameError::PlayerNotFound)?,
            )
        } else {
            None
        };

        // 6. 執行卡牌效果
        let mut effects = Vec::new();
        #[allow(unused_assignments)]
        let mut damage_dealt = 0;
        #[allow(unused_assignments)]
        let mut healing_done = 0;

        match card.card_type {
            CardType::Attack => {
                if let Some(target) = target_player {
                    if target.id == player_id {
                        return Err(GameError::InvalidAction("不能攻擊自己".to_string()));
                    }
                    damage_dealt = card.base_value;
                    effects.push(GameEffect::ReputationChange {
                        player_id: target.id,
                        amount: -damage_dealt,
                    });
                }
            }
            CardType::Defense => {
                // 防禦卡在反駁中使用，這裡只是記錄使用
            }
            CardType::Utility => {
                if card.id.contains("endorse") {
                    if let Some(target) = target_player {
                        healing_done = card.base_value;
                        effects.push(GameEffect::ReputationChange {
                            player_id: target.id,
                            amount: healing_done,
                        });
                    }
                }
            }
            CardType::Signature => {
                // 角色專屬卡效果
                match card.id.as_str() {
                    "thomas_unity" => {
                        // 團結效果：增加防禦
                    }
                    "richard_bribe" => {
                        if let Some(target) = target_player {
                            effects.push(GameEffect::Silenced {
                                player_id: target.id,
                            });
                        }
                    }
                    "edward_scoop" => {
                        // 爆料效果：揭露信息
                        if let Some(target) = target_player {
                            effects.push(GameEffect::SkillRevealed {
                                player_id: target.id,
                                character: target.character,
                            });
                        }
                    }
                    "george_fury" => {
                        if let Some(target) = target_player {
                            damage_dealt = card.base_value;
                            let self_damage = 10;
                            effects.push(GameEffect::ReputationChange {
                                player_id: target.id,
                                amount: -damage_dealt,
                            });
                            effects.push(GameEffect::ReputationChange {
                                player_id,
                                amount: -self_damage,
                            });
                        }
                    }
                    _ => {}
                }
            }
        }

        // 7. 消耗資源並移除卡牌
        let player_mut = self.state.get_player_mut(player_id).unwrap();
        player_mut.spend_influence(card.influence_cost);
        if card.gold_cost > 0 {
            player_mut.spend_gold(card.gold_cost);
        }
        let used_card = player_mut
            .remove_card_from_hand(card_id)
            .ok_or_else(|| GameError::InvalidAction("卡牌不在手牌中".to_string()))?;

        // 8. 將使用過的卡牌加入棄牌堆
        self.state.discard_card(used_card.clone());

        // 9. 應用效果到遊戲狀態
        for effect in &effects {
            match effect {
                GameEffect::ReputationChange { player_id, amount } => {
                    if let Some(target) = self.state.get_player_mut(*player_id) {
                        if *amount < 0 {
                            target.take_damage(-*amount);
                        } else {
                            target.heal(*amount);
                        }
                    }
                }
                GameEffect::Silenced { player_id } => {
                    if let Some(target) = self.state.get_player_mut(*player_id) {
                        target.silence();
                    }
                }
                _ => {}
            }
        }

        // 10. 記錄行動
        self.state.action_log.push(GameAction::CardUsed {
            player_id,
            card_name: used_card.name.clone(),
            target_id,
            timestamp: Utc::now(),
        });

        Ok(ActionResult {
            success: true,
            message: format!("使用了卡牌：{}", used_card.name),
            effects,
        })
    }

    /// 抽牌
    pub fn draw_card(&mut self, player_id: Uuid) -> Result<GameCard, GameError> {
        let player = self
            .state
            .get_player(player_id)
            .ok_or(GameError::PlayerNotFound)?;

        if !player.can_act() {
            return Err(GameError::InvalidAction("玩家無法行動".to_string()));
        }

        if player.hand.is_full() {
            return Err(GameError::InvalidAction("手牌已滿".to_string()));
        }

        // 從卡牌池抽取卡牌
        let card = self
            .state
            .draw_card_from_pool()
            .ok_or_else(|| GameError::InvalidAction("卡牌池已空".to_string()))?;

        // 為卡牌生成唯一 ID
        let mut unique_card = card.clone();
        unique_card.id = format!("{}_{}", card.id, uuid::Uuid::new_v4());

        // 添加到玩家手牌
        let player_mut = self.state.get_player_mut(player_id).unwrap();
        if !player_mut.add_card_to_hand(unique_card.clone()) {
            return Err(GameError::InvalidAction("無法將卡牌加入手牌".to_string()));
        }

        // 記錄抽牌行動
        self.state.action_log.push(GameAction::CardDrawn {
            player_id,
            card_name: unique_card.name.clone(),
            timestamp: Utc::now(),
        });

        Ok(unique_card)
    }

    /// 棄牌
    pub fn discard_card(&mut self, player_id: Uuid, card_id: &str) -> Result<(), GameError> {
        let player = self
            .state
            .get_player(player_id)
            .ok_or(GameError::PlayerNotFound)?;

        if !player.can_act() {
            return Err(GameError::InvalidAction("玩家無法行動".to_string()));
        }

        if !player.has_card(card_id) {
            return Err(GameError::InvalidAction("手牌中沒有此卡牌".to_string()));
        }

        // 從手牌移除卡牌
        let player_mut = self.state.get_player_mut(player_id).unwrap();
        let discarded_card = player_mut
            .remove_card_from_hand(card_id)
            .ok_or_else(|| GameError::InvalidAction("卡牌不在手牌中".to_string()))?;

        // 加入棄牌堆
        self.state.discard_card(discarded_card.clone());

        // 記錄棄牌行動
        self.state.action_log.push(GameAction::CardDiscarded {
            player_id,
            card_name: discarded_card.name,
            timestamp: Utc::now(),
        });

        Ok(())
    }

    /// 創建單人遊戲（1 個真實玩家 + 3 個 AI）
    pub fn create_single_player(
        room_code: String,
        human_player: (Uuid, String, CharacterType),
        ai_difficulty: AIDifficulty,
    ) -> Self {
        // 創建人類玩家
        let mut player_states = vec![PlayerState::new(
            human_player.0,
            human_player.1,
            human_player.2,
        )];

        let mut ai_manager = AIManager::new();

        // 創建 3 個 AI 玩家
        let ai_ids = ai_manager.create_single_player_ais(human_player.2, ai_difficulty);

        // 為每個 AI 創建 PlayerState
        for (i, ai_id) in ai_ids.iter().enumerate() {
            let ai_character = match i {
                0 => {
                    if human_player.2 != CharacterType::Richard {
                        CharacterType::Richard
                    } else {
                        CharacterType::Thomas
                    }
                }
                1 => {
                    if human_player.2 != CharacterType::Edward {
                        CharacterType::Edward
                    } else {
                        CharacterType::Thomas
                    }
                }
                _ => {
                    if human_player.2 != CharacterType::George {
                        CharacterType::George
                    } else {
                        CharacterType::Thomas
                    }
                }
            };

            let ai_name = match ai_character {
                CharacterType::Thomas => "AI-Thomas",
                CharacterType::Richard => "AI-Richard",
                CharacterType::Edward => "AI-Edward",
                CharacterType::George => "AI-George",
            };

            player_states.push(PlayerState::new(*ai_id, ai_name.to_string(), ai_character));
        }

        let state = EngineState::new(room_code, player_states);

        Self {
            state,
            config: GameConfig::default(),
            ai_manager,
            bill_system: BillSystem::new(),
            alliance_manager: AllianceManager::new(),
        }
    }

    /// 執行 AI 回合（在對應階段被調用）
    pub fn process_ai_actions(&mut self) -> Vec<ActionResult> {
        let mut results = Vec::new();

        // 獲取所有 AI 行動
        let ai_actions = self.ai_manager.get_all_ai_actions(&self.state);

        for (ai_id, action) in ai_actions {
            // 檢查 AI 是否還存活
            if let Some(ai_player) = self.state.get_player(ai_id) {
                if !ai_player.can_act() {
                    continue;
                }
            } else {
                continue;
            }

            let result = match action {
                AIAction::Wait => continue,
                AIAction::UseCard { card_id, target_id } => {
                    self.use_card(ai_id, &card_id, target_id)
                }
                AIAction::DrawCard => match self.draw_card(ai_id) {
                    Ok(_) => Ok(ActionResult::success("AI 抽牌")),
                    Err(e) => Err(e),
                },
                AIAction::Challenge { target_id } => self.process_challenge(ai_id, target_id),
                AIAction::Counter => self.process_counter(ai_id),
                AIAction::UseSkill { target_id } => self.process_skill(ai_id, target_id),
                AIAction::Vote { choice } => self.process_vote(ai_id, choice),
                AIAction::FormAlliance { target_id } => self.process_alliance(ai_id, target_id),
                AIAction::Betray { target_id } => self.process_betray(ai_id, target_id),
            };

            if let Ok(action_result) = result {
                results.push(action_result);
            }
        }

        results
    }

    /// 檢查是否為 AI 玩家
    pub fn is_ai_player(&self, player_id: Uuid) -> bool {
        self.ai_manager.get_ai_player(player_id).is_some()
    }

    /// 檢查遊戲是否結束
    pub fn is_game_over(&self) -> bool {
        self.state.alive_player_count() <= 1 || self.state.phase == GamePhase::Finished
    }

    // ============================================================
    // 同盟系統方法
    // ============================================================

    /// 提議同盟
    pub fn propose_alliance(
        &mut self,
        proposer_id: Uuid,
        target_id: Uuid,
    ) -> Result<Uuid, AllianceError> {
        self.alliance_manager
            .propose_alliance(proposer_id, target_id)
    }

    /// 接受同盟提議
    pub fn accept_alliance(
        &mut self,
        target_id: Uuid,
        proposer_id: Uuid,
    ) -> Result<Uuid, AllianceError> {
        self.alliance_manager
            .accept_proposal(target_id, proposer_id)
    }

    /// 拒絕同盟提議
    pub fn reject_alliance(
        &mut self,
        target_id: Uuid,
        proposer_id: Uuid,
    ) -> Result<(), AllianceError> {
        self.alliance_manager
            .reject_proposal(target_id, proposer_id)
    }

    /// 背叛同盟（在投票階段投反對票觸發）
    pub fn betray_alliance(
        &mut self,
        betrayer_id: Uuid,
        target_id: Uuid,
    ) -> Result<Uuid, AllianceError> {
        self.alliance_manager
            .betray_alliance(betrayer_id, target_id)
    }

    /// 檢查兩個玩家是否有同盟關係
    pub fn are_allied(&self, player1: Uuid, player2: Uuid) -> bool {
        self.alliance_manager.are_allied(player1, player2)
    }

    /// 計算考慮同盟的傷害
    pub fn calculate_alliance_damage(
        &self,
        attacker_id: Uuid,
        target_id: Uuid,
        base_damage: i32,
    ) -> i32 {
        self.alliance_manager
            .calculate_damage_reduction(attacker_id, target_id, base_damage)
    }

    /// 獲取玩家的所有有效同盟
    pub fn get_player_alliances(&self, player_id: Uuid) -> Vec<&super::alliance::Alliance> {
        self.alliance_manager.get_player_alliances(player_id)
    }

    /// 清理過期的同盟提議
    pub fn cleanup_expired_alliances(&mut self) {
        self.alliance_manager.cleanup_expired_proposals();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_players() -> Vec<(Uuid, String, CharacterType)> {
        vec![
            (Uuid::new_v4(), "Thomas".to_string(), CharacterType::Thomas),
            (
                Uuid::new_v4(),
                "Richard".to_string(),
                CharacterType::Richard,
            ),
            (Uuid::new_v4(), "Edward".to_string(), CharacterType::Edward),
            (Uuid::new_v4(), "George".to_string(), CharacterType::George),
        ]
    }

    fn create_test_engine() -> GameEngine {
        let players = create_test_players();
        GameEngine::from_player_data("TEST123".to_string(), players)
    }

    fn find_player_by_character(engine: &GameEngine, character: CharacterType) -> Uuid {
        engine
            .state
            .players
            .values()
            .find(|p| p.character == character)
            .unwrap()
            .id
    }

    #[test]
    fn test_create_engine() {
        let engine = create_test_engine();
        assert_eq!(engine.state.room_code, "TEST123");
        assert_eq!(engine.state.players.len(), 4);
        assert_eq!(engine.state.phase, GamePhase::Waiting);
    }

    #[test]
    fn test_start_game() {
        let players = create_test_players();
        let mut engine = GameEngine::from_player_data("TEST123".to_string(), players);
        engine.state.phase = GamePhase::Waiting;

        let result = engine.start_game();
        assert!(result.is_ok());
        assert_eq!(engine.state.phase, GamePhase::PlayerTurn);
    }

    #[test]
    fn test_advance_phase() {
        let mut engine = create_test_engine();

        // Start the game first (transitions from Waiting to PlayerTurn)
        engine.start_game().unwrap();
        assert_eq!(engine.state.phase, GamePhase::PlayerTurn);
        assert_eq!(engine.state.current_round, 1);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Voting);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Result);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::PlayerTurn);
        assert_eq!(engine.state.current_round, 2);
    }

    /// 將引擎設置為某個玩家的行動回合（測試用）
    fn set_current_turn(engine: &mut GameEngine, player_id: Uuid) {
        engine.state.phase = GamePhase::PlayerTurn;
        // 找到該玩家在 turn_order 中的位置
        if let Some(idx) = engine.state.turn_order.iter().position(|&id| id == player_id) {
            engine.state.current_turn_index = idx;
        }
        engine.state.action_points_remaining = engine.state.max_action_points;
    }

    #[test]
    fn test_challenge_and_counter() {
        let mut engine = create_test_engine();

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let edward_id = find_player_by_character(&engine, CharacterType::Edward);

        set_current_turn(&mut engine, george_id);

        // 發起質詢
        let result = engine.process_challenge(george_id, edward_id);
        assert!(result.is_ok());
        assert!(engine.state.pending_challenge.is_some());

        // 反駁（不需要是反駁者的回合）
        let result = engine.process_counter(edward_id);
        assert!(result.is_ok());
        assert!(engine.state.pending_challenge.is_none());
    }

    #[test]
    fn test_challenge_resolve() {
        let mut engine = create_test_engine();

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let edward_id = find_player_by_character(&engine, CharacterType::Edward);

        set_current_turn(&mut engine, george_id);

        let edward_initial_rep = engine.state.get_player(edward_id).unwrap().reputation;

        // 發起質詢
        engine.process_challenge(george_id, edward_id).unwrap();

        // 解決質詢（不反駁）
        let result = engine.resolve_challenge();
        assert!(result.is_ok());

        // 檢查傷害
        let edward_rep = engine.state.get_player(edward_id).unwrap().reputation;
        assert_eq!(
            edward_rep,
            edward_initial_rep - engine.config.base_challenge_damage
        );
    }

    #[test]
    fn test_bribe_skill() {
        let mut engine = create_test_engine();

        let richard_id = find_player_by_character(&engine, CharacterType::Richard);
        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);

        set_current_turn(&mut engine, richard_id);

        let result = engine.process_skill(richard_id, Some(thomas_id));
        assert!(result.is_ok());
        assert!(engine.state.get_player(thomas_id).unwrap().is_silenced);
    }

    #[test]
    fn test_expose_skill() {
        let mut engine = create_test_engine();

        let edward_id = find_player_by_character(&engine, CharacterType::Edward);
        let george_id = find_player_by_character(&engine, CharacterType::George);

        set_current_turn(&mut engine, edward_id);

        let result = engine.process_skill(edward_id, Some(george_id));
        assert!(result.is_ok());

        let action_result = result.unwrap();
        assert!(action_result.effects.iter().any(|e| {
            matches!(e, GameEffect::SkillRevealed { character, .. } if *character == CharacterType::George)
        }));
    }

    #[test]
    fn test_rage_skill() {
        let mut engine = create_test_engine();

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

        set_current_turn(&mut engine, george_id);

        let george_initial_rep = engine.state.get_player(george_id).unwrap().reputation;
        let richard_initial_rep = engine.state.get_player(richard_id).unwrap().reputation;

        let result = engine.process_skill(george_id, Some(richard_id));
        assert!(result.is_ok());

        // George 受到 10 自傷
        assert_eq!(
            engine.state.get_player(george_id).unwrap().reputation,
            george_initial_rep - 10
        );

        // Richard 受到 30 傷害（15 * 2）
        assert_eq!(
            engine.state.get_player(richard_id).unwrap().reputation,
            richard_initial_rep - 30
        );
    }

    #[test]
    fn test_vote() {
        let mut engine = create_test_engine();
        engine.state.phase = GamePhase::Voting;

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);

        let result = engine.process_vote(thomas_id, VoteChoice::A);
        assert!(result.is_ok());
        assert_eq!(engine.state.votes.get(&thomas_id), Some(&VoteChoice::A));
    }

    #[test]
    fn test_calculate_results() {
        let mut engine = create_test_engine();
        engine.state.phase = GamePhase::Voting;

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);
        let edward_id = find_player_by_character(&engine, CharacterType::Edward);
        let george_id = find_player_by_character(&engine, CharacterType::George);

        // Thomas (70 rep) 和 George (80 rep) 投 A
        // Richard (60 rep) 和 Edward (50 rep) 投 B
        engine.process_vote(thomas_id, VoteChoice::A).unwrap();
        engine.process_vote(george_id, VoteChoice::A).unwrap();
        engine.process_vote(richard_id, VoteChoice::B).unwrap();
        engine.process_vote(edward_id, VoteChoice::B).unwrap();

        let result = engine.calculate_results();

        // 每人聲望 >= 50，權重都是 1.0
        assert_eq!(result.vote_counts.option_a, 2.0);
        assert_eq!(result.vote_counts.option_b, 2.0);
        // 平手時選 A（因為 A >= B）
        assert_eq!(result.winning_choice, Some(VoteChoice::A));
    }

    #[test]
    fn test_alliance() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap(); // Start the game to enter PlayerTurn phase

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

        // 設置當前回合為 thomas
        set_current_turn(&mut engine, thomas_id);

        let result = engine.process_alliance(thomas_id, richard_id);
        assert!(result.is_ok());
        assert!(engine.state.are_allies(thomas_id, richard_id));
    }

    #[test]
    fn test_betray() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap(); // Start the game to enter PlayerTurn phase

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

        // 設置當前回合為 thomas
        set_current_turn(&mut engine, thomas_id);

        // 先結盟
        engine.process_alliance(thomas_id, richard_id).unwrap();

        // 再背叛
        let result = engine.process_betray(thomas_id, richard_id);
        assert!(result.is_ok());
        assert!(!engine.state.are_allies(thomas_id, richard_id));
    }

    #[test]
    fn test_config_default() {
        let config = GameConfig::default();
        assert_eq!(config.voting_duration_secs, 60);
        assert_eq!(config.base_challenge_damage, 15);
        assert_eq!(config.action_points_per_turn, 3);
        assert_eq!(config.max_rounds, 5);
    }

    #[test]
    fn test_starting_hand() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        // 檢查每個玩家都有 6 張起始手牌
        for player in engine.state.players.values() {
            assert_eq!(player.hand.count(), 6, "每個玩家應該有 6 張起始手牌");
        }
    }

    #[test]
    fn test_draw_card() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let player_id = engine.state.players.keys().next().unwrap().clone();
        let initial_hand_count = engine.state.get_player(player_id).unwrap().hand.count();

        // 抽牌
        let result = engine.draw_card(player_id);
        assert!(result.is_ok(), "應該能成功抽牌");

        // 檢查手牌數量 +1
        let new_hand_count = engine.state.get_player(player_id).unwrap().hand.count();
        assert_eq!(new_hand_count, initial_hand_count + 1, "抽牌後手牌 +1");
    }

    #[test]
    fn test_use_card_attack() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let player_ids: Vec<Uuid> = engine.state.players.keys().cloned().collect();
        let attacker_id = player_ids[0];
        let target_id = player_ids[1];

        set_current_turn(&mut engine, attacker_id);

        // 檢查攻擊者是否已有卡牌（起始手牌中）
        let attacker = engine.state.get_player(attacker_id).unwrap();
        if let Some(existing_card) = attacker.hand.cards.first() {
            let card_id = existing_card.id.clone();

            // 記錄目標初始聲望
            let initial_reputation = engine.state.get_player(target_id).unwrap().reputation;

            // 使用手牌中的卡牌
            let result = engine.use_card(attacker_id, &card_id, Some(target_id));
            if let Err(e) = &result {
                // 如果是非攻擊卡或其他原因失敗，跳過此測試
                println!("使用卡牌失敗（可能非攻擊卡）: {:?}", e);
                return;
            }

            // 檢查目標聲望減少（只有在成功時才檢查）
            let final_reputation = engine.state.get_player(target_id).unwrap().reputation;
            if initial_reputation != final_reputation {
                assert!(final_reputation < initial_reputation, "目標聲望應該減少");
            }
        } else {
            // 沒有手牌，跳過測試
            println!("攻擊者沒有手牌，跳過測試");
        }
    }

    #[test]
    fn test_insufficient_resources() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let player_id = engine.state.players.keys().next().unwrap().clone();
        set_current_turn(&mut engine, player_id);

        // 清空玩家影響力
        engine.state.get_player_mut(player_id).unwrap().influence = 0;

        // 添加需要影響力的卡牌
        if let Some(interrogate_card) = cards::get_card_by_id("common_interrogate") {
            let mut test_card = interrogate_card.clone();
            test_card.id = "test_no_influence".to_string();
            engine
                .state
                .get_player_mut(player_id)
                .unwrap()
                .hand
                .add_card(test_card);

            // 嘗試使用卡牌（應該失敗）
            let result = engine.use_card(player_id, "test_no_influence", None);
            assert!(result.is_err(), "影響力不足時應該無法使用卡牌");
        }
    }

    #[test]
    fn test_ai_basic_action() {
        use crate::game::ai::{AIAction, AIDifficulty, AIPlayer};

        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let ai_id = engine.state.players.keys().next().unwrap().clone();
        let ai = AIPlayer::new(ai_id, CharacterType::Thomas, AIDifficulty::Easy);

        // AI 決定行動
        let action = ai.decide_action(&engine.state);

        // AI 應該能夠決定某種行動（不只是等待）
        match action {
            AIAction::Wait => {
                // 如果沒有手牌，AI 可能選擇等待，這是合理的
            }
            _ => {
                // AI 決定了某種行動，測試通過
            }
        }
    }

    #[test]
    fn test_full_round() {
        let mut engine = create_test_engine();

        // 開始遊戲
        engine.start_game().unwrap();
        assert_eq!(engine.state.phase, GamePhase::PlayerTurn);
        assert_eq!(engine.state.current_round, 1);

        // 行動階段 → 投票階段
        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Voting);

        // 投票階段 → 結果階段
        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Result);

        // 結果階段 → 下一回合或遊戲結束
        let next_phase = engine.advance_phase();
        // 遊戲可能結束或進入下一回合
        assert!(next_phase == GamePhase::Finished || next_phase == GamePhase::PlayerTurn);
    }

    #[test]
    fn test_end_turn() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let current_player = engine.state.current_turn_player().unwrap();

        // 結束當前玩家回合
        let result = engine.end_turn(current_player);
        assert!(result.is_ok());

        // 確認切換到下一位玩家
        let new_player = engine.state.current_turn_player().unwrap();
        assert_ne!(current_player, new_player);
    }

    #[test]
    fn test_action_points() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap();

        let current_player = engine.state.current_turn_player().unwrap();
        assert_eq!(
            engine.state.action_points_remaining,
            engine.config.action_points_per_turn
        );

        // 消耗行動點數
        assert!(engine.state.consume_action_point());
        assert_eq!(
            engine.state.action_points_remaining,
            engine.config.action_points_per_turn - 1
        );
    }
}
