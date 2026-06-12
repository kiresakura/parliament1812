//! 邀請連結 API 處理器
//!
//! - POST /api/v1/invite/generate     — 生成邀請連結（需認證）
//! - POST /api/v1/invite/resolve/:token — 解析邀請連結（公開）
//! - GET  /api/v1/invite/stats        — 取得邀請統計（需認證）
//! - POST /api/v1/invite/convert      — 標記轉化（需認證，內部使用）

use axum::{
    extract::{Path, State},
    Json,
};
use serde::Serialize;

use crate::auth::AuthUser;
use crate::domain::attribution::{ConversionRequest, CreateInviteRequest, InviteLink, InviteStats, InviteResolution};
use crate::domain::summons::{CreateSummonsRequest, SummonsResponse};
use crate::error::AppResult;
use crate::services::AttributionService;
use crate::services::SummonsService;
use crate::AppState;

/// 操作回應
#[derive(Debug, Serialize)]
pub struct ActionResponse {
    pub message: String,
}

// ============================================================
// 生成邀請連結
// ============================================================

/// POST /api/v1/invite/generate
///
/// 為當前認證用戶生成一個新的邀請連結
pub async fn generate_invite(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateInviteRequest>,
) -> AppResult<Json<InviteLink>> {
    let link = AttributionService::generate_invite(&state.db, auth.user_id, &req.channel).await?;
    Ok(Json(link))
}

// ============================================================
// 解析邀請連結
// ============================================================

/// POST /api/v1/invite/resolve/:token
///
/// 公開端點，解析邀請 token 並追蹤點擊
pub async fn resolve_invite(
    State(state): State<AppState>,
    Path(token): Path<String>,
) -> AppResult<Json<InviteResolution>> {
    let resolution = AttributionService::resolve_invite(&state.db, &token).await?;
    Ok(Json(resolution))
}

// ============================================================
// 邀請統計
// ============================================================

/// GET /api/v1/invite/stats
///
/// 取得當前認證用戶的邀請統計數據
pub async fn get_invite_stats(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<InviteStats>> {
    let stats = AttributionService::get_invite_stats(&state.db, auth.user_id).await?;
    Ok(Json(stats))
}

// ============================================================
// 標記轉化
// ============================================================

/// POST /api/v1/invite/convert
///
/// 標記用戶的轉化狀態（內部使用）
pub async fn mark_conversion(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<ConversionRequest>,
) -> AppResult<Json<ActionResponse>> {
    AttributionService::mark_conversion(&state.db, auth.user_id, &req.token, &req.conversion_type)
        .await?;

    Ok(Json(ActionResponse {
        message: "轉化狀態已更新".to_string(),
    }))
}

// ============================================================
// 傳票式邀請
// ============================================================

/// POST /api/v1/invite/summons
///
/// 產生維多利亞風格的傳票式邀請連結
pub async fn create_summons(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateSummonsRequest>,
) -> AppResult<Json<SummonsResponse>> {
    let response = SummonsService::create_summons(&state.db, auth.user_id, payload).await?;
    Ok(Json(response))
}
