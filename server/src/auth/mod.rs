//! 認證模組
//!
//! 提供 JWT 認證相關功能

pub mod jwt;
pub mod middleware;

// 重新匯出常用類型
pub use jwt::{Claims, JwtManager};
pub use middleware::{
    auth_middleware, optional_auth_middleware, AuthError, AuthUser, OptionalAuthUser,
};
