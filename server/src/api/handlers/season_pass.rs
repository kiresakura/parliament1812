//! 賽季通行證 API 處理器
//!
//! GET  /api/v1/season-pass              — 取得通行證狀態（需認證）
//! POST /api/v1/season-pass/claim        — 領取獎勵（需認證）
//! POST /api/v1/season-pass/premium      — 購買高級通行證（需認證）
//! GET  /api/v1/season-pass/leaderboard  — XP 排行榜（公開）

use axum::{
    extract::{Query, State},
    Json,
};
use serde::Serialize;

use crate::auth::AuthUser;
use crate::domain::season_pass::{
    ClaimSeasonRewardRequest, LeaderboardEntry, LeaderboardQuery, PurchasePremiumResponse,
    SeasonPassQuery, SeasonPassResponse,
};
use crate::error::{AppError, AppResult};
use crate::game::season;
use crate::services::SeasonPassService;
use crate::AppState;

// ============================================================
// GET /api/v1/season-pass
// ============================================================

/// 取得玩家的賽季通行證狀態
///
/// 需要認證。如果未指定 season_id，使用當前活躍賽季。
pub async fn get_pass_status(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Query(query): Query<SeasonPassQuery>,
) -> Result<Json<SeasonPassResponse>, AppError> {
    let season_id = resolve_season_id(&state, query.season_id).await?;

    let response =
        SeasonPassService::get_pass_status(&state.db, auth_user.user_id, season_id).await?;

    Ok(Json(response))
}

// ============================================================
// POST /api/v1/season-pass/claim
// ============================================================

/// 領取賽季獎勵回應
#[derive(Debug, Serialize)]
pub struct ClaimRewardResponse {
    pub reward: serde_json::Value,
    pub tier_level: i32,
    pub track: String,
}

/// 領取賽季獎勵
///
/// 需要認證。驗證等級已解鎖且未領取過。
pub async fn claim_season_reward(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<ClaimSeasonRewardRequest>,
) -> Result<Json<ClaimRewardResponse>, AppError> {
    // 使用當前活躍賽季
    let season_id = resolve_season_id(&state, None).await?;

    let reward = SeasonPassService::claim_reward(
        &state.db,
        auth_user.user_id,
        season_id,
        request.tier_level,
        &request.track,
    )
    .await?;

    Ok(Json(ClaimRewardResponse {
        reward,
        tier_level: request.tier_level,
        track: request.track,
    }))
}

// ============================================================
// POST /api/v1/season-pass/premium
// ============================================================

/// 購買高級通行證
///
/// 需要認證。冪等操作。
pub async fn purchase_premium(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<PurchasePremiumResponse>, AppError> {
    let season_id = resolve_season_id(&state, None).await?;

    let response =
        SeasonPassService::purchase_premium(&state.db, auth_user.user_id, season_id).await?;

    Ok(Json(response))
}

// ============================================================
// GET /api/v1/season-pass/leaderboard
// ============================================================

/// 排行榜回應
#[derive(Debug, Serialize)]
pub struct LeaderboardResponse {
    pub season_id: i32,
    pub entries: Vec<LeaderboardEntry>,
}

/// 取得賽季 XP 排行榜
///
/// 公開端點，不需要認證。
pub async fn get_season_leaderboard(
    State(state): State<AppState>,
    Query(query): Query<LeaderboardQuery>,
) -> Result<Json<LeaderboardResponse>, AppError> {
    let season_id = resolve_season_id(&state, query.season_id).await?;
    let limit = query.limit.unwrap_or(50);

    let entries = SeasonPassService::get_leaderboard(&state.db, season_id, limit).await?;

    Ok(Json(LeaderboardResponse {
        season_id,
        entries,
    }))
}

// ============================================================
// 工具函數
// ============================================================

/// 解析賽季 ID：如果未指定，取當前活躍賽季
async fn resolve_season_id(state: &AppState, season_id: Option<i32>) -> AppResult<i32> {
    match season_id {
        Some(id) => Ok(id),
        None => {
            let current = season::get_current_season(&state.db)
                .await
                .map_err(|e| AppError::DatabaseError(e.to_string()))?;

            current
                .map(|s| s.id)
                .ok_or_else(|| AppError::NotFound("沒有活躍的賽季".to_string()))
        }
    }
}
