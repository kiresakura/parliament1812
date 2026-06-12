//! 實況主模式 API 處理器
//!
//! - POST /api/v1/streamer/enable            — 啟用實況主模式（需認證）
//! - POST /api/v1/streamer/disable           — 停用實況主模式（需認證）
//! - GET  /api/v1/streamer/settings          — 取得設定（需認證）
//! - PUT  /api/v1/streamer/settings          — 更新設定（需認證）
//! - GET  /api/v1/streamer/overlay/:token    — 取得 overlay 資料（公開）
//! - POST /api/v1/streamer/regenerate-token  — 重新生成 token（需認證）

use axum::{
    extract::{Path, State},
    Json,
};

use crate::auth::AuthUser;
use crate::domain::streamer::{
    EnableStreamerResponse, OverlayData, StreamerSettingsResponse,
    UpdateStreamerSettingsRequest,
};
use crate::error::AppResult;
use crate::services::StreamerService;
use crate::AppState;

// ============================================================
// 啟用實況主模式
// ============================================================

/// POST /api/v1/streamer/enable
///
/// 啟用實況主模式，生成 overlay token 和 URL
pub async fn enable_streamer(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<EnableStreamerResponse>> {
    let response = StreamerService::enable_streamer_mode(&state.db, auth.user_id).await?;
    Ok(Json(response))
}

// ============================================================
// 停用實況主模式
// ============================================================

/// POST /api/v1/streamer/disable
///
/// 停用實況主模式，清除 overlay token
pub async fn disable_streamer(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<serde_json::Value>> {
    StreamerService::disable_streamer_mode(&state.db, auth.user_id).await?;
    Ok(Json(serde_json::json!({
        "message": "實況主模式已停用"
    })))
}

// ============================================================
// 取得實況主設定
// ============================================================

/// GET /api/v1/streamer/settings
///
/// 取得目前的實況主設定
pub async fn get_streamer_settings(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<StreamerSettingsResponse>> {
    let response = StreamerService::get_settings(&state.db, auth.user_id).await?;
    Ok(Json(response))
}

// ============================================================
// 更新實況主設定
// ============================================================

/// PUT /api/v1/streamer/settings
///
/// 部分更新實況主設定（只更新有值的欄位）
pub async fn update_streamer_settings(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(request): Json<UpdateStreamerSettingsRequest>,
) -> AppResult<Json<StreamerSettingsResponse>> {
    let response =
        StreamerService::update_settings(&state.db, auth.user_id, request).await?;
    Ok(Json(response))
}

// ============================================================
// 取得 OBS overlay 資料（公開端點）
// ============================================================

/// GET /api/v1/streamer/overlay/:token
///
/// 透過 overlay token 取得即時遊戲資料。
/// 此端點為公開端點，OBS Browser Source 直接存取。
/// 所有敏感資訊已透過 SpectatorService::sanitize_game_state 過濾。
pub async fn get_overlay_data(
    State(state): State<AppState>,
    Path(token): Path<String>,
) -> AppResult<Json<OverlayData>> {
    let data = StreamerService::get_overlay_data(
        &state.db,
        &token,
        &state.ws_hub,
        &state.games,
    )
    .await?;
    Ok(Json(data))
}

// ============================================================
// 重新生成 overlay token
// ============================================================

/// POST /api/v1/streamer/regenerate-token
///
/// 重新生成 overlay token（安全更換已洩露的 token）
pub async fn regenerate_overlay_token(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<EnableStreamerResponse>> {
    let new_token = StreamerService::regenerate_token(&state.db, auth.user_id).await?;
    let overlay_url = format!("https://1812game.com/obs/{}", new_token);

    Ok(Json(EnableStreamerResponse {
        overlay_token: new_token,
        overlay_url,
    }))
}
