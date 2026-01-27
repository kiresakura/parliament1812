//! 認證相關 API 處理器
//!
//! 提供用戶註冊、登入、取得當前用戶資訊等功能

use axum::{extract::State, Json};

use crate::{
    auth::AuthUser,
    domain::{CreateUserRequest, LoginRequest, TokenResponse, User, UserResponse},
    error::{AppError, AppResult},
    AppState,
};

/// 用戶註冊
///
/// POST /api/v1/auth/register
pub async fn register(
    State(state): State<AppState>,
    Json(req): Json<CreateUserRequest>,
) -> AppResult<Json<UserResponse>> {
    // 驗證請求
    req.validate()
        .map_err(|e| AppError::BadRequest(e.to_string()))?;

    // 額外驗證
    if req.username.len() < 3 || req.username.len() > 20 {
        return Err(AppError::BadRequest(
            "使用者名稱長度必須在 3-20 字元之間".to_string(),
        ));
    }
    if req.password.len() < 6 || req.password.len() > 50 {
        return Err(AppError::BadRequest(
            "密碼長度必須在 6-50 字元之間".to_string(),
        ));
    }

    // 檢查用戶名是否已存在
    {
        let users = state.users.read().await;
        if users.values().any(|u| u.username == req.username) {
            return Err(AppError::BadRequest("使用者名稱已被使用".to_string()));
        }
    }

    // 使用 argon2 雜湊密碼
    let password_hash = hash_password(&req.password)?;

    // 建立用戶
    let user = User::new(req.username, password_hash);
    let user_id = user.id;

    // 儲存用戶
    {
        let mut users = state.users.write().await;
        users.insert(user_id, user.clone());
    }

    tracing::info!(user_id = %user_id, username = %user.username, "新用戶註冊");

    Ok(Json(user.into()))
}

/// 用戶登入
///
/// POST /api/v1/auth/login
pub async fn login(
    State(state): State<AppState>,
    Json(req): Json<LoginRequest>,
) -> AppResult<Json<TokenResponse>> {
    // 驗證請求
    req.validate()
        .map_err(|e| AppError::BadRequest(e.to_string()))?;

    // 查詢用戶
    let user = {
        let users = state.users.read().await;
        users
            .values()
            .find(|u| u.username == req.username)
            .cloned()
            .ok_or_else(|| AppError::Unauthorized("使用者名稱或密碼錯誤".to_string()))?
    };

    // 驗證密碼
    if !verify_password(&req.password, &user.password_hash)? {
        return Err(AppError::Unauthorized("使用者名稱或密碼錯誤".to_string()));
    }

    // 生成 JWT token
    let token = state.jwt.generate_token(user.id)?;
    let expires_in = state.jwt.expiration_seconds();

    tracing::info!(user_id = %user.id, username = %user.username, "用戶登入");

    Ok(Json(TokenResponse::new(token, expires_in)))
}

/// 取得當前用戶資訊
///
/// GET /api/v1/auth/me
pub async fn me(State(state): State<AppState>, auth: AuthUser) -> AppResult<Json<UserResponse>> {
    let users = state.users.read().await;
    let user = users
        .get(&auth.user_id)
        .ok_or_else(|| AppError::NotFound("用戶不存在".to_string()))?;

    Ok(Json(user.clone().into()))
}

/// 使用 argon2 雜湊密碼
fn hash_password(password: &str) -> AppResult<String> {
    use argon2::{
        password_hash::{rand_core::OsRng, PasswordHasher, SaltString},
        Argon2,
    };

    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| AppError::InternalError(format!("密碼雜湊失敗: {}", e)))
}

/// 驗證密碼
fn verify_password(password: &str, hash: &str) -> AppResult<bool> {
    use argon2::{
        password_hash::{PasswordHash, PasswordVerifier},
        Argon2,
    };

    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| AppError::InternalError(format!("密碼雜湊解析失敗: {}", e)))?;

    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_password_hash_and_verify() {
        let password = "test_password_123";
        let hash = hash_password(password).unwrap();

        assert!(verify_password(password, &hash).unwrap());
        assert!(!verify_password("wrong_password", &hash).unwrap());
    }
}
