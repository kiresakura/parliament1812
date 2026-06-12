//! Discord 整合 API 處理器
//!
//! - POST   /api/v1/discord/link                  — 綁定 Discord 帳號（需認證）
//! - DELETE /api/v1/discord/link                  — 解除綁定（需認證）
//! - GET    /api/v1/discord/stats/:discord_user_id — 查詢玩家統計（公開）
//! - POST   /api/v1/discord/challenge             — 建立對戰挑戰（需 Bot Token）
//! - GET    /api/v1/discord/weekly                — 當週法案資訊（公開）
//! - POST   /api/v1/discord/guild                 — 註冊 Discord 伺服器（需 Bot Token）

use axum::{
    extract::{Path, State},
    http::HeaderMap,
    Json,
};

use crate::auth::AuthUser;
use crate::domain::discord::{
    DiscordChallengeRequest, DiscordChallengeResponse, DiscordGuild, DiscordStatsResponse,
    DiscordWeeklyResponse, LinkDiscordRequest, LinkDiscordResponse, RegisterGuildRequest,
};
use crate::error::{AppError, AppResult};
use crate::services::DiscordService;
use crate::AppState;

// ============================================================
// Bot Token 驗證輔助
// ============================================================

/// 從 Header `X-Bot-Token` 驗證 Bot API Key
///
/// 與環境變數 `DISCORD_BOT_TOKEN` 比對，不符則回傳 Unauthorized。
fn verify_bot_token(headers: &HeaderMap) -> AppResult<()> {
    let expected = std::env::var("DISCORD_BOT_TOKEN").unwrap_or_default();
    if expected.is_empty() {
        return Err(AppError::InternalError(
            "伺服器尚未設定 DISCORD_BOT_TOKEN".to_string(),
        ));
    }

    let token = headers
        .get("X-Bot-Token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default();

    if token != expected {
        return Err(AppError::Unauthorized("Bot Token 驗證失敗".to_string()));
    }

    Ok(())
}

// ============================================================
// POST /api/v1/discord/link（需認證）
// ============================================================

/// 綁定 Discord 帳號
pub async fn link_discord(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(body): Json<LinkDiscordRequest>,
) -> AppResult<Json<LinkDiscordResponse>> {
    let resp = DiscordService::link_account(
        &state.db,
        auth_user.user_id,
        &body.discord_user_id,
        body.discord_username.as_deref(),
    )
    .await?;

    Ok(Json(resp))
}

// ============================================================
// DELETE /api/v1/discord/link（需認證）
// ============================================================

/// 解除 Discord 帳號綁定
pub async fn unlink_discord(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> AppResult<Json<serde_json::Value>> {
    DiscordService::unlink_account(&state.db, auth_user.user_id).await?;

    Ok(Json(serde_json::json!({
        "success": true,
        "message": "已解除 Discord 帳號綁定"
    })))
}

// ============================================================
// GET /api/v1/discord/stats/:discord_user_id（公開）
// ============================================================

/// 查詢玩家統計（Bot 呼叫，公開端點）
pub async fn get_discord_stats(
    State(state): State<AppState>,
    Path(discord_user_id): Path<String>,
) -> AppResult<Json<DiscordStatsResponse>> {
    let resp = DiscordService::get_stats_by_discord_id(&state.db, &discord_user_id).await?;
    Ok(Json(resp))
}

// ============================================================
// POST /api/v1/discord/challenge（需 Bot Token）
// ============================================================

/// 建立對戰挑戰
pub async fn create_discord_challenge(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<DiscordChallengeRequest>,
) -> AppResult<Json<DiscordChallengeResponse>> {
    verify_bot_token(&headers)?;

    let resp = DiscordService::create_challenge(
        &state.db,
        &body.challenger_discord_id,
        &body.target_discord_id,
    )
    .await?;

    Ok(Json(resp))
}

// ============================================================
// GET /api/v1/discord/weekly（公開）
// ============================================================

/// 取得當週法案資訊（公開端點）
pub async fn get_discord_weekly(
    State(state): State<AppState>,
) -> AppResult<Json<DiscordWeeklyResponse>> {
    let resp = DiscordService::get_weekly_info(&state.db).await?;
    Ok(Json(resp))
}

// ============================================================
// POST /api/v1/discord/guild（需 Bot Token）
// ============================================================

/// 註冊 Discord 伺服器
pub async fn register_discord_guild(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<RegisterGuildRequest>,
) -> AppResult<Json<DiscordGuild>> {
    verify_bot_token(&headers)?;

    let guild = DiscordService::register_guild(&state.db, &body).await?;
    Ok(Json(guild))
}
