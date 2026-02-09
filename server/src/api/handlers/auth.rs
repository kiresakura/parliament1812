//! 認證相關 API 處理器
//!
//! 提供用戶註冊、登入、OAuth、密碼重設、取得當前用戶資訊等功能

use axum::{extract::State, Json};
use uuid::Uuid;

use crate::{
    auth::{hash_password, validate_password_strength, verify_password, AuthUser},
    domain::{
        ForgotPasswordRequest, LoginRequest, MessageResponse, OAuthLoginRequest,
        RefreshTokenRequest, ResetPasswordRequest, TokenResponse, UserResponse,
    },
    error::{AppError, AppResult},
    AppState,
};

// ============================================================
// POST /api/v1/auth/register
// ============================================================

/// 用戶註冊請求
#[derive(Debug, serde::Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub email: String,
    pub password: String,
}

/// 用戶註冊
///
/// POST /api/v1/auth/register
/// Body: { username, email, password }
pub async fn register(
    State(state): State<AppState>,
    Json(req): Json<RegisterRequest>,
) -> AppResult<Json<TokenResponse>> {
    // 驗證 username
    if req.username.len() < 3 || req.username.len() > 20 {
        return Err(AppError::BadRequest(
            "使用者名稱長度必須在 3-20 字元之間".to_string(),
        ));
    }

    // 驗證 email 格式（簡單檢查）
    if !req.email.contains('@') || !req.email.contains('.') {
        return Err(AppError::BadRequest("Email 格式無效".to_string()));
    }

    // 驗證密碼強度
    validate_password_strength(&req.password)?;

    let repo = state.user_repo();

    // 檢查用戶名是否已存在
    if repo
        .exists_by_username(&req.username)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
    {
        return Err(AppError::BadRequest("使用者名稱已被使用".to_string()));
    }

    // 檢查 email 是否已存在
    if repo
        .exists_by_email(&req.email)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
    {
        return Err(AppError::BadRequest("Email 已被使用".to_string()));
    }

    // 雜湊密碼
    let password_hash = hash_password(&req.password)?;

    // 建立用戶 (DB)
    let user_record = repo
        .create_with_email(&req.username, &req.email, &password_hash)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    // 同時更新記憶體 store（向後兼容）
    {
        let user = crate::domain::User::new(req.username.clone(), password_hash);
        let mut users = state.users.write().await;
        users.insert(user_record.id, crate::domain::User {
            id: user_record.id,
            username: user.username,
            password_hash: user.password_hash,
            created_at: user.created_at,
        });
    }

    // 生成 token pair
    let pair = state.jwt.generate_token_pair(user_record.id)?;
    let user_response = user_record.into_response();

    tracing::info!(user_id = %user_response.id, username = %user_response.username, "新用戶註冊");

    Ok(Json(TokenResponse::from_pair(pair, Some(user_response))))
}

// ============================================================
// POST /api/v1/auth/login
// ============================================================

/// 用戶登入
///
/// POST /api/v1/auth/login
/// Body: { username, password } — username 可以是 email 或 username
pub async fn login(
    State(state): State<AppState>,
    Json(req): Json<LoginRequest>,
) -> AppResult<Json<TokenResponse>> {
    req.validate()
        .map_err(|e| AppError::BadRequest(e.to_string()))?;

    let repo = state.user_repo();

    // 嘗試用 email 查詢
    let user_record = if req.username.contains('@') {
        repo.find_by_email(&req.username)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?
    } else {
        // 用 username 查詢
        // 先嘗試 DB
        let record = repo
            .find_by_username(&req.username)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        if let Some(r) = record {
            // 也查 full record
            repo.find_full_by_id(r.id)
                .await
                .map_err(|e| AppError::DatabaseError(e.to_string()))?
        } else {
            // 回退：從記憶體 store 查詢（向後兼容）
            let users = state.users.read().await;
            if let Some(mem_user) = users.values().find(|u| u.username == req.username) {
                if !verify_password(&req.password, &mem_user.password_hash)? {
                    return Err(AppError::Unauthorized(
                        "使用者名稱或密碼錯誤".to_string(),
                    ));
                }
                let token = state.jwt.generate_token(mem_user.id)?;
                let expires_in = state.jwt.expiration_seconds();
                tracing::info!(user_id = %mem_user.id, username = %mem_user.username, "用戶登入 (記憶體)");
                return Ok(Json(TokenResponse::new(token, expires_in)));
            }
            None
        }
    };

    let user_record = user_record
        .ok_or_else(|| AppError::Unauthorized("使用者名稱或密碼錯誤".to_string()))?;

    // 檢查是否被封禁
    if user_record.is_banned.unwrap_or(false) {
        return Err(AppError::Forbidden("帳號已被停權".to_string()));
    }

    // 驗證密碼
    let password_hash = user_record
        .password_hash
        .as_deref()
        .ok_or_else(|| {
            AppError::BadRequest("此帳號使用 OAuth 登入，請使用 Google/Apple 登入".to_string())
        })?;

    if !verify_password(&req.password, password_hash)? {
        return Err(AppError::Unauthorized(
            "使用者名稱或密碼錯誤".to_string(),
        ));
    }

    // 更新最後登入時間
    let _ = repo.update_last_login(user_record.id).await;

    // 生成 token pair
    let pair = state.jwt.generate_token_pair(user_record.id)?;
    let user_response = user_record.into_response();

    tracing::info!(user_id = %user_response.id, username = %user_response.username, "用戶登入");

    Ok(Json(TokenResponse::from_pair(pair, Some(user_response))))
}

