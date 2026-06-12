//! 傳票邀請領域模型
//!
//! 定義維多利亞風格傳票邀請系統的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 傳票邀請請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSummonsRequest {
    /// 被邀請者顯示名稱
    pub target_name: String,
    /// 自訂訊息
    pub message: Option<String>,
    /// 是否包含邀請者戰績
    pub include_stats: bool,
}

/// 邀請者戰績
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InviterStats {
    /// 已遊玩場數
    pub games_played: i64,
    /// 勝率（0.0 ~ 1.0）
    pub win_rate: f64,
    /// 議員頭銜
    pub title: String,
    /// ELO 分數
    pub elo_rating: i32,
    /// 偏好陣營（最近 20 場最常選擇的角色）
    pub faction_preference: Option<String>,
}

/// 傳票回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SummonsResponse {
    /// 傳票 ID
    pub summons_id: Uuid,
    /// 分享連結
    pub share_url: String,
    /// 維多利亞風格分享文字
    pub share_text: String,
    /// 邀請者戰績（如果請求中 include_stats = true）
    pub inviter_stats: Option<InviterStats>,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}
