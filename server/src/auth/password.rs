//! 密碼處理模組
//!
//! 提供密碼雜湊、驗證、和強度檢查功能
//! 使用 argon2 作為主要雜湊演算法

use crate::error::{AppError, AppResult};

/// 密碼強度驗證
///
/// 規則：
/// - 最少 8 字元
/// - 最多 128 字元
pub fn validate_password_strength(password: &str) -> AppResult<()> {
    if password.len() < 8 {
        return Err(AppError::BadRequest(
            "密碼至少需要 8 個字元".to_string(),
        ));
    }
    if password.len() > 128 {
        return Err(AppError::BadRequest(
            "密碼不能超過 128 個字元".to_string(),
        ));
    }
    Ok(())
}

/// 使用 argon2 雜湊密碼
pub fn hash_password(password: &str) -> AppResult<String> {
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

/// 驗證密碼是否符合 argon2 雜湊
pub fn verify_password(password: &str, hash: &str) -> AppResult<bool> {
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

    #[test]
    fn test_password_strength_too_short() {
        let result = validate_password_strength("short");
        assert!(result.is_err());
    }

    #[test]
    fn test_password_strength_valid() {
        let result = validate_password_strength("valid_password_123");
        assert!(result.is_ok());
    }

    #[test]
    fn test_password_strength_too_long() {
        let long_password = "a".repeat(129);
        let result = validate_password_strength(&long_password);
        assert!(result.is_err());
    }

    #[test]
    fn test_password_strength_exactly_8() {
        let result = validate_password_strength("12345678");
        assert!(result.is_ok());
    }
}