// ============================================================
// POST /api/v1/auth/refresh
// ============================================================

/// 重新整理 Token
///
/// POST /api/v1/auth/refresh
/// Body: { refresh_token }
pub async fn refresh_token(
    State(state): State<AppState>,
    Json(req): Json<RefreshTokenRequest>,
) -> AppResult<Json<TokenResponse>> {
    let pair = state.jwt.refresh_access_token(&req.refresh_token)?;

    Ok(Json(TokenResponse::from_pair(pair, None)))
}

// ============================================================
// POST /api/v1/auth/oauth/google
// ============================================================

/// Google OAuth 登入
///
/// POST /api/v1/auth/oauth/google
/// Body: { token: "google_id_token", display_name?: "..." }
pub async fn oauth_google(
    State(state): State<AppState>,
    Json(req): Json<OAuthLoginRequest>,
) -> AppResult<Json<TokenResponse>> {
    let oauth_result = crate::auth::verify_google_token(&req.token).await?;
    handle_oauth_login(state, oauth_result, req.display_name).await
}

// ============================================================
// POST /api/v1/auth/oauth/apple
// ============================================================

/// Apple Sign-In 登入
///
/// POST /api/v1/auth/oauth/apple
/// Body: { token: "apple_identity_token", display_name?: "..." }
pub async fn oauth_apple(
    State(state): State<AppState>,
    Json(req): Json<OAuthLoginRequest>,
) -> AppResult<Json<TokenResponse>> {
    let oauth_result = crate::auth::verify_apple_token(&req.token).await?;
    handle_oauth_login(state, oauth_result, req.display_name).await
}

/// 統一 OAuth 登入處理
async fn handle_oauth_login(
    state: AppState,
    oauth_result: crate::auth::OAuthResult,
    display_name: Option<String>,
) -> AppResult<Json<TokenResponse>> {
    let repo = state.user_repo();

    // 查找已有的 OAuth 使用者
    let existing = repo
        .find_by_oauth(&oauth_result.provider, &oauth_result.provider_user_id)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let user_record = if let Some(record) = existing {
        // 已有帳號，更新最後登入時間
        let _ = repo.update_last_login(record.id).await;
        record
    } else {
        // 建立新帳號
        let username = generate_oauth_username(
            &oauth_result.provider,
            &oauth_result.provider_user_id,
        );
        let name = display_name
            .or(oauth_result.name)
            .unwrap_or_else(|| username.clone());

        repo.create_oauth_user(
            &username,
            oauth_result.email.as_deref(),
            &oauth_result.provider,
            &oauth_result.provider_user_id,
            Some(&name),
            oauth_result.avatar_url.as_deref(),
        )
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
    };

    // 生成 token pair
    let pair = state.jwt.generate_token_pair(user_record.id)?;
    let user_response = user_record.into_response();

    tracing::info!(
        user_id = %user_response.id,
        provider = %oauth_result.provider,
        "OAuth 登入"
    );

    Ok(Json(TokenResponse::from_pair(pair, Some(user_response))))
}

/// 為 OAuth 使用者生成唯一的 username
fn generate_oauth_username(provider: &str, provider_id: &str) -> String {
    let short_id = &provider_id[..provider_id.len().min(8)];
    format!("{}_{}", provider, short_id)
}

