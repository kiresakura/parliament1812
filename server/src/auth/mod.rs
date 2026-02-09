//! 認證模組
//!
//! 提供 JWT 認證、密碼處理、OAuth 驗證等功能

pub mod jwt;
pub mod middleware;
pub mod oauth;
pub mod password;

// 重新匯出常用類型
pub use jwt::{Claims, JwtManager, TokenPair, TokenType};
pub use middleware::{
    auth_middleware, optional_auth_middleware, AuthError, AuthUser, OptionalAuthUser,
};
pub use oauth::{verify_apple_token, verify_google_token, OAuthResult};
pub use password::{hash_password, validate_password_strength, verify_password};
