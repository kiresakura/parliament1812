//! 應用程式錯誤處理
//!
//! 統一的錯誤類型和 HTTP 回應轉換

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;

/// 錯誤回應格式
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    /// 錯誤代碼
    pub code: u16,
    /// 錯誤類型
    pub error: String,
    /// 錯誤訊息
    pub message: String,
}

/// 應用程式錯誤類型
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    /// 找不到資源
    #[error("找不到資源: {0}")]
    NotFound(String),

    /// 請求無效
    #[error("請求無效: {0}")]
    BadRequest(String),

    /// 未授權
    #[error("未授權: {0}")]
    Unauthorized(String),

    /// 禁止存取
    #[error("禁止存取: {0}")]
    Forbidden(String),

    /// 內部錯誤
    #[error("內部錯誤: {0}")]
    InternalError(String),

    /// 資料庫錯誤
    #[error("資料庫錯誤: {0}")]
    DatabaseError(String),

    /// 驗證錯誤
    #[error("驗證錯誤: {0}")]
    ValidationError(String),
}

impl AppError {
    /// 取得對應的 HTTP 狀態碼
    pub fn status_code(&self) -> StatusCode {
        match self {
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
            AppError::Unauthorized(_) => StatusCode::UNAUTHORIZED,
            AppError::Forbidden(_) => StatusCode::FORBIDDEN,
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::ValidationError(_) => StatusCode::UNPROCESSABLE_ENTITY,
        }
    }

    /// 取得錯誤類型名稱
    pub fn error_type(&self) -> &'static str {
        match self {
            AppError::NotFound(_) => "NOT_FOUND",
            AppError::BadRequest(_) => "BAD_REQUEST",
            AppError::Unauthorized(_) => "UNAUTHORIZED",
            AppError::Forbidden(_) => "FORBIDDEN",
            AppError::InternalError(_) => "INTERNAL_ERROR",
            AppError::DatabaseError(_) => "DATABASE_ERROR",
            AppError::ValidationError(_) => "VALIDATION_ERROR",
        }
    }

    /// 取得錯誤訊息
    pub fn message(&self) -> String {
        match self {
            AppError::NotFound(msg) => msg.clone(),
            AppError::BadRequest(msg) => msg.clone(),
            AppError::Unauthorized(msg) => msg.clone(),
            AppError::Forbidden(msg) => msg.clone(),
            AppError::InternalError(msg) => msg.clone(),
            AppError::DatabaseError(msg) => msg.clone(),
            AppError::ValidationError(msg) => msg.clone(),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status = self.status_code();

        // 記錄錯誤日誌（內部錯誤和資料庫錯誤記錄詳細資訊）
        match &self {
            AppError::InternalError(msg) => {
                tracing::error!(error = %msg, "內部伺服器錯誤");
            }
            AppError::DatabaseError(msg) => {
                tracing::error!(error = %msg, "資料庫錯誤");
            }
            _ => {
                tracing::warn!(error = %self, "請求錯誤");
            }
        }

        let error_response = ErrorResponse {
            code: status.as_u16(),
            error: self.error_type().to_string(),
            message: self.message(),
        };

        (status, Json(error_response)).into_response()
    }
}

// ============================================================
// 從其他錯誤類型轉換
// ============================================================

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFound("資料不存在".to_string()),
            _ => AppError::DatabaseError(err.to_string()),
        }
    }
}

impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self {
        AppError::InternalError(err.to_string())
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::BadRequest(format!("JSON 解析錯誤: {}", err))
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(err: jsonwebtoken::errors::Error) -> Self {
        AppError::Unauthorized(format!("Token 錯誤: {}", err))
    }
}

/// Result 類型別名
pub type AppResult<T> = Result<T, AppError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_codes() {
        assert_eq!(
            AppError::NotFound("test".to_string()).status_code(),
            StatusCode::NOT_FOUND
        );
        assert_eq!(
            AppError::BadRequest("test".to_string()).status_code(),
            StatusCode::BAD_REQUEST
        );
        assert_eq!(
            AppError::Unauthorized("test".to_string()).status_code(),
            StatusCode::UNAUTHORIZED
        );
        assert_eq!(
            AppError::Forbidden("test".to_string()).status_code(),
            StatusCode::FORBIDDEN
        );
        assert_eq!(
            AppError::InternalError("test".to_string()).status_code(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
        assert_eq!(
            AppError::DatabaseError("test".to_string()).status_code(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
        assert_eq!(
            AppError::ValidationError("test".to_string()).status_code(),
            StatusCode::UNPROCESSABLE_ENTITY
        );
    }

    #[test]
    fn test_error_types() {
        assert_eq!(
            AppError::NotFound("test".to_string()).error_type(),
            "NOT_FOUND"
        );
        assert_eq!(
            AppError::BadRequest("test".to_string()).error_type(),
            "BAD_REQUEST"
        );
    }
}
