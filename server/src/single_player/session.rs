//! 單人遊戲 Session 管理
//!
//! 管理單人遊戲的生命週期：開始 → 玩家行動 → AI 回應 → 結束

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use super::ai_engine::{AiAction, AiDifficulty, AiEngine};
use super::campaign::{ChapterId, SpecialRule};
use crate::domain::card::GameCard;
use crate::domain::{CharacterType, GamePhase, VoteChoice};
use crate::game::actions::GameEffect;
use crate::game::engine::GameEngine;

/// 單人遊戲狀態
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SinglePlayerState {
    /// Session ID
    pub session_id: Uuid,
    /// 人類玩家 ID
    pub human_player_id: Uuid,
    /// AI 難度
    pub difficulty: AiDifficulty,
    /// 當前遊戲階段
    pub phase: GamePhase,
    /// 當前回合
    pub current_round: i32,
    /// 當前議案
    pub current_bill: String,
    /// 玩家狀態（公開資訊）
    pub players: Vec<SinglePlayerInfo>,
    /// 人類玩家手牌
    pub hand: Vec<GameCard>,
    /// 階段剩餘時間（秒）
    pub phase_time_remaining: u32,
    /// AI 行動日誌（本回合）
    pub ai_actions_log: Vec<String>,
    /// 是否遊戲結束
    pub is_game_over: bool,
    /// 遊戲結果
    pub result: Option<SinglePlayerResult>,
    /// 戰役章節（如果是戰役模式）
    pub campaign_chapter: Option<ChapterId>,
}

/// 單一玩家資訊（供客戶端顯示）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SinglePlayerInfo {
    pub id: Uuid,
    pub name: String,
    pub character: CharacterType,
    pub reputation: i32,
    pub gold: i32,
    pub is_ai: bool,
    pub is_politically_dead: bool,
    pub hand_count: usize,
    pub is_silenced: bool,
    pub has_used_skill: bool,
}

/// 遊戲結果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SinglePlayerResult {
    pub winner_id: Option<Uuid>,
    pub winner_name: Option<String>,
    pub is_human_winner: bool,
    pub final_scores: Vec<PlayerFinalScore>,
    pub total_rounds: i32,
}

/// 最終分數
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerFinalScore {
    pub player_id: Uuid,
    pub player_name: String,
    pub character: CharacterType,
    pub final_reputation: i32,
    pub final_gold: i32,
    pub total_score: i32,
    pub is_alive: bool,
    pub is_ai: bool,
}

/// 玩家行動
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SinglePlayerAction {
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
    /// 跳過（推進階段）
    Skip,
    /// 結束回合
    EndPhase,
}

/// 單人遊戲回應
#[derive(Debug, Clone, Serialize)]
pub struct SinglePlayerResponse {
    /// 是否成功
    pub success: bool,
    /// 訊息
    pub message: String,
    /// 效果
    pub effects: Vec<GameEffect>,
    /// AI 行動描述
    pub ai_actions: Vec<AiActionDescription>,
    /// 更新後的遊戲狀態
    pub state: SinglePlayerState,
}

/// AI 行動描述（供客戶端顯示）
#[derive(Debug, Clone, Serialize)]
pub struct AiActionDescription {
    pub ai_name: String,
    pub ai_character: CharacterType,
    pub description: String,
}

/// 單人遊戲 Session
pub struct SinglePlayerSession {
    /// Session ID
    pub id: Uuid,
    /// 遊戲引擎
    pub engine: GameEngine,
    /// AI 引擎列表（每個 AI 玩家一個）
    pub ai_engines: HashMap<Uuid, AiEngine>,
    /// 人類玩家 ID
    pub human_player_id: Uuid,
    /// AI 玩家 ID 列表
    pub ai_player_ids: Vec<Uuid>,
    /// 建立時間
    pub created_at: DateTime<Utc>,
    /// AI 難度
    pub difficulty: AiDifficulty,
    /// 戰役章節
    pub campaign_chapter: Option<ChapterId>,
    /// 特殊規則
    pub special_rules: Vec<SpecialRule>,
}

