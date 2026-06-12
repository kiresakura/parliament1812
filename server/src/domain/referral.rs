//! 推薦獎勵領域模型
//!
//! 定義推薦里程碑、獎勵領取相關的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 推薦里程碑（資料庫記錄）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ReferralMilestone {
    /// 里程碑 ID
    pub id: Uuid,
    /// 里程碑名稱
    pub milestone_name: String,
    /// 所需推薦人數
    pub required_referrals: i32,
    /// 獎勵類型：avatar, card_skin, title, gems, emote
    pub reward_type: String,
    /// 獎勵資料（JSON 格式）
    pub reward_data: serde_json::Value,
    /// 描述
    pub description: Option<String>,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

/// 推薦獎勵領取記錄（資料庫記錄）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ReferralRewardClaim {
    /// 記錄 ID
    pub id: Uuid,
    /// 用戶 ID
    pub user_id: Uuid,
    /// 里程碑 ID
    pub milestone_id: Uuid,
    /// 領取時間
    pub claimed_at: DateTime<Utc>,
}

/// 推薦進度回應
#[derive(Debug, Serialize)]
pub struct ReferralProgressResponse {
    /// 當前已轉化的推薦人數
    pub current_referrals: i64,
    /// 各里程碑的進度
    pub milestones: Vec<MilestoneProgress>,
}

/// 單個里程碑的進度
#[derive(Debug, Serialize)]
pub struct MilestoneProgress {
    /// 里程碑資訊
    pub milestone: ReferralMilestone,
    /// 是否已領取
    pub claimed: bool,
    /// 是否可領取（達標且未領取）
    pub claimable: bool,
}

/// 領取獎勵請求
#[derive(Debug, Deserialize)]
pub struct ClaimRewardRequest {
    /// 要領取的里程碑 ID
    pub milestone_id: Uuid,
}

/// 領取獎勵回應
#[derive(Debug, Serialize)]
pub struct ClaimRewardResponse {
    /// 是否成功
    pub success: bool,
    /// 獎勵類型
    pub reward_type: String,
    /// 獎勵資料
    pub reward_data: serde_json::Value,
    /// 回應訊息
    pub message: String,
}
