//! 遊戲領域模型
//!
//! 定義遊戲相關的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::player::PlayerResponse;

/// 遊戲階段
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum GamePhase {
    /// 等待中
    #[default]
    Waiting,
    /// 玩家行動階段（回合制核心：玩家輪流行動）
    PlayerTurn,
    /// 投票階段
    Voting,
    /// 結果階段
    Result,
    /// 已結束
    Finished,
}

impl std::fmt::Display for GamePhase {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            GamePhase::Waiting => write!(f, "等待中"),
            GamePhase::PlayerTurn => write!(f, "玩家行動"),
            GamePhase::Voting => write!(f, "投票階段"),
            GamePhase::Result => write!(f, "結果階段"),
            GamePhase::Finished => write!(f, "已結束"),
        }
    }
}

/// 投票選項
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum VoteChoice {
    /// 選項 A：禁止機器
    A,
    /// 選項 B：保護財產
    B,
    /// 選項 C：折衷改革
    C,
}

impl std::fmt::Display for VoteChoice {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VoteChoice::A => write!(f, "A. 禁止機器"),
            VoteChoice::B => write!(f, "B. 保護財產"),
            VoteChoice::C => write!(f, "C. 折衷改革"),
        }
    }
}

impl VoteChoice {
    /// 取得選項描述
    pub fn description(&self) -> &'static str {
        match self {
            VoteChoice::A => "禁止機器 → 工人派 +50 分",
            VoteChoice::B => "保護財產 → 資方派 +50 分",
            VoteChoice::C => "折衷改革 → 改革派 +30 分",
        }
    }

    /// 取得所有選項
    pub fn all() -> Vec<VoteChoice> {
        vec![VoteChoice::A, VoteChoice::B, VoteChoice::C]
    }
}

/// 遊戲動作類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ActionType {
    /// 質詢（攻擊）
    Question,
    /// 反駁（防禦）
    Rebut,
    /// 使用技能
    Skill,
    /// 跳過
    Pass,
}

impl std::fmt::Display for ActionType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ActionType::Question => write!(f, "質詢"),
            ActionType::Rebut => write!(f, "反駁"),
            ActionType::Skill => write!(f, "技能"),
            ActionType::Pass => write!(f, "跳過"),
        }
    }
}

/// 遊戲動作
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameActionRecord {
    /// 動作 ID
    pub id: Uuid,
    /// 執行者 ID
    pub actor_id: Uuid,
    /// 動作類型
    pub action_type: ActionType,
    /// 目標 ID（可選）
    pub target_id: Option<Uuid>,
    /// 傷害/效果值
    pub value: i32,
    /// 動作時間
    pub timestamp: DateTime<Utc>,
    /// 動作描述
    pub description: String,
}

impl GameActionRecord {
    /// 建立新動作
    pub fn new(
        actor_id: Uuid,
        action_type: ActionType,
        target_id: Option<Uuid>,
        value: i32,
        description: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            actor_id,
            action_type,
            target_id,
            value,
            timestamp: Utc::now(),
            description,
        }
    }
}

/// 投票記錄
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Vote {
    /// 投票者 ID
    pub player_id: Uuid,
    /// 投票選項
    pub choice: VoteChoice,
    /// 投票權重
    pub weight: f64,
    /// 投票時間
    pub timestamp: DateTime<Utc>,
}

impl Vote {
    /// 建立新投票
    pub fn new(player_id: Uuid, choice: VoteChoice, weight: f64) -> Self {
        Self {
            player_id,
            choice,
            weight,
            timestamp: Utc::now(),
        }
    }
}

/// 投票結果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteResult {
    /// 各選項得票
    pub votes: std::collections::HashMap<VoteChoice, f64>,
    /// 獲勝選項
    pub winner: VoteChoice,
    /// 所有投票記錄
    pub vote_records: Vec<Vote>,
}

