//! JWT 管理模組
//!
//! 提供 JWT Token 的生成與驗證功能

use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;

/// JWT Claims
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    /// Subject (user_id)
    pub sub: String,
    /// 過期時間戳
    pub exp: usize,
    /// 簽發時間戳
    pub iat: usize,
}

impl Claims {
    /// 取得 user_id
    pub fn user_id(&self) -> Result<Uuid, AppError> {
        Uuid::parse_str(&self.sub).map_err(|_| AppError::Unauthorized("無效的 user_id".to_string()))
    }
}

/// JWT 管理器
#[derive(Clone)]
pub struct JwtManager {
    /// 密鑰
    secret: String,
    /// Token 有效時間（小時）
    expiration_hours: i64,
}

impl JwtManager {
    /// 建立新的 JWT 管理器
    pub fn new(secret: String, expiration_hours: i64) -> Self {
        Self {
            secret,
            expiration_hours,
        }
    }

    /// 生成 Token
    pub fn generate_token(&self, user_id: Uuid) -> Result<String, AppError> {
        let now = Utc::now();
        let exp = now + Duration::hours(self.expiration_hours);

        let claims = Claims {
            sub: user_id.to_string(),
            exp: exp.timestamp() as usize,
            iat: now.timestamp() as usize,
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

    /// 取得過期時間（秒）
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
}
