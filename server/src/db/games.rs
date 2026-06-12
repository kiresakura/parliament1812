//! 遊戲持久化資料庫操作
//!
//! 處理 games + game_players 的持久化：
//! - 遊戲開始時建立記錄
//! - 遊戲結束時寫入結果
//! - 歷史對局查詢

use chrono::{DateTime, Utc};
use serde_json::Value as JsonValue;
use sqlx::PgPool;
use uuid::Uuid;

/// games 表記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct GameRecord {
    pub id: Uuid,
    pub room_code: Option<String>,
    pub status: String,
    pub game_mode: String,
    pub round_count: Option<i32>,
    pub max_rounds: Option<i32>,
    pub created_at: Option<DateTime<Utc>>,
    pub finished_at: Option<DateTime<Utc>>,
    pub winner_id: Option<Uuid>,
    pub game_data: Option<JsonValue>,
}

/// game_players 表記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct GamePlayerRecord {
    pub game_id: Uuid,
    pub user_id: Uuid,
    pub character_type: Option<String>,
    pub final_reputation: Option<i32>,
    pub final_gold: Option<i32>,
    pub placement: Option<i32>,
    pub is_mvp: Option<bool>,
}

/// 遊戲資料庫操作
pub struct GameDb;

impl GameDb {
    /// 建立新遊戲記錄（遊戲開始時呼叫）
    pub async fn create_game(
        pool: &PgPool,
        room_code: &str,
        game_mode: &str,
        max_rounds: i32,
    ) -> Result<GameRecord, sqlx::Error> {
        sqlx::query_as::<_, GameRecord>(
            r#"
            INSERT INTO games (room_code, status, game_mode, max_rounds)
            VALUES ($1, 'playing', $2, $3)
            RETURNING id, room_code, status, game_mode, round_count, max_rounds,
                      created_at, finished_at, winner_id, game_data
            "#,
        )
        .bind(room_code)
        .bind(game_mode)
        .bind(max_rounds)
        .fetch_one(pool)
        .await
    }

