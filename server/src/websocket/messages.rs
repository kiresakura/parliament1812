//! WebSocket 訊息定義
//!
//! 定義客戶端和伺服器之間的 WebSocket 訊息格式

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use crate::domain::{CharacterType, GamePhase, PlayerResponse, RoomResponse, VoteChoice};

// ============================================================
// 客戶端訊息（玩家發送到伺服器）
// ============================================================

/// 客戶端訊息
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    /// 加入房間
    JoinRoom {
        /// 房間代碼
        room_code: String,
        /// 玩家名稱
        player_name: String,
    },

    /// 離開房間
    LeaveRoom,

    /// 選擇角色
    SelectCharacter {
        /// 角色類型
        character: CharacterType,
    },

    /// 準備
    Ready,

    /// 取消準備
    Unready,

    /// 開始遊戲（僅房主）
    StartGame,

    /// 發送公開聊天
    SendChat {
        /// 聊天內容
        content: String,
    },

    /// 發送私訊
    SendPrivateChat {
        /// 目標玩家 ID
        target_id: Uuid,
        /// 聊天內容
        content: String,
    },

    /// 質詢（攻擊）
    Challenge {
        /// 目標玩家 ID
        target_id: Uuid,
    },

    /// 反駁（防禦）
    Counter,

    /// 使用技能
    UseSkill {
        /// 目標玩家 ID（可選，部分技能不需要目標）
        target_id: Option<Uuid>,
    },

    /// 投票
    Vote {
        /// 投票選項
        choice: VoteChoice,
    },

    /// 使用卡牌
    UseCard {
        /// 卡牌 ID
        card_id: String,
        /// 目標玩家 ID（可選）
        target_id: Option<Uuid>,
    },

    /// 抽牌
    DrawCard,

    /// 棄牌
    DiscardCard {
        /// 卡牌 ID
        card_id: String,
    },

    /// 心跳
    Ping,
}

// ============================================================
// 伺服器訊息（伺服器發送到客戶端）
// ============================================================

