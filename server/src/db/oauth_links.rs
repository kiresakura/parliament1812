//! OAuth 連結資料庫操作
//!
//! 處理 user_oauth_links 表的 CRUD：
//! - 查詢使用者的 OAuth 連結
//! - 建立/刪除 OAuth 連結

use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::PgPool;
use uuid::Uuid;

/// OAuth 連結記錄
#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct OAuthLink {
    pub id: Uuid,
    pub user_id: Uuid,
    pub provider: String,
    pub provider_user_id: String,
    pub email: Option<String>,
    pub linked_at: DateTime<Utc>,
}

/// OAuth 連結資料庫操作
pub struct OAuthLinkDb;

impl OAuthLinkDb {
    /// 根據 provider 和 provider_user_id 查詢 OAuth 連結
    pub async fn find_by_provider(
        pool: &PgPool,
        provider: &str,
        provider_user_id: &str,
    ) -> Result<Option<OAuthLink>, sqlx::Error> {
        sqlx::query_as::<_, OAuthLink>(
            r#"
            SELECT id, user_id, provider, provider_user_id, email, linked_at
            FROM user_oauth_links
            WHERE provider = $1 AND provider_user_id = $2
            "#,
        )
        .bind(provider)
        .bind(provider_user_id)
        .fetch_optional(pool)
        .await
    }

    /// 查詢使用者的所有 OAuth 連結
    pub async fn find_by_user(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<OAuthLink>, sqlx::Error> {
        sqlx::query_as::<_, OAuthLink>(
            r#"
            SELECT id, user_id, provider, provider_user_id, email, linked_at
            FROM user_oauth_links
            WHERE user_id = $1
            ORDER BY linked_at ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
    }

    /// 建立 OAuth 連結
    pub async fn create_link(
        pool: &PgPool,
        user_id: Uuid,
        provider: &str,
        provider_user_id: &str,
        email: Option<&str>,
    ) -> Result<OAuthLink, sqlx::Error> {
        sqlx::query_as::<_, OAuthLink>(
            r#"
            INSERT INTO user_oauth_links (user_id, provider, provider_user_id, email)
            VALUES ($1, $2, $3, $4)
            RETURNING id, user_id, provider, provider_user_id, email, linked_at
            "#,
        )
        .bind(user_id)
        .bind(provider)
        .bind(provider_user_id)
        .bind(email)
        .fetch_one(pool)
        .await
    }

    /// 刪除 OAuth 連結
    pub async fn delete_link(
        pool: &PgPool,
        user_id: Uuid,
        provider: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM user_oauth_links
            WHERE user_id = $1 AND provider = $2
            "#,
        )
        .bind(user_id)
        .bind(provider)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 計算使用者的 OAuth 連結數量
    pub async fn count_by_user(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM user_oauth_links
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
    }
}
