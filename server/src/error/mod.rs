//! 錯誤處理模組
//!
//! 提供統一的錯誤類型和 HTTP 回應轉換

mod app_error;

pub use app_error::{AppError, AppResult, ErrorResponse};