/// 伺服器訊息
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    /// 連接成功
    Connected {
        /// 玩家 ID（如果已認證）
        player_id: Option<Uuid>,
        /// 伺服器版本
        server_version: String,
    },

    /// 錯誤訊息
    Error {
        /// 錯誤代碼
        code: String,
        /// 錯誤訊息
        message: String,
    },

    /// 房間狀態更新
    RoomState {
        /// 房間資訊
        room: RoomResponse,
        /// 玩家列表
        players: Vec<PlayerResponse>,
    },

    /// 玩家加入房間
    PlayerJoined {
        /// 玩家資訊
        player: PlayerResponse,
    },

    /// 玩家離開房間
    PlayerLeft {
        /// 玩家 ID
        player_id: Uuid,
        /// 玩家名稱
        player_name: String,
        /// 是否為房主離開
        was_host: bool,
        /// 新房主 ID（如果有）
        new_host_id: Option<Uuid>,
    },

    /// 玩家選擇角色
    PlayerSelectedCharacter {
        /// 玩家 ID
        player_id: Uuid,
        /// 角色類型
        character: CharacterType,
    },

    /// 玩家準備
    PlayerReady {
        /// 玩家 ID
        player_id: Uuid,
    },

    /// 玩家取消準備
    PlayerUnready {
        /// 玩家 ID
        player_id: Uuid,
    },

    /// 遊戲開始
    GameStarted {
        /// 初始階段
        phase: GamePhase,
        /// 階段持續時間（秒）
        duration_secs: u32,
    },

    /// 階段變更
    PhaseChanged {
        /// 新階段
        phase: GamePhase,
        /// 階段持續時間（秒）
        duration_secs: u32,
        /// 當前回合
        round: u32,
    },

    /// 聊天訊息
    ChatMessage {
        /// 發送者 ID
        from_id: Uuid,
        /// 發送者名稱
        from_name: String,
        /// 聊天內容
        content: String,
        /// 是否為私訊
        is_private: bool,
        /// 時間戳
        timestamp: i64,
    },

    /// 質詢事件
    ChallengeEvent {
        /// 攻擊者 ID
        attacker_id: Uuid,
        /// 攻擊者名稱
        attacker_name: String,
        /// 目標 ID
        target_id: Uuid,
        /// 目標名稱
        target_name: String,
        /// 傷害值
        damage: i32,
        /// 是否被反駁
        countered: bool,
    },

    /// 反駁事件
    CounterEvent {
        /// 防禦者 ID
        defender_id: Uuid,
        /// 防禦者名稱
        defender_name: String,
        /// 抵消的傷害
        damage_blocked: i32,
    },

    /// 技能使用
    SkillUsed {
        /// 使用者 ID
        player_id: Uuid,
        /// 使用者名稱
        player_name: String,
        /// 技能名稱
        skill_name: String,
        /// 目標 ID（可選）
        target_id: Option<Uuid>,
        /// 目標名稱（可選）
        target_name: Option<String>,
        /// 效果描述
        effect_description: String,
    },

    /// 聲望變更
    ReputationChanged {
        /// 玩家 ID
        player_id: Uuid,
        /// 新聲望值
        new_reputation: i32,
        /// 變化量（正數為增加，負數為減少）
        change: i32,
        /// 變化原因
        reason: String,
    },

    /// 金幣變更
    GoldChanged {
        /// 玩家 ID
        player_id: Uuid,
        /// 新金幣數
        new_gold: i32,
        /// 變化量
        change: i32,
        /// 變化原因
        reason: String,
    },

    /// 卡牌使用事件
    CardUsed {
        /// 使用者 ID
        player_id: Uuid,
        /// 使用者名稱
        player_name: String,
        /// 卡牌 ID
        card_id: String,
        /// 卡牌名稱
        card_name: String,
        /// 目標 ID（可選）
        target_id: Option<Uuid>,
        /// 目標名稱（可選）
        target_name: Option<String>,
        /// 效果描述
        effect_description: String,
        /// 造成的傷害/治療值
        value: i32,
    },

    /// 抽牌事件（僅發送給當事人）
    CardDrawn {
        /// 卡牌 ID
        card_id: String,
        /// 卡牌名稱
        card_name: String,
        /// 卡牌類型
        card_type: String,
        /// 卡牌描述
        description: String,
        /// 消耗
        cost: i32,
    },

    /// 手牌更新（發送完整手牌）
    HandUpdated {
        /// 手牌列表
        cards: Vec<CardInfo>,
    },

    /// 玩家手牌數量更新（公開資訊）
    PlayerHandCountChanged {
        /// 玩家 ID
        player_id: Uuid,
        /// 手牌數量
        card_count: u32,
    },

    /// 收到投票
    VoteReceived {
        /// 投票者 ID
        player_id: Uuid,
        /// 已投票人數
        votes_count: u32,
        /// 總人數
        total_players: u32,
    },

    /// 投票結果
    VoteResult {
        /// 各選項得票
        votes: HashMap<String, f64>,
        /// 獲勝選項
        winner: VoteChoice,
    },

    /// 遊戲結束
    GameResult {
        /// 獲勝陣營
        winner_faction: String,
        /// 各選項得票
        votes: HashMap<String, f64>,
        /// 玩家排名
        rankings: Vec<PlayerRanking>,
    },

    /// 玩家政治死亡
    PlayerPoliticalDeath {
        /// 玩家 ID
        player_id: Uuid,
        /// 玩家名稱
        player_name: String,
    },

    /// 系統訊息
    SystemMessage {
        /// 訊息內容
        content: String,
        /// 訊息類型
        message_type: SystemMessageType,
    },

    /// 心跳回應
    Pong {
        /// 伺服器時間戳
        timestamp: i64,
    },

    /// 計時器更新
    TimerUpdate {
        /// 剩餘秒數
        remaining_secs: u32,
    },
}

/// 卡牌資訊（用於 WebSocket 傳輸）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CardInfo {
    /// 卡牌 ID
    pub id: String,
    /// 卡牌名稱
    pub name: String,
    /// 卡牌描述
    pub description: String,
    /// 卡牌類型
    pub card_type: String,
    /// 稀有度
    pub rarity: String,
    /// 目標類型
    pub target_type: String,
    /// 影響力消耗
    pub influence_cost: i32,
    /// 金幣消耗
    pub gold_cost: i32,
    /// 基礎效果值
    pub base_value: i32,
    /// 角色專屬（可選）
    pub role_id: Option<String>,
}

/// 玩家排名
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerRanking {
    /// 玩家 ID
    pub player_id: Uuid,
    /// 玩家名稱
    pub player_name: String,
    /// 角色
    pub character: CharacterType,
    /// 最終聲望
    pub final_reputation: i32,
    /// 排名
    pub rank: u32,
    /// 獲得分數
    pub score: i32,
}

/// 系統訊息類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SystemMessageType {
    /// 資訊
    Info,
    /// 警告
    Warning,
    /// 成功
    Success,
    /// 錯誤
    Error,
}

