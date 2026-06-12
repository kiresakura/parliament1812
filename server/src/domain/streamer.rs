//! 實況主模式領域模型
//!
//! 定義實況主設定、OBS overlay 資料等結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 實況主設定
///
/// 對應資料庫 `streamer_settings` 表
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct StreamerSettings {
    /// 設定 ID
    pub id: Uuid,
    /// 使用者 ID
    pub user_id: Uuid,
    /// 是否為實況主
    pub is_streamer: bool,
    /// OBS overlay 存取 token
    pub overlay_token: Option<String>,
    /// overlay 主題（classic / dark / minimal / victorian）
    pub overlay_theme: String,
    /// 是否顯示觀戰人數
    pub show_spectator_count: bool,
    /// 是否顯示聊天
    pub show_chat: bool,
    /// 是否顯示戲劇分數
    pub show_drama_score: bool,
    /// 是否顯示回合計時器
    pub show_round_timer: bool,
    /// 自訂標題
    pub custom_title: Option<String>,
    /// 建立時間
    pub created_at: DateTime<Utc>,
    /// 更新時間
    pub updated_at: DateTime<Utc>,
}

/// 更新實況主設定請求
///
/// 所有欄位都是 Option，只更新有值的欄位
#[derive(Debug, Clone, Deserialize)]
pub struct UpdateStreamerSettingsRequest {
    /// overlay 主題
    pub overlay_theme: Option<String>,
    /// 是否顯示觀戰人數
    pub show_spectator_count: Option<bool>,
    /// 是否顯示聊天
    pub show_chat: Option<bool>,
    /// 是否顯示戲劇分數
    pub show_drama_score: Option<bool>,
    /// 是否顯示回合計時器
    pub show_round_timer: Option<bool>,
    /// 自訂標題
    pub custom_title: Option<String>,
}

/// 實況主設定回應
///
/// 包含設定資料和 overlay URL
#[derive(Debug, Clone, Serialize)]
pub struct StreamerSettingsResponse {
    /// 設定 ID
    pub id: Uuid,
    /// 使用者 ID
    pub user_id: Uuid,
    /// 是否為實況主
    pub is_streamer: bool,
    /// overlay 主題
    pub overlay_theme: String,
    /// 是否顯示觀戰人數
    pub show_spectator_count: bool,
    /// 是否顯示聊天
    pub show_chat: bool,
    /// 是否顯示戲劇分數
    pub show_drama_score: bool,
    /// 是否顯示回合計時器
    pub show_round_timer: bool,
    /// 自訂標題
    pub custom_title: Option<String>,
    /// overlay URL（OBS Browser Source 使用）
    pub overlay_url: Option<String>,
    /// 建立時間
    pub created_at: DateTime<Utc>,
    /// 更新時間
    pub updated_at: DateTime<Utc>,
}

impl StreamerSettingsResponse {
    /// 從 StreamerSettings 建立回應
    pub fn from_settings(settings: StreamerSettings) -> Self {
        let overlay_url = settings
            .overlay_token
            .as_ref()
            .map(|token| format!("https://1812game.com/obs/{}", token));

        Self {
            id: settings.id,
            user_id: settings.user_id,
            is_streamer: settings.is_streamer,
            overlay_theme: settings.overlay_theme,
            show_spectator_count: settings.show_spectator_count,
            show_chat: settings.show_chat,
            show_drama_score: settings.show_drama_score,
            show_round_timer: settings.show_round_timer,
            custom_title: settings.custom_title,
            overlay_url,
            created_at: settings.created_at,
            updated_at: settings.updated_at,
        }
    }
}

/// OBS overlay 資料
///
/// 透過 overlay_token 取得的即時遊戲資料，
/// 所有敏感資訊已透過 SpectatorService::sanitize_game_state 過濾
#[derive(Debug, Clone, Serialize)]
pub struct OverlayData {
    /// 房間代碼
    pub room_code: String,
    /// 淨化後的遊戲狀態（不含手牌、隱藏議程等）
    pub game_state: serde_json::Value,
    /// 觀戰人數
    pub spectator_count: u32,
    /// 當前回合
    pub round: i32,
    /// 當前階段
    pub phase: String,
    /// 戲劇分數
    pub drama_score: Option<f64>,
    /// 玩家公開分數
    pub player_scores: Vec<OverlayPlayerScore>,
    /// overlay 設定（主題等）
    pub settings: OverlaySettings,
}

/// overlay 中的玩家分數（僅公開資訊）
#[derive(Debug, Clone, Serialize)]
pub struct OverlayPlayerScore {
    /// 玩家名稱
    pub name: String,
    /// 角色類型
    pub character: String,
    /// 聲望
    pub reputation: i32,
    /// 影響力
    pub influence: i32,
}

/// overlay 顯示設定
#[derive(Debug, Clone, Serialize)]
pub struct OverlaySettings {
    /// 主題
    pub theme: String,
    /// 是否顯示觀戰人數
    pub show_spectator_count: bool,
    /// 是否顯示聊天
    pub show_chat: bool,
    /// 是否顯示戲劇分數
    pub show_drama_score: bool,
    /// 是否顯示回合計時器
    pub show_round_timer: bool,
    /// 自訂標題
    pub custom_title: Option<String>,
}

/// 啟用實況主模式回應
#[derive(Debug, Clone, Serialize)]
pub struct EnableStreamerResponse {
    /// overlay 存取 token
    pub overlay_token: String,
    /// overlay URL
    pub overlay_url: String,
}
