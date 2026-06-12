//! 故事戰役 API 處理器
//!
//! GET  /api/v1/campaign/chapters         - 所有章節資訊
//! GET  /api/v1/campaign/chapters/:id     - 章節詳情
//! GET  /api/v1/campaign/progress         - 戰役進度
//! POST /api/v1/campaign/complete         - 完成關卡
//! POST /api/v1/campaign/unlock           - 解鎖章節
//! GET  /api/v1/campaign/chapter/:id      - 單章詳情

use axum::{
    extract::{Path, State},
    Json,
};
use serde::Serialize;

use crate::auth::middleware::AuthUser;
use crate::error::AppError;
use crate::services::campaign_service::{
    CampaignProgressResponse, CampaignService, ChapterDetailResponse, ChapterInfo,
    CompleteStageRequest, CompleteStageResponse, UnlockChapterRequest, UnlockChapterResponse,
};
use crate::AppState;

/// 所有章節回應
#[derive(Debug, Serialize)]
pub struct ChaptersResponse {
    pub chapters: Vec<ChapterInfo>,
}

// ============================================================
// Handlers
// ============================================================

/// GET /api/v1/campaign/chapters
pub async fn get_chapters() -> Result<Json<ChaptersResponse>, AppError> {
    let chapters = CampaignService::get_all_chapters();
    Ok(Json(ChaptersResponse { chapters }))
}

/// GET /api/v1/campaign/chapter/:id
pub async fn get_chapter_detail(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Path(chapter_id): Path<i32>,
) -> Result<Json<ChapterDetailResponse>, AppError> {
    let detail =
        CampaignService::get_chapter_detail(&state.db, auth_user.user_id, chapter_id).await?;
    Ok(Json(detail))
}

/// GET /api/v1/campaign/progress
pub async fn get_progress(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<CampaignProgressResponse>, AppError> {
    let progress = CampaignService::get_progress(&state.db, auth_user.user_id).await?;
    Ok(Json(progress))
}

/// POST /api/v1/campaign/complete
pub async fn complete_stage(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<CompleteStageRequest>,
) -> Result<Json<CompleteStageResponse>, AppError> {
    let result = CampaignService::complete_stage(&state.db, auth_user.user_id, &request).await?;
    Ok(Json(result))
}

/// POST /api/v1/campaign/unlock
pub async fn unlock_chapter(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<UnlockChapterRequest>,
) -> Result<Json<UnlockChapterResponse>, AppError> {
    let result = CampaignService::unlock_chapter(&state.db, auth_user.user_id, &request).await?;
    Ok(Json(result))
}
