//! OAuth 認證模組
//!
//! 支援 Google OAuth 和 Apple Sign-In
//! 在沒有實際 credentials 時可用 mock 模式

use serde::{Deserialize, Serialize};

use crate::error::{AppError, AppResult};

/// OAuth 驗證結果（統一 struct）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OAuthResult {
    /// OAuth 提供者 (google, apple)
    pub provider: String,
    /// 提供者端的使用者 ID
    pub provider_user_id: String,
    /// Email
    pub email: Option<String>,
    /// 顯示名稱
    pub name: Option<String>,
    /// 頭像 URL
    pub avatar_url: Option<String>,
}

/// Google OAuth: 驗證 id_token
///
/// 呼叫 Google tokeninfo API 驗證 token
pub async fn verify_google_token(id_token: &str) -> AppResult<OAuthResult> {
    // 檢查是否為 mock token（開發用）
    if id_token.starts_with("mock_google_") {
        return Ok(mock_google_result(id_token));
    }

    let url = format!(
        "https://oauth2.googleapis.com/tokeninfo?id_token={}",
        id_token
    );

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| AppError::InternalError(format!("Google OAuth 驗證請求失敗: {}", e)))?;

    if !response.status().is_success() {
        return Err(AppError::Unauthorized(
            "Google OAuth token 無效".to_string(),
        ));
    }

    let token_info: GoogleTokenInfo = response
        .json()
        .await
        .map_err(|e| AppError::InternalError(format!("Google OAuth 回應解析失敗: {}", e)))?;

    Ok(OAuthResult {
        provider: "google".to_string(),
        provider_user_id: token_info.sub,
        email: Some(token_info.email),
        name: token_info.name,
        avatar_url: token_info.picture,
    })
}

/// Apple Sign-In: 驗證 identity_token
///
/// 使用 Apple 公開金鑰驗證 JWT token
pub async fn verify_apple_token(identity_token: &str) -> AppResult<OAuthResult> {
    // 檢查是否為 mock token（開發用）
    if identity_token.starts_with("mock_apple_") {
        return Ok(mock_apple_result(identity_token));
    }

    // 取得 Apple 的公開金鑰
    let client = reqwest::Client::new();
    let keys_response = client
        .get("https://appleid.apple.com/auth/keys")
        .send()
        .await
        .map_err(|e| AppError::InternalError(format!("Apple 公開金鑰請求失敗: {}", e)))?;

    if !keys_response.status().is_success() {
        return Err(AppError::InternalError(
            "無法取得 Apple 公開金鑰".to_string(),
        ));
    }

    let apple_keys: AppleKeysResponse = keys_response
        .json()
        .await
        .map_err(|e| AppError::InternalError(format!("Apple 金鑰解析失敗: {}", e)))?;

    // 解碼 JWT header 取得 kid
    let header = jsonwebtoken::decode_header(identity_token)
        .map_err(|e| AppError::Unauthorized(format!("Apple token header 無效: {}", e)))?;

    let kid = header
        .kid
        .ok_or_else(|| AppError::Unauthorized("Apple token 缺少 kid".to_string()))?;

    // 找到對應的金鑰
    let key = apple_keys
        .keys
        .iter()
        .find(|k| k.kid == kid)
        .ok_or_else(|| AppError::Unauthorized("找不到對應的 Apple 金鑰".to_string()))?;

    // 使用金鑰驗證 JWT
    let decoding_key = jsonwebtoken::DecodingKey::from_rsa_components(&key.n, &key.e)
        .map_err(|e| AppError::InternalError(format!("RSA 金鑰建立失敗: {}", e)))?;

    let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::RS256);
    validation.set_issuer(&["https://appleid.apple.com"]);
    // Apple 的 audience 是 app 的 bundle identifier
    validation.validate_aud = false; // 暫時跳過 audience 驗證

    let token_data = jsonwebtoken::decode::<AppleTokenClaims>(
        identity_token,
        &decoding_key,
        &validation,
    )
    .map_err(|e| AppError::Unauthorized(format!("Apple token 驗證失敗: {}", e)))?;

    Ok(OAuthResult {
        provider: "apple".to_string(),
        provider_user_id: token_data.claims.sub,
        email: token_data.claims.email,
        name: None, // Apple 只在首次登入時提供名稱
        avatar_url: None,
    })
}

// ============================================================
// Google OAuth 相關結構
// ============================================================

#[derive(Debug, Deserialize)]
struct GoogleTokenInfo {
    /// Google user ID
    sub: String,
    /// Email
    email: String,
    /// 名稱
    name: Option<String>,
    /// 頭像
    picture: Option<String>,
}

// ============================================================
// Apple Sign-In 相關結構
// ============================================================

#[derive(Debug, Deserialize)]
struct AppleKeysResponse {
    keys: Vec<AppleKey>,
}

#[derive(Debug, Deserialize)]
struct AppleKey {
    kid: String,
    n: String,
    e: String,
}

#[derive(Debug, Deserialize)]
struct AppleTokenClaims {
    sub: String,
    email: Option<String>,
}

// ============================================================
// Mock 函式（開發用）
// ============================================================

fn mock_google_result(token: &str) -> OAuthResult {
    let user_id = token.strip_prefix("mock_google_").unwrap_or("unknown");
    OAuthResult {
        provider: "google".to_string(),
        provider_user_id: format!("google_{}", user_id),
        email: Some(format!("{}@gmail.com", user_id)),
        name: Some(format!("Google User {}", user_id)),
        avatar_url: None,
    }
}

fn mock_apple_result(token: &str) -> OAuthResult {
    let user_id = token.strip_prefix("mock_apple_").unwrap_or("unknown");
    OAuthResult {
        provider: "apple".to_string(),
        provider_user_id: format!("apple_{}", user_id),
        email: Some(format!("{}@privaterelay.appleid.com", user_id)),
        name: Some(format!("Apple User {}", user_id)),
        avatar_url: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_mock_google_token() {
        let result = verify_google_token("mock_google_testuser").await.unwrap();
        assert_eq!(result.provider, "google");
        assert_eq!(result.provider_user_id, "google_testuser");
        assert_eq!(result.email, Some("testuser@gmail.com".to_string()));
    }

    #[tokio::test]
    async fn test_mock_apple_token() {
        let result = verify_apple_token("mock_apple_testuser").await.unwrap();
        assert_eq!(result.provider, "apple");
        assert_eq!(result.provider_user_id, "apple_testuser");
    }
}
