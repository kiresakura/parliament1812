//! 跨局玩家關係服務
//!
//! 根據遊戲事件更新玩家之間的關係（信任分數、盟友、宿敵等）

use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::relationship::{
    relationship_type_from_trust, PlayerRelationship, RelationshipListResponse,
    RelationshipResponse,
};
use crate::error::{AppError, AppResult};
use crate::services::EventService;

/// 玩家關係服務
///
/// 負責跨局關係的計算與查詢
pub struct RelationshipService;

impl RelationshipService {
    /// 根據一場遊戲的事件更新所有參與玩家之間的關係
    ///
    /// 流程：
    /// 1. 取得該局所有事件
    /// 2. 找出所有參與玩家
    /// 3. 對每對玩家計算互動並更新關係
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn update_relationships_from_game(
        pool: &PgPool,
        game_id: Uuid,
    ) -> AppResult<()> {
        // 取得該局所有事件
        let events = EventService::get_game_events(pool, game_id).await?;

        if events.is_empty() {
            return Ok(());
        }

        // 收集所有參與玩家的 ID
        let mut player_ids: Vec<Uuid> = Vec::new();
        for event in &events {
            if let Some(actor_id) = event.actor_id {
                if !player_ids.contains(&actor_id) {
                    player_ids.push(actor_id);
                }
            }
            if let Some(target_id) = event.target_id {
                if !player_ids.contains(&target_id) {
                    player_ids.push(target_id);
                }
            }
        }

        // 對每對玩家更新關係
        for i in 0..player_ids.len() {
            for j in (i + 1)..player_ids.len() {
                // 確保 player_a < player_b（UUID 排序）
                let (pa, pb) = Self::ordered_pair(player_ids[i], player_ids[j]);

                // 計算這對玩家之間的互動
                let mut alliance_delta: i32 = 0;
                let mut betrayal_delta: i32 = 0;
                let mut challenge_delta: i32 = 0;
                let mut had_interaction = false;

                for event in &events {
                    let actor = event.actor_id;
                    let target = event.target_id;

                    // 檢查事件是否涉及這對玩家
                    let involves_pair = match (actor, target) {
                        (Some(a), Some(t)) => {
                            (a == player_ids[i] && t == player_ids[j])
                                || (a == player_ids[j] && t == player_ids[i])
                        }
                        _ => false,
                    };

                    if !involves_pair {
                        continue;
                    }

                    had_interaction = true;

                    match event.event_type.as_str() {
                        "alliance_formed" => alliance_delta += 1,
                        "alliance_betrayed" => betrayal_delta += 1,
                        "challenge_success" => challenge_delta += 1,
                        _ => {}
                    }
                }

                // 計算信任分數變化
                let trust_change = if had_interaction {
                    (alliance_delta as f64 * 10.0)
                        - (betrayal_delta as f64 * 15.0)
                        - (challenge_delta as f64 * 3.0)
                } else {
                    // 無互動：微幅提升信任
                    1.0
                };

                // UPSERT 關係記錄
                Self::upsert_relationship(
                    pool,
                    pa,
                    pb,
                    alliance_delta,
                    betrayal_delta,
                    challenge_delta,
                    trust_change,
                    game_id,
                )
                .await?;
            }
        }

        Ok(())
    }

