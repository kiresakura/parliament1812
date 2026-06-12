//! 每週法案服務
//!
//! 負責每週法案的查詢、啟用、遊玩次數統計等業務邏輯

use chrono::{Datelike, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::weekly_bill::{BillHistoryResponse, CurrentBillResponse, WeeklyBill};
use crate::error::{AppError, AppResult};

/// 每週法案服務
pub struct WeeklyBillService;

impl WeeklyBillService {
    /// 取得當週法案
    ///
    /// 依據 ISO 週數查詢對應法案，並計算剩餘天數。
    /// 如果法案尚未啟用，會自動啟用。
    pub async fn get_current_bill(pool: &PgPool) -> AppResult<CurrentBillResponse> {
        let now = Utc::now();
        let iso_week = now.iso_week();
        let week_number = iso_week.week() as i32;
        let year = iso_week.year();

        // 查詢當週法案
        let bill = sqlx::query_as::<_, WeeklyBill>(
            r#"
            SELECT id, week_number, year, bill_name, bill_description, bill_type,
                   version_a, version_b, version_c, special_rules,
                   is_active, play_count, created_at
            FROM weekly_bills
            WHERE week_number = $1 AND year = $2
            "#,
        )
        .bind(week_number)
        .bind(year)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢當週法案失敗: {}", e)))?
        .ok_or_else(|| {
            AppError::NotFound(format!(
                "找不到 {} 年第 {} 週的法案",
                year, week_number
            ))
        })?;

        // 如果尚未啟用，自動啟用
        if !bill.is_active {
            Self::activate_weekly_bill(pool).await?;
        }

        // 計算距離本週日剩餘天數
        let current_weekday = now.weekday().num_days_from_monday(); // 0=Mon, 6=Sun
        let days_remaining = (6 - current_weekday) as i64; // 到週日的天數

        let week_label = format!("{} 第 {} 週", year, week_number);

        Ok(CurrentBillResponse {
            bill,
            week_label,
            days_remaining,
        })
    }

    /// 取得法案歷史
    ///
    /// 查詢所有過去的法案，按年份與週數降序排列
    pub async fn get_bill_history(
        pool: &PgPool,
        limit: i64,
        offset: i64,
    ) -> AppResult<BillHistoryResponse> {
        let bills = sqlx::query_as::<_, WeeklyBill>(
            r#"
            SELECT id, week_number, year, bill_name, bill_description, bill_type,
                   version_a, version_b, version_c, special_rules,
                   is_active, play_count, created_at
            FROM weekly_bills
            ORDER BY year DESC, week_number DESC
            LIMIT $1 OFFSET $2
            "#,
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢法案歷史失敗: {}", e)))?;

        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM weekly_bills")
            .fetch_one(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("計算法案總數失敗: {}", e)))?;

        Ok(BillHistoryResponse {
            bills,
            total: total.0,
        })
    }

    /// 增加遊玩次數
    pub async fn increment_play_count(pool: &PgPool, bill_id: Uuid) -> AppResult<()> {
        sqlx::query(
            r#"
            UPDATE weekly_bills
            SET play_count = play_count + 1
            WHERE id = $1
            "#,
        )
        .bind(bill_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新遊玩次數失敗: {}", e)))?;

        Ok(())
    }

    /// 取得特殊規則
    ///
    /// 遊戲初始化時使用，取得當週法案的特殊規則
    pub async fn get_special_rules(
        pool: &PgPool,
        week_number: i32,
        year: i32,
    ) -> AppResult<serde_json::Value> {
        let result: Option<(serde_json::Value,)> = sqlx::query_as(
            r#"
            SELECT special_rules
            FROM weekly_bills
            WHERE week_number = $1 AND year = $2
            "#,
        )
        .bind(week_number)
        .bind(year)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢特殊規則失敗: {}", e)))?;

        match result {
            Some((rules,)) => Ok(rules),
            None => Ok(serde_json::json!({})),
        }
    }

    /// 啟用當週法案
    ///
    /// 將當週法案設為 is_active = true，其餘全部設為 false。
    /// 返回被啟用的法案。
    pub async fn activate_weekly_bill(pool: &PgPool) -> AppResult<Option<WeeklyBill>> {
        let now = Utc::now();
        let iso_week = now.iso_week();
        let week_number = iso_week.week() as i32;
        let year = iso_week.year();

        // 先將所有法案停用
        sqlx::query("UPDATE weekly_bills SET is_active = false WHERE is_active = true")
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("停用法案失敗: {}", e)))?;

        // 啟用當週法案
        let bill = sqlx::query_as::<_, WeeklyBill>(
            r#"
            UPDATE weekly_bills
            SET is_active = true
            WHERE week_number = $1 AND year = $2
            RETURNING id, week_number, year, bill_name, bill_description, bill_type,
                      version_a, version_b, version_c, special_rules,
                      is_active, play_count, created_at
            "#,
        )
        .bind(week_number)
        .bind(year)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("啟用當週法案失敗: {}", e)))?;

        Ok(bill)
    }
}
