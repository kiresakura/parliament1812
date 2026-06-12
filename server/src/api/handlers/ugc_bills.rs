//! 玩家自創法案（UGC）API 處理器
//!
//! - POST /api/v1/bills — 建立法案（需認證）
//! - POST /api/v1/bills/:bill_id/vote — 投票（需認證）
//! - GET  /api/v1/bills — 列出法案（公開）
//! - GET  /api/v1/bills/:bill_id — 取得法案詳情（公開）
//! - GET  /api/v1/bills/mine — 取得自己的法案（需認證）

use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::domain::user_bill::{
    CreateUserBillRequest, UserBill, UserBillListResponse, UserBillResponse, VoteBillRequest,
};
use crate::error::AppError;
use crate::services::UgcBillService;
use crate::AppState;

// ============================================================
// POST /api/v1/bills — 建立法案
// ============================================================

/// 建立法案（需認證）
pub async fn create_bill(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(request): Json<CreateUserBillRequest>,
) -> Result<Json<UserBill>, AppError> {
    let bill = UgcBillService::create_bill(&state.db, auth.user_id, request).await?;
    Ok(Json(bill))
}

// ============================================================
// POST /api/v1/bills/:bill_id/vote — 投票
// ============================================================

/// 投票（需認證，支援 toggle）
pub async fn vote_bill(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(bill_id): Path<Uuid>,
    Json(request): Json<VoteBillRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    UgcBillService::vote_bill(&state.db, bill_id, auth.user_id, &request.vote_type).await?;
    Ok(Json(serde_json::json!({ "success": true })))
}

// ============================================================
// GET /api/v1/bills — 列出法案
// ============================================================

/// 法案列表查詢參數
#[derive(Debug, Deserialize)]
pub struct ListBillsParams {
    /// 狀態篩選（預設 approved）
    pub status: Option<String>,
    /// 排序方式：newest / popular / controversial（預設 newest）
    pub sort_by: Option<String>,
    /// 每頁筆數（預設 20，最大 50）
    pub limit: Option<i64>,
    /// 偏移量（預設 0）
    pub offset: Option<i64>,
}

/// 列出法案（公開端點）
pub async fn list_bills(
    State(state): State<AppState>,
    Query(params): Query<ListBillsParams>,
) -> Result<Json<UserBillListResponse>, AppError> {
    let limit = params.limit.unwrap_or(20).min(50).max(1);
    let offset = params.offset.unwrap_or(0).max(0);

    let resp = UgcBillService::list_bills(
        &state.db,
        params.status.as_deref(),
        params.sort_by.as_deref(),
        limit,
        offset,
        None, // 公開端點不帶 viewer_id
    )
    .await?;

    Ok(Json(resp))
}

// ============================================================
// GET /api/v1/bills/:bill_id — 取得法案詳情
// ============================================================

/// 取得法案詳情（公開端點）
pub async fn get_bill(
    State(state): State<AppState>,
    Path(bill_id): Path<Uuid>,
) -> Result<Json<UserBillResponse>, AppError> {
    let resp = UgcBillService::get_bill(&state.db, bill_id, None).await?;
    Ok(Json(resp))
}

// ============================================================
// GET /api/v1/bills/mine — 取得自己的法案
// ============================================================

/// 個人法案查詢參數
#[derive(Debug, Deserialize)]
pub struct MyBillsParams {
    /// 每頁筆數（預設 20，最大 50）
    pub limit: Option<i64>,
    /// 偏移量（預設 0）
    pub offset: Option<i64>,
}

/// 取得自己的法案（需認證）
pub async fn get_my_bills(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<MyBillsParams>,
) -> Result<Json<UserBillListResponse>, AppError> {
    let limit = params.limit.unwrap_or(20).min(50).max(1);
    let offset = params.offset.unwrap_or(0).max(0);

    let resp =
        UgcBillService::get_my_bills(&state.db, auth.user_id, limit, offset).await?;
    Ok(Json(resp))
}