// ============================================================
// 錯誤代碼常數
// ============================================================

/// 錯誤代碼
pub mod error_codes {
    /// 未授權
    pub const UNAUTHORIZED: &str = "UNAUTHORIZED";
    /// 房間不存在
    pub const ROOM_NOT_FOUND: &str = "ROOM_NOT_FOUND";
    /// 房間已滿
    pub const ROOM_FULL: &str = "ROOM_FULL";
    /// 遊戲已開始
    pub const GAME_ALREADY_STARTED: &str = "GAME_ALREADY_STARTED";
    /// 不在房間中
    pub const NOT_IN_ROOM: &str = "NOT_IN_ROOM";
    /// 非房主
    pub const NOT_HOST: &str = "NOT_HOST";
    /// 無效動作
    pub const INVALID_ACTION: &str = "INVALID_ACTION";
    /// 不是你的回合
    pub const NOT_YOUR_TURN: &str = "NOT_YOUR_TURN";
    /// 目標無效
    pub const INVALID_TARGET: &str = "INVALID_TARGET";
    /// 資源不足
    pub const INSUFFICIENT_RESOURCES: &str = "INSUFFICIENT_RESOURCES";
    /// 技能冷卻中
    pub const SKILL_ON_COOLDOWN: &str = "SKILL_ON_COOLDOWN";
    /// 已投票
    pub const ALREADY_VOTED: &str = "ALREADY_VOTED";
    /// 內部錯誤
    pub const INTERNAL_ERROR: &str = "INTERNAL_ERROR";
}

// ============================================================
// 輔助方法
// ============================================================

impl ServerMessage {
    /// 建立錯誤訊息
    pub fn error(code: impl Into<String>, message: impl Into<String>) -> Self {
        ServerMessage::Error {
            code: code.into(),
            message: message.into(),
        }
    }

    /// 建立系統訊息
    pub fn system(content: impl Into<String>, message_type: SystemMessageType) -> Self {
        ServerMessage::SystemMessage {
            content: content.into(),
            message_type,
        }
    }

    /// 建立資訊系統訊息
    pub fn info(content: impl Into<String>) -> Self {
        Self::system(content, SystemMessageType::Info)
    }

    /// 建立警告系統訊息
    pub fn warning(content: impl Into<String>) -> Self {
        Self::system(content, SystemMessageType::Warning)
    }

    /// 建立成功系統訊息
    pub fn success(content: impl Into<String>) -> Self {
        Self::system(content, SystemMessageType::Success)
    }
}

impl ClientMessage {
    /// 檢查訊息是否需要在房間內
    pub fn requires_room(&self) -> bool {
        !matches!(self, ClientMessage::JoinRoom { .. } | ClientMessage::Ping)
    }

    /// 檢查訊息是否需要遊戲進行中
    pub fn requires_game_in_progress(&self) -> bool {
        matches!(
            self,
            ClientMessage::Challenge { .. }
                | ClientMessage::Counter
                | ClientMessage::UseSkill { .. }
                | ClientMessage::Vote { .. }
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_client_message_serialization() {
        let msg = ClientMessage::JoinRoom {
            room_code: "ABC123".to_string(),
            player_name: "TestPlayer".to_string(),
        };

        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("join_room"));
        assert!(json.contains("ABC123"));

        let deserialized: ClientMessage = serde_json::from_str(&json).unwrap();
        match deserialized {
            ClientMessage::JoinRoom {
                room_code,
                player_name,
            } => {
                assert_eq!(room_code, "ABC123");
                assert_eq!(player_name, "TestPlayer");
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_server_message_serialization() {
        let msg = ServerMessage::Connected {
            player_id: Some(Uuid::new_v4()),
            server_version: "0.1.0".to_string(),
        };

        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("connected"));
        assert!(json.contains("0.1.0"));
    }

    #[test]
    fn test_error_message() {
        let msg = ServerMessage::error(error_codes::ROOM_NOT_FOUND, "房間不存在");

        match msg {
            ServerMessage::Error { code, message } => {
                assert_eq!(code, "ROOM_NOT_FOUND");
                assert_eq!(message, "房間不存在");
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_client_message_requires_room() {
        assert!(!ClientMessage::JoinRoom {
            room_code: "".to_string(),
            player_name: "".to_string(),
        }
        .requires_room());

        assert!(ClientMessage::LeaveRoom.requires_room());
        assert!(ClientMessage::Ready.requires_room());
        assert!(!ClientMessage::Ping.requires_room());
    }
}
