//! 歸因追蹤領域模型
//!
//! 定義邀請連結、轉化追蹤相關的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 歸因事件（資料庫記錄）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AttributionEvent {
    /// 事件 ID
    pub id: Uuid,
    /// 邀請者 ID
    pub inviter_id: Option<Uuid>,
    /// 被邀請者 ID
    pub invitee_id: Option<Uuid>,
    /// 來源渠道（例如：discord, twitter, line）
    pub channel: String,
    /// 深度連結 token
    pub deep_link_token: Option<String>,
    /// 狀態：pending, clicked, registered, first_game, converted
    pub status: String,
    /// 點擊次數
    pub click_count: i32,
    /// 轉化完成時間
    pub converted_at: Option<DateTime<Utc>>,
    /// 額外元資料
    pub metadata: serde_json::Value,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

/// 建立邀請連結請求
#[derive(Debug, Deserialize)]
pub struct CreateInviteRequest {
    /// 來源渠道
    pub channel: String,
}

/// 邀請連結回應
#[derive(Debug, Serialize)]
pub struct InviteLink {
    /// 邀請 ID
    pub invite_id: Uuid,
    /// 邀請 token
    pub token: String,
    /// 分享用的完整 URL
    pub share_url: String,
}

/// 邀請解析結果
#[derive(Debug, Serialize)]
pub struct InviteResolution {
    /// 邀請者 ID
    pub inviter_id: Option<Uuid>,
    /// 來源渠道
    pub channel: String,
    /// 當前狀態
    pub status: String,
}

/// 邀請統計
#[derive(Debug, Serialize)]
pub struct InviteStats {
    /// 總邀請數
    pub total_invites: i64,
    /// 總點擊數
    pub total_clicks: i64,
    /// 已註冊數
    pub total_registered: i64,
    /// 已轉化數
    pub total_converted: i64,
    /// K-factor（病毒傳播係數）
    pub k_factor: f64,
}

/// 轉化請求
#[derive(Debug, Deserialize)]
pub struct ConversionRequest {
    /// 轉化類型：registered, first_game, converted
    pub conversion_type: String,
    /// 關聯的邀請 token
    pub token: String,
}
