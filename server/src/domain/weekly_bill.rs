//! 每週法案領域模型
//!
//! 定義每週法案輪替系統的核心資料結構

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 每週法案
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WeeklyBill {
    pub id: Uuid,
    pub week_number: i32,
    pub year: i32,
    pub bill_name: String,
    pub bill_description: Option<String>,
    pub bill_type: String,
    pub version_a: serde_json::Value,
    pub version_b: serde_json::Value,
    pub version_c: serde_json::Value,
    pub special_rules: serde_json::Value,
    pub is_active: bool,
    pub play_count: i32,
    pub created_at: DateTime<Utc>,
}

/// 當週法案回應（簡化版）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CurrentBillResponse {
    pub bill: WeeklyBill,
    /// 週標籤，如 "2026 第 12 週"
    pub week_label: String,
    /// 距離本週日剩餘天數
    pub days_remaining: i64,
}

/// 法案歷史回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BillHistoryResponse {
    pub bills: Vec<WeeklyBill>,
    pub total: i64,
}
