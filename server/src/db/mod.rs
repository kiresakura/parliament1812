//! 資料庫持久化層
//!
//! 提供 PostgreSQL 持久化操作，用於遊戲結束後的資料寫入、
//! 排行榜查詢、使用者擴展資料等。
//!
//! 與 `repository/` 模組的區別：
//! - `repository/` 處理基礎 CRUD（users, rooms, players）
//! - `db/` 處理擴展功能（遊戲持久化、排行榜、社交、交易）

pub mod codex;
pub mod friends;
pub mod games;
pub mod migrations;
pub mod oauth_links;
pub mod rankings;
pub mod users;

use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

/// 建立資料庫連接池
///
/// # Arguments
/// * `database_url` - PostgreSQL 連接 URL
/// * `max_connections` - 最大連接數
///
/// # Returns
/// PgPool 連接池
pub async fn create_pool(database_url: &str, max_connections: u32) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(max_connections)
        .connect(database_url)
        .await
}

/// 建立 lazy 連接池（不立即連接，適用於測試）
///
/// # Arguments
/// * `database_url` - PostgreSQL 連接 URL
///
/// # Returns
/// PgPool 連接池（延遲連接）
pub fn create_lazy_pool(database_url: &str) -> PgPool {
    sqlx::pool::PoolOptions::new()
        .max_connections(1)
        .connect_lazy(database_url)
        .expect("無法建立 lazy 連接池")
}
