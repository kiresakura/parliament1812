//! JWT 管理模組
//!
//! 提供 JWT Token 的生成與驗證功能
//! 支援 AccessToken (短期 15min) + RefreshToken (長期 30 days)

use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;

/// Token 類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TokenType {
    /// 存取 Token（短期 15 分鐘）
    Access,
    /// 重新整理 Token（長期 30 天）
    Refresh,
}

/// JWT Claims
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    /// Subject (user_id)
    pub sub: String,
    /// 過期時間戳
    pub exp: usize,
    /// 簽發時間戳
    pub iat: usize,
    /// Token 類型
    #[serde(default = "default_token_type")]
    pub token_type: TokenType,
}

fn default_token_type() -> TokenType {
    TokenType::Access
}

impl Claims {
    /// 取得 user_id
    pub fn user_id(&self) -> Result<Uuid, AppError> {
        Uuid::parse_str(&self.sub).map_err(|_| AppError::Unauthorized("無效的 user_id".to_string()))
    }
}

/// Token 對（access + refresh）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
    /// access_token 過期時間（秒）
    pub expires_in: i64,
}

/// JWT 管理器
#[derive(Clone)]
pub struct JwtManager {
    /// 密鑰
    secret: String,
    /// Access Token 有效時間（分鐘）
    access_token_minutes: i64,
    /// Refresh Token 有效時間（天）
    refresh_token_days: i64,
    /// 向後兼容：舊的單一 token 有效時間（小時）
    expiration_hours: i64,
}

impl JwtManager {
    /// 建立新的 JWT 管理器
    pub fn new(secret: String, expiration_hours: i64) -> Self {
        Self {
            secret,
            access_token_minutes: 15, // 15 分鐘
            refresh_token_days: 30,   // 30 天
            expiration_hours,
        }
    }

    /// 生成 Token 對（access + refresh）
    pub fn generate_token_pair(&self, user_id: Uuid) -> Result<TokenPair, AppError> {
        let access_token = self.generate_typed_token(user_id, TokenType::Access)?;
        let refresh_token = self.generate_typed_token(user_id, TokenType::Refresh)?;

        Ok(TokenPair {
            access_token,
            refresh_token,
            expires_in: self.access_token_minutes * 60,
        })
    }

    /// 生成指定類型的 Token
    fn generate_typed_token(
        &self,
        user_id: Uuid,
        token_type: TokenType,
    ) -> Result<String, AppError> {
        let now = Utc::now();
        let exp = match token_type {
            TokenType::Access => now + Duration::minutes(self.access_token_minutes),
            TokenType::Refresh => now + Duration::days(self.refresh_token_days),
        };

        let claims = Claims {
            sub: user_id.to_string(),
            exp: exp.timestamp() as usize,
            iat: now.timestamp() as usize,
            token_type,
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret.as_bytes()),
        )
        .map_err(|e| AppError::InternalError(format!("Token 生成失敗: {}", e)))
    }

    /// 生成 Token（向後兼容，使用 expiration_hours）
    pub fn generate_token(&self, user_id: Uuid) -> Result<String, AppError> {
        let now = Utc::now();
        let exp = now + Duration::hours(self.expiration_hours);

        let claims = Claims {
            sub: user_id.to_string(),
            exp: exp.timestamp() as usize,
            iat: now.timestamp() as usize,
            token_type: TokenType::Access,
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret.as_bytes()),
        )
        .map_err(|e| AppError::InternalError(format!("Token 生成失敗: {}", e)))
    }

    /// 驗證 Token
    pub fn validate_token(&self, token: &str) -> Result<Claims, AppError> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                AppError::Unauthorized("Token 已過期".to_string())
            }
            jsonwebtoken::errors::ErrorKind::InvalidToken => {
                AppError::Unauthorized("無效的 Token".to_string())
            }
            _ => AppError::Unauthorized(format!("Token 驗證失敗: {}", e)),
        })?;

        Ok(token_data.claims)
    }

    /// 驗證 Refresh Token 並產生新的 Access Token
    pub fn refresh_access_token(&self, refresh_token: &str) -> Result<TokenPair, AppError> {
        let claims = self.validate_token(refresh_token)?;

        if claims.token_type != TokenType::Refresh {
            return Err(AppError::Unauthorized("必須使用 refresh token".to_string()));
        }

        let user_id = claims.user_id()?;
        self.generate_token_pair(user_id)
    }

    /// 取得過期時間（秒）— 向後兼容
    pub fn expiration_seconds(&self) -> i64 {
        self.expiration_hours * 3600
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_validate_token() {
        let manager = JwtManager::new("test_secret_key_12345".to_string(), 24);
        let user_id = Uuid::new_v4();

        let token = manager.generate_token(user_id).unwrap();
        assert!(!token.is_empty());

        let claims = manager.validate_token(&token).unwrap();
        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.user_id().unwrap(), user_id);
    }

    #[test]
    fn test_invalid_token() {
        let manager = JwtManager::new("test_secret_key_12345".to_string(), 24);

        let result = manager.validate_token("invalid_token");
        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_secret() {
        let manager1 = JwtManager::new("secret1".to_string(), 24);
        let manager2 = JwtManager::new("secret2".to_string(), 24);
        let user_id = Uuid::new_v4();

        let token = manager1.generate_token(user_id).unwrap();
        let result = manager2.validate_token(&token);
        assert!(result.is_err());
    }

    #[test]
    fn test_generate_token_pair() {
        let manager = JwtManager::new("test_secret_key_12345".to_string(), 24);
        let user_id = Uuid::new_v4();

        let pair = manager.generate_token_pair(user_id).unwrap();
        assert!(!pair.access_token.is_empty());
        assert!(!pair.refresh_token.is_empty());
        assert_eq!(pair.expires_in, 15 * 60); // 15 minutes in seconds

        // Validate both tokens
        let access_claims = manager.validate_token(&pair.access_token).unwrap();
        assert_eq!(access_claims.token_type, TokenType::Access);
        assert_eq!(access_claims.user_id().unwrap(), user_id);

        let refresh_claims = manager.validate_token(&pair.refresh_token).unwrap();
        assert_eq!(refresh_claims.token_type, TokenType::Refresh);
        assert_eq!(refresh_claims.user_id().unwrap(), user_id);
    }

    #[test]
    fn test_refresh_access_token() {
        let manager = JwtManager::new("test_secret_key_12345".to_string(), 24);
        let user_id = Uuid::new_v4();

        let pair = manager.generate_token_pair(user_id).unwrap();

        // Refresh using refresh_token should succeed
        let new_pair = manager.refresh_access_token(&pair.refresh_token).unwrap();
        assert!(!new_pair.access_token.is_empty());

        let new_claims = manager.validate_token(&new_pair.access_token).unwrap();
        assert_eq!(new_claims.user_id().unwrap(), user_id);
    }

    #[test]
    fn test_refresh_with_access_token_fails() {
        let manager = JwtManager::new("test_secret_key_12345".to_string(), 24);
        let user_id = Uuid::new_v4();

        let pair = manager.generate_token_pair(user_id).unwrap();

        // Refresh using access_token should fail
        let result = manager.refresh_access_token(&pair.access_token);
        assert!(result.is_err());
    }
}
