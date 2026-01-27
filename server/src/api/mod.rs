//! API 模組
//!
//! 包含所有 HTTP API 相關的程式碼

pub mod handlers;
pub mod router;

pub use router::{create_health_only_router, create_router};
