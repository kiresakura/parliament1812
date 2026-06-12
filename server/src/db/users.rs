//! 使用者擴展資料庫操作
//!
//! 處理 users 表擴展欄位的 CRUD：
//! - 更新 ELO 評分、遊戲統計
//! - OAuth 使用者管理
//! - 封禁管理

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

/// 擴展使用者記錄（包含所有欄位）
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct ExtendedUserRecord {
    pub id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub password_hash: Option<String>,
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

/// 使用者擴展資料庫操作
pub struct UserDb;

impl UserDb {
    /// 根據 ID 取得擴展使用者資料
    pub async fn find_extended_by_id(
        pool: &PgPool,
        id: Uuid,
    ) -> Result<Option<ExtendedUserRecord>, sqlx::Error> {
        sqlx::query_as::<_, ExtendedUserRecord>(
            r#"
            SELECT id, username, display_name, email, password_hash,
                   oauth_provider, oauth_id, avatar_url,
                   created_at, updated_at, last_login_at,
                   is_banned, elo_rating, total_games, total_wins
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(pool)
        .await
    }

    /// 更新使用者 ELO 評分
    pub async fn update_elo(
        pool: &PgPool,
        user_id: Uuid,
        new_elo: i32,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE users
            SET elo_rating = $2, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .bind(new_elo)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 增加遊戲統計（total_games + 1，若勝利則 total_wins + 1）
    pub async fn increment_game_stats(
        pool: &PgPool,
        user_id: Uuid,
        is_win: bool,
    ) -> Result<bool, sqlx::Error> {
        let result = if is_win {
            sqlx::query(
                r#"
                UPDATE users
                SET total_games = COALESCE(total_games, 0) + 1,
                    total_wins = COALESCE(total_wins, 0) + 1,
                    updated_at = NOW()
                WHERE id = $1
                "#,
            )
            .bind(user_id)
            .execute(pool)
            .await?
        } else {
            sqlx::query(
                r#"
                UPDATE users
                SET total_games = COALESCE(total_games, 0) + 1,
                    updated_at = NOW()
                WHERE id = $1
                "#,
            )
            .bind(user_id)
            .execute(pool)
            .await?
        };

        Ok(result.rows_affected() > 0)
    }

    /// 更新最後登入時間
    pub async fn update_last_login(pool: &PgPool, user_id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE users
            SET last_login_at = NOW(), updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新顯示名稱
    pub async fn update_display_name(
        pool: &PgPool,
        user_id: Uuid,
        display_name: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE users
            SET display_name = $2, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .bind(display_name)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 設定封禁狀態
    pub async fn set_banned(
        pool: &PgPool,
        user_id: Uuid,
        is_banned: bool,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE users
            SET is_banned = $2, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .bind(is_banned)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 根據 OAuth 資訊查詢使用者
    pub async fn find_by_oauth(
        pool: &PgPool,
        provider: &str,
        oauth_id: &str,
    ) -> Result<Option<ExtendedUserRecord>, sqlx::Error> {
        sqlx::query_as::<_, ExtendedUserRecord>(
            r#"
            SELECT id, username, display_name, email, password_hash,
                   oauth_provider, oauth_id, avatar_url,
                   created_at, updated_at, last_login_at,
                   is_banned, elo_rating, total_games, total_wins
            FROM users
            WHERE oauth_provider = $1 AND oauth_id = $2
            "#,
        )
        .bind(provider)
        .bind(oauth_id)
        .fetch_optional(pool)
        .await
    }

    /// 建立 OAuth 使用者
    pub async fn create_oauth_user(
        pool: &PgPool,
        username: &str,
        display_name: &str,
        email: Option<&str>,
        oauth_provider: &str,
        oauth_id: &str,
        avatar_url: Option<&str>,
    ) -> Result<ExtendedUserRecord, sqlx::Error> {
        sqlx::query_as::<_, ExtendedUserRecord>(
            r#"
            INSERT INTO users (username, display_name, email, oauth_provider, oauth_id, avatar_url)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, username, display_name, email, password_hash,
                      oauth_provider, oauth_id, avatar_url,
                      created_at, updated_at, last_login_at,
                      is_banned, elo_rating, total_games, total_wins
            "#,
        )
        .bind(username)
        .bind(display_name)
        .bind(email)
        .bind(oauth_provider)
        .bind(oauth_id)
        .bind(avatar_url)
        .fetch_one(pool)
        .await
    }
}

#[cfg(test)]
mod tests {
    // DB 測試需要實際連線，使用 feature flag 或 mock
    // 在沒有 DB 的環境中跳過
}
