//! 資料庫遷移
//!
//! 提供啟動時自動執行 migration 的功能。
//! 實際的 migration SQL 檔案在 `server/migrations/` 目錄下，
//! 由 `sqlx::migrate!()` 巨集在編譯時嵌入。
//!
//! main.rs 中已有自動遷移邏輯：
//! ```rust,ignore
//! sqlx::migrate!("./migrations").run(&state.db).await?;
//! ```
//!
//! 此模組提供額外的工具函式。

use sqlx::PgPool;

/// 執行所有待處理的 migration
///
/// 使用 sqlx 內建的 migration 系統，自動追蹤已執行的 migration。
/// Migration 檔案按數字順序執行（001_, 002_, ...）。
///
/// # Arguments
/// * `pool` - 資料庫連接池
///
/// # Returns
/// 成功或錯誤
pub async fn run_migrations(pool: &PgPool) -> Result<(), sqlx::migrate::MigrateError> {
    tracing::info!("開始執行資料庫遷移...");

    sqlx::migrate!("./migrations").run(pool).await?;

    tracing::info!("資料庫遷移完成");
    Ok(())
}

/// 檢查是否有待處理的 migration
///
/// # Arguments
/// * `pool` - 資料庫連接池
///
/// # Returns
/// 是否有待處理的 migration
pub async fn has_pending_migrations(pool: &PgPool) -> Result<bool, sqlx::Error> {
    // 檢查 _sqlx_migrations 表是否存在
    let table_exists = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = '_sqlx_migrations'
        )
        "#,
    )
    .fetch_one(pool)
    .await?;

    if !table_exists {
        return Ok(true); // 表不存在代表還沒跑過任何 migration
    }

    // 比較已執行的 migration 數量
    let executed_count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM _sqlx_migrations WHERE success = true
        "#,
    )
    .fetch_one(pool)
    .await?;

    // 我們有 5 個 migration 檔案
    Ok(executed_count < 5)
}
