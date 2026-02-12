//! 遊戲狀態快取
//!
//! 使用 Redis 快取遊戲狀態和連線資訊

use deadpool_redis::Pool as RedisPool;
use redis::AsyncCommands;
use uuid::Uuid;

use crate::error::AppError;
use crate::game::EngineState;

/// Redis Key 前綴
const KEY_GAME_STATE: &str = "game:state:";
const KEY_PLAYER_CONN: &str = "player:conn:";
const KEY_ROOM_CONNS: &str = "room:conns:";
const KEY_ROOM_CHANNEL: &str = "room:channel:";

/// 預設 TTL（秒）
const DEFAULT_GAME_STATE_TTL: u64 = 3600; // 1 小時
const DEFAULT_CONN_TTL: u64 = 1800; // 30 分鐘

/// 遊戲狀態快取
#[derive(Clone)]
pub struct GameCache {
    pool: RedisPool,
}

impl GameCache {
    /// 建立新的 GameCache
    pub fn new(pool: RedisPool) -> Self {
        Self { pool }
    }

    // ==================== 遊戲狀態快取 ====================

    /// 設定遊戲狀態
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `state` - 遊戲狀態
    /// * `ttl_secs` - 過期時間（秒）
    pub async fn set_game_state(
        &self,
        room_code: &str,
        state: &EngineState,
        ttl_secs: Option<u64>,
    ) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_GAME_STATE, room_code);
        let ttl = ttl_secs.unwrap_or(DEFAULT_GAME_STATE_TTL);

        // 序列化遊戲狀態
        let json = serde_json::to_string(state)
            .map_err(|e| AppError::InternalError(format!("序列化遊戲狀態失敗: {}", e)))?;

        // 設定值和過期時間
        conn.set_ex::<_, _, ()>(&key, &json, ttl)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SET 失敗: {}", e)))?;

        tracing::debug!(room_code = %room_code, ttl = ttl, "遊戲狀態已快取");
        Ok(())
    }

    /// 取得遊戲狀態
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 遊戲狀態（如果存在）
    pub async fn get_game_state(&self, room_code: &str) -> Result<Option<EngineState>, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_GAME_STATE, room_code);

        let json: Option<String> = conn
            .get(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis GET 失敗: {}", e)))?;

        match json {
            Some(json) => {
                let state: EngineState = serde_json::from_str(&json)
                    .map_err(|e| AppError::InternalError(format!("反序列化遊戲狀態失敗: {}", e)))?;
                Ok(Some(state))
            }
            None => Ok(None),
        }
    }

    /// 刪除遊戲狀態
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    pub async fn delete_game_state(&self, room_code: &str) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_GAME_STATE, room_code);

        conn.del::<_, ()>(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis DEL 失敗: {}", e)))?;

        tracing::debug!(room_code = %room_code, "遊戲狀態已從快取刪除");
        Ok(())
    }

    /// 更新遊戲狀態 TTL
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `ttl_secs` - 新的過期時間（秒）
    pub async fn refresh_game_state_ttl(
        &self,
        room_code: &str,
        ttl_secs: Option<u64>,
    ) -> Result<bool, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_GAME_STATE, room_code);
        let ttl = ttl_secs.unwrap_or(DEFAULT_GAME_STATE_TTL);

        let result: bool = conn
            .expire(&key, ttl as i64)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis EXPIRE 失敗: {}", e)))?;

        Ok(result)
    }

    // ==================== 玩家連線映射 ====================

    /// 設定玩家連線對應
    ///
    /// # Arguments
    /// * `player_id` - 玩家 ID
    /// * `conn_id` - 連線 ID
    pub async fn set_player_connection(
        &self,
        player_id: Uuid,
        conn_id: Uuid,
    ) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_PLAYER_CONN, player_id);

        conn.set_ex::<_, _, ()>(&key, conn_id.to_string(), DEFAULT_CONN_TTL)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SET 失敗: {}", e)))?;

        tracing::trace!(player_id = %player_id, conn_id = %conn_id, "玩家連線已記錄");
        Ok(())
    }

    /// 取得玩家連線
    ///
    /// # Arguments
    /// * `player_id` - 玩家 ID
    ///
    /// # Returns
    /// 連線 ID（如果存在）
    pub async fn get_player_connection(&self, player_id: Uuid) -> Result<Option<Uuid>, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_PLAYER_CONN, player_id);

        let conn_id: Option<String> = conn
            .get(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis GET 失敗: {}", e)))?;

        match conn_id {
            Some(id) => {
                let uuid = Uuid::parse_str(&id)
                    .map_err(|e| AppError::InternalError(format!("無效的連線 ID: {}", e)))?;
                Ok(Some(uuid))
            }
            None => Ok(None),
        }
    }

    /// 刪除玩家連線
    ///
    /// # Arguments
    /// * `player_id` - 玩家 ID
    pub async fn delete_player_connection(&self, player_id: Uuid) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_PLAYER_CONN, player_id);

        conn.del::<_, ()>(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis DEL 失敗: {}", e)))?;

        Ok(())
    }

    /// 刷新玩家連線 TTL
    pub async fn refresh_player_connection(&self, player_id: Uuid) -> Result<bool, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_PLAYER_CONN, player_id);

        let result: bool = conn
            .expire(&key, DEFAULT_CONN_TTL as i64)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis EXPIRE 失敗: {}", e)))?;

        Ok(result)
    }

    // ==================== 房間連線集合 ====================

    /// 新增連線到房間
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `conn_id` - 連線 ID
    pub async fn add_to_room_connections(
        &self,
        room_code: &str,
        conn_id: Uuid,
    ) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_ROOM_CONNS, room_code);

        // 使用 SADD 新增到集合
        conn.sadd::<_, _, ()>(&key, conn_id.to_string())
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SADD 失敗: {}", e)))?;

        // 設定過期時間
        conn.expire::<_, ()>(&key, DEFAULT_GAME_STATE_TTL as i64)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis EXPIRE 失敗: {}", e)))?;

        tracing::trace!(room_code = %room_code, conn_id = %conn_id, "連線已加入房間");
        Ok(())
    }

    /// 從房間移除連線
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `conn_id` - 連線 ID
    pub async fn remove_from_room_connections(
        &self,
        room_code: &str,
        conn_id: Uuid,
    ) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_ROOM_CONNS, room_code);

        // 使用 SREM 從集合移除
        conn.srem::<_, _, ()>(&key, conn_id.to_string())
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SREM 失敗: {}", e)))?;

        tracing::trace!(room_code = %room_code, conn_id = %conn_id, "連線已從房間移除");
        Ok(())
    }

    /// 取得房間所有連線
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 連線 ID 列表
    pub async fn get_room_connections(&self, room_code: &str) -> Result<Vec<Uuid>, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_ROOM_CONNS, room_code);

        // 使用 SMEMBERS 取得所有成員
        let members: Vec<String> = conn
            .smembers(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SMEMBERS 失敗: {}", e)))?;

        let mut uuids = Vec::with_capacity(members.len());
        for member in members {
            if let Ok(uuid) = Uuid::parse_str(&member) {
                uuids.push(uuid);
            }
        }

        Ok(uuids)
    }

    /// 取得房間連線數量
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 連線數量
    pub async fn get_room_connection_count(&self, room_code: &str) -> Result<usize, AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_ROOM_CONNS, room_code);

        let count: usize = conn
            .scard(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis SCARD 失敗: {}", e)))?;

        Ok(count)
    }

    /// 刪除房間所有連線記錄
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    pub async fn delete_room_connections(&self, room_code: &str) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}", KEY_ROOM_CONNS, room_code);

        conn.del::<_, ()>(&key)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis DEL 失敗: {}", e)))?;

        Ok(())
    }

    // ==================== Pub/Sub 功能 ====================

    /// 發布訊息到房間頻道
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    /// * `message` - 訊息內容（JSON 字串）
    pub async fn publish_to_room(&self, room_code: &str, message: &str) -> Result<(), AppError> {
        let mut conn = self.get_conn().await?;
        let channel = format!("{}{}", KEY_ROOM_CHANNEL, room_code);

        conn.publish::<_, _, ()>(&channel, message)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis PUBLISH 失敗: {}", e)))?;

        tracing::trace!(room_code = %room_code, "訊息已發布到房間頻道");
        Ok(())
    }

    /// 取得房間頻道名稱
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 頻道名稱
    pub fn get_room_channel(room_code: &str) -> String {
        format!("{}{}", KEY_ROOM_CHANNEL, room_code)
    }

    // ==================== 輔助方法 ====================

    /// 取得 Redis 連線
    async fn get_conn(&self) -> Result<deadpool_redis::Connection, AppError> {
        self.pool
            .get()
            .await
            .map_err(|e| AppError::InternalError(format!("無法取得 Redis 連線: {}", e)))
    }

    /// 清理房間相關的所有快取
    ///
    /// # Arguments
    /// * `room_code` - 房間代碼
    pub async fn cleanup_room(&self, room_code: &str) -> Result<(), AppError> {
        // 刪除遊戲狀態
        self.delete_game_state(room_code).await?;

        // 刪除房間連線記錄
        self.delete_room_connections(room_code).await?;

        tracing::debug!(room_code = %room_code, "房間快取已清理");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_formats() {
        assert_eq!(GameCache::get_room_channel("ABC123"), "room:channel:ABC123");
    }
}