/// 遊戲狀態
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameState {
    /// 遊戲 ID
    pub id: Uuid,
    /// 房間 ID
    pub room_id: Uuid,
    /// 當前階段
    pub phase: GamePhase,
    /// 當前回合
    pub round: i32,
    /// 階段剩餘時間（秒）— 僅投票階段使用
    pub phase_time_remaining: i32,
    /// 當前議案
    pub current_bill: String,
    /// 遊戲動作歷史
    pub actions: Vec<GameActionRecord>,
    /// 投票記錄
    pub votes: Vec<Vote>,
    /// 開始時間
    pub started_at: Option<DateTime<Utc>>,
    /// 結束時間
    pub ended_at: Option<DateTime<Utc>>,
    /// 回合順序（玩家 ID 列表）
    pub turn_order: Vec<Uuid>,
    /// 當前行動玩家索引（在 turn_order 中的位置）
    pub current_turn_index: usize,
    /// 當前行動玩家剩餘行動點數
    pub action_points_remaining: i32,
    /// 每回合行動點數上限
    pub max_action_points: i32,
}

impl GameState {
    /// 建立新遊戲狀態
    pub fn new(room_id: Uuid) -> Self {
        Self {
            id: Uuid::new_v4(),
            room_id,
            phase: GamePhase::Waiting,
            round: 0,
            phase_time_remaining: 0,
            current_bill: "機器法案".to_string(),
            actions: Vec::new(),
            votes: Vec::new(),
            started_at: None,
            ended_at: None,
            turn_order: Vec::new(),
            current_turn_index: 0,
            action_points_remaining: 3,
            max_action_points: 3,
        }
    }

    /// 開始遊戲
    pub fn start(&mut self) {
        self.phase = GamePhase::PlayerTurn;
        self.round = 1;
        self.phase_time_remaining = 0;
        self.started_at = Some(Utc::now());
    }

    /// 取得當前行動玩家 ID
    pub fn current_turn_player(&self) -> Option<Uuid> {
        self.turn_order.get(self.current_turn_index).copied()
    }

    /// 進入下一階段
    pub fn next_phase(&mut self) {
        match self.phase {
            GamePhase::Waiting => {
                self.phase = GamePhase::PlayerTurn;
                self.phase_time_remaining = 0;
            }
            GamePhase::PlayerTurn => {
                self.phase = GamePhase::Voting;
                self.phase_time_remaining = 60; // 投票階段 60 秒
            }
            GamePhase::Voting => {
                self.phase = GamePhase::Result;
                self.phase_time_remaining = 30; // 結果階段 30 秒
            }
            GamePhase::Result => {
                self.phase = GamePhase::Finished;
                self.phase_time_remaining = 0;
                self.ended_at = Some(Utc::now());
            }
            GamePhase::Finished => {}
        }
    }

    /// 記錄動作
    pub fn record_action(&mut self, action: GameActionRecord) {
        self.actions.push(action);
    }

    /// 記錄投票
    pub fn record_vote(&mut self, vote: Vote) {
        // 移除該玩家之前的投票（如果有）
        self.votes.retain(|v| v.player_id != vote.player_id);
        self.votes.push(vote);
    }

    /// 計算投票結果
    pub fn calculate_vote_result(&self) -> VoteResult {
        use std::collections::HashMap;

        let mut votes: HashMap<VoteChoice, f64> = HashMap::new();
        votes.insert(VoteChoice::A, 0.0);
        votes.insert(VoteChoice::B, 0.0);
        votes.insert(VoteChoice::C, 0.0);

        for vote in &self.votes {
            *votes.entry(vote.choice).or_insert(0.0) += vote.weight;
        }

        // 找出獲勝選項
        let winner = votes
            .iter()
            .max_by(|a, b| a.1.partial_cmp(b.1).unwrap())
            .map(|(choice, _)| *choice)
            .unwrap_or(VoteChoice::C);

        VoteResult {
            votes,
            winner,
            vote_records: self.votes.clone(),
        }
    }
}

