//! 遊戲摘要領域模型
//!
//! 定義遊戲結束後摘要系統的資料結構，包含精華時刻、報紙資料和回放資料

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 遊戲摘要
///
/// 對應資料庫 `game_summaries` 表，儲存每場遊戲的結算摘要
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct GameSummary {
    /// 摘要唯一識別碼
    pub id: Uuid,
    /// 所屬遊戲 ID
    pub game_id: Uuid,
    /// 戲劇性指數
    pub drama_score: f64,
    /// 總回合數
    pub total_rounds: i32,
    /// 獲勝陣營
    pub winning_faction: Option<String>,
    /// MVP 玩家 ID
    pub mvp_player_id: Option<Uuid>,
    /// 背叛次數
    pub betrayal_count: i32,
    /// 爆料次數
    pub expose_count: i32,
    /// 結盟次數
    pub alliance_count: i32,
    /// 最大逆轉玩家 ID
    pub biggest_comeback_player_id: Option<Uuid>,
    /// 精華時刻（JSON 陣列）
    pub highlights: serde_json::Value,
    /// 報紙資料（JSON 物件）
    pub newspaper_data: serde_json::Value,
    /// 分享 token（64 字元 URL-safe 隨機字串）
    pub share_token: Option<String>,
    /// 瀏覽次數
    pub view_count: i32,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

/// 精華時刻
///
/// 遊戲中最具戲劇性的事件片段
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Highlight {
    /// 發生回合
    pub round: i32,
    /// 事件類型
    pub event_type: String,
    /// 發起者 ID
    pub actor_id: Option<Uuid>,
    /// 發起者名稱
    pub actor_name: Option<String>,
    /// 目標 ID
    pub target_id: Option<Uuid>,
    /// 目標名稱
    pub target_name: Option<String>,
    /// 戲劇性分數
    pub drama_score: f64,
    /// 敘事鍵（用於前端選擇對應的敘事模板）
    pub narration_key: String,
}

/// 報紙資料
///
/// 模擬維多利亞時代報紙的遊戲結算頁面資料
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewspaperData {
    /// 頭條標題
    pub headline: String,
    /// 副標題
    pub subheadline: String,
    /// 內文段落
    pub body_paragraphs: Vec<String>,
    /// 引言
    pub quotes: Vec<NewspaperQuote>,
    /// MVP 玩家名稱
    pub mvp_name: Option<String>,
    /// 法案結果
    pub bill_result: Option<String>,
}

/// 報紙引言
///
/// 報紙中引用的角色發言
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewspaperQuote {
    /// 發言者
    pub speaker: String,
    /// 引言內容
    pub text: String,
    /// 上下文描述
    pub context: String,
}

/// 回放資料
///
/// 用於前端 30 秒精華回放動畫的資料結構
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReplayData {
    /// 所屬遊戲 ID
    pub game_id: Uuid,
    /// 總時長（秒）
    pub total_duration_sec: i32,
    /// 精華片段列表
    pub highlights: Vec<ReplayHighlight>,
    /// 最終分數列表
    pub final_scores: Vec<ReplayPlayerScore>,
}

/// 回放精華片段
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReplayHighlight {
    /// 時間戳（秒）
    pub timestamp_sec: i32,
    /// 回合數
    pub round: i32,
    /// 遊戲階段
    pub phase: String,
    /// 事件列表
    pub events: Vec<ReplayEvent>,
    /// 戲劇性分數
    pub drama_score: f64,
    /// 敘事鍵
    pub narration_key: String,
}

/// 回放事件
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReplayEvent {
    /// 事件類型
    pub event_type: String,
    /// 發起者 ID
    pub actor_id: Option<Uuid>,
    /// 發起者名稱
    pub actor_name: Option<String>,
    /// 目標 ID
    pub target_id: Option<Uuid>,
    /// 目標名稱
    pub target_name: Option<String>,
    /// 額外元資料
    pub metadata: serde_json::Value,
}

/// 回放玩家分數
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReplayPlayerScore {
    /// 玩家 ID
    pub player_id: Uuid,
    /// 玩家名稱
    pub player_name: String,
    /// 陣營
    pub faction: String,
    /// 最終聲望
    pub final_reputation: i32,
    /// 排名
    pub rank: i32,
}
