//! WebSocket 升級處理器
//!
//! 處理 WebSocket 連線升級請求

use axum::{
    extract::{Path, Query, State, WebSocketUpgrade},
    http::{header, StatusCode},
    response::IntoResponse,
};
use serde::Deserialize;

use crate::websocket::connection::handle_socket;
use crate::AppState;

/// Token 查詢參數
#[derive(Debug, Deserialize)]
pub struct TokenQuery {
    /// JWT token
    pub token: Option<String>,
}

/// WebSocket 升級處理函數
///
/// 處理 WebSocket 連線升級請求，驗證 JWT token 後建立連線
///
/// # 路由
/// GET /ws/:room_code?token=<jwt_token>
///
/// # 認證方式
/// 1. Query parameter: ?token=<jwt_token>
/// 2. Authorization header: Bearer <jwt_token>
///
/// # 流程
/// 1. 從 query parameter 或 Authorization header 取得 token
/// 2. 驗證 JWT token
/// 3. 呼叫 ws.on_upgrade() 並傳入 handle_socket
pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Path(room_code): Path<String>,
    Query(query): Query<TokenQuery>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    // 從 query parameter 或 Authorization header 取得 token
    let token = query.token.or_else(|| {
        headers
            .get(header::AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .and_then(|auth| auth.strip_prefix("Bearer "))
            .map(|s| s.to_string())
    });

    // 驗證 token
    let token = match token {
        Some(t) => t,
        None => {
            tracing::warn!(room_code = %room_code, "WebSocket 連線缺少認證 token");
            return (
                StatusCode::UNAUTHORIZED,
                "需要提供認證 token。請使用 ?token=<jwt_token> 或 Authorization: Bearer <token>",
            )
                .into_response();
        }
    };

    // 驗證 JWT token
    let claims = match state.jwt.validate_token(&token) {
        Ok(claims) => claims,
        Err(e) => {
            tracing::warn!(
                room_code = %room_code,
                error = %e,
                "WebSocket 連線 token 驗證失敗"
            );
            return (StatusCode::UNAUTHORIZED, format!("Token 驗證失敗: {}", e)).into_response();
        }
    };

    // 取得使用者 ID
    let user_id = match claims.user_id() {
        Ok(id) => id,
        Err(e) => {
            tracing::warn!(
                room_code = %room_code,
                error = %e,
                "無法從 token 取得使用者 ID"
            );
            return (StatusCode::UNAUTHORIZED, format!("無效的 token: {}", e)).into_response();
        }
    };

    tracing::info!(
        user_id = %user_id,
        room_code = %room_code,
        "WebSocket 連線升級請求"
    );

    // 升級為 WebSocket 連線
    ws.on_upgrade(move |socket| handle_socket(socket, state, user_id))
        .into_response()
}

/// WebSocket 升級處理函數（無房間代碼）
///
/// 用於一般 WebSocket 連線，不需要指定房間
///
/// # 路由
/// GET /ws?token=<jwt_token>
pub async fn ws_handler_general(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(query): Query<TokenQuery>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    // 從 query parameter 或 Authorization header 取得 token
    let token = query.token.or_else(|| {
        headers
            .get(header::AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .and_then(|auth| auth.strip_prefix("Bearer "))
            .map(|s| s.to_string())
    });

    // 驗證 token
    let token = match token {
        Some(t) => t,
        None => {
            tracing::warn!("WebSocket 連線缺少認證 token");
            return (
                StatusCode::UNAUTHORIZED,
                "需要提供認證 token。請使用 ?token=<jwt_token> 或 Authorization: Bearer <token>",
            )
                .into_response();
        }
    };

    // 驗證 JWT token
    let claims = match state.jwt.validate_token(&token) {
        Ok(claims) => claims,
        Err(e) => {
            tracing::warn!(error = %e, "WebSocket 連線 token 驗證失敗");
            return (StatusCode::UNAUTHORIZED, format!("Token 驗證失敗: {}", e)).into_response();
        }
    };

    // 取得使用者 ID
    let user_id = match claims.user_id() {
        Ok(id) => id,
        Err(e) => {
            tracing::warn!(error = %e, "無法從 token 取得使用者 ID");
            return (StatusCode::UNAUTHORIZED, format!("無效的 token: {}", e)).into_response();
        }
    };

    tracing::info!(user_id = %user_id, "WebSocket 一般連線升級請求");

    // 升級為 WebSocket 連線
    ws.on_upgrade(move |socket| handle_socket(socket, state, user_id))
        .into_response()
}
