//! 好友系統資料庫操作
//!
//! 處理 friends 表的 CRUD：
//! - 發送 / 接受 / 拒絕好友請求
//! - 刪除好友、封鎖 / 解除封鎖
//! - 好友列表（雙向）、待處理請求
//! - 搜尋用戶

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

// ============================================================
// 資料結構
// ============================================================

/// 好友關係狀態
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FriendStatus {
    Pending,
    Accepted,
    Blocked,
}

impl FriendStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            FriendStatus::Pending => "pending",
            FriendStatus::Accepted => "accepted",
            FriendStatus::Blocked => "blocked",
        }
    }

    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "pending" => Some(FriendStatus::Pending),
            "accepted" => Some(FriendStatus::Accepted),
            "blocked" => Some(FriendStatus::Blocked),
            _ => None,
        }
    }
}

/// 好友資訊（含用戶資料 + 在線狀態）
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FriendInfo {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub elo_rating: Option<i32>,
    pub is_online: Option<bool>,
    pub last_seen_at: Option<DateTime<Utc>>,
    pub friend_since: Option<DateTime<Utc>>,
}

/// 好友請求
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FriendRequest {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub elo_rating: Option<i32>,
    pub requested_at: Option<DateTime<Utc>>,
}

/// 用戶搜尋結果
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserSummary {
    pub id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub elo_rating: Option<i32>,
    pub is_online: Option<bool>,
    /// 與搜尋者的好友關係（null = 非好友）
    pub friend_status: Option<String>,
}

/// 好友資料庫操作
pub struct FriendDb;

impl FriendDb {
    // ============================================================
    // 好友請求
    // ============================================================

    /// 發送好友請求
    ///
    /// 建立 pending 關係（from_user_id → to_user_id）。
    /// 如果對方已經發送過請求，直接建立雙向好友。
    pub async fn send_request(
        pool: &PgPool,
        from_user_id: Uuid,
        to_user_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        // 檢查是否已有任何方向的關係
        let existing = sqlx::query_scalar::<_, String>(
            r#"
            SELECT status FROM friends
            WHERE (user_id = $1 AND friend_id = $2)
               OR (user_id = $2 AND friend_id = $1)
            LIMIT 1
            "#,
        )
        .bind(from_user_id)
        .bind(to_user_id)
        .fetch_optional(pool)
        .await?;

        match existing.as_deref() {
            Some("accepted") => return Ok(false), // 已是好友
            Some("blocked") => return Ok(false),  // 被封鎖
            Some("pending") => {
                // 檢查是不是對方先發的請求 → 自動接受
                let reverse_pending = sqlx::query_scalar::<_, bool>(
                    r#"
                    SELECT EXISTS(
                        SELECT 1 FROM friends
                        WHERE user_id = $2 AND friend_id = $1 AND status = 'pending'
                    )
                    "#,
                )
                .bind(from_user_id)
                .bind(to_user_id)
                .fetch_one(pool)
                .await?;

                if reverse_pending {
                    // 對方已發送請求 → 直接接受
                    return Self::accept_request(pool, from_user_id, to_user_id).await;
                }
                return Ok(false); // 已發送過請求
            }
            _ => {} // 無關係，繼續
        }

        sqlx::query(
            r#"
            INSERT INTO friends (user_id, friend_id, status, created_at)
            VALUES ($1, $2, 'pending', NOW())
            ON CONFLICT (user_id, friend_id) DO NOTHING
            "#,
        )
        .bind(from_user_id)
        .bind(to_user_id)
        .execute(pool)
        .await?;

        Ok(true)
    }

    /// 接受好友請求
    ///
    /// 將 pending → accepted，並建立反向關係
    pub async fn accept_request(
        pool: &PgPool,
        user_id: Uuid,
        from_user_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        // 更新原始請求為 accepted
        let result = sqlx::query(
            r#"
            UPDATE friends SET status = 'accepted'
            WHERE user_id = $2 AND friend_id = $1 AND status = 'pending'
            "#,
        )
        .bind(user_id)
        .bind(from_user_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Ok(false); // 沒有待處理的請求
        }

        // 建立反向關係
        sqlx::query(
            r#"
            INSERT INTO friends (user_id, friend_id, status, created_at)
            VALUES ($1, $2, 'accepted', NOW())
            ON CONFLICT (user_id, friend_id)
            DO UPDATE SET status = 'accepted'
            "#,
        )
        .bind(user_id)
        .bind(from_user_id)
        .execute(pool)
        .await?;

        Ok(true)
    }

