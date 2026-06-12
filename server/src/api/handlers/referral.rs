//! 推薦獎勵 API 處理器
//!
//! - GET  /api/v1/referral/milestones — 查詢所有里程碑（公開）
//! - GET  /api/v1/referral/progress   — 查詢推薦進度（需認證）
//! - POST /api/v1/referral/claim      — 領取推薦獎勵（需認證）

use axum::{extract::State, Json};

use crate::auth::AuthUser;
use crate::domain::referral::{
    ClaimRewardRequest, ClaimRewardResponse, ReferralMilestone, ReferralProgressResponse,
};
use crate::error::AppResult;
use crate::services::ReferralService;
use crate::AppState;

// ============================================================
// 查詢所有里程碑（公開）
// ============================================================

/// GET /api/v1/referral/milestones
///
/// 公開端點，列出所有推薦獎勵里程碑
pub async fn get_milestones(
    State(state): State<AppState>,
) -> AppResult<Json<Vec<ReferralMilestone>>> {
    let milestones = ReferralService::get_milestones(&state.db).await?;
    Ok(Json(milestones))
}

// ============================================================
// 查詢推薦進度（需認證）
// ============================================================

/// GET /api/v1/referral/progress
///
/// 取得當前用戶的推薦進度，包含各里程碑的領取狀態
pub async fn get_referral_progress(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<ReferralProgressResponse>> {
    let progress = ReferralService::get_progress(&state.db, auth.user_id).await?;
    Ok(Json(progress))
}

// ============================================================
// 領取推薦獎勵（需認證）
// ============================================================

/// POST /api/v1/referral/claim
///
/// 領取指定里程碑的推薦獎勵，支援 idempotent 操作
pub async fn claim_referral_reward(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<ClaimRewardRequest>,
) -> AppResult<Json<ClaimRewardResponse>> {
    let response =
        ReferralService::claim_reward(&state.db, auth.user_id, req.milestone_id).await?;
    Ok(Json(response))
}