    /// 插入或更新玩家關係記錄
    ///
    /// 使用 PostgreSQL 的 ON CONFLICT 實現 UPSERT
    async fn upsert_relationship(
        pool: &PgPool,
        player_a: Uuid,
        player_b: Uuid,
        alliance_delta: i32,
        betrayal_delta: i32,
        challenge_delta: i32,
        trust_change: f64,
        game_id: Uuid,
    ) -> AppResult<()> {
        // 先嘗試取得現有記錄以計算新的 trust_score
        let existing = sqlx::query_as::<_, PlayerRelationship>(
            r#"
            SELECT id, player_a, player_b, alliance_count, betrayal_count,
                   challenge_count, games_together, trust_score, relationship_type,
                   last_game_id, updated_at
            FROM player_relationships
            WHERE player_a = $1 AND player_b = $2
            "#,
        )
        .bind(player_a)
        .bind(player_b)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢玩家關係失敗: {}", e)))?;

        match existing {
            Some(rel) => {
                // 更新現有記錄
                let new_trust = (rel.trust_score + trust_change).clamp(0.0, 100.0);
                let new_type = relationship_type_from_trust(new_trust);

                sqlx::query(
                    r#"
                    UPDATE player_relationships
                    SET alliance_count = alliance_count + $3,
                        betrayal_count = betrayal_count + $4,
                        challenge_count = challenge_count + $5,
                        games_together = games_together + 1,
                        trust_score = $6,
                        relationship_type = $7,
                        last_game_id = $8,
                        updated_at = NOW()
                    WHERE player_a = $1 AND player_b = $2
                    "#,
                )
                .bind(player_a)
                .bind(player_b)
                .bind(alliance_delta)
                .bind(betrayal_delta)
                .bind(challenge_delta)
                .bind(new_trust)
                .bind(new_type)
                .bind(game_id)
                .execute(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("更新玩家關係失敗: {}", e)))?;
            }
            None => {
                // 插入新記錄
                let new_trust = (50.0_f64 + trust_change).clamp(0.0, 100.0);
                let new_type = relationship_type_from_trust(new_trust);

                sqlx::query(
                    r#"
                    INSERT INTO player_relationships
                        (player_a, player_b, alliance_count, betrayal_count,
                         challenge_count, games_together, trust_score,
                         relationship_type, last_game_id)
                    VALUES ($1, $2, $3, $4, $5, 1, $6, $7, $8)
                    "#,
                )
                .bind(player_a)
                .bind(player_b)
                .bind(alliance_delta)
                .bind(betrayal_delta)
                .bind(challenge_delta)
                .bind(new_trust)
                .bind(new_type)
                .bind(game_id)
                .execute(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("建立玩家關係失敗: {}", e)))?;
            }
        }

        Ok(())
    }

    /// 查詢玩家的所有關係
    ///
    /// JOIN users 表取得對方的名字和 ELO
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `user_id` - 查詢者的使用者 ID
    pub async fn get_relationships(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<RelationshipListResponse> {
        // 查詢所有涉及該玩家的關係，並 JOIN users 取得對方資訊
        let rows = sqlx::query_as::<_, RelationshipWithUser>(
            r#"
            SELECT r.id, r.player_a, r.player_b, r.alliance_count, r.betrayal_count,
                   r.challenge_count, r.games_together, r.trust_score, r.relationship_type,
                   r.last_game_id, r.updated_at,
                   u.id AS other_id, u.display_name AS other_name,
                   COALESCE(u.elo_rating, 1000) AS other_elo
            FROM player_relationships r
            JOIN users u ON u.id = CASE
                WHEN r.player_a = $1 THEN r.player_b
                ELSE r.player_a
            END
            WHERE r.player_a = $1 OR r.player_b = $1
            ORDER BY r.trust_score DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢玩家關係列表失敗: {}", e)))?;

        let total = rows.len() as i64;
        let relationships = rows
            .into_iter()
            .map(|row| row.into_response())
            .collect();

        Ok(RelationshipListResponse {
            relationships,
            total,
        })
    }

    /// 查詢與特定玩家的關係
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `user_id` - 查詢者的使用者 ID
    /// * `other_id` - 對方的使用者 ID
    pub async fn get_relationship_with(
        pool: &PgPool,
        user_id: Uuid,
        other_id: Uuid,
    ) -> AppResult<RelationshipResponse> {
        let (pa, pb) = Self::ordered_pair(user_id, other_id);

        let row = sqlx::query_as::<_, RelationshipWithUser>(
            r#"
            SELECT r.id, r.player_a, r.player_b, r.alliance_count, r.betrayal_count,
                   r.challenge_count, r.games_together, r.trust_score, r.relationship_type,
                   r.last_game_id, r.updated_at,
                   u.id AS other_id, u.display_name AS other_name,
                   COALESCE(u.elo_rating, 1000) AS other_elo
            FROM player_relationships r
            JOIN users u ON u.id = $3
            WHERE r.player_a = $1 AND r.player_b = $2
            "#,
        )
        .bind(pa)
        .bind(pb)
        .bind(other_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢特定玩家關係失敗: {}", e)))?;

        match row {
            Some(r) => Ok(r.into_response()),
            None => Err(AppError::NotFound(format!(
                "與玩家 {} 尚無關係記錄",
                other_id
            ))),
        }
    }

    /// 查詢宿敵列表（nemesis / rival）
    ///
    /// 按信任分數升序排列（最不信任的排最前）
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `user_id` - 查詢者的使用者 ID
    pub async fn get_nemeses(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<RelationshipListResponse> {
        let rows = sqlx::query_as::<_, RelationshipWithUser>(
            r#"
            SELECT r.id, r.player_a, r.player_b, r.alliance_count, r.betrayal_count,
                   r.challenge_count, r.games_together, r.trust_score, r.relationship_type,
                   r.last_game_id, r.updated_at,
                   u.id AS other_id, u.display_name AS other_name,
                   COALESCE(u.elo_rating, 1000) AS other_elo
            FROM player_relationships r
            JOIN users u ON u.id = CASE
                WHEN r.player_a = $1 THEN r.player_b
                ELSE r.player_a
            END
            WHERE (r.player_a = $1 OR r.player_b = $1)
              AND r.relationship_type IN ('nemesis', 'rival')
            ORDER BY r.trust_score ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢宿敵列表失敗: {}", e)))?;

        let total = rows.len() as i64;
        let relationships = rows
            .into_iter()
            .map(|row| row.into_response())
            .collect();

        Ok(RelationshipListResponse {
            relationships,
            total,
        })
    }

    /// 查詢盟友列表（sworn_ally / trusted）
    ///
    /// 按信任分數降序排列（最信任的排最前）
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `user_id` - 查詢者的使用者 ID
    pub async fn get_allies(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<RelationshipListResponse> {
        let rows = sqlx::query_as::<_, RelationshipWithUser>(
            r#"
            SELECT r.id, r.player_a, r.player_b, r.alliance_count, r.betrayal_count,
                   r.challenge_count, r.games_together, r.trust_score, r.relationship_type,
                   r.last_game_id, r.updated_at,
                   u.id AS other_id, u.display_name AS other_name,
                   COALESCE(u.elo_rating, 1000) AS other_elo
            FROM player_relationships r
            JOIN users u ON u.id = CASE
                WHEN r.player_a = $1 THEN r.player_b
                ELSE r.player_a
            END
            WHERE (r.player_a = $1 OR r.player_b = $1)
              AND r.relationship_type IN ('sworn_ally', 'trusted')
            ORDER BY r.trust_score DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢盟友列表失敗: {}", e)))?;

        let total = rows.len() as i64;
        let relationships = rows
            .into_iter()
            .map(|row| row.into_response())
            .collect();

        Ok(RelationshipListResponse {
            relationships,
            total,
        })
    }

    /// 排序兩個 UUID，確保 player_a < player_b
    fn ordered_pair(a: Uuid, b: Uuid) -> (Uuid, Uuid) {
        if a < b {
            (a, b)
        } else {
            (b, a)
        }
    }
}

/// 內部用的查詢結果結構（關係 + 對方資訊）
#[derive(Debug, sqlx::FromRow)]
struct RelationshipWithUser {
    // 關係欄位
    id: Uuid,
    player_a: Uuid,
    player_b: Uuid,
    alliance_count: i32,
    betrayal_count: i32,
    challenge_count: i32,
    games_together: i32,
    trust_score: f64,
    relationship_type: String,
    last_game_id: Option<Uuid>,
    updated_at: chrono::DateTime<chrono::Utc>,
    // 對方玩家資訊
    other_id: Uuid,
    other_name: String,
    other_elo: i32,
}

impl RelationshipWithUser {
    /// 轉換為 API 回應格式
    fn into_response(self) -> RelationshipResponse {
        RelationshipResponse {
            relationship: PlayerRelationship {
                id: self.id,
                player_a: self.player_a,
                player_b: self.player_b,
                alliance_count: self.alliance_count,
                betrayal_count: self.betrayal_count,
                challenge_count: self.challenge_count,
                games_together: self.games_together,
                trust_score: self.trust_score,
                relationship_type: self.relationship_type,
                last_game_id: self.last_game_id,
                updated_at: self.updated_at,
            },
            other_player_id: self.other_id,
            other_player_name: self.other_name,
            other_player_elo: self.other_elo,
        }
    }
}
