//! 使用者資料存取
//!
//! 提供使用者相關的資料庫操作

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

/// 資料庫中的使用者記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct UserRecord {
    pub id: Uuid,
    pub username: String,
    pub password_hash: String,
    pub created_at: Option<DateTime<Utc>>,
}

/// 使用者資料存取
pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    /// 建立新的 UserRepository
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 建立新使用者
    ///
    /// # Arguments
    /// * `username` - 使用者名稱
    /// * `password_hash` - 密碼雜湊
    ///
    /// # Returns
    /// 新建立的使用者記錄
    pub async fn create(
        &self,
        username: &str,
        password_hash: &str,
    ) -> Result<UserRecord, sqlx::Error> {
        let record = sqlx::query_as::<_, UserRecord>(
            r#"
            INSERT INTO users (username, password_hash)
            VALUES ($1, $2)
            RETURNING id, username, password_hash, created_at
            "#,
        )
        .bind(username)
        .bind(password_hash)
        .fetch_one(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據 ID 查詢使用者
    ///
    /// # Arguments
    /// * `id` - 使用者 ID
    ///
    /// # Returns
    /// 使用者記錄（如果存在）
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<UserRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, username, password_hash, created_at
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據使用者名稱查詢使用者
    ///
    /// # Arguments
    /// * `username` - 使用者名稱
    ///
    /// # Returns
    /// 使用者記錄（如果存在）
    pub async fn find_by_username(
        &self,
        username: &str,
    ) -> Result<Option<UserRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, username, password_hash, created_at
            FROM users
            WHERE username = $1
            "#,
        )
        .bind(username)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 檢查使用者名稱是否已存在
    ///
    /// # Arguments
    /// * `username` - 使用者名稱
    ///
    /// # Returns
    /// 是否存在
    pub async fn exists_by_username(&self, username: &str) -> Result<bool, sqlx::Error> {
        let result = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)
            "#,
        )
        .bind(username)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    /// 刪除使用者
    ///
    /// # Arguments
    /// * `id` - 使用者 ID
    ///
    /// # Returns
    /// 是否成功刪除
    pub async fn delete(&self, id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM users WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }
}

impl UserRecord {
    /// 轉換為領域模型
    pub fn into_domain(self) -> crate::domain::User {
        crate::domain::User {
            id: self.id,
            username: self.username,
            password_hash: self.password_hash,
            created_at: self.created_at.unwrap_or_else(Utc::now),
        }
    }
}
