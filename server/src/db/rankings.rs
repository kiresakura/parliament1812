//! 排行榜資料庫操作
//!
//! 處理 rankings 表的查詢和更新

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

/// 排行榜記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct RankingRecord {
    pub user_id: Uuid,
    pub season: i32,
    pub elo_rating: Option<i32>,
    pub rank_position: Option<i32>,
    pub games_played: Option<i32>,
    pub wins: Option<i32>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// 排行榜查詢結果（含使用者名稱）
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct LeaderboardEntry {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub elo_rating: Option<i32>,
    pub games_played: Option<i32>,
    pub wins: Option<i32>,
    pub rank_position: Option<i32>,
}

/// 排行榜資料庫操作
pub struct RankingDb;

impl RankingDb {
    /// 取得當前賽季排行榜（前 N 名）
    pub async fn get_leaderboard(
        pool: &PgPool,
        season: i32,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<LeaderboardEntry>, sqlx::Error> {
        sqlx::query_as::<_, LeaderboardEntry>(
            r#"
            SELECT r.user_id, u.username, u.display_name,
                   r.elo_rating, r.games_played, r.wins, r.rank_position
            FROM rankings r
            INNER JOIN users u ON r.user_id = u.id
            WHERE r.season = $1
            ORDER BY r.elo_rating DESC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(season)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
    }

    /// 取得使用者在指定賽季的排名
    pub async fn get_user_ranking(
        pool: &PgPool,
        user_id: Uuid,
        season: i32,
    ) -> Result<Option<RankingRecord>, sqlx::Error> {
        sqlx::query_as::<_, RankingRecord>(
            r#"
            SELECT user_id, season, elo_rating, rank_position, games_played, wins, updated_at
            FROM rankings
            WHERE user_id = $1 AND season = $2
            "#,
        )
        .bind(user_id)
        .bind(season)
        .fetch_optional(pool)
        .await
    }

    /// 更新或插入使用者排名（upsert）
    pub async fn upsert_ranking(
        pool: &PgPool,
        user_id: Uuid,
        season: i32,
        elo_rating: i32,
        is_win: bool,
    ) -> Result<RankingRecord, sqlx::Error> {
        let wins_increment = if is_win { 1 } else { 0 };

        sqlx::query_as::<_, RankingRecord>(
            r#"
            INSERT INTO rankings (user_id, season, elo_rating, games_played, wins)
            VALUES ($1, $2, $3, 1, $4)
            ON CONFLICT (user_id, season)
            DO UPDATE SET
                elo_rating = $3,
                games_played = rankings.games_played + 1,
                wins = rankings.wins + $4,
                updated_at = NOW()
            RETURNING user_id, season, elo_rating, rank_position, games_played, wins, updated_at
            "#,
        )
        .bind(user_id)
        .bind(season)
        .bind(elo_rating)
        .bind(wins_increment)
        .fetch_one(pool)
        .await
    }

    /// 重新計算排名位置（定期執行）
    pub async fn recalculate_positions(
        pool: &PgPool,
        season: i32,
    ) -> Result<u64, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE rankings r
            SET rank_position = sub.pos
            FROM (
                SELECT user_id,
                       ROW_NUMBER() OVER (ORDER BY elo_rating DESC) as pos
                FROM rankings
                WHERE season = $1
            ) sub
            WHERE r.user_id = sub.user_id AND r.season = $1
            "#,
        )
        .bind(season)
        .execute(pool)
        .await?;

        Ok(result.rows_affected())
    }

    /// 取得使用者在排行榜中的位置（不依賴 rank_position 欄位）
    pub async fn get_user_position(
        pool: &PgPool,
        user_id: Uuid,
        season: i32,
    ) -> Result<Option<i64>, sqlx::Error> {
        let result = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT position FROM (
                SELECT user_id,
                       ROW_NUMBER() OVER (ORDER BY elo_rating DESC) as position
                FROM rankings
                WHERE season = $1
            ) ranked
            WHERE user_id = $2
            "#,
        )
        .bind(season)
        .bind(user_id)
        .fetch_optional(pool)
        .await?;

        Ok(result)
    }

    /// 取得排行榜總人數
    pub async fn get_total_ranked(
        pool: &PgPool,
        season: i32,
    ) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM rankings WHERE season = $1
            "#,
        )
        .bind(season)
        .fetch_one(pool)
        .await
    }
}

#[cfg(test)]
mod tests {
    // DB 測試需要實際連線，在沒有 DB 的環境中跳過
}
