//! 健康檢查處理器
//!
//! 提供伺服器健康狀態檢查端點

use axum::{extract::State, http::StatusCode, Json};
use serde::Serialize;

use crate::{AppError, AppState};

/// 健康檢查回應
#[derive(Debug, Serialize)]
pub struct HealthResponse {
    /// 狀態
    pub status: &'static str,
    /// 版本
    pub version: &'static str,
}

/// 資料庫健康檢查回應
#[derive(Debug, Serialize)]
pub struct DbHealthResponse {
    /// 狀態
    pub status: &'static str,
    /// 資料庫類型
    pub database: &'static str,
    /// 連線狀態
    pub connected: bool,
    /// 錯誤訊息（如果有）
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// Redis 健康檢查回應
#[derive(Debug, Serialize)]
pub struct RedisHealthResponse {
    /// 狀態
    pub status: &'static str,
    /// 服務類型
    pub service: &'static str,
    /// 連線狀態
    pub connected: bool,
    /// 錯誤訊息（如果有）
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// 基本健康檢查
///
/// GET /health
///
/// 回傳伺服器基本狀態和版本資訊
pub async fn health_check() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok",
        version: env!("CARGO_PKG_VERSION"),
    })
}

/// 資料庫健康檢查
///
/// GET /health/db
///
/// 檢查資料庫連線是否正常
pub async fn db_health_check(
    State(state): State<AppState>,
) -> Result<Json<DbHealthResponse>, (StatusCode, Json<DbHealthResponse>)> {
    match state.check_db_health().await {
        Ok(()) => Ok(Json(DbHealthResponse {
            status: "ok",
            database: "postgresql",
            connected: true,
            error: None,
        })),
        Err(AppError::DatabaseError(msg)) => Err((
            StatusCode::SERVICE_UNAVAILABLE,
            Json(DbHealthResponse {
                status: "error",
                database: "postgresql",
                connected: false,
                error: Some(msg),
            }),
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(DbHealthResponse {
                status: "error",
                database: "postgresql",
                connected: false,
                error: Some(e.to_string()),
            }),
        )),
    }
}

/// Redis 健康檢查
///
/// GET /health/redis
///
/// 檢查 Redis 連線是否正常
pub async fn redis_health_check(
    State(state): State<AppState>,
) -> Result<Json<RedisHealthResponse>, (StatusCode, Json<RedisHealthResponse>)> {
    match state.check_redis_health().await {
        Ok(()) => Ok(Json(RedisHealthResponse {
            status: "ok",
            service: "redis",
            connected: true,
            error: None,
        })),
        Err(AppError::InternalError(msg)) => Err((
            StatusCode::SERVICE_UNAVAILABLE,
            Json(RedisHealthResponse {
                status: "error",
                service: "redis",
                connected: false,
                error: Some(msg),
            }),
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(RedisHealthResponse {
                status: "error",
                service: "redis",
                connected: false,
                error: Some(e.to_string()),
            }),
        )),
    }
}

/// 完整健康檢查回應
#[derive(Debug, Serialize)]
pub struct FullHealthResponse {
    /// 整體狀態
    pub status: &'static str,
    /// 版本
    pub version: &'static str,
    /// 各服務狀態
    pub services: ServicesHealth,
}

/// 各服務健康狀態
#[derive(Debug, Serialize)]
pub struct ServicesHealth {
    /// 資料庫狀態
    pub database: ServiceStatus,
    /// Redis 狀態
    pub redis: ServiceStatus,
}

/// 單一服務狀態
#[derive(Debug, Serialize)]
pub struct ServiceStatus {
    /// 是否連線
    pub connected: bool,
    /// 錯誤訊息
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// 完整健康檢查
///
/// GET /health/full
///
/// 檢查所有服務的健康狀態
pub async fn full_health_check(State(state): State<AppState>) -> Json<FullHealthResponse> {
    let db_status = match state.check_db_health().await {
        Ok(()) => ServiceStatus {
            connected: true,
            error: None,
        },
        Err(e) => ServiceStatus {
            connected: false,
            error: Some(e.to_string()),
        },
    };

    let redis_status = match state.check_redis_health().await {
        Ok(()) => ServiceStatus {
            connected: true,
            error: None,
        },
        Err(e) => ServiceStatus {
            connected: false,
            error: Some(e.to_string()),
        },
    };

    let overall_status = if db_status.connected && redis_status.connected {
        "ok"
    } else {
        "degraded"
    };

    Json(FullHealthResponse {
        status: overall_status,
        version: env!("CARGO_PKG_VERSION"),
        services: ServicesHealth {
            database: db_status,
            redis: redis_status,
        },
    })
}