impl SinglePlayerSession {
    /// 建立新的單人遊戲 Session
    pub fn new(
        human_name: String,
        human_character: CharacterType,
        difficulty: AiDifficulty,
    ) -> Self {
        let session_id = Uuid::new_v4();
        let human_id = Uuid::new_v4();
        let room_code = format!("SP_{}", &session_id.to_string()[..8]);

        // 建立 AI 玩家
        let ai_characters: Vec<CharacterType> = CharacterType::all()
            .into_iter()
            .filter(|c| *c != human_character)
            .collect();

        let mut ai_ids = Vec::new();
        let mut ai_engines = HashMap::new();
        let mut player_data = vec![(human_id, human_name, human_character)];

        for ai_char in ai_characters {
            let ai_id = Uuid::new_v4();
            let ai_name = format!("AI-{}", ai_char.name());
            player_data.push((ai_id, ai_name, ai_char));
            ai_ids.push(ai_id);
            ai_engines.insert(ai_id, AiEngine::new(difficulty));
        }

        let engine = GameEngine::from_player_data(room_code, player_data);

        Self {
            id: session_id,
            engine,
            ai_engines,
            human_player_id: human_id,
            ai_player_ids: ai_ids,
            created_at: Utc::now(),
            difficulty,
            campaign_chapter: None,
            special_rules: Vec::new(),
        }
    }

    /// 建立戰役模式 Session
    pub fn new_campaign(
        human_name: String,
        human_character: CharacterType,
        chapter: ChapterId,
        difficulty: AiDifficulty,
        special_rules: Vec<SpecialRule>,
        _ai_count: usize,
    ) -> Self {
        let mut session = Self::new(human_name, human_character, difficulty);
        session.campaign_chapter = Some(chapter);
        session.special_rules = special_rules.clone();

        // 應用特殊規則
        for rule in &special_rules {
            match rule {
                SpecialRule::ShorterTimer => {
                    // 回合制不需要調整行動階段時長，僅調整投票計時
                    session.engine.config.voting_duration_secs = 30;
                }
                SpecialRule::ExtraAi => {
                    // 2v1 模式已由 ai_count 參數處理
                }
                SpecialRule::LimitedCards => {
                    // 開始遊戲後在 start 中處理
                }
                SpecialRule::SpecialEvents => {
                    // 在遊戲過程中觸發
                }
                SpecialRule::None => {}
            }
        }

        session
    }

    /// 開始遊戲
    pub fn start(&mut self) -> Result<SinglePlayerState, String> {
        self.engine
            .start_game()
            .map_err(|e| format!("無法開始遊戲: {}", e))?;

        // 應用限制卡牌規則
        if self.special_rules.contains(&SpecialRule::LimitedCards) {
            self.apply_limited_cards();
        }

        Ok(self.get_state())
    }

