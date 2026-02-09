//! 使用者領域模型
//!
//! 定義使用者相關的資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 使用者
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    /// 使用者 ID
    pub id: Uuid,
    /// 使用者名稱
    pub username: String,
    /// 密碼雜湊
    #[serde(skip_serializing)]
    pub password_hash: String,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

impl User {
    /// 建立新使用者
    pub fn new(username: String, password_hash: String) -> Self {
        Self {
            id: Uuid::new_v4(),
            username,
            password_hash,
            created_at: Utc::now(),
        }
    }

    /// 轉換為回應格式（不含密碼）
    pub fn into_response(self) -> UserResponse {
        UserResponse {
            id: self.id,
            username: self.username,
            created_at: self.created_at,
            display_name: None,
            email: None,
            avatar_url: None,
            elo_rating: None,
        }
    }
}

/// 使用者回應（不含密碼）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserResponse {
    /// 使用者 ID
    pub id: Uuid,
    /// 使用者名稱
    pub username: String,
    /// 建立時間
    pub created_at: DateTime<Utc>,
    /// 顯示名稱
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display_name: Option<String>,
    /// Email
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    /// 頭像 URL
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar_url: Option<String>,
    /// ELO 評分
    #[serde(skip_serializing_if = "Option::is_none")]
    pub elo_rating: Option<i32>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            username: user.username,
            created_at: user.created_at,
            display_name: None,
            email: None,
            avatar_url: None,
            elo_rating: None,
        }
    }
}

/// 建立使用者請求（email + password 註冊）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateUserRequest {
    /// 使用者名稱
    pub username: String,
    /// 密碼（明文，將被雜湊）
    pub password: String,
    /// Email（可選）
    #[serde(default)]
    pub email: Option<String>,
}

impl CreateUserRequest {
    /// 驗證請求
    pub fn validate(&self) -> Result<(), &'static str> {
        if self.username.is_empty() {
            return Err("使用者名稱不能為空");
        }
        if self.username.len() < 3 {
            return Err("使用者名稱至少需要 3 個字元");
        }
        if self.username.len() > 20 {
            return Err("使用者名稱不能超過 20 個字元");
        }
        if self.password.is_empty() {
            return Err("密碼不能為空");
        }
        if self.password.len() < 6 {
            return Err("密碼至少需要 6 個字元");
        }
        Ok(())
    }
}

/// 登入請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoginRequest {
    /// 使用者名稱（支援 email 或 username）
    pub username: String,
    /// 密碼
    pub password: String,
}

impl LoginRequest {
    /// 驗證請求
    pub fn validate(&self) -> Result<(), &'static str> {
        if self.username.is_empty() {
            return Err("使用者名稱不能為空");
        }
        if self.password.is_empty() {
            return Err("密碼不能為空");
        }
        Ok(())
    }
}

/// Token 回應（向後兼容 + 新的 token pair 格式）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenResponse {
    /// 存取 Token
    pub access_token: String,
    /// Token 類型
    pub token_type: String,
    /// 過期時間（秒）
    pub expires_in: i64,
    /// 重新整理 Token
    #[serde(skip_serializing_if = "Option::is_none")]
    pub refresh_token: Option<String>,
    /// 使用者資訊
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user: Option<UserResponse>,
}

impl TokenResponse {
    /// 建立新的 Token 回應（向後兼容）
    pub fn new(access_token: String, expires_in: i64) -> Self {
        Self {
            access_token,
            token_type: "Bearer".to_string(),
            expires_in,
            refresh_token: None,
            user: None,
        }
    }

    /// 從 TokenPair 建立（新版）
    pub fn from_pair(pair: crate::auth::TokenPair, user: Option<UserResponse>) -> Self {
        Self {
            access_token: pair.access_token,
            token_type: "Bearer".to_string(),
            expires_in: pair.expires_in,
            refresh_token: Some(pair.refresh_token),
            user,
        }
    }
}

/// Refresh Token 請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

/// OAuth 登入請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OAuthLoginRequest {
    /// OAuth token (id_token for Google, identity_token for Apple)
    pub token: String,
    /// 顯示名稱（Apple 首次登入時可能提供）
    #[serde(default)]
    pub display_name: Option<String>,
}

/// 忘記密碼請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ForgotPasswordRequest {
    pub email: String,
}

/// 重設密碼請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResetPasswordRequest {
    pub reset_token: String,
    pub new_password: String,
}

/// 通用訊息回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageResponse {
    pub message: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_user_request_validation() {
        let valid = CreateUserRequest {
            username: "testuser".to_string(),
            password: "password123".to_string(),
            email: None,
        };
        assert!(valid.validate().is_ok());

        let empty_username = CreateUserRequest {
            username: "".to_string(),
            password: "password123".to_string(),
            email: None,
        };
        assert!(empty_username.validate().is_err());

        let short_password = CreateUserRequest {
            username: "testuser".to_string(),
            password: "12345".to_string(),
            email: None,
        };
        assert!(short_password.validate().is_err());
    }

    #[test]
    fn test_user_response_excludes_password() {
        let user = User::new("testuser".to_string(), "hashed_password".to_string());
        let response: UserResponse = user.into();

        // UserResponse 不應該有 password_hash 欄位
        let json = serde_json::to_string(&response).unwrap();
        assert!(!json.contains("password"));
    }

    #[test]
    fn test_token_response_from_pair() {
        let pair = crate::auth::TokenPair {
            access_token: "access_123".to_string(),
            refresh_token: "refresh_456".to_string(),
            expires_in: 900,
        };
        let response = TokenResponse::from_pair(pair, None);
        assert_eq!(response.access_token, "access_123");
        assert_eq!(response.refresh_token, Some("refresh_456".to_string()));
        assert_eq!(response.expires_in, 900);
    }
}
