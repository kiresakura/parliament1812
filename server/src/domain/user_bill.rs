//! 玩家自創法案（UGC）領域模型
//!
//! 定義玩家提交法案、社群投票篩選的核心資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 玩家自創法案
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserBill {
    pub id: Uuid,
    pub author_id: Uuid,
    pub bill_name: String,
    pub bill_description: String,
    pub bill_type: String,
    pub version_a: serde_json::Value,
    pub version_b: serde_json::Value,
    pub version_c: serde_json::Value,
    pub special_rules: serde_json::Value,
    pub status: String,
    pub upvotes: i32,
    pub downvotes: i32,
    pub play_count: i32,
    pub featured_week: Option<i32>,
    pub featured_year: Option<i32>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 建立法案請求
#[derive(Debug, Clone, Deserialize)]
pub struct CreateUserBillRequest {
    pub bill_name: String,
    pub bill_description: String,
    pub bill_type: String,
    pub version_a: serde_json::Value,
    pub version_b: serde_json::Value,
    pub version_c: serde_json::Value,
    pub special_rules: Option<serde_json::Value>,
}

/// 投票請求
#[derive(Debug, Clone, Deserialize)]
pub struct VoteBillRequest {
    /// "up" 或 "down"
    pub vote_type: String,
}

/// 法案回應（含作者名稱與觀看者投票狀態）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserBillResponse {
    pub id: Uuid,
    pub author_id: Uuid,
    pub author_name: String,
    pub bill_name: String,
    pub bill_description: String,
    pub bill_type: String,
    pub version_a: serde_json::Value,
    pub version_b: serde_json::Value,
    pub version_c: serde_json::Value,
    pub special_rules: serde_json::Value,
    pub status: String,
    pub upvotes: i32,
    pub downvotes: i32,
    pub play_count: i32,
    pub featured_week: Option<i32>,
    pub featured_year: Option<i32>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    /// 觀看者的投票狀態：Some("up"), Some("down"), 或 None
    pub user_vote: Option<String>,
}

/// 法案列表回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserBillListResponse {
    pub bills: Vec<UserBillResponse>,
    pub total: i64,
}

/// 法案投票記錄
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BillVote {
    pub id: Uuid,
    pub bill_id: Uuid,
    pub voter_id: Uuid,
    pub vote_type: String,
    pub created_at: DateTime<Utc>,
}
