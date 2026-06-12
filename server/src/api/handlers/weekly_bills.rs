//! 每週法案 API 處理器
//!
//! - GET /api/v1/weekly/current-bill — 取得當週法案
//! - GET /api/v1/weekly/history — 取得法案歷史

use axum::{
    extract::{Query, State},
    Json,
};
use serde::Deserialize;

use crate::domain::weekly_bill::{BillHistoryResponse, CurrentBillResponse};
use crate::error::AppError;
use crate::services::WeeklyBillService;
use crate::AppState;

// ============================================================
// GET /api/v1/weekly/current-bill
// ============================================================

/// 取得當週法案（公開端點）
pub async fn get_current_bill(
    State(state): State<AppState>,
) -> Result<Json<CurrentBillResponse>, AppError> {
    let resp = WeeklyBillService::get_current_bill(&state.db).await?;
    Ok(Json(resp))
}

// ============================================================
// GET /api/v1/weekly/history
// ============================================================

/// 法案歷史查詢參數
#[derive(Debug, Deserialize)]
pub struct BillHistoryParams {
    /// 每頁筆數（預設 10，最大 50）
    pub limit: Option<i64>,
    /// 偏移量（預設 0）
    pub offset: Option<i64>,
}

/// 取得法案歷史（公開端點）
pub async fn get_bill_history(
    State(state): State<AppState>,
    Query(params): Query<BillHistoryParams>,
) -> Result<Json<BillHistoryResponse>, AppError> {
    let limit = params.limit.unwrap_or(10).min(50).max(1);
    let offset = params.offset.unwrap_or(0).max(0);

    let resp = WeeklyBillService::get_bill_history(&state.db, limit, offset).await?;
    Ok(Json(resp))
}
