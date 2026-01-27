//! 認證中介層
//!
//! 提供 JWT 認證中介層和 AuthUser extractor

use axum::{
    extract::{FromRequestParts, Request, State},
    http::{header::AUTHORIZATION, request::Parts, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use uuid::Uuid;

use crate::{error::ErrorResponse, AppState};

/// 認證使用者資訊
#[derive(Debug, Clone)]
pub struct AuthUser {
    /// 使用者 ID
    pub user_id: Uuid,
}

/// 認證中介層
///
/// 從 Authorization header 提取 Bearer token 並驗證
pub async fn auth_middleware(
    State(state): State<AppState>,
    mut request: Request,
    next: Next,
) -> Response {
    // 從 header 提取 token
    let token = match extract_bearer_token(&request) {
        Some(token) => token,
        None => {
            return unauthorized_response("缺少認證 Token");
        }
    };

    // 驗證 token
    let claims = match state.jwt.validate_token(&token) {
        Ok(claims) => claims,
        Err(e) => {
            return unauthorized_response(&e.to_string());
        }
    };

    // 解析 user_id
    let user_id = match claims.user_id() {
        Ok(id) => id,
        Err(_) => {
            return unauthorized_response("無效的使用者 ID");
        }
    };

    // 將 AuthUser 注入 request extensions
    request.extensions_mut().insert(AuthUser { user_id });

    // 繼續處理請求
    next.run(request).await
}

/// 從 request 提取 Bearer token
fn extract_bearer_token(request: &Request) -> Option<String> {
    request
        .headers()
        .get(AUTHORIZATION)?
        .to_str()
        .ok()?
        .strip_prefix("Bearer ")
        .map(|s| s.to_string())
}

/// 回傳 401 Unauthorized 回應
fn unauthorized_response(message: &str) -> Response {
    let error = ErrorResponse {
        code: 401,
        error: "unauthorized".to_string(),
        message: message.to_string(),
    };
    (StatusCode::UNAUTHORIZED, Json(error)).into_response()
}

/// 可選的認證中介層
///
/// 如果有 token 則驗證，沒有則跳過
pub async fn optional_auth_middleware(
    State(state): State<AppState>,
    mut request: Request,
    next: Next,
) -> Response {
    // 嘗試提取 token
    if let Some(token) = extract_bearer_token(&request) {
        // 如果有 token，嘗試驗證
        if let Ok(claims) = state.jwt.validate_token(&token) {
            if let Ok(user_id) = claims.user_id() {
                request.extensions_mut().insert(AuthUser { user_id });
            }
        }
    }

    // 無論是否認證成功，都繼續處理請求
    next.run(request).await
}

/// AuthUser extractor
///
/// 從 request extensions 提取認證使用者
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AuthError;

    fn from_request_parts<'life0, 'life1, 'async_trait>(
        parts: &'life0 mut Parts,
        _state: &'life1 S,
    ) -> ::core::pin::Pin<
        Box<
            dyn ::core::future::Future<Output = Result<Self, Self::Rejection>>
                + ::core::marker::Send
                + 'async_trait,
        >,
    >
    where
        'life0: 'async_trait,
        'life1: 'async_trait,
        Self: 'async_trait,
    {
        Box::pin(async move {
            parts
                .extensions
                .get::<AuthUser>()
                .cloned()
                .ok_or(AuthError::MissingAuth)
        })
    }
}

/// 認證錯誤
#[derive(Debug)]
pub enum AuthError {
    /// 缺少認證資訊
    MissingAuth,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AuthError::MissingAuth => (StatusCode::UNAUTHORIZED, "需要認證"),
        };

        let error = ErrorResponse {
            code: status.as_u16(),
            error: "unauthorized".to_string(),
            message: message.to_string(),
        };

        (status, Json(error)).into_response()
    }
}

/// 可選的 AuthUser extractor
#[derive(Debug, Clone)]
pub struct OptionalAuthUser(pub Option<AuthUser>);

impl<S> FromRequestParts<S> for OptionalAuthUser
where
    S: Send + Sync,
{
    type Rejection = std::convert::Infallible;

    fn from_request_parts<'life0, 'life1, 'async_trait>(
        parts: &'life0 mut Parts,
        _state: &'life1 S,
    ) -> ::core::pin::Pin<
        Box<
            dyn ::core::future::Future<Output = Result<Self, Self::Rejection>>
                + ::core::marker::Send
                + 'async_trait,
        >,
    >
    where
        'life0: 'async_trait,
        'life1: 'async_trait,
        Self: 'async_trait,
    {
        Box::pin(async move {
            Ok(OptionalAuthUser(
                parts.extensions.get::<AuthUser>().cloned(),
            ))
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_auth_user_clone() {
        let user = AuthUser {
            user_id: Uuid::new_v4(),
        };
        let cloned = user.clone();
        assert_eq!(user.user_id, cloned.user_id);
    }
}
