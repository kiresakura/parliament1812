//! 教學系統 API 處理器
//!
//! GET  /api/v1/tutorial/steps     - 教學步驟定義
//! GET  /api/v1/tutorial/progress  - 教學進度
//! POST /api/v1/tutorial/complete  - 完成教學步驟
//! POST /api/v1/tutorial/reset     - 重置教學

use axum::{extract::State, Json};
use serde::Serialize;

use crate::auth::middleware::AuthUser;
use crate::error::AppError;
use crate::services::tutorial_service::{
    CompleteTutorialStepRequest, TutorialProgressResponse, TutorialService, TutorialStep,
};
use crate::AppState;

/// 教學步驟列表回應
#[derive(Debug, Serialize)]
pub struct TutorialStepsResponse {
    pub steps: Vec<TutorialStep>,
}

/// 簡單成功回應
#[derive(Debug, Serialize)]
pub struct TutorialResetResponse {
    pub success: bool,
}

/// 檢查是否需要教學回應
#[derive(Debug, Serialize)]
pub struct NeedsTutorialResponse {
    pub needs_tutorial: bool,
}

// ============================================================
// Handlers
// ============================================================

/// GET /api/v1/tutorial/steps
pub async fn get_steps() -> Result<Json<TutorialStepsResponse>, AppError> {
    let steps = TutorialService::get_tutorial_steps();
    Ok(Json(TutorialStepsResponse { steps }))
}

/// GET /api/v1/tutorial/progress
pub async fn get_progress(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<TutorialProgressResponse>, AppError> {
    let progress = TutorialService::get_progress(&state.db, auth_user.user_id).await?;
    Ok(Json(progress))
}

/// POST /api/v1/tutorial/complete
pub async fn complete_step(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<CompleteTutorialStepRequest>,
) -> Result<Json<TutorialProgressResponse>, AppError> {
    let progress =
        TutorialService::complete_step(&state.db, auth_user.user_id, request.step).await?;
    Ok(Json(progress))
}

/// POST /api/v1/tutorial/reset
pub async fn reset_tutorial(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<TutorialResetResponse>, AppError> {
    TutorialService::reset_tutorial(&state.db, auth_user.user_id).await?;
    Ok(Json(TutorialResetResponse { success: true }))
}

/// GET /api/v1/tutorial/check
pub async fn check_needs_tutorial(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<NeedsTutorialResponse>, AppError> {
    let completed = TutorialService::is_tutorial_completed(&state.db, auth_user.user_id).await?;
    Ok(Json(NeedsTutorialResponse {
        needs_tutorial: !completed,
    }))
}
