//! 遊戲事件領域模型
//!
//! 定義事件收集系統的資料結構，包含事件日誌、建立請求和戲劇性指數

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 遊戲事件日誌
///
/// 對應資料庫 `game_event_logs` 表，記錄遊戲中發生的每一個事件
#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct GameEventLog {
    /// 事件唯一識別碼
    pub id: Uuid,
    /// 所屬遊戲 ID
    pub game_id: Uuid,
    /// 事件類型（如 expose, challenge_success, alliance_formed 等）
    pub event_type: String,
    /// 發起者 ID
    pub actor_id: Option<Uuid>,
    /// 目標 ID
    pub target_id: Option<Uuid>,
    /// 相關卡牌類型
    pub card_type: Option<String>,
    /// 額外元資料（JSON 格式）
    pub metadata: serde_json::Value,
    /// 聲望變化量
    pub reputation_change: i32,
    /// 事件發生的回合數
    pub round_number: i32,
    /// 事件發生時的遊戲階段
    pub phase: String,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

/// 建立事件日誌的請求 DTO
///
/// 用於從遊戲引擎收集事件時傳遞資料
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateEventLog {
    /// 所屬遊戲 ID
    pub game_id: Uuid,
    /// 事件類型
    pub event_type: String,
    /// 發起者 ID
    pub actor_id: Option<Uuid>,
    /// 目標 ID
    pub target_id: Option<Uuid>,
    /// 相關卡牌類型
    pub card_type: Option<String>,
    /// 額外元資料
    pub metadata: serde_json::Value,
    /// 聲望變化量
    pub reputation_change: i32,
    /// 事件發生的回合數
    pub round_number: i32,
    /// 事件發生時的遊戲階段
    pub phase: String,
}

/// 戲劇性指數結果
///
/// 計算一場遊戲的戲劇性分數，用於遊戲結束後的精彩回顧
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DramaScore {
    /// 所屬遊戲 ID
    pub game_id: Uuid,
    /// 戲劇性分數
    pub score: f64,
    /// 最精彩的事件列表（依權重排序）
    pub top_events: Vec<GameEventLog>,
    /// 背叛次數
    pub betrayal_count: i32,
    /// 爆料次數
    pub expose_count: i32,
}
