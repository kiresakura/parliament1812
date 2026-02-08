//! 玩家資料存取
//!
//! 提供玩家相關的資料庫操作

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::CharacterType;

/// 資料庫中的玩家記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct PlayerRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub room_id: Uuid,
    pub name: String,
    pub character: Option<String>,
    pub reputation: i32,
    pub gold: i32,
    pub is_ready: bool,
    pub is_host: bool,
    pub created_at: Option<DateTime<Utc>>,
}

/// 玩家資料存取
pub struct PlayerRepository {
    pool: PgPool,
}

impl PlayerRepository {
    /// 建立新的 PlayerRepository
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 建立新玩家
    ///
    /// # Arguments
    /// * `user_id` - 使用者 ID
    /// * `room_id` - 房間 ID
    /// * `name` - 玩家名稱
    /// * `is_host` - 是否為房主
    ///
    /// # Returns
    /// 新建立的玩家記錄
    pub async fn create(
        &self,
        user_id: Uuid,
        room_id: Uuid,
        name: &str,
        is_host: bool,
    ) -> Result<PlayerRecord, sqlx::Error> {
        let record = sqlx::query_as::<_, PlayerRecord>(
            r#"
            INSERT INTO players (user_id, room_id, name, is_host)
            VALUES ($1, $2, $3, $4)
            RETURNING id, user_id, room_id, name, character::text, reputation, gold, is_ready, is_host, created_at
            "#,
        )
        .bind(user_id)
        .bind(room_id)
        .bind(name)
        .bind(is_host)
        .fetch_one(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據 ID 查詢玩家
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    ///
    /// # Returns
    /// 玩家記錄（如果存在）
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<PlayerRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, PlayerRecord>(
            r#"
            SELECT id, user_id, room_id, name, character::text, reputation, gold, is_ready, is_host, created_at
            FROM players
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據使用者 ID 查詢玩家（當前活動的）
    ///
    /// # Arguments
    /// * `user_id` - 使用者 ID
    ///
    /// # Returns
    /// 玩家記錄（如果存在）
    pub async fn find_by_user_id(
        &self,
        user_id: Uuid,
    ) -> Result<Option<PlayerRecord>, sqlx::Error> {
        let record = sqlx::query_as::<_, PlayerRecord>(
            r#"
            SELECT p.id, p.user_id, p.room_id, p.name, p.character::text, p.reputation, p.gold, p.is_ready, p.is_host, p.created_at
            FROM players p
            JOIN rooms r ON p.room_id = r.id
            WHERE p.user_id = $1 AND r.status != 'finished'
            "#,
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    /// 根據房間 ID 查詢所有玩家
    ///
    /// # Arguments
    /// * `room_id` - 房間 ID
    ///
    /// # Returns
    /// 玩家列表
    pub async fn find_by_room(&self, room_id: Uuid) -> Result<Vec<PlayerRecord>, sqlx::Error> {
        let records = sqlx::query_as::<_, PlayerRecord>(
            r#"
            SELECT id, user_id, room_id, name, character::text, reputation, gold, is_ready, is_host, created_at
            FROM players
            WHERE room_id = $1
            ORDER BY created_at ASC
            "#,
        )
        .bind(room_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 更新玩家準備狀態
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    /// * `is_ready` - 是否準備
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_ready(&self, id: Uuid, is_ready: bool) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE players
            SET is_ready = $2
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(is_ready)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新玩家角色
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    /// * `character` - 角色類型
    /// * `reputation` - 初始聲望
    /// * `gold` - 初始金幣
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_character(
        &self,
        id: Uuid,
        character: CharacterType,
        reputation: i32,
        gold: i32,
    ) -> Result<bool, sqlx::Error> {
        let character_str = match character {
            CharacterType::Thomas => "thomas",
            CharacterType::Richard => "richard",
            CharacterType::Edward => "edward",
            CharacterType::George => "george",
        };

        let result = sqlx::query(
            r#"
            UPDATE players
            SET character = $2::character_type, reputation = $3, gold = $4
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(character_str)
        .bind(reputation)
        .bind(gold)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新玩家為房主
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    /// * `is_host` - 是否為房主
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_host(&self, id: Uuid, is_host: bool) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE players
            SET is_host = $2
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(is_host)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 更新玩家遊戲狀態
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    /// * `reputation` - 聲望
    /// * `gold` - 金幣
    ///
    /// # Returns
    /// 是否成功更新
    pub async fn update_game_state(
        &self,
        id: Uuid,
        reputation: i32,
        gold: i32,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE players
            SET reputation = $2, gold = $3
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(reputation)
        .bind(gold)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 刪除玩家
    ///
    /// # Arguments
    /// * `id` - 玩家 ID
    ///
    /// # Returns
    /// 是否成功刪除
    pub async fn delete(&self, id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM players WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 刪除房間內所有玩家
    ///
    /// # Arguments
    /// * `room_id` - 房間 ID
    ///
    /// # Returns
    /// 刪除的玩家數量
    pub async fn delete_by_room(&self, room_id: Uuid) -> Result<u64, sqlx::Error> {
        let result = sqlx::query(
            r#"
            DELETE FROM players WHERE room_id = $1
            "#,
        )
        .bind(room_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected())
    }

    /// 計算房間內的玩家數量
    ///
    /// # Arguments
    /// * `room_id` - 房間 ID
    ///
    /// # Returns
    /// 玩家數量
    pub async fn count_by_room(&self, room_id: Uuid) -> Result<i64, sqlx::Error> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM players WHERE room_id = $1
            "#,
        )
        .bind(room_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(count)
    }

    /// 檢查使用者是否已在房間中
    ///
    /// # Arguments
    /// * `user_id` - 使用者 ID
    ///
    /// # Returns
    /// 是否在房間中
    pub async fn is_user_in_active_room(&self, user_id: Uuid) -> Result<bool, sqlx::Error> {
        let result = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM players p
                JOIN rooms r ON p.room_id = r.id
                WHERE p.user_id = $1 AND r.status != 'finished'
            )
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    /// 檢查角色是否已在房間中被選擇
    ///
    /// # Arguments
    /// * `room_id` - 房間 ID
    /// * `character` - 角色類型
    /// * `exclude_player_id` - 排除的玩家 ID
    ///
    /// # Returns
    /// 是否已被選擇
    pub async fn is_character_taken(
        &self,
        room_id: Uuid,
        character: CharacterType,
        exclude_player_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let character_str = match character {
            CharacterType::Thomas => "thomas",
            CharacterType::Richard => "richard",
            CharacterType::Edward => "edward",
            CharacterType::George => "george",
        };

        let result = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM players
                WHERE room_id = $1 AND character = $2::character_type AND id != $3
            )
            "#,
        )
        .bind(room_id)
        .bind(character_str)
        .bind(exclude_player_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }
}

impl PlayerRecord {
    /// 轉換為領域模型
    pub fn into_domain(self) -> crate::domain::Player {
        let character = self.character.as_deref().map(|c| match c {
            "thomas" => CharacterType::Thomas,
            "richard" => CharacterType::Richard,
            "edward" => CharacterType::Edward,
            "george" => CharacterType::George,
            _ => CharacterType::Thomas,
        });

        crate::domain::Player {
            id: self.id,
            user_id: self.user_id,
            room_id: self.room_id,
            name: self.name,
            character,
            reputation: self.reputation,
            gold: self.gold,
            is_ready: self.is_ready,
            is_host: self.is_host,
            is_spectator: false, // 從資料庫載入的都是正常玩家，不是觀戰者
        }
    }
}
