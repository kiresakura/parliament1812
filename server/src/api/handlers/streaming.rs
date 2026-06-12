//! 串流整合 API 處理器
//!
//! - POST   /api/v1/streaming/link               — 綁定串流帳號（需認證）
//! - DELETE /api/v1/streaming/link/:platform      — 解除綁定（需認證）
//! - GET    /api/v1/streaming/status              — 查詢串流狀態（需認證）
//! - PUT    /api/v1/streaming/settings/:platform  — 更新串流設定（需認證）
//! - POST   /api/v1/streaming/live                — 設定直播狀態（需認證）
//! - GET    /api/v1/streaming/live                — 查詢正在直播的玩家（公開）
//! - GET    /api/v1/streaming/analytics           — 串流數據分析（需認證）

use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;

use crate::auth::AuthUser;
use crate::domain::streaming::{
    LinkStreamingRequest, LinkStreamingResponse, SetLiveRequest, StreamingAccountInfo,
    StreamingStatusResponse, UpdateStreamingSettingsRequest,
};
use crate::error::AppResult;
use crate::services::StreamingService;
use crate::AppState;

// ============================================================
// 請求結構
// ============================================================

/// 分析查詢參數
#[derive(Debug, Deserialize)]
pub struct AnalyticsQuery {
    /// 統計天數（預設 30 天）
    pub days: Option<i32>,
}

// ============================================================
// 回應結構
// ============================================================

/// 通用操作回應
#[derive(Debug, serde::Serialize)]
pub struct StreamingActionResponse {
    pub message: String,
}

// ============================================================
// 綁定串流帳號（需認證）
// ============================================================

/// POST /api/v1/streaming/link
///
/// 綁定串流平台帳號。如果已綁定則更新現有記錄。
pub async fn link_streaming(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<LinkStreamingRequest>,
) -> AppResult<Json<LinkStreamingResponse>> {
    let response = StreamingService::link_account(&state.db, auth.user_id, req).await?;
    Ok(Json(response))
}

// ============================================================
// 解除綁定（需認證）
// ============================================================

/// DELETE /api/v1/streaming/link/:platform
///
/// 解除指定平台的串流帳號綁定
pub async fn unlink_streaming(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(platform): Path<String>,
) -> AppResult<Json<StreamingActionResponse>> {
    StreamingService::unlink_account(&state.db, auth.user_id, &platform).await?;
    Ok(Json(StreamingActionResponse {
        message: format!("已解除 {} 帳號綁定", platform),
    }))
}

// ============================================================
// 查詢串流狀態（需認證）
// ============================================================

/// GET /api/v1/streaming/status
///
/// 查詢當前用戶所有綁定的串流帳號狀態
pub async fn get_streaming_status(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<StreamingStatusResponse>> {
    let status = StreamingService::get_status(&state.db, auth.user_id).await?;
    Ok(Json(status))
}

// ============================================================
// 更新串流設定（需認證）
// ============================================================

/// PUT /api/v1/streaming/settings/:platform
///
/// 更新指定平台的串流帳號設定
pub async fn update_streaming_settings(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(platform): Path<String>,
    Json(req): Json<UpdateStreamingSettingsRequest>,
) -> AppResult<Json<StreamingActionResponse>> {
    StreamingService::update_settings(&state.db, auth.user_id, &platform, req).await?;
    Ok(Json(StreamingActionResponse {
        message: "串流設定已更新".to_string(),
    }))
}

// ============================================================
// 設定直播狀態（需認證）
// ============================================================

/// POST /api/v1/streaming/live
///
/// 設定用戶的直播狀態，同時記錄 stream_start / stream_end 事件
pub async fn set_live(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetLiveRequest>,
) -> AppResult<Json<StreamingActionResponse>> {
    StreamingService::set_live_status(&state.db, auth.user_id, &req.platform, req.is_live)
        .await?;

    let status = if req.is_live { "開始直播" } else { "結束直播" };
    Ok(Json(StreamingActionResponse {
        message: format!("{} 平台已{}", req.platform, status),
    }))
}

// ============================================================
// 查詢正在直播的玩家（公開）
// ============================================================

/// GET /api/v1/streaming/live
///
/// 公開端點，查詢所有正在直播的玩家
pub async fn get_live_streamers(
    State(state): State<AppState>,
) -> AppResult<Json<Vec<StreamingAccountInfo>>> {
    let streamers = StreamingService::get_live_streamers(&state.db).await?;
    Ok(Json(streamers))
}

// ============================================================
// 串流數據分析（需認證）
// ============================================================

/// GET /api/v1/streaming/analytics?days=30
///
/// 取得串流數據分析，統計過去 N 天的串流數據
pub async fn get_streaming_analytics(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(query): Query<AnalyticsQuery>,
) -> AppResult<Json<serde_json::Value>> {
    let days = query.days.unwrap_or(30).min(365).max(1);
    let analytics =
        StreamingService::get_streaming_analytics(&state.db, auth.user_id, days).await?;
    Ok(Json(analytics))
}