// ============================================================
// POST /api/v1/auth/forgot-password
// ============================================================

/// 忘記密碼
///
/// POST /api/v1/auth/forgot-password
/// Body: { email }
pub async fn forgot_password(
    State(state): State<AppState>,
    Json(req): Json<ForgotPasswordRequest>,
) -> AppResult<Json<MessageResponse>> {
    let repo = state.user_repo();

    // 查找使用者（不管是否存在，都回傳成功，以防止 email 枚舉攻擊）
    if let Ok(Some(user)) = repo.find_by_email(&req.email).await {
        // 生成 reset token
        let reset_token = Uuid::new_v4().to_string();
        let expires_at = chrono::Utc::now() + chrono::Duration::hours(1);

        if let Err(e) = repo
            .create_password_reset_token(user.id, &reset_token, expires_at)
            .await
        {
            tracing::error!("建立密碼重設 token 失敗: {}", e);
        } else {
            // 暫時印出 log（之後改為寄信）
            tracing::info!(
                email = %req.email,
                reset_token = %reset_token,
                "密碼重設 token 已建立（請在 1 小時內使用）"
            );
        }
    } else {
        // 使用者不存在，但不洩漏此資訊
        tracing::info!(email = %req.email, "忘記密碼請求（使用者不存在）");
    }

    Ok(Json(MessageResponse {
        message: "如果該 email 已註冊，您將收到密碼重設指示".to_string(),
    }))
}

// ============================================================
// POST /api/v1/auth/reset-password
// ============================================================

/// 重設密碼
///
/// POST /api/v1/auth/reset-password
/// Body: { reset_token, new_password }
pub async fn reset_password(
    State(state): State<AppState>,
    Json(req): Json<ResetPasswordRequest>,
) -> AppResult<Json<MessageResponse>> {
    // 驗證新密碼強度
    validate_password_strength(&req.new_password)?;

    let repo = state.user_repo();

    // 驗證 reset token
    let user_id = repo
        .validate_password_reset_token(&req.reset_token)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
        .ok_or_else(|| AppError::BadRequest("無效或過期的重設 token".to_string()))?;

    // 雜湊新密碼
    let password_hash = hash_password(&req.new_password)?;

    // 更新密碼
    repo.update_password(user_id, &password_hash)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    // 標記 token 為已使用
    let _ = repo.mark_reset_token_used(&req.reset_token).await;

    tracing::info!(user_id = %user_id, "密碼已重設");

    Ok(Json(MessageResponse {
        message: "密碼已成功重設".to_string(),
    }))
}

// ============================================================
// GET /api/v1/auth/me
// ============================================================

/// 取得當前用戶資訊
///
/// GET /api/v1/auth/me
/// Header: Authorization: Bearer <access_token>
pub async fn me(State(state): State<AppState>, auth: AuthUser) -> AppResult<Json<UserResponse>> {
    let repo = state.user_repo();

    // 先嘗試從 DB 取得完整資料
    if let Ok(Some(record)) = repo.find_full_by_id(auth.user_id).await {
        return Ok(Json(record.into_response()));
    }

    // 回退：從記憶體 store 查詢
    let users = state.users.read().await;
    let user = users
        .get(&auth.user_id)
        .ok_or_else(|| AppError::NotFound("用戶不存在".to_string()))?;

    Ok(Json(user.clone().into()))
}

// ============================================================
// DELETE /api/v1/auth/account
// ============================================================

/// 刪除帳號（GDPR）
///
/// DELETE /api/v1/auth/account
/// Header: Authorization: Bearer <access_token>
pub async fn delete_account(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<MessageResponse>> {
    let repo = state.user_repo();

    // 從 DB 刪除
    let deleted = repo
        .delete(auth.user_id)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    if !deleted {
        return Err(AppError::NotFound("帳號不存在".to_string()));
    }

    // 也從記憶體 store 移除
    {
        let mut users = state.users.write().await;
        users.remove(&auth.user_id);
    }

    tracing::info!(user_id = %auth.user_id, "帳號已刪除 (GDPR)");

    Ok(Json(MessageResponse {
        message: "帳號已成功刪除".to_string(),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_oauth_username() {
        let username = generate_oauth_username("google", "1234567890");
        assert_eq!(username, "google_12345678");

        let username = generate_oauth_username("apple", "abc");
        assert_eq!(username, "apple_abc");
    }
}