    /// 拒絕好友請求
    pub async fn reject_request(
        pool: &PgPool,
        user_id: Uuid,
        from_user_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM friends
            WHERE user_id = $2 AND friend_id = $1 AND status = 'pending'
            "#,
        )
        .bind(user_id)
        .bind(from_user_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // ============================================================
    // 好友管理
    // ============================================================

    /// 刪除好友（雙向）
    pub async fn remove_friend(
        pool: &PgPool,
        user_id: Uuid,
        friend_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM friends
            WHERE (user_id = $1 AND friend_id = $2 AND status = 'accepted')
               OR (user_id = $2 AND friend_id = $1 AND status = 'accepted')
            "#,
        )
        .bind(user_id)
        .bind(friend_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 封鎖用戶
    ///
    /// 刪除雙向好友關係，建立 blocked 記錄
    pub async fn block_user(
        pool: &PgPool,
        user_id: Uuid,
        target_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        // 刪除所有雙向關係
        sqlx::query(
            r#"
            DELETE FROM friends
            WHERE (user_id = $1 AND friend_id = $2)
               OR (user_id = $2 AND friend_id = $1)
            "#,
        )
        .bind(user_id)
        .bind(target_id)
        .execute(pool)
        .await?;

        // 建立封鎖記錄
        sqlx::query(
            r#"
            INSERT INTO friends (user_id, friend_id, status, created_at)
            VALUES ($1, $2, 'blocked', NOW())
            ON CONFLICT (user_id, friend_id)
            DO UPDATE SET status = 'blocked'
            "#,
        )
        .bind(user_id)
        .bind(target_id)
        .execute(pool)
        .await?;

        Ok(true)
    }

    /// 解除封鎖
    pub async fn unblock_user(
        pool: &PgPool,
        user_id: Uuid,
        target_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM friends
            WHERE user_id = $1 AND friend_id = $2 AND status = 'blocked'
            "#,
        )
        .bind(user_id)
        .bind(target_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // ============================================================
    // 查詢
    // ============================================================

    /// 取得好友列表（雙向查詢，含在線狀態）
    pub async fn get_friends_list(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<FriendInfo>, sqlx::Error> {
        sqlx::query_as::<_, FriendInfo>(
            r#"
            SELECT
                u.id AS user_id,
                u.username,
                u.display_name,
                u.avatar_url,
                u.elo_rating,
                u.is_online,
                u.last_seen_at,
                f.created_at AS friend_since
            FROM friends f
            JOIN users u ON u.id = CASE
                WHEN f.user_id = $1 THEN f.friend_id
                ELSE f.user_id
            END
            WHERE (f.user_id = $1 OR f.friend_id = $1)
              AND f.status = 'accepted'
            GROUP BY u.id, u.username, u.display_name, u.avatar_url,
                     u.elo_rating, u.is_online, u.last_seen_at, f.created_at
            ORDER BY u.is_online DESC NULLS LAST, u.username ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
    }

    /// 取得待處理的好友請求（別人發給我的）
    pub async fn get_pending_requests(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<FriendRequest>, sqlx::Error> {
        sqlx::query_as::<_, FriendRequest>(
            r#"
            SELECT
                u.id AS user_id,
                u.username,
                u.display_name,
                u.avatar_url,
                u.elo_rating,
                f.created_at AS requested_at
            FROM friends f
            JOIN users u ON u.id = f.user_id
            WHERE f.friend_id = $1 AND f.status = 'pending'
            ORDER BY f.created_at DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
    }

    /// 搜尋用戶（by username / display_name）
    pub async fn search_users(
        pool: &PgPool,
        query: &str,
        current_user_id: Uuid,
        limit: i64,
    ) -> Result<Vec<UserSummary>, sqlx::Error> {
        let pattern = format!("%{}%", query);
        sqlx::query_as::<_, UserSummary>(
            r#"
            SELECT
                u.id,
                u.username,
                u.display_name,
                u.avatar_url,
                u.elo_rating,
                u.is_online,
                f.status AS friend_status
            FROM users u
            LEFT JOIN friends f ON (
                (f.user_id = $2 AND f.friend_id = u.id)
                OR (f.user_id = u.id AND f.friend_id = $2)
            )
            WHERE u.id != $2
              AND (u.username ILIKE $1 OR u.display_name ILIKE $1)
              AND (u.is_banned IS NULL OR u.is_banned = FALSE)
            ORDER BY
                CASE WHEN u.username ILIKE $1 THEN 0 ELSE 1 END,
                u.username ASC
            LIMIT $3
            "#,
        )
        .bind(&pattern)
        .bind(current_user_id)
        .bind(limit)
        .fetch_all(pool)
        .await
    }

    // ============================================================
    // 在線狀態
    // ============================================================

    /// 設定用戶在線
    pub async fn set_online(pool: &PgPool, user_id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            UPDATE users SET is_online = TRUE, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await?;
        Ok(())
    }

    /// 設定用戶離線 + 更新 last_seen_at
    pub async fn set_offline(pool: &PgPool, user_id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            UPDATE users SET is_online = FALSE, last_seen_at = NOW(), updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await?;
        Ok(())
    }

    // ============================================================
    // 輔助查詢
    // ============================================================

    /// 檢查兩人是否為好友
    pub async fn are_friends(
        pool: &PgPool,
        user_id: Uuid,
        other_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM friends
                WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
                  AND status = 'accepted'
            )
            "#,
        )
        .bind(user_id)
        .bind(other_id)
        .fetch_one(pool)
        .await
    }

    /// 檢查是否已封鎖
    pub async fn is_blocked(
        pool: &PgPool,
        user_id: Uuid,
        target_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM friends
                WHERE user_id = $1 AND friend_id = $2 AND status = 'blocked'
            )
            "#,
        )
        .bind(user_id)
        .bind(target_id)
        .fetch_one(pool)
        .await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_friend_status_round_trip() {
        assert_eq!(
            FriendStatus::parse(FriendStatus::Pending.as_str()),
            Some(FriendStatus::Pending)
        );
        assert_eq!(
            FriendStatus::parse(FriendStatus::Accepted.as_str()),
            Some(FriendStatus::Accepted)
        );
        assert_eq!(
            FriendStatus::parse(FriendStatus::Blocked.as_str()),
            Some(FriendStatus::Blocked)
        );
        assert_eq!(FriendStatus::parse("unknown"), None);
    }
}
