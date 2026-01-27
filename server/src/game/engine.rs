//! 遊戲引擎
//!
//! 協調遊戲流程、處理階段轉換、管理遊戲狀態

use chrono::Utc;
use rand::seq::SliceRandom;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::actions::{ActionResult, GameAction, GameEffect, GameResult, PlayerScore, VoteCounts};
use super::characters::{CharacterSkills, GameError};
use super::state::{GameState, PendingChallenge, PlayerState};
use crate::domain::{CharacterType, GamePhase, Player, VoteChoice};

/// 遊戲設定
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameConfig {
    /// 密謀階段時長（秒）
    pub conspiracy_duration_secs: u32,
    /// 辯論階段時長（秒）
    pub debate_duration_secs: u32,
    /// 投票階段時長（秒）
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
}

impl Default for GameConfig {
    fn default() -> Self {
        Self {
            conspiracy_duration_secs: 120,
            debate_duration_secs: 300,
            voting_duration_secs: 60,
            result_duration_secs: 30,
            counter_timeout_secs: 10,
            base_challenge_damage: 15,
            challenge_cost: 10,
            counter_cost: 5,
            bribe_cost: 30,
        }
    }
}

/// 遊戲引擎
#[derive(Debug, Clone)]
pub struct GameEngine {
    /// 遊戲狀態
    pub state: GameState,
    /// 遊戲設定
    pub config: GameConfig,
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

        let state = GameState::new(room_code, player_states);

        Self { state, config }
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

        let state = GameState::new(room_code, player_states);

        Self {
            state,
            config: GameConfig::default(),
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

        self.state.phase = GamePhase::Conspiracy;
        self.state.phase_start_time = Utc::now();
        self.state.current_round = 1;

        Ok(())
    }

    /// 進入下一階段
    pub fn advance_phase(&mut self) -> GamePhase {
        // 處理階段結束事件
        self.handle_phase_end();

        // 轉換到下一階段
        self.state.phase = match self.state.phase {
            GamePhase::Waiting => GamePhase::Conspiracy,
            GamePhase::Conspiracy => GamePhase::Debate,
            GamePhase::Debate => GamePhase::Voting,
            GamePhase::Voting => GamePhase::Result,
            GamePhase::Result => {
                self.state.current_round += 1;
                self.clear_round_effects();
                GamePhase::Conspiracy
            }
            GamePhase::Finished => GamePhase::Finished,
        };

        self.state.phase_start_time = Utc::now();
        self.state.phase
    }

    /// 處理階段結束
    fn handle_phase_end(&mut self) {
        match self.state.phase {
            GamePhase::Debate => {
                // 處理未決的質詢
                if self.state.pending_challenge.is_some() {
                    let _ = self.resolve_challenge();
                }
            }
            GamePhase::Voting => {
                // 投票結果會在 calculate_results 中處理
            }
            _ => {}
        }
    }

    /// 清除回合效果
    fn clear_round_effects(&mut self) {
        for player in self.state.players.values_mut() {
            player.is_silenced = false;
            player.has_used_skill = false;
        }
        self.state.votes.clear();
        self.state.pending_challenge = None;
    }

    /// 取得階段剩餘時間（秒）
    pub fn get_phase_remaining_secs(&self) -> u32 {
        let duration = match self.state.phase {
            GamePhase::Waiting => 0,
            GamePhase::Conspiracy => self.config.conspiracy_duration_secs,
            GamePhase::Debate => self.config.debate_duration_secs,
            GamePhase::Voting => self.config.voting_duration_secs,
            GamePhase::Result => self.config.result_duration_secs,
            GamePhase::Finished => 0,
        };

        let elapsed = Utc::now()
            .signed_duration_since(self.state.phase_start_time)
            .num_seconds() as u32;

        duration.saturating_sub(elapsed)
    }