/// 遊戲回應（給客戶端）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameResponse {
    /// 遊戲 ID
    pub id: Uuid,
    /// 房間 ID
    pub room_id: Uuid,
    /// 當前階段
    pub phase: GamePhase,
    /// 當前回合
    pub round: i32,
    /// 階段剩餘時間（僅投票階段）
    pub phase_time_remaining: i32,
    /// 當前議案
    pub current_bill: String,
    /// 玩家列表
    pub players: Vec<PlayerResponse>,
    /// 最近動作
    pub recent_actions: Vec<GameActionRecord>,
    /// 當前行動玩家 ID（回合制）
    pub current_turn_player_id: Option<Uuid>,
    /// 當前玩家剩餘行動點數
    pub action_points_remaining: i32,
    /// 回合順序
    pub turn_order: Vec<Uuid>,
}

/// 遊戲事件（WebSocket 推送）
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum GameEvent {
    /// 玩家加入
    PlayerJoined { player: PlayerResponse },
    /// 玩家離開
    PlayerLeft { player_id: Uuid },
    /// 遊戲開始
    GameStarted { game_id: Uuid },
    /// 階段變更
    PhaseChanged {
        phase: GamePhase,
        time_remaining: i32,
    },
    /// 回合變更（輪到某玩家行動）
    TurnChanged {
        player_id: Uuid,
        action_points: i32,
    },
    /// 動作執行
    ActionPerformed { action: GameActionRecord },
    /// 玩家狀態更新
    PlayerUpdated { player: PlayerResponse },
    /// 投票提交
    VoteSubmitted { player_id: Uuid },
    /// 遊戲結束
    GameEnded { result: VoteResult },
    /// 聊天訊息
    ChatMessage {
        sender_id: Uuid,
        sender_name: String,
        message: String,
        is_private: bool,
    },
}

/// 投票請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteRequest {
    /// 投票選項
    pub choice: VoteChoice,
}

/// 聊天請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatRequest {
    /// 訊息內容
    pub message: String,
    /// 是否私訊
    #[serde(default)]
    pub is_private: bool,
    /// 私訊目標（如果是私訊）
    pub target_id: Option<Uuid>,
}

impl ChatRequest {
    /// 驗證請求
    pub fn validate(&self) -> Result<(), &'static str> {
        if self.message.is_empty() {
            return Err("訊息不能為空");
        }
        if self.message.len() > 500 {
            return Err("訊息不能超過 500 個字元");
        }
        if self.is_private && self.target_id.is_none() {
            return Err("私訊必須指定目標");
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_game_phase_flow() {
        let mut state = GameState::new(Uuid::new_v4());
        assert_eq!(state.phase, GamePhase::Waiting);

        state.start();
        assert_eq!(state.phase, GamePhase::PlayerTurn);

        state.next_phase();
        assert_eq!(state.phase, GamePhase::Voting);

        state.next_phase();
        assert_eq!(state.phase, GamePhase::Result);

        state.next_phase();
        assert_eq!(state.phase, GamePhase::Finished);
    }

    #[test]
    fn test_vote_calculation() {
        let mut state = GameState::new(Uuid::new_v4());

        // 模擬投票
        state.record_vote(Vote::new(Uuid::new_v4(), VoteChoice::A, 1.5));
        state.record_vote(Vote::new(Uuid::new_v4(), VoteChoice::A, 1.0));
        state.record_vote(Vote::new(Uuid::new_v4(), VoteChoice::B, 1.0));

        let result = state.calculate_vote_result();
        assert_eq!(result.winner, VoteChoice::A);
        assert_eq!(*result.votes.get(&VoteChoice::A).unwrap(), 2.5);
    }

    #[test]
    fn test_vote_override() {
        let mut state = GameState::new(Uuid::new_v4());
        let player_id = Uuid::new_v4();

        // 玩家先投 A
        state.record_vote(Vote::new(player_id, VoteChoice::A, 1.0));
        assert_eq!(state.votes.len(), 1);

        // 玩家改投 B
        state.record_vote(Vote::new(player_id, VoteChoice::B, 1.0));
        assert_eq!(state.votes.len(), 1);
        assert_eq!(state.votes[0].choice, VoteChoice::B);
    }
}
