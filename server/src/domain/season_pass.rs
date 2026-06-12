//! 賽季通行證領域模型
//!
//! 定義賽季通行證相關的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ============================================================
// 資料庫模型
// ============================================================

/// 賽季通行證等級
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SeasonPassTier {
    pub id: Uuid,
    pub season_id: i32,
    pub tier_level: i32,
    pub xp_required: i32,
    pub free_reward: Option<serde_json::Value>,
    pub premium_reward: Option<serde_json::Value>,
    pub created_at: Option<DateTime<Utc>>,
}

/// 玩家賽季通行證進度
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SeasonPassProgress {
    pub id: Uuid,
    pub user_id: Uuid,
    pub season_id: i32,
    pub current_xp: i32,
    pub current_tier: i32,
    pub is_premium: bool,
    pub premium_purchased_at: Option<DateTime<Utc>>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// 已領取的賽季獎勵
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SeasonRewardClaim {
    pub id: Uuid,
    pub user_id: Uuid,
    pub season_id: i32,
    pub tier_level: i32,
    pub reward_track: String,
    pub claimed_at: Option<DateTime<Utc>>,
}

// ============================================================
// API 回應
// ============================================================

/// 賽季通行證完整狀態回應
#[derive(Debug, Clone, Serialize)]
pub struct SeasonPassResponse {
    /// 玩家進度
    pub progress: SeasonPassProgress,
    /// 所有等級（含領取狀態）
    pub tiers: Vec<TierWithClaimStatus>,
    /// 下一級所需 XP（已滿級則為 None）
    pub next_tier_xp: Option<i32>,
}

/// 等級 + 領取狀態
#[derive(Debug, Clone, Serialize)]
pub struct TierWithClaimStatus {
    /// 等級資訊
    #[serde(flatten)]
    pub tier: SeasonPassTier,
    /// 免費獎勵是否已領取
    pub free_claimed: bool,
    /// 高級獎勵是否已領取
    pub premium_claimed: bool,
    /// 是否已解鎖（current_tier >= tier_level）
    pub unlocked: bool,
}

// ============================================================
// API 請求
// ============================================================

/// 增加 XP 請求
#[derive(Debug, Clone, Deserialize)]
pub struct AddXpRequest {
    /// XP 數量
    pub xp_amount: i32,
    /// 來源（如 "game_complete", "game_win", "daily_quest"）
    pub source: String,
}

/// 增加 XP 回應
#[derive(Debug, Clone, Serialize)]
pub struct AddXpResponse {
    /// 新的總 XP
    pub new_xp: i32,
    /// 新的等級
    pub new_tier: i32,
    /// 是否升級了
    pub leveled_up: bool,
    /// 新解鎖的獎勵等級
    pub unlocked_rewards: Vec<SeasonPassTier>,
}

/// 領取賽季獎勵請求
#[derive(Debug, Clone, Deserialize)]
pub struct ClaimSeasonRewardRequest {
    /// 要領取的等級
    pub tier_level: i32,
    /// 獎勵軌道：'free' 或 'premium'
    pub track: String,
}

/// 購買高級通行證回應
#[derive(Debug, Clone, Serialize)]
pub struct PurchasePremiumResponse {
    pub success: bool,
    pub message: String,
}

/// 排行榜項目
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct LeaderboardEntry {
    pub user_id: Uuid,
    pub username: String,
    pub current_xp: i32,
    pub current_tier: i32,
    pub is_premium: bool,
}

/// 排行榜查詢參數
#[derive(Debug, Deserialize)]
pub struct SeasonPassQuery {
    /// 賽季 ID（不填則用當前賽季）
    pub season_id: Option<i32>,
}

/// 排行榜查詢參數
#[derive(Debug, Deserialize)]
pub struct LeaderboardQuery {
    /// 賽季 ID
    pub season_id: Option<i32>,
    /// 筆數上限（預設 50）
    pub limit: Option<i64>,
}