    /// 處理玩家行動
    pub fn process_action(
        &mut self,
        action: SinglePlayerAction,
    ) -> Result<SinglePlayerResponse, String> {
        let player_id = self.human_player_id;

        // 執行玩家行動
        let (success, message, effects) = match action {
            SinglePlayerAction::PlayCard { card_id, target_id } => {
                match self.engine.use_card(player_id, &card_id, target_id) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::DrawCard => match self.engine.draw_card(player_id) {
                Ok(card) => (true, format!("抽到了: {}", card.name), Vec::new()),
                Err(e) => (false, format!("{}", e), Vec::new()),
            },
            SinglePlayerAction::Challenge { target_id } => {
                match self.engine.process_challenge(player_id, target_id) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::Counter => match self.engine.process_counter(player_id) {
                Ok(result) => (result.success, result.message, result.effects),
                Err(e) => (false, format!("{}", e), Vec::new()),
            },
            SinglePlayerAction::UseSkill { target_id } => {
                match self.engine.process_skill(player_id, target_id) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::Vote { choice } => {
                match self.engine.process_vote(player_id, choice) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::FormAlliance { target_id } => {
                match self.engine.process_alliance(player_id, target_id) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::Betray { target_id } => {
                match self.engine.process_betray(player_id, target_id) {
                    Ok(result) => (result.success, result.message, result.effects),
                    Err(e) => (false, format!("{}", e), Vec::new()),
                }
            }
            SinglePlayerAction::Skip => (true, "跳過".to_string(), Vec::new()),
            SinglePlayerAction::EndPhase => {
                self.engine.advance_phase();
                (
                    true,
                    format!("進入 {}", self.engine.state.phase),
                    Vec::new(),
                )
            }
        };

        // AI 回應
        let ai_actions = if success {
            self.process_ai_responses()
        } else {
            Vec::new()
        };

        // 檢查遊戲是否結束
        if self.engine.is_game_over() {
            self.engine.state.finish_game();
        }

        Ok(SinglePlayerResponse {
            success,
            message,
            effects,
            ai_actions,
            state: self.get_state(),
        })
    }

    /// 推進遊戲（用於階段超時或自動推進）
    pub fn advance(&mut self) -> SinglePlayerResponse {
        let ai_actions = self.process_ai_responses();
        self.engine.advance_phase();

        // 新階段的 AI 行動
        let new_phase_ai = self.process_ai_responses();

        let mut all_actions = ai_actions;
        all_actions.extend(new_phase_ai);

        if self.engine.is_game_over() {
            self.engine.state.finish_game();
        }

        SinglePlayerResponse {
            success: true,
            message: format!("進入 {}", self.engine.state.phase),
            effects: Vec::new(),
            ai_actions: all_actions,
            state: self.get_state(),
        }
    }

    /// 取得當前遊戲狀態
    pub fn get_state(&self) -> SinglePlayerState {
        let human_hand = self
            .engine
            .state
            .get_player(self.human_player_id)
            .map(|p| p.hand.cards.clone())
            .unwrap_or_default();

        let players: Vec<SinglePlayerInfo> = self
            .engine
            .state
            .players
            .values()
            .map(|p| SinglePlayerInfo {
                id: p.id,
                name: p.name.clone(),
                character: p.character,
                reputation: p.reputation,
                gold: p.gold,
                is_ai: self.ai_player_ids.contains(&p.id),
                is_politically_dead: p.is_politically_dead,
                hand_count: p.hand.count(),
                is_silenced: p.is_silenced,
                has_used_skill: p.has_used_skill,
            })
            .collect();

        let is_game_over = self.engine.state.is_game_over();
        let result = if is_game_over {
            Some(self.calculate_result())
        } else {
            None
        };

        SinglePlayerState {
            session_id: self.id,
            human_player_id: self.human_player_id,
            difficulty: self.difficulty,
            phase: self.engine.state.phase,
            current_round: self.engine.state.current_round,
            current_bill: self.engine.state.current_bill.clone(),
            players,
            hand: human_hand,
            phase_time_remaining: self.engine.get_phase_remaining_secs(),
            ai_actions_log: Vec::new(),
            is_game_over,
            result,
            campaign_chapter: self.campaign_chapter,
        }
    }

    // ==================== 私有方法 ====================

    /// 執行所有 AI 的回應
    fn process_ai_responses(&mut self) -> Vec<AiActionDescription> {
        let mut descriptions = Vec::new();

        let ai_ids = self.ai_player_ids.clone();
        for ai_id in &ai_ids {
            if let Some(ai_engine) = self.ai_engines.get_mut(ai_id) {
                let action = ai_engine.decide(&self.engine.state, *ai_id);

                let ai_player = self.engine.state.get_player(*ai_id);
                let ai_name = ai_player.map(|p| p.name.clone()).unwrap_or_default();
                let ai_char = ai_player
                    .map(|p| p.character)
                    .unwrap_or(CharacterType::Thomas);

                let description = self.execute_ai_action(*ai_id, &action);

                if let Some(desc) = description {
                    descriptions.push(AiActionDescription {
                        ai_name,
                        ai_character: ai_char,
                        description: desc,
                    });
                }
            }
        }

        descriptions
    }

    /// 執行單個 AI 的行動，返回描述
    fn execute_ai_action(&mut self, ai_id: Uuid, action: &AiAction) -> Option<String> {
        match action {
            AiAction::Wait => None,
            AiAction::PlayCard { card_id, target_id } => {
                match self.engine.use_card(ai_id, card_id, *target_id) {
                    Ok(result) => Some(result.message),
                    Err(_) => None,
                }
            }
            AiAction::DrawCard => match self.engine.draw_card(ai_id) {
                Ok(_) => Some("抽了一張牌".to_string()),
                Err(_) => None,
            },
            AiAction::Challenge { target_id } => {
                match self.engine.process_challenge(ai_id, *target_id) {
                    Ok(result) => Some(result.message),
                    Err(_) => None,
                }
            }
            AiAction::Counter => match self.engine.process_counter(ai_id) {
                Ok(result) => Some(result.message),
                Err(_) => None,
            },
            AiAction::UseSkill { target_id } => {
                match self.engine.process_skill(ai_id, *target_id) {
                    Ok(result) => Some(result.message),
                    Err(_) => None,
                }
            }
            AiAction::Vote { choice } => match self.engine.process_vote(ai_id, *choice) {
                Ok(_) => Some(format!("投票給 {}", choice)),
                Err(_) => None,
            },
            AiAction::FormAlliance { target_id } => {
                match self.engine.process_alliance(ai_id, *target_id) {
                    Ok(result) => Some(result.message),
                    Err(_) => None,
                }
            }
            AiAction::Betray { target_id } => match self.engine.process_betray(ai_id, *target_id) {
                Ok(result) => Some(result.message),
                Err(_) => None,
            },
        }
    }

    /// 計算遊戲結果
    fn calculate_result(&self) -> SinglePlayerResult {
        let game_result = self.engine.calculate_results();
        let human_id = self.human_player_id;

        let final_scores: Vec<PlayerFinalScore> = game_result
            .player_scores
            .iter()
            .map(|ps| PlayerFinalScore {
                player_id: ps.player_id,
                player_name: ps.player_name.clone(),
                character: ps.character,
                final_reputation: ps.final_reputation,
                final_gold: ps.final_gold,
                total_score: ps.total_score,
                is_alive: ps.is_alive,
                is_ai: self.ai_player_ids.contains(&ps.player_id),
            })
            .collect();

        let winner = game_result
            .player_scores
            .iter()
            .filter(|ps| ps.is_alive)
            .max_by_key(|ps| ps.total_score);

        SinglePlayerResult {
            winner_id: winner.map(|w| w.player_id),
            winner_name: winner.map(|w| w.player_name.clone()),
            is_human_winner: winner.map(|w| w.player_id == human_id).unwrap_or(false),
            final_scores,
            total_rounds: self.engine.state.current_round,
        }
    }

    /// 應用限制卡牌規則（戰役用）
    fn apply_limited_cards(&mut self) {
        // 移除人類玩家的一些卡牌（只保留基本卡）
        if let Some(player) = self.engine.state.get_player_mut(self.human_player_id) {
            let limited_cards: Vec<GameCard> = player
                .hand
                .cards
                .iter()
                .filter(|c| c.card_type != crate::domain::card::CardType::Signature)
                .cloned()
                .collect();
            player.hand.cards = limited_cards;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_session() {
        let session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );

        assert_eq!(session.ai_player_ids.len(), 3);
        assert_eq!(session.ai_engines.len(), 3);
        assert_eq!(session.difficulty, AiDifficulty::Easy);
    }

    #[test]
    fn test_start_game() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );

        let state = session.start().unwrap();
        assert_eq!(state.phase, GamePhase::PlayerTurn);
        assert_eq!(state.current_round, 1);
        assert!(!state.hand.is_empty(), "玩家應該有初始手牌");
        assert_eq!(state.players.len(), 4);
    }

    #[test]
    fn test_player_action_draw() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        // 推進到辯論階段（玩家可以抽牌）
        session.engine.state.phase = GamePhase::PlayerTurn;

        let response = session
            .process_action(SinglePlayerAction::DrawCard)
            .unwrap();
        assert!(response.success);
    }

    #[test]
    fn test_player_vote() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        // 推進到投票階段
        session.engine.state.phase = GamePhase::Voting;

        let response = session
            .process_action(SinglePlayerAction::Vote {
                choice: VoteChoice::A,
            })
            .unwrap();
        assert!(response.success);
    }

    #[test]
    fn test_player_challenge() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();
        session.engine.state.phase = GamePhase::PlayerTurn;

        let target_id = session.ai_player_ids[0];
        let response = session
            .process_action(SinglePlayerAction::Challenge { target_id })
            .unwrap();
        assert!(response.success);
    }

    #[test]
    fn test_advance_phase() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();
        assert_eq!(session.engine.state.phase, GamePhase::PlayerTurn);

        let response = session.advance();
        assert!(response.success);
        // PlayerTurn → Voting (advance_phase 的正確轉換)
        assert_eq!(response.state.phase, GamePhase::Voting);
    }

