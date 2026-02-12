//! 內購 API 處理器
//!
//! POST /api/v1/iap/verify/apple   - Apple 收據驗證
//! POST /api/v1/iap/verify/google  - Google 收據驗證
//! GET  /api/v1/iap/balance        - 寶石餘額
//! GET  /api/v1/iap/history        - 購買記錄
//! POST /api/v1/iap/spend          - 消費寶石

use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};

use crate::auth::middleware::AuthUser;
use crate::error::AppError;
use crate::services::iap_service::{
    AppleVerifyRequest, GoogleVerifyRequest, IapService, VerifyResponse,
};
use crate::AppState;

// ============================================================
// 額外請求 / 回應
// ============================================================

/// 寶石餘額回應
#[derive(Debug, Serialize)]
pub struct GemBalanceResponse {
    pub gems: i64,
    pub has_ai_unlimited: bool,
}

/// 消費寶石請求
#[derive(Debug, Deserialize)]
pub struct SpendGemsRequest {
    pub amount: i64,
    pub reason: String,
}

/// 消費寶石回應
#[derive(Debug, Serialize)]
pub struct SpendGemsResponse {
    pub success: bool,
    pub remaining_gems: i64,
}

/// 購買記錄回應
#[derive(Debug, Serialize)]
pub struct PurchaseHistoryResponse {
    pub transactions: Vec<TransactionEntry>,
}

#[derive(Debug, Serialize)]
pub struct TransactionEntry {
    pub id: String,
    pub platform: String,
    pub product_id: String,
    pub transaction_id: String,
    pub purchase_time: String,
    pub verified: bool,
}

// ============================================================
// Handlers
// ============================================================

/// POST /api/v1/iap/verify/apple
pub async fn verify_apple(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<AppleVerifyRequest>,
) -> Result<Json<VerifyResponse>, AppError> {
    let result =
        IapService::verify_apple_transaction(&state.db, auth_user.user_id, &request).await?;
    Ok(Json(result))
}

/// POST /api/v1/iap/verify/google
pub async fn verify_google(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<GoogleVerifyRequest>,
) -> Result<Json<VerifyResponse>, AppError> {
    let result = IapService::verify_google_purchase(&state.db, auth_user.user_id, &request).await?;
    Ok(Json(result))
}

/// GET /api/v1/iap/balance
pub async fn get_balance(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<GemBalanceResponse>, AppError> {
    let gems = IapService::get_gem_balance(&state.db, auth_user.user_id).await?;
    let has_ai_unlimited = IapService::has_ai_unlimited(&state.db, auth_user.user_id).await?;

    Ok(Json(GemBalanceResponse {
        gems,
        has_ai_unlimited,
    }))
}

/// POST /api/v1/iap/spend
pub async fn spend_gems(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(request): Json<SpendGemsRequest>,
) -> Result<Json<SpendGemsResponse>, AppError> {
    if request.amount <= 0 {
        return Err(AppError::BadRequest("消費數量必須大於 0".to_string()));
    }

    let remaining = IapService::spend_gems(
        &state.db,
        auth_user.user_id,
        request.amount,
        &request.reason,
    )
    .await?;

    Ok(Json(SpendGemsResponse {
        success: true,
        remaining_gems: remaining,
    }))
}

/// GET /api/v1/iap/history
pub async fn get_history(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<PurchaseHistoryResponse>, AppError> {
    let records = IapService::get_purchase_history(&state.db, auth_user.user_id).await?;

    let transactions: Vec<TransactionEntry> = records
        .into_iter()
        .map(|r| TransactionEntry {
            id: r.id.to_string(),
            platform: r.platform,
            product_id: r.product_id,
            transaction_id: r.transaction_id,
            purchase_time: r.purchase_time.to_rfc3339(),
            verified: r.verified,
        })
        .collect();

    Ok(Json(PurchaseHistoryResponse { transactions }))
}
