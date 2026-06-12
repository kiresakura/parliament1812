//! 串流整合領域模型
//!
//! 定義串流平台（Twitch / YouTube）整合相關的資料結構，
//! 包含帳號綁定、串流事件、精華片段等

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// ============================================================
// 資料庫模型
// ============================================================

/// 串流平台帳號綁定
///
/// 對應資料庫 `streaming_accounts` 表
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct StreamingAccount {
    /// 帳號 ID
    pub id: Uuid,
    /// 用戶 ID
    pub user_id: Uuid,
    /// 平台名稱：twitch / youtube
    pub platform: String,
    /// 平台上的用戶 ID
    pub platform_user_id: String,
    /// 平台上的用戶名稱
    pub platform_username: Option<String>,
    /// OAuth access token
    /// TODO: 未來應加密存儲，目前為 plaintext
    pub access_token: Option<String>,
    /// OAuth refresh token
    /// TODO: 未來應加密存儲，目前為 plaintext
    pub refresh_token: Option<String>,
    /// Token 過期時間
    pub token_expires_at: Option<DateTime<Utc>>,
    /// 是否正在直播
    pub is_live: bool,
    /// 帳號設定（JSON）
    pub settings: serde_json::Value,
    /// 建立時間
    pub created_at: DateTime<Utc>,
    /// 更新時間
    pub updated_at: DateTime<Utc>,
}

/// 串流事件紀錄
///
/// 對應資料庫 `streaming_events` 表
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct StreamingEvent {
    /// 事件 ID
    pub id: Uuid,
    /// 串流帳號 ID
    pub streaming_account_id: Uuid,
    /// 事件類型：stream_start / stream_end / game_highlight / viewer_peak
    pub event_type: String,
    /// 關聯的遊戲房間 ID
    pub game_id: Option<Uuid>,
    /// 事件元資料（JSON）
    pub metadata: serde_json::Value,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

// ============================================================
// 請求結構
// ============================================================

/// 綁定串流帳號請求
#[derive(Debug, Deserialize)]
pub struct LinkStreamingRequest {
    /// 平台名稱：twitch / youtube
    pub platform: String,
    /// 平台上的用戶 ID
    pub platform_user_id: String,
    /// 平台上的用戶名稱
    pub platform_username: Option<String>,
    /// OAuth access token（可選，供未來 OAuth 整合使用）
    pub access_token: Option<String>,
    /// OAuth refresh token（可選，供未來 OAuth 整合使用）
    pub refresh_token: Option<String>,
}

/// 更新串流設定請求
#[derive(Debug, Deserialize)]
pub struct UpdateStreamingSettingsRequest {
    /// 是否自動發布遊戲結果
    pub auto_post_results: Option<bool>,
    /// 是否啟用精華片段功能
    pub highlight_clips: Option<bool>,
}

/// 設定直播狀態請求
#[derive(Debug, Deserialize)]
pub struct SetLiveRequest {
    /// 平台名稱
    pub platform: String,
    /// 是否正在直播
    pub is_live: bool,
}

/// 串流精華片段推送資料
///
/// 用於向串流平台 API 推送精華片段（目前僅記錄事件，未來擴充為 API 呼叫）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamHighlightPayload {
    /// 精華片段標題
    pub title: String,
    /// 精華時刻描述
    pub description: Option<String>,
    /// 精華時刻的時間戳
    pub timestamp: DateTime<Utc>,
    /// 額外元資料
    pub metadata: serde_json::Value,
}

// ============================================================
// 回應結構
// ============================================================

/// 綁定串流帳號回應
#[derive(Debug, Serialize)]
pub struct LinkStreamingResponse {
    /// 是否成功
    pub success: bool,
    /// 訊息
    pub message: String,
    /// 帳號 ID
    pub account_id: Uuid,
}

/// 串流狀態回應
#[derive(Debug, Serialize)]
pub struct StreamingStatusResponse {
    /// 已綁定的串流帳號列表
    pub accounts: Vec<StreamingAccountInfo>,
}

/// 串流帳號摘要資訊
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct StreamingAccountInfo {
    /// 平台名稱
    pub platform: String,
    /// 平台上的用戶名稱
    pub username: Option<String>,
    /// 是否正在直播
    pub is_live: bool,
    /// 綁定時間
    pub linked_at: DateTime<Utc>,
}

/// 遊戲中的串流相關資料
///
/// 提供遊戲內的串流相關統計（觀眾數、精華片段觸發等）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamingGameData {
    /// 當前觀眾數
    pub viewer_count: i64,
    /// 精華片段觸發次數
    pub highlight_count: i32,
    /// 是否正在直播
    pub is_streaming: bool,
    /// 串流平台
    pub platform: Option<String>,
}