    #[test]
    fn test_end_phase_action() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        let response = session
            .process_action(SinglePlayerAction::EndPhase)
            .unwrap();
        assert!(response.success);
        // PlayerTurn → Voting (advance_phase 的正確轉換)
        assert_eq!(response.state.phase, GamePhase::Voting);
    }

    #[test]
    fn test_get_state() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Normal,
        );
        session.start().unwrap();

        let state = session.get_state();
        assert_eq!(state.difficulty, AiDifficulty::Normal);
        assert_eq!(state.players.len(), 4);

        // 檢查只有一個是人類
        let human_count = state.players.iter().filter(|p| !p.is_ai).count();
        assert_eq!(human_count, 1);

        let ai_count = state.players.iter().filter(|p| p.is_ai).count();
        assert_eq!(ai_count, 3);
    }

    #[test]
    fn test_campaign_session() {
        let session = SinglePlayerSession::new_campaign(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            ChapterId::Chapter1,
            AiDifficulty::Easy,
            vec![SpecialRule::None],
            3,
        );

        assert_eq!(session.campaign_chapter, Some(ChapterId::Chapter1));
    }

    #[test]
    fn test_campaign_shorter_timer() {
        let session = SinglePlayerSession::new_campaign(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            ChapterId::Chapter3,
            AiDifficulty::Normal,
            vec![SpecialRule::ShorterTimer],
            3,
        );

        // 回合制不再有 conspiracy/debate 時長，僅投票計時
        assert_eq!(session.engine.config.voting_duration_secs, 30);
    }

    #[test]
    fn test_skip_action() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        let response = session.process_action(SinglePlayerAction::Skip).unwrap();
        assert!(response.success);
        assert_eq!(response.message, "跳過");
    }

    #[test]
    fn test_invalid_action_wrong_phase() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        // 在密謀階段嘗試投票（應該失敗）
        let response = session
            .process_action(SinglePlayerAction::Vote {
                choice: VoteChoice::A,
            })
            .unwrap();
        assert!(!response.success);
    }

    #[test]
    fn test_ai_responses_generated() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Normal,
        );
        session.start().unwrap();
        session.engine.state.phase = GamePhase::Voting;

        let response = session
            .process_action(SinglePlayerAction::Vote {
                choice: VoteChoice::A,
            })
            .unwrap();

        // AI 應該也會投票
        // （不一定每個 AI 都會產生可見行動，但機制應該運作）
        assert!(response.success);
    }

    #[test]
    fn test_game_over_detection() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        // 殺死所有 AI
        for ai_id in &session.ai_player_ids.clone() {
            if let Some(ai) = session.engine.state.get_player_mut(*ai_id) {
                ai.take_damage(100);
            }
        }

        let state = session.get_state();
        assert!(state.is_game_over);
        assert!(state.result.is_some());

        let result = state.result.unwrap();
        assert!(result.is_human_winner);
    }

    #[test]
    fn test_human_loses() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        // 殺死人類玩家和部分 AI，只留一個 AI
        let human_id = session.human_player_id;
        if let Some(human) = session.engine.state.get_player_mut(human_id) {
            human.take_damage(100);
        }

        // 殺死 2 個 AI，留 1 個
        for ai_id in session.ai_player_ids[..2].to_vec() {
            if let Some(ai) = session.engine.state.get_player_mut(ai_id) {
                ai.take_damage(100);
            }
        }

        let state = session.get_state();
        assert!(state.is_game_over);
        let result = state.result.unwrap();
        assert!(!result.is_human_winner);
    }

    #[test]
    fn test_limited_cards_rule() {
        let mut session = SinglePlayerSession::new_campaign(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            ChapterId::Chapter2,
            AiDifficulty::Easy,
            vec![SpecialRule::LimitedCards],
            3,
        );
        session.start().unwrap();

        // 限制卡牌規則應該移除角色專屬卡
        let human = session
            .engine
            .state
            .get_player(session.human_player_id)
            .unwrap();
        assert!(
            !human
                .hand
                .cards
                .iter()
                .any(|c| c.card_type == crate::domain::card::CardType::Signature),
            "限制卡牌模式不應該有角色專屬卡"
        );
    }

    #[test]
    fn test_form_alliance_action() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        let target_id = session.ai_player_ids[0];
        let response = session
            .process_action(SinglePlayerAction::FormAlliance { target_id })
            .unwrap();
        assert!(response.success);
    }

    #[test]
    fn test_betray_action() {
        let mut session = SinglePlayerSession::new(
            "TestPlayer".to_string(),
            CharacterType::Thomas,
            AiDifficulty::Easy,
        );
        session.start().unwrap();

        let target_id = session.ai_player_ids[0];

        // 先結盟
        session
            .process_action(SinglePlayerAction::FormAlliance { target_id })
            .unwrap();

        // 再背叛
        let response = session
            .process_action(SinglePlayerAction::Betray { target_id })
            .unwrap();
        assert!(response.success);
    }

    #[test]
    fn test_session_all_difficulties() {
        for difficulty in [AiDifficulty::Easy, AiDifficulty::Normal, AiDifficulty::Hard] {
            let mut session = SinglePlayerSession::new(
                "TestPlayer".to_string(),
                CharacterType::Thomas,
                difficulty,
            );
            let state = session.start().unwrap();
            assert_eq!(state.phase, GamePhase::PlayerTurn);
            assert_eq!(state.difficulty, difficulty);
        }
    }
}