    /// 檢查並處理階段超時
    pub fn check_phase_timeout(&mut self) -> bool {
        if self.get_phase_remaining_secs() == 0 && self.state.phase != GamePhase::Finished {
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
        if self.state.phase != GamePhase::Debate {
            return Err(GameError::InvalidAction(
                "只能在辯論階段發起質詢".to_string(),
            ));
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

        // 設定待處理的質詢
        self.state.pending_challenge = Some(PendingChallenge {
            attacker_id,
            target_id,
            damage: self.config.base_challenge_damage,
            timestamp: Utc::now(),
        });

        // 記錄行動
        self.state.action_log.push(GameAction::Challenge {
            attacker_id,
            target_id,
            damage: self.config.base_challenge_damage,
            was_countered: false,
        });

        Ok(ActionResult::success_with_effects(
            format!("質詢 {}，等待反駁", target_name),
            vec![
                GameEffect::ReputationChange {
                    player_id: attacker_id,
                    amount: -self.config.challenge_cost,
                },
                GameEffect::PendingCounter {
                    defender_id: target_id,
                    attacker_id,
                    damage: self.config.base_challenge_damage,
                },
            ],
        ))
    }

    /// 處理反駁
    pub fn process_counter(&mut self, defender_id: Uuid) -> Result<ActionResult, GameError> {
        // 檢查階段
        if self.state.phase != GamePhase::Debate {
            return Err(GameError::InvalidAction("只能在辯論階段反駁".to_string()));
        }

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
        if self.state.phase != GamePhase::Debate {
            return Err(GameError::InvalidAction(
                "只能在辯論階段使用技能".to_string(),
            ));
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

        // 記錄投票
        self.state.votes.insert(player_id, choice);

        // 記錄行動
        self.state
            .action_log
            .push(GameAction::Vote { player_id, choice });

        Ok(ActionResult::success(format!("已投票給 {}", choice)))
    }

    /// 處理結盟
    pub fn process_alliance(
        &mut self,
        player_a: Uuid,
        player_b: Uuid,
    ) -> Result<ActionResult, GameError> {
        // 結盟可以在密謀和辯論階段
        if self.state.phase != GamePhase::Conspiracy && self.state.phase != GamePhase::Debate {
            return Err(GameError::InvalidAction(
                "只能在密謀或辯論階段結盟".to_string(),
            ));
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

        // 決定獲勝派系
        let winning_faction = winning_choice.map(|c| match c {
            VoteChoice::A => "工人派".to_string(),
            VoteChoice::B => "資方派".to_string(),
            VoteChoice::C => "改革派".to_string(),
        });

        // 計算玩家得分
        let player_scores: Vec<PlayerScore> = self
            .state
            .players
            .values()
            .map(|p| {
                let base_score = p.reputation + p.gold;
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
                    final_reputation: p.reputation,
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

    /// 檢查遊戲是否結束
    pub fn is_game_over(&self) -> bool {
        self.state.alive_player_count() <= 1 || self.state.phase == GamePhase::Finished
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
        assert_eq!(engine.state.phase, GamePhase::Conspiracy);
    }

    #[test]
    fn test_advance_phase() {
        let mut engine = create_test_engine();

        // Start the game first (transitions from Waiting to Conspiracy)
        engine.start_game().unwrap();
        assert_eq!(engine.state.phase, GamePhase::Conspiracy);
        assert_eq!(engine.state.current_round, 1);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Debate);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Voting);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Result);

        engine.advance_phase();
        assert_eq!(engine.state.phase, GamePhase::Conspiracy);
        assert_eq!(engine.state.current_round, 2);
    }

    #[test]
    fn test_challenge_and_counter() {
        let mut engine = create_test_engine();
        engine.state.phase = GamePhase::Debate;

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let edward_id = find_player_by_character(&engine, CharacterType::Edward);

        // 發起質詢
        let result = engine.process_challenge(george_id, edward_id);
        assert!(result.is_ok());
        assert!(engine.state.pending_challenge.is_some());

        // 反駁
        let result = engine.process_counter(edward_id);
        assert!(result.is_ok());
        assert!(engine.state.pending_challenge.is_none());
    }

    #[test]
    fn test_challenge_resolve() {
        let mut engine = create_test_engine();
        engine.state.phase = GamePhase::Debate;

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let edward_id = find_player_by_character(&engine, CharacterType::Edward);

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
        engine.state.phase = GamePhase::Debate;

        let richard_id = find_player_by_character(&engine, CharacterType::Richard);
        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);

        let result = engine.process_skill(richard_id, Some(thomas_id));
        assert!(result.is_ok());
        assert!(engine.state.get_player(thomas_id).unwrap().is_silenced);
    }

    #[test]
    fn test_expose_skill() {
        let mut engine = create_test_engine();
        engine.state.phase = GamePhase::Debate;

        let edward_id = find_player_by_character(&engine, CharacterType::Edward);
        let george_id = find_player_by_character(&engine, CharacterType::George);

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
        engine.state.phase = GamePhase::Debate;

        let george_id = find_player_by_character(&engine, CharacterType::George);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

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
        engine.start_game().unwrap(); // Start the game to enter Conspiracy phase

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

        let result = engine.process_alliance(thomas_id, richard_id);
        assert!(result.is_ok());
        assert!(engine.state.are_allies(thomas_id, richard_id));
    }

    #[test]
    fn test_betray() {
        let mut engine = create_test_engine();
        engine.start_game().unwrap(); // Start the game to enter Conspiracy phase

        let thomas_id = find_player_by_character(&engine, CharacterType::Thomas);
        let richard_id = find_player_by_character(&engine, CharacterType::Richard);

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
        assert_eq!(config.conspiracy_duration_secs, 120);
        assert_eq!(config.debate_duration_secs, 300);
        assert_eq!(config.voting_duration_secs, 60);
        assert_eq!(config.base_challenge_damage, 15);
    }
}
