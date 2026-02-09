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

/// 完整使用者記錄（含擴展欄位）
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct FullUserRecord {
    pub id: Uuid,
    pub username: String,
    pub password_hash: Option<String>,
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub oauth_provider: Option<String>,
    pub oauth_id: Option<String>,
    pub avatar_url: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub last_login_at: Option<DateTime<Utc>>,
    pub is_banned: Option<bool>,
    pub elo_rating: Option<i32>,
    pub total_games: Option<i32>,
    pub total_wins: Option<i32>,
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

    /// 建立使用者（含 email）
    pub async fn create_with_email(
        &self,
        username: &str,
        email: &str,
        password_hash: &str,
    ) -> Result<FullUserRecord, sqlx::Error> {
        sqlx::query_as::<_, FullUserRecord>(
            r#"
            INSERT INTO users (username, email, password_hash, display_name)
            VALUES ($1, $2, $3, $1)
            RETURNING id, username, password_hash, display_name, email,
                      oauth_provider, oauth_id, avatar_url,
                      created_at, updated_at, last_login_at,
                      is_banned, elo_rating, total_games, total_wins
            "#,
        )
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .fetch_one(&self.pool)
        .await
    }

    /// 建立 OAuth 使用者
    pub async fn create_oauth_user(
        &self,
        username: &str,
        email: Option<&str>,
        oauth_provider: &str,
        oauth_id: &str,
        display_name: Option<&str>,
        avatar_url: Option<&str>,
    ) -> Result<FullUserRecord, sqlx::Error> {
        sqlx::query_as::<_, FullUserRecord>(
            r#"
            INSERT INTO users (username, email, oauth_provider, oauth_id, display_name, avatar_url)
            VALUES ($1, $2, $3, $4, COALESCE($5, $1), $6)
            RETURNING id, username, password_hash, display_name, email,
                      oauth_provider, oauth_id, avatar_url,
                      created_at, updated_at, last_login_at,
                      is_banned, elo_rating, total_games, total_wins
            "#,
        )
        .bind(username)
        .bind(email)
        .bind(oauth_provider)
        .bind(oauth_id)
        .bind(display_name)
        .bind(avatar_url)
        .fetch_one(&self.pool)
        .await
    }

    /// 根據 ID 查詢使用者
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<UserRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, username, COALESCE(password_hash, '') as password_hash, created_at
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據 ID 查詢完整使用者資料
    pub async fn find_full_by_id(&self, id: Uuid) -> Result<Option<FullUserRecord>, sqlx::Error> {
        sqlx::query_as::<_, FullUserRecord>(
            r#"
            SELECT id, username, password_hash, display_name, email,
                   oauth_provider, oauth_id, avatar_url,
                   created_at, updated_at, last_login_at,
                   is_banned, elo_rating, total_games, total_wins
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
    }

    /// 根據使用者名稱查詢使用者
    pub async fn find_by_username(
        &self,
        username: &str,
    ) -> Result<Option<UserRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, username, COALESCE(password_hash, '') as password_hash, created_at
            FROM users
            WHERE username = $1
            "#,
        )
        .bind(username)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據 email 查詢完整使用者資料
    pub async fn find_by_email(&self, email: &str) -> Result<Option<FullUserRecord>, sqlx::Error> {
        sqlx::query_as::<_, FullUserRecord>(
            r#"
            SELECT id, username, password_hash, display_name, email,
                   oauth_provider, oauth_id, avatar_url,
                   created_at, updated_at, last_login_at,
                   is_banned, elo_rating, total_games, total_wins
            FROM users
            WHERE email = $1
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await
    }

    /// 根據 OAuth 資訊查詢使用者
    pub async fn find_by_oauth(
        &self,
        provider: &str,
        oauth_id: &str,
    ) -> Result<Option<FullUserRecord>, sqlx::Error> {
        sqlx::query_as::<_, FullUserRecord>(
            r#"
            SELECT id, username, password_hash, display_name, email,
                   oauth_provider, oauth_id, avatar_url,
                   created_at, updated_at, last_login_at,
                   is_banned, elo_rating, total_games, total_wins
            FROM users
            WHERE oauth_provider = $1 AND oauth_id = $2
            "#,
        )
        .bind(provider)
        .bind(oauth_id)
        .fetch_optional(&self.pool)
        .await
    }

    /// 檢查使用者名稱是否已存在
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

    /// 檢查 email 是否已存在
    pub async fn exists_by_email(&self, email: &str) -> Result<bool, sqlx::Error> {
        let result = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)
            "#,
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    /// 更新密碼
    pub async fn update_password(
        &self,
        user_id: Uuid,
        password_hash: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE users SET password_hash = $2, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .bind(password_hash)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新最後登入時間
    pub async fn update_last_login(&self, user_id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            UPDATE users SET last_login_at = NOW(), updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// 刪除使用者（GDPR）
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

    // ============================================================
    // 密碼重設 Token
    // ============================================================

    /// 建立密碼重設 token
    pub async fn create_password_reset_token(
        &self,
        user_id: Uuid,
        token: &str,
        expires_at: DateTime<Utc>,
    ) -> Result<(), sqlx::Error> {
        // 先讓該使用者的舊 token 失效
        sqlx::query(
            r#"
            UPDATE password_reset_tokens SET used = TRUE
            WHERE user_id = $1 AND used = FALSE
            "#,
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        sqlx::query(
            r#"
            INSERT INTO password_reset_tokens (user_id, token, expires_at)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(user_id)
        .bind(token)
        .bind(expires_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// 驗證密碼重設 token 並回傳 user_id
    pub async fn validate_password_reset_token(
        &self,
        token: &str,
    ) -> Result<Option<Uuid>, sqlx::Error> {
        let result = sqlx::query_scalar::<_, Uuid>(
            r#"
            SELECT user_id FROM password_reset_tokens
            WHERE token = $1 AND used = FALSE AND expires_at > NOW()
            "#,
        )
        .bind(token)
        .fetch_optional(&self.pool)
        .await?;

        Ok(result)
    }

    /// 標記密碼重設 token 為已使用
    pub async fn mark_reset_token_used(&self, token: &str) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            UPDATE password_reset_tokens SET used = TRUE
            WHERE token = $1
            "#,
        )
        .bind(token)
        .execute(&self.pool)
        .await?;

        Ok(())
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

impl FullUserRecord {
    /// 轉換為 UserResponse
    pub fn into_response(self) -> crate::domain::UserResponse {
        crate::domain::UserResponse {
            id: self.id,
            username: self.username,
            created_at: self.created_at.unwrap_or_else(Utc::now),
            display_name: self.display_name,
            email: self.email,
            avatar_url: self.avatar_url,
            elo_rating: self.elo_rating,
        }
    }
}
