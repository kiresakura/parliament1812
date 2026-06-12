//! 遊戲摘要 API 處理器
//!
//! - GET  /api/v1/games/:game_id/summary  — 取得遊戲摘要（需認證）
//! - GET  /api/v1/share/:share_token      — 透過分享連結取得摘要（公開）
//! - GET  /api/v1/games/:game_id/replay   — 取得回放資料（需認證）

use axum::{
    extract::{Path, State},
    Json,
};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::domain::summary::{GameSummary, ReplayData};
use crate::error::AppResult;
use crate::services::SummaryService;
use crate::AppState;

// ============================================================
// 取得遊戲摘要
// ============================================================

/// GET /api/v1/games/:game_id/summary
///
/// 取得指定遊戲的摘要。如果尚未生成，則自動生成。
pub async fn get_game_summary(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(game_id): Path<Uuid>,
) -> AppResult<Json<GameSummary>> {
    // 嘗試查詢已生成的摘要
    match SummaryService::get_summary(&state.db, game_id).await {
        Ok(summary) => Ok(Json(summary)),
        Err(_) => {
            // 尚未生成，自動生成
            let summary = SummaryService::generate_summary(&state.db, game_id).await?;
            Ok(Json(summary))
        }
    }
}

// ============================================================
// 分享摘要（公開）
// ============================================================

/// GET /api/v1/share/:share_token
///
/// 透過分享 token 取得遊戲摘要（公開端點，不需認證）
pub async fn get_shared_summary(
    State(state): State<AppState>,
    Path(share_token): Path<String>,
) -> AppResult<Json<GameSummary>> {
    let summary = SummaryService::get_by_share_token(&state.db, &share_token).await?;
    Ok(Json(summary))
}

// ============================================================
// 取得回放資料
// ============================================================

/// GET /api/v1/games/:game_id/replay
///
/// 取得指定遊戲的 30 秒精華回放資料
pub async fn get_replay_data(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(game_id): Path<Uuid>,
) -> AppResult<Json<ReplayData>> {
    let replay = SummaryService::get_replay_data(&state.db, game_id).await?;
    Ok(Json(replay))
}
