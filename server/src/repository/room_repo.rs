//! 房間資料存取
//!
//! 提供房間相關的資料庫操作

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::RoomStatus;

/// 資料庫中的房間記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct RoomRecord {
    pub id: Uuid,
    pub code: String,
    pub host_id: Uuid,
    pub status: String,
    pub max_players: i32,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// 房間資料存取
pub struct RoomRepository {
    pool: PgPool,
}

impl RoomRepository {
    /// 建立新的 RoomRepository
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 建立新房間
    ///
    /// # Arguments
    /// * `code` - 房間代碼
    /// * `host_id` - 房主 ID
    ///
    /// # Returns
    /// 新建立的房間記錄
    pub async fn create(&self, code: &str, host_id: Uuid) -> Result<RoomRecord, sqlx::Error> {
        let record = sqlx::query_as::<_, RoomRecord>(
            r#"
            INSERT INTO rooms (code, host_id, status, max_players)
            VALUES ($1, $2, 'waiting', 4)
            RETURNING id, code, host_id, status::text, max_players, created_at, updated_at
            "#,
        )
        .bind(code)
        .bind(host_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據房間代碼查詢房間
    ///
    /// # Arguments
    /// * `code` - 房間代碼
    ///
    /// # Returns
    /// 房間記錄（如果存在）
    pub async fn find_by_code(&self, code: &str) -> Result<Option<RoomRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, RoomRecord>(
            r#"
            SELECT id, code, host_id, status::text, max_players, created_at, updated_at
            FROM rooms
            WHERE code = $1
            "#,
        )
        .bind(code)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據 ID 查詢房間
    ///
    /// # Arguments
    /// * `id` - 房間 ID
    ///
    /// # Returns
    /// 房間記錄（如果存在）
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<RoomRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, RoomRecord>(
            r#"
            SELECT id, code, host_id, status::text, max_players, created_at, updated_at
            FROM rooms
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 查詢等待中的房間
    ///
    /// # Returns
    /// 等待中的房間列表
    pub async fn find_waiting_rooms(&self) -> Result<Vec<RoomRecord>, sqlx::Error> {
        let records = sqlx::query_as::<_, RoomRecord>(
            r#"
            SELECT id, code, host_id, status::text, max_players, created_at, updated_at
            FROM rooms
            WHERE status = 'waiting'
            ORDER BY created_at DESC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 更新房間狀態
    ///
    /// # Arguments
    /// * `id` - 房間 ID
    /// * `status` - 新狀態
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_status(&self, id: Uuid, status: RoomStatus) -> Result<bool, sqlx::Error> {
        let status_str = match status {
            RoomStatus::Waiting => "waiting",
            RoomStatus::Playing => "playing",
            RoomStatus::Finished => "finished",
        };

        let result = sqlx::query(
            r#"
            UPDATE rooms
            SET status = $2::room_status, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(status_str)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新房主
    ///
    /// # Arguments
    /// * `id` - 房間 ID
    /// * `host_id` - 新房主 ID
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_host(&self, id: Uuid, host_id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE rooms
            SET host_id = $2, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(host_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 刪除房間
    ///
    /// # Arguments
    /// * `id` - 房間 ID
    ///
    /// # Returns
    /// 是否成功刪除
    pub async fn delete(&self, id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM rooms WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 檢查房間代碼是否已存在
    ///
    /// # Arguments
    /// * `code` - 房間代碼
    ///
    /// # Returns
    /// 是否存在
    pub async fn exists_by_code(&self, code: &str) -> Result<bool, sqlx::Error> {
        let result = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(SELECT 1 FROM rooms WHERE code = $1)
            "#,
        )
        .bind(code)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }
}

impl RoomRecord {
    /// 轉換為領域模型
    pub fn into_domain(self) -> crate::domain::Room {
        let status = match self.status.as_str() {
            "waiting" => RoomStatus::Waiting,
            "playing" => RoomStatus::Playing,
            "finished" => RoomStatus::Finished,
            _ => RoomStatus::Waiting,
        };

        crate::domain::Room {
            id: self.id,
            code: self.code,
            host_id: self.host_id,
            status,
            max_players: self.max_players,
            created_at: self.created_at.unwrap_or_else(Utc::now),
        }
    }
}
