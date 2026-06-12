//! Discord 整合領域模型
//!
//! 定義 Discord Bot 整合所需的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// ============================================================
// 資料庫模型
// ============================================================

/// Discord 伺服器（Guild）綁定
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DiscordGuild {
    pub id: Uuid,
    pub guild_id: String,
    pub guild_name: Option<String>,
    pub webhook_url: Option<String>,
    pub notification_channel_id: Option<String>,
    pub is_active: bool,
    pub settings: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Discord 用戶綁定
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DiscordUserLink {
    pub id: Uuid,
    pub user_id: Uuid,
    pub discord_user_id: String,
    pub discord_username: Option<String>,
    pub linked_at: DateTime<Utc>,
}

// ============================================================
// API 請求/回應
// ============================================================

/// 綁定 Discord 帳號請求
#[derive(Debug, Deserialize)]
pub struct LinkDiscordRequest {
    pub discord_user_id: String,
    pub discord_username: Option<String>,
}

/// 綁定 Discord 帳號回應
#[derive(Debug, Serialize)]
pub struct LinkDiscordResponse {
    pub success: bool,
    pub message: String,
}

/// Discord 玩家統計回應
#[derive(Debug, Serialize)]
pub struct DiscordStatsResponse {
    /// 遊戲帳號名稱
    pub username: String,
    /// 已玩局數
    pub games_played: i64,
    /// 勝率（百分比）
    pub win_rate: f64,
    /// ELO 分數
    pub elo: i32,
    /// 頭銜
    pub title: String,
    /// 最近 5 場結果（"win" / "lose"）
    pub recent_results: Vec<String>,
}

/// Discord 挑戰請求
#[derive(Debug, Deserialize)]
pub struct DiscordChallengeRequest {
    pub challenger_discord_id: String,
    pub target_discord_id: String,
}

/// Discord 挑戰回應
#[derive(Debug, Serialize)]
pub struct DiscordChallengeResponse {
    pub room_code: Option<String>,
    pub message: String,
    pub join_url: Option<String>,
}

/// Discord 每週資訊回應
#[derive(Debug, Serialize)]
pub struct DiscordWeeklyResponse {
    /// 當週法案名稱
    pub bill_name: Option<String>,
    /// 法案描述
    pub bill_description: Option<String>,
    /// 週標籤（例如 "2026 第 12 週"）
    pub week_label: String,
    /// 距離本週日剩餘天數
    pub days_remaining: i64,
    /// 本週參與人數
    pub participants_this_week: i64,
}

/// Webhook 推送酬載
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebhookPayload {
    /// 事件類型（如 "game_result", "weekly_bill"）
    pub event_type: String,
    /// 事件資料
    pub data: serde_json::Value,
}

/// 註冊 Discord 伺服器請求
#[derive(Debug, Deserialize)]
pub struct RegisterGuildRequest {
    pub guild_id: String,
    pub guild_name: Option<String>,
    pub webhook_url: Option<String>,
    pub notification_channel_id: Option<String>,
}