    /// 更新遊戲狀態
    pub async fn update_status(
        pool: &PgPool,
        game_id: Uuid,
        status: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE games SET status = $2 WHERE id = $1
            "#,
        )
        .bind(game_id)
        .bind(status)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 完成遊戲（寫入最終資料）
    pub async fn finish_game(
        pool: &PgPool,
        game_id: Uuid,
        winner_id: Option<Uuid>,
        round_count: i32,
        game_data: Option<&JsonValue>,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE games
            SET status = 'finished',
                finished_at = NOW(),
                winner_id = $2,
                round_count = $3,
                game_data = $4
            WHERE id = $1
            "#,
        )
        .bind(game_id)
        .bind(winner_id)
        .bind(round_count)
        .bind(game_data)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 取消遊戲
    pub async fn cancel_game(pool: &PgPool, game_id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE games
            SET status = 'cancelled', finished_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(game_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 根據 ID 查詢遊戲
    pub async fn find_by_id(
        pool: &PgPool,
        game_id: Uuid,
    ) -> Result<Option<GameRecord>, sqlx::Error> {
        sqlx::query_as::<_, GameRecord>(
            r#"
            SELECT id, room_code, status, game_mode, round_count, max_rounds,
                   created_at, finished_at, winner_id, game_data
            FROM games
            WHERE id = $1
            "#,
        )
        .bind(game_id)
        .fetch_optional(pool)
        .await
    }

    /// 根據房間代碼查詢最新遊戲
    pub async fn find_by_room_code(
        pool: &PgPool,
        room_code: &str,
    ) -> Result<Option<GameRecord>, sqlx::Error> {
        sqlx::query_as::<_, GameRecord>(
            r#"
            SELECT id, room_code, status, game_mode, round_count, max_rounds,
                   created_at, finished_at, winner_id, game_data
            FROM games
            WHERE room_code = $1
            ORDER BY created_at DESC
            LIMIT 1
            "#,
        )
        .bind(room_code)
        .fetch_optional(pool)
        .await
    }

    /// 查詢使用者的歷史對局
    pub async fn find_user_games(
        pool: &PgPool,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<GameRecord>, sqlx::Error> {
        sqlx::query_as::<_, GameRecord>(
            r#"
            SELECT g.id, g.room_code, g.status, g.game_mode, g.round_count, g.max_rounds,
                   g.created_at, g.finished_at, g.winner_id, g.game_data
            FROM games g
            INNER JOIN game_players gp ON g.id = gp.game_id
            WHERE gp.user_id = $1 AND g.status = 'finished'
            ORDER BY g.finished_at DESC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
    }

    /// 新增遊戲玩家記錄
    pub async fn add_game_player(
        pool: &PgPool,
        game_id: Uuid,
        user_id: Uuid,
        character_type: &str,
    ) -> Result<GamePlayerRecord, sqlx::Error> {
        sqlx::query_as::<_, GamePlayerRecord>(
            r#"
            INSERT INTO game_players (game_id, user_id, character_type)
            VALUES ($1, $2, $3)
            RETURNING game_id, user_id, character_type, final_reputation, final_gold, placement, is_mvp
            "#,
        )
        .bind(game_id)
        .bind(user_id)
        .bind(character_type)
        .fetch_one(pool)
        .await
    }

    /// 更新遊戲玩家結果（遊戲結束時）
    pub async fn update_game_player_result(
        pool: &PgPool,
        game_id: Uuid,
        user_id: Uuid,
        final_reputation: i32,
        final_gold: i32,
        placement: i32,
        is_mvp: bool,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE game_players
            SET final_reputation = $3,
                final_gold = $4,
                placement = $5,
                is_mvp = $6
            WHERE game_id = $1 AND user_id = $2
            "#,
        )
        .bind(game_id)
        .bind(user_id)
        .bind(final_reputation)
        .bind(final_gold)
        .bind(placement)
        .bind(is_mvp)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 查詢遊戲的所有玩家記錄
    pub async fn find_game_players(
        pool: &PgPool,
        game_id: Uuid,
    ) -> Result<Vec<GamePlayerRecord>, sqlx::Error> {
        sqlx::query_as::<_, GamePlayerRecord>(
            r#"
            SELECT game_id, user_id, character_type, final_reputation, final_gold, placement, is_mvp
            FROM game_players
            WHERE game_id = $1
            ORDER BY placement ASC NULLS LAST
            "#,
        )
        .bind(game_id)
        .fetch_all(pool)
        .await
    }

    /// 批量寫入遊戲結果（事務）
    ///
    /// 在遊戲結束時一次性寫入：
    /// 1. 更新 games 表
    /// 2. 更新所有 game_players 結果
    /// 3. 更新使用者統計
    pub async fn persist_game_result(
        pool: &PgPool,
        game_id: Uuid,
        winner_id: Option<Uuid>,
        round_count: i32,
        game_data: Option<&JsonValue>,
        player_results: &[(Uuid, i32, i32, i32, bool)], // (user_id, reputation, gold, placement, is_mvp)
    ) -> Result<(), sqlx::Error> {
        let mut tx = pool.begin().await?;

        // 1. 更新 games
        sqlx::query(
            r#"
            UPDATE games
            SET status = 'finished',
                finished_at = NOW(),
                winner_id = $2,
                round_count = $3,
                game_data = $4
            WHERE id = $1
            "#,
        )
        .bind(game_id)
        .bind(winner_id)
        .bind(round_count)
        .bind(game_data)
        .execute(&mut *tx)
        .await?;

        // 2. 更新所有 game_players
        for (user_id, reputation, gold, placement, is_mvp) in player_results {
            sqlx::query(
                r#"
                UPDATE game_players
                SET final_reputation = $3,
                    final_gold = $4,
                    placement = $5,
                    is_mvp = $6
                WHERE game_id = $1 AND user_id = $2
                "#,
            )
            .bind(game_id)
            .bind(user_id)
            .bind(reputation)
            .bind(gold)
            .bind(placement)
            .bind(is_mvp)
            .execute(&mut *tx)
            .await?;

            // 3. 更新使用者統計
            let is_winner = winner_id == Some(*user_id);
            if is_winner {
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
                .execute(&mut *tx)
                .await?;
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
                .execute(&mut *tx)
                .await?;
            }
        }

        tx.commit().await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    // DB 測試需要實際連線，在沒有 DB 的環境中跳過
}
