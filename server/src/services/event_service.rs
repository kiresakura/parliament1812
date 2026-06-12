//! 事件收集服務
//!
//! 提供遊戲事件的寫入、查詢和戲劇性指數計算功能

use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::event::{CreateEventLog, DramaScore, GameEventLog};
use crate::error::{AppError, AppResult};

/// 事件收集服務
///
/// 負責遊戲事件日誌的持久化和分析
pub struct EventService;

impl EventService {
    /// 寫入單一事件日誌
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `event` - 事件建立請求
    pub async fn log_event(pool: &PgPool, event: &CreateEventLog) -> AppResult<()> {
        sqlx::query(
            r#"
            INSERT INTO game_event_logs
                (game_id, event_type, actor_id, target_id, card_type, metadata, reputation_change, round_number, phase)
            VALUES
                ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            "#,
        )
        .bind(event.game_id)
        .bind(&event.event_type)
        .bind(event.actor_id)
        .bind(event.target_id)
        .bind(&event.card_type)
        .bind(&event.metadata)
        .bind(event.reputation_change)
        .bind(event.round_number)
        .bind(&event.phase)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("寫入事件日誌失敗: {}", e)))?;

        Ok(())
    }

    /// 批次寫入事件日誌（使用 transaction）
    ///
    /// 將多筆事件在同一個交易中寫入，確保原子性
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `events` - 事件建立請求列表
    pub async fn log_events_batch(pool: &PgPool, events: &[CreateEventLog]) -> AppResult<()> {
        if events.is_empty() {
            return Ok(());
        }

        let mut tx = pool
            .begin()
            .await
            .map_err(|e| AppError::DatabaseError(format!("開啟交易失敗: {}", e)))?;

        for event in events {
            sqlx::query(
                r#"
                INSERT INTO game_event_logs
                    (game_id, event_type, actor_id, target_id, card_type, metadata, reputation_change, round_number, phase)
                VALUES
                    ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                "#,
            )
            .bind(event.game_id)
            .bind(&event.event_type)
            .bind(event.actor_id)
            .bind(event.target_id)
            .bind(&event.card_type)
            .bind(&event.metadata)
            .bind(event.reputation_change)
            .bind(event.round_number)
            .bind(&event.phase)
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("批次寫入事件日誌失敗: {}", e)))?;
        }

        tx.commit()
            .await
            .map_err(|e| AppError::DatabaseError(format!("提交交易失敗: {}", e)))?;

        Ok(())
    }

    /// 查詢特定遊戲的所有事件
    ///
    /// 依建立時間排序回傳
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn get_game_events(
        pool: &PgPool,
        game_id: Uuid,
    ) -> AppResult<Vec<GameEventLog>> {
        let events = sqlx::query_as::<_, GameEventLog>(
            r#"
            SELECT id, game_id, event_type, actor_id, target_id, card_type,
                   metadata, reputation_change, round_number, phase, created_at
            FROM game_event_logs
            WHERE game_id = $1
            ORDER BY created_at ASC
            "#,
        )
        .bind(game_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢遊戲事件失敗: {}", e)))?;

        Ok(events)
    }

    /// 查詢特定玩家在特定遊戲中的事件
    ///
    /// 包含該玩家作為發起者或目標的所有事件
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    /// * `player_id` - 玩家 ID
    pub async fn get_player_events(
        pool: &PgPool,
        game_id: Uuid,
        player_id: Uuid,
    ) -> AppResult<Vec<GameEventLog>> {
        let events = sqlx::query_as::<_, GameEventLog>(
            r#"
            SELECT id, game_id, event_type, actor_id, target_id, card_type,
                   metadata, reputation_change, round_number, phase, created_at
            FROM game_event_logs
            WHERE game_id = $1 AND (actor_id = $2 OR target_id = $2)
            ORDER BY created_at ASC
            "#,
        )
        .bind(game_id)
        .bind(player_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢玩家事件失敗: {}", e)))?;

        Ok(events)
    }

    /// 計算戲劇性指數
    ///
    /// 根據遊戲事件計算一場遊戲的戲劇性分數。
    /// 公式：drama_score = Σ(event_weight × recency_factor × surprise_factor)
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn calculate_drama_score(
        pool: &PgPool,
        game_id: Uuid,
    ) -> AppResult<DramaScore> {
        // 取得該遊戲的所有事件
        let events = Self::get_game_events(pool, game_id).await?;

        if events.is_empty() {
            return Ok(DramaScore {
                game_id,
                score: 0.0,
                top_events: Vec::new(),
                betrayal_count: 0,
                expose_count: 0,
            });
        }

        // 計算最大回合數（用於 recency_factor）
        let total_rounds = events
            .iter()
            .map(|e| e.round_number)
            .max()
            .unwrap_or(1)
            .max(1);

        // 統計背叛和爆料次數
        let betrayal_count = events
            .iter()
            .filter(|e| e.event_type == "alliance_betrayed")
            .count() as i32;

        let expose_count = events
            .iter()
            .filter(|e| e.event_type == "expose")
            .count() as i32;

        // 計算每個事件的加權分數
        let mut scored_events: Vec<(f64, &GameEventLog)> = events
            .iter()
            .map(|event| {
                let event_weight = Self::get_event_weight(&event.event_type);
                let recency_factor =
                    1.0 + (event.round_number as f64 / total_rounds as f64);
                let surprise_factor = Self::get_surprise_factor(&event.metadata);

                let score = event_weight * recency_factor * surprise_factor;
                (score, event)
            })
            .collect();

        // 計算總分
        let total_score: f64 = scored_events.iter().map(|(s, _)| s).sum();

        // 取得最精彩的前 5 個事件
        scored_events.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));
        let top_events: Vec<GameEventLog> = scored_events
            .iter()
            .take(5)
            .map(|(_, event)| (*event).clone())
            .collect();

        Ok(DramaScore {
            game_id,
            score: total_score,
            top_events,
            betrayal_count,
            expose_count,
        })
    }

    /// 取得事件類型的權重
    ///
    /// # Arguments
    /// * `event_type` - 事件類型字串
    fn get_event_weight(event_type: &str) -> f64 {
        match event_type {
            "expose" => 5.0,
            "alliance_betrayed" => 4.5,
            "challenge_success" => 3.0,
            "challenge_blocked" => 2.5,
            "alliance_formed" => 2.0,
            "vote_cast" => 1.0,
            "speech" => 1.0,
            "card_played" => 1.5,
            "skill_used" => 2.0,
            "political_death" => 4.0,
            _ => 1.0,
        }
    }

    /// 計算驚喜係數
    ///
    /// 如果 metadata 中 was_ally 為 true，驚喜係數為 1.5，否則為 1.0
    ///
    /// # Arguments
    /// * `metadata` - 事件的元資料 JSON
    fn get_surprise_factor(metadata: &serde_json::Value) -> f64 {
        if let Some(was_ally) = metadata.get("was_ally") {
            if was_ally.as_bool().unwrap_or(false) {
                return 1.5;
            }
        }
        1.0
    }
}
