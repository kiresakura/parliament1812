//! WebSocket Hub
//!
//! 管理所有 WebSocket 連線和房間廣播
//! 支援 Redis Pub/Sub 跨實例通訊

use deadpool_redis::Pool as RedisPool;
use futures::StreamExt;
use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use tokio::sync::{broadcast, mpsc, RwLock};
use uuid::Uuid;

use super::messages::ServerMessage;
use crate::cache::GameCache;

/// 連線句柄
#[derive(Debug, Clone)]
pub struct ConnectionHandle {
    /// 連線 ID
    pub id: Uuid,
    /// 使用者 ID
    pub user_id: Uuid,
    /// 玩家 ID（加入房間後設定）
    pub player_id: Option<Uuid>,
    /// 房間代碼（加入房間後設定）
    pub room_code: Option<String>,
    /// 訊息發送器
    pub sender: mpsc::UnboundedSender<ServerMessage>,
}

impl ConnectionHandle {
    /// 建立新的連線句柄
    pub fn new(id: Uuid, user_id: Uuid, sender: mpsc::UnboundedSender<ServerMessage>) -> Self {
        Self {
            id,
            user_id,
            player_id: None,
            room_code: None,
            sender,
        }
    }

    /// 發送訊息
    pub fn send(&self, message: ServerMessage) -> bool {
        self.sender.send(message).is_ok()
    }
}

/// WebSocket Hub
///
/// 管理所有活動的 WebSocket 連線
/// 支援 Redis Pub/Sub 跨實例廣播
pub struct WebSocketHub {
    /// 所有連線（以連線 ID 為鍵）
    connections: RwLock<HashMap<Uuid, ConnectionHandle>>,
    /// 房間連線映射（房間代碼 -> 連線 ID 集合）
    rooms: RwLock<HashMap<String, HashSet<Uuid>>>,
    /// 房間序列號（房間代碼 -> 序列號）
    room_sequences: RwLock<HashMap<String, u64>>,
    /// 斷線玩家保留（玩家 ID -> 斷線時間戳）
    disconnected_players: RwLock<HashMap<Uuid, i64>>,
    /// 關閉信號發送器
    shutdown_tx: broadcast::Sender<()>,
    /// Redis 連接池（可選，用於跨實例通訊）
    redis_pool: RwLock<Option<RedisPool>>,
    /// 訂閱中的房間頻道
    subscribed_rooms: RwLock<HashSet<String>>,
}

impl WebSocketHub {
    /// 建立新的 WebSocket Hub
    pub fn new() -> Arc<Self> {
        let (shutdown_tx, _) = broadcast::channel(1);

        Arc::new(Self {
            connections: RwLock::new(HashMap::new()),
            rooms: RwLock::new(HashMap::new()),
            room_sequences: RwLock::new(HashMap::new()),
            disconnected_players: RwLock::new(HashMap::new()),
            shutdown_tx,
            redis_pool: RwLock::new(None),
            subscribed_rooms: RwLock::new(HashSet::new()),
        })
    }

    /// 建立帶有 Redis 支援的 WebSocket Hub
    pub fn with_redis(redis_pool: RedisPool) -> Arc<Self> {
        let (shutdown_tx, _) = broadcast::channel(1);

        Arc::new(Self {
            connections: RwLock::new(HashMap::new()),
            rooms: RwLock::new(HashMap::new()),
            room_sequences: RwLock::new(HashMap::new()),
            disconnected_players: RwLock::new(HashMap::new()),
            shutdown_tx,
            redis_pool: RwLock::new(Some(redis_pool)),
            subscribed_rooms: RwLock::new(HashSet::new()),
        })
    }

    /// 設定 Redis 連接池
    pub async fn set_redis_pool(&self, pool: RedisPool) {
        let mut redis = self.redis_pool.write().await;
        *redis = Some(pool);
        tracing::info!("WebSocket Hub Redis 連接池已設定");
    }

    /// 取得關閉信號接收器
    pub fn subscribe_shutdown(&self) -> broadcast::Receiver<()> {
        self.shutdown_tx.subscribe()
    }

    /// 發送關閉信號
    pub fn shutdown(&self) {
        let _ = self.shutdown_tx.send(());
    }

    /// 註冊新連線
    ///
    /// 返回連線 ID
    pub async fn register(
        &self,
        user_id: Uuid,
        sender: mpsc::UnboundedSender<ServerMessage>,
    ) -> Uuid {
        let conn_id = Uuid::new_v4();
        let handle = ConnectionHandle::new(conn_id, user_id, sender);

        let mut connections = self.connections.write().await;
        connections.insert(conn_id, handle);

        tracing::debug!(
            conn_id = %conn_id,
            user_id = %user_id,
            total_connections = connections.len(),
            "WebSocket 連線已註冊"
        );

        conn_id
    }

    /// 取消註冊連線
    pub async fn unregister(&self, conn_id: Uuid) {
        // 先離開房間
        self.leave_room(conn_id).await;

        // 移除連線
        let mut connections = self.connections.write().await;
        if let Some(handle) = connections.remove(&conn_id) {
            tracing::debug!(
                conn_id = %conn_id,
                user_id = %handle.user_id,
                total_connections = connections.len(),
                "WebSocket 連線已取消註冊"
            );
        }
    }

    /// 將連線加入房間
    pub async fn join_room(&self, conn_id: Uuid, room_code: String, player_id: Uuid) {
        // 更新連線資訊
        {
            let mut connections = self.connections.write().await;
            if let Some(handle) = connections.get_mut(&conn_id) {
                // 如果已在其他房間，先離開
                if let Some(old_room) = handle.room_code.take() {
                    let mut rooms = self.rooms.write().await;
                    if let Some(room_conns) = rooms.get_mut(&old_room) {
                        room_conns.remove(&conn_id);
                        if room_conns.is_empty() {
                            rooms.remove(&old_room);
                        }
                    }
                }

                handle.room_code = Some(room_code.clone());
                handle.player_id = Some(player_id);
            }
        }

        // 將連線加入房間
        {
            let mut rooms = self.rooms.write().await;
            rooms
                .entry(room_code.clone())
                .or_insert_with(HashSet::new)
                .insert(conn_id);
        }

        tracing::debug!(
            conn_id = %conn_id,
            room_code = %room_code,
            player_id = %player_id,
            "連線已加入房間"
        );
    }

    /// 將連線從房間移除
    ///
    /// 返回 (房間代碼, 玩家 ID)（如果有的話）
    pub async fn leave_room(&self, conn_id: Uuid) -> Option<(String, Uuid)> {
        let (room_code, player_id) = {
            let mut connections = self.connections.write().await;
            if let Some(handle) = connections.get_mut(&conn_id) {
                let room_code = handle.room_code.take();
                let player_id = handle.player_id.take();
                match (room_code, player_id) {
                    (Some(r), Some(p)) => (r, p),
                    _ => return None,
                }
            } else {
                return None;
            }
        };

        // 從房間移除連線
        {
            let mut rooms = self.rooms.write().await;
            if let Some(room_conns) = rooms.get_mut(&room_code) {
                room_conns.remove(&conn_id);
                if room_conns.is_empty() {
                    rooms.remove(&room_code);
                }
            }
        }

        tracing::debug!(
            conn_id = %conn_id,
            room_code = %room_code,
            player_id = %player_id,
            "連線已離開房間"
        );

        Some((room_code, player_id))
    }

    /// 廣播訊息給房間內所有玩家
    ///
    /// 同時發送到本地連線和 Redis Pub/Sub（如果已設定）
    pub async fn broadcast_to_room(&self, room_code: &str, message: ServerMessage) {
        // 發送到本地連線
        self.broadcast_to_room_local(room_code, message.clone())
            .await;

        // 發布到 Redis（跨實例廣播）
        self.publish_to_redis(room_code, &message).await;
    }

    /// 廣播訊息給本地房間連線（不發布到 Redis）
    pub async fn broadcast_to_room_local(&self, room_code: &str, message: ServerMessage) {
        let conn_ids = {
            let rooms = self.rooms.read().await;
            rooms.get(room_code).cloned().unwrap_or_default()
        };

        if conn_ids.is_empty() {
            return;
        }

        let connections = self.connections.read().await;
        let mut sent_count = 0;

        for conn_id in conn_ids {
            if let Some(handle) = connections.get(&conn_id) {
                if handle.send(message.clone()) {
                    sent_count += 1;
                }
            }
        }

        tracing::trace!(
            room_code = %room_code,
            sent_count = sent_count,
            "廣播訊息到本地房間連線"
        );
    }

    /// 發布訊息到 Redis 頻道
    async fn publish_to_redis(&self, room_code: &str, message: &ServerMessage) {
        let pool = {
            let redis = self.redis_pool.read().await;
            match redis.as_ref() {
                Some(p) => p.clone(),
                None => return, // 沒有設定 Redis，跳過
            }
        };

        // 序列化訊息
        let json = match serde_json::to_string(message) {
            Ok(j) => j,
            Err(e) => {
                tracing::warn!(error = %e, "序列化 WebSocket 訊息失敗");
                return;
            }
        };

        // 發布到 Redis
        let game_cache = GameCache::new(pool);
        if let Err(e) = game_cache.publish_to_room(room_code, &json).await {
            tracing::warn!(room_code = %room_code, error = %e, "發布訊息到 Redis 失敗");
        }
    }

    /// 訂閱房間的 Redis 頻道
    ///
    /// 當收到其他實例發布的訊息時，轉發給本地連線
    ///
    /// 注意：Redis Pub/Sub 需要專用連線，這個方法會建立一個獨立的 Redis 連線用於訂閱
    pub async fn subscribe_to_room(self: &Arc<Self>, room_code: &str, redis_url: &str) {
        // 檢查是否已訂閱
        {
            let subscribed = self.subscribed_rooms.read().await;
            if subscribed.contains(room_code) {
                return;
            }
        }

        // 標記為已訂閱
        {
            let mut subscribed = self.subscribed_rooms.write().await;
            subscribed.insert(room_code.to_string());
        }

        let channel = GameCache::get_room_channel(room_code);
        let hub = Arc::clone(self);
        let room_code_owned = room_code.to_string();
        let redis_url_owned = redis_url.to_string();

        // 在背景啟動訂閱任務
        tokio::spawn(async move {
            tracing::debug!(room_code = %room_code_owned, channel = %channel, "開始訂閱 Redis 頻道");

            // 建立專用 Redis 連線（Pub/Sub 需要獨立連線）
            let client = match redis::Client::open(redis_url_owned.as_str()) {
                Ok(c) => c,
                Err(e) => {
                    tracing::error!(error = %e, "無法建立 Redis 客戶端用於訂閱");
                    let mut subscribed = hub.subscribed_rooms.write().await;
                    subscribed.remove(&room_code_owned);
                    return;
                }
            };

            let conn = match client.get_async_connection().await {
                Ok(c) => c,
                Err(e) => {
                    tracing::error!(error = %e, "無法取得 Redis 連線用於訂閱");
                    let mut subscribed = hub.subscribed_rooms.write().await;
                    subscribed.remove(&room_code_owned);
                    return;
                }
            };

            // 建立 Pub/Sub 連線
            let mut pubsub = conn.into_pubsub();
            if let Err(e) = pubsub.subscribe(&channel).await {
                tracing::error!(channel = %channel, error = %e, "Redis 訂閱失敗");
                let mut subscribed = hub.subscribed_rooms.write().await;
                subscribed.remove(&room_code_owned);
                return;
            }

            // 取得關閉信號
            let mut shutdown_rx = hub.subscribe_shutdown();

            // 取得訊息串流
            let mut msg_stream = pubsub.on_message();

            loop {
                tokio::select! {
                    // 關閉信號
                    _ = shutdown_rx.recv() => {
                        tracing::debug!(room_code = %room_code_owned, "收到關閉信號，停止訂閱");
                        break;
                    }
                    // Redis 訊息
                    msg = msg_stream.next() => {
                        match msg {
                            Some(msg) => {
                                let payload: String = match msg.get_payload() {
                                    Ok(p) => p,
                                    Err(e) => {
                                        tracing::warn!(error = %e, "解析 Redis 訊息失敗");
                                        continue;
                                    }
                                };

                                // 反序列化訊息
                                let server_msg: ServerMessage = match serde_json::from_str(&payload) {
                                    Ok(m) => m,
                                    Err(e) => {
                                        tracing::warn!(error = %e, "反序列化 ServerMessage 失敗");
                                        continue;
                                    }
                                };

                                // 廣播到本地連線（不再發布到 Redis，避免迴圈）
                                hub.broadcast_to_room_local(&room_code_owned, server_msg).await;
                            }
                            None => {
                                tracing::debug!(room_code = %room_code_owned, "Redis 訂閱連線已關閉");
                                break;
                            }
                        }
                    }
                }

                // 檢查房間是否還有連線，沒有的話停止訂閱
                if hub.room_connection_count(&room_code_owned).await == 0 {
                    tracing::debug!(room_code = %room_code_owned, "房間已無連線，停止訂閱");
                    break;
                }
            }

            // 移除訂閱標記
            let mut subscribed = hub.subscribed_rooms.write().await;
            subscribed.remove(&room_code_owned);
            tracing::debug!(room_code = %room_code_owned, "Redis 訂閱已停止");
        });
    }

    /// 檢查是否已訂閱房間
    pub async fn is_subscribed(&self, room_code: &str) -> bool {
        let subscribed = self.subscribed_rooms.read().await;
        subscribed.contains(room_code)
    }

    /// 取消訂閱房間的 Redis 頻道
    pub async fn unsubscribe_from_room(&self, room_code: &str) {
        let mut subscribed = self.subscribed_rooms.write().await;
        subscribed.remove(room_code);
        // 注意：實際取消訂閱會由訂閱任務的房間連線數檢查觸發
    }

    /// 廣播訊息給房間內所有玩家（排除特定連線）
    pub async fn broadcast_to_room_except(
        &self,
        room_code: &str,
        message: ServerMessage,
        except_conn_id: Uuid,
    ) {
        let conn_ids = {
            let rooms = self.rooms.read().await;
            rooms.get(room_code).cloned().unwrap_or_default()
        };

        let connections = self.connections.read().await;

        for conn_id in conn_ids {
            if conn_id != except_conn_id {
                if let Some(handle) = connections.get(&conn_id) {
                    let _ = handle.send(message.clone());
                }
            }
        }
    }

    /// 發送訊息給特定連線
    pub async fn send_to_connection(&self, conn_id: Uuid, message: ServerMessage) -> bool {
        let connections = self.connections.read().await;
        if let Some(handle) = connections.get(&conn_id) {
            return handle.send(message);
        }
        false
    }

    /// 發送訊息給特定玩家
    pub async fn send_to_player(&self, player_id: Uuid, message: ServerMessage) -> bool {
        let connections = self.connections.read().await;
        for handle in connections.values() {
            if handle.player_id == Some(player_id) && handle.send(message.clone()) {
                return true;
            }
        }
        false
    }

    /// 發送訊息給特定使用者
    pub async fn send_to_user(&self, user_id: Uuid, message: ServerMessage) -> bool {
        let connections = self.connections.read().await;
        for handle in connections.values() {
            if handle.user_id == user_id && handle.send(message.clone()) {
                return true;
            }
        }
        false
    }

    /// 取得房間內的連線 ID 列表
    pub async fn get_room_connections(&self, room_code: &str) -> Vec<Uuid> {
        let rooms = self.rooms.read().await;
        rooms
            .get(room_code)
            .map(|set| set.iter().copied().collect())
            .unwrap_or_default()
    }

    /// 取得連線資訊
    pub async fn get_connection(&self, conn_id: Uuid) -> Option<ConnectionHandle> {
        let connections = self.connections.read().await;
        connections.get(&conn_id).cloned()
    }

    /// 取得連線的房間代碼
    pub async fn get_room_code(&self, conn_id: Uuid) -> Option<String> {
        let connections = self.connections.read().await;
        connections.get(&conn_id).and_then(|h| h.room_code.clone())
    }

    /// 取得連線的玩家 ID
    pub async fn get_player_id(&self, conn_id: Uuid) -> Option<Uuid> {
        let connections = self.connections.read().await;
        connections.get(&conn_id).and_then(|h| h.player_id)
    }

    /// 取得連線的使用者 ID
    pub async fn get_user_id(&self, conn_id: Uuid) -> Option<Uuid> {
        let connections = self.connections.read().await;
        connections.get(&conn_id).map(|h| h.user_id)
    }

    /// 取得房間內的連線數
    pub async fn room_connection_count(&self, room_code: &str) -> usize {
        let rooms = self.rooms.read().await;
        rooms.get(room_code).map(|set| set.len()).unwrap_or(0)
    }

    /// 取得總連線數
    pub async fn total_connections(&self) -> usize {
        let connections = self.connections.read().await;
        connections.len()
    }

    /// 取得總房間數
    pub async fn total_rooms(&self) -> usize {
        let rooms = self.rooms.read().await;
        rooms.len()
    }

    /// 檢查使用者是否已連線
    pub async fn is_user_connected(&self, user_id: Uuid) -> bool {
        let connections = self.connections.read().await;
        connections.values().any(|h| h.user_id == user_id)
    }

    /// 取得使用者的連線 ID
    pub async fn get_user_connection_id(&self, user_id: Uuid) -> Option<Uuid> {
        let connections = self.connections.read().await;
        for handle in connections.values() {
            if handle.user_id == user_id {
                return Some(handle.id);
            }
        }
        None
    }

    /// 廣播訊息給所有連線
    pub async fn broadcast_all(&self, message: ServerMessage) {
        let connections = self.connections.read().await;
        for handle in connections.values() {
            let _ = handle.send(message.clone());
        }
    }

    /// 更新連線的玩家 ID
    pub async fn set_player_id(&self, conn_id: Uuid, player_id: Uuid) {
        let mut connections = self.connections.write().await;
        if let Some(handle) = connections.get_mut(&conn_id) {
            handle.player_id = Some(player_id);
        }
    }

    /// 獲取房間的下一個序列號
    pub async fn get_next_sequence(&self, room_code: &str) -> u64 {
        let mut sequences = self.room_sequences.write().await;
        let seq = sequences.entry(room_code.to_string()).or_insert(0);
        *seq += 1;
        *seq
    }

    /// 廣播帶序列號的訊息到房間
    pub async fn broadcast_to_room_with_sequence(&self, room_code: &str, message: ServerMessage) {
        use super::messages::WrappedMessage;
        
        let seq = self.get_next_sequence(room_code).await;
        let wrapped = WrappedMessage::new(seq, message);
        
        // 發送到本地連線
        self.broadcast_wrapped_message_local(room_code, wrapped.clone()).await;
        
        // 發布到 Redis
        self.publish_wrapped_message_to_redis(room_code, &wrapped).await;
    }

    /// 廣播包裝訊息到本地房間連線
    async fn broadcast_wrapped_message_local(&self, room_code: &str, message: super::messages::WrappedMessage) {
        let conn_ids = {
            let rooms = self.rooms.read().await;
            rooms.get(room_code).cloned().unwrap_or_default()
        };

        if conn_ids.is_empty() {
            return;
        }

        let connections = self.connections.read().await;
        let mut sent_count = 0;

        for conn_id in conn_ids {
            if let Some(handle) = connections.get(&conn_id) {
                // 將 WrappedMessage 序列化為 JSON，然後發送為文字消息
                if let Ok(json) = serde_json::to_string(&message) {
                    // 這裡暫時使用 SystemMessage 來傳送 JSON，
                    // 實際實現中應該修改 ConnectionHandle 以支持原始 JSON
                    if handle.send(ServerMessage::system(json, super::messages::SystemMessageType::Info)) {
                        sent_count += 1;
                    }
                }
            }
        }

        tracing::trace!(
            room_code = %room_code,
            sent_count = sent_count,
            seq = message.seq,
            "廣播包裝訊息到本地房間連線"
        );
    }

    /// 發布包裝訊息到 Redis
    async fn publish_wrapped_message_to_redis(&self, room_code: &str, message: &super::messages::WrappedMessage) {
        let pool = {
            let redis = self.redis_pool.read().await;
            match redis.as_ref() {
                Some(p) => p.clone(),
                None => return,
            }
        };

        let json = match serde_json::to_string(message) {
            Ok(j) => j,
            Err(e) => {
                tracing::warn!(error = %e, "序列化包裝訊息失敗");
                return;
            }
        };

        let game_cache = GameCache::new(pool);
        if let Err(e) = game_cache.publish_to_room(room_code, &json).await {
            tracing::warn!(room_code = %room_code, error = %e, "發布包裝訊息到 Redis 失敗");
        }
    }

    /// 記錄玩家斷線（保留 120 秒）
    pub async fn record_player_disconnect(&self, player_id: Uuid) {
        let timestamp = chrono::Utc::now().timestamp();
        let mut disconnected = self.disconnected_players.write().await;
        disconnected.insert(player_id, timestamp);
        
        tracing::info!(player_id = %player_id, "玩家斷線已記錄");
    }

    /// 清理斷線玩家記錄
    pub async fn cleanup_disconnected_players(&self) {
        let now = chrono::Utc::now().timestamp();
        let mut disconnected = self.disconnected_players.write().await;
        
        // 移除 120 秒前斷線的玩家
        disconnected.retain(|player_id, &mut timestamp| {
            let keep = now - timestamp < 120;
            if !keep {
                tracing::info!(player_id = %player_id, "清理過期斷線記錄");
            }
            keep
        });
    }

    /// 檢查玩家是否在斷線保護期內
    pub async fn is_player_disconnected(&self, player_id: Uuid) -> bool {
        let disconnected = self.disconnected_players.read().await;
        disconnected.contains_key(&player_id)
    }

    /// 玩家重連時移除斷線記錄
    pub async fn player_reconnected(&self, player_id: Uuid) {
        let mut disconnected = self.disconnected_players.write().await;
        if disconnected.remove(&player_id).is_some() {
            tracing::info!(player_id = %player_id, "玩家重連，移除斷線記錄");
        }
    }
}

impl Default for WebSocketHub {
    fn default() -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            connections: RwLock::new(HashMap::new()),
            rooms: RwLock::new(HashMap::new()),
            room_sequences: RwLock::new(HashMap::new()),
            disconnected_players: RwLock::new(HashMap::new()),
            shutdown_tx,
            redis_pool: RwLock::new(None),
            subscribed_rooms: RwLock::new(HashSet::new()),
        }
    }
}

impl std::fmt::Debug for WebSocketHub {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("WebSocketHub")
            .field("connections", &"RwLock<HashMap<...>>")
            .field("rooms", &"RwLock<HashMap<...>>")
            .finish()
    }
}

// 為了向後兼容，保留 Hub 別名
pub type Hub = WebSocketHub;

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_hub_register_unregister() {
        let hub = WebSocketHub::new();
        let user_id = Uuid::new_v4();
        let (tx, _rx) = mpsc::unbounded_channel();

        let conn_id = hub.register(user_id, tx).await;
        assert_eq!(hub.total_connections().await, 1);
        assert!(hub.is_user_connected(user_id).await);

        hub.unregister(conn_id).await;
        assert_eq!(hub.total_connections().await, 0);
        assert!(!hub.is_user_connected(user_id).await);
    }

    #[tokio::test]
    async fn test_hub_join_leave_room() {
        let hub = WebSocketHub::new();
        let user_id = Uuid::new_v4();
        let room_code = "ABC123".to_string();
        let player_id = Uuid::new_v4();
        let (tx, _rx) = mpsc::unbounded_channel();

        let conn_id = hub.register(user_id, tx).await;
        hub.join_room(conn_id, room_code.clone(), player_id).await;

        assert_eq!(hub.room_connection_count(&room_code).await, 1);
        assert_eq!(hub.get_room_code(conn_id).await, Some(room_code.clone()));
        assert_eq!(hub.get_player_id(conn_id).await, Some(player_id));

        let result = hub.leave_room(conn_id).await;
        assert_eq!(result, Some((room_code.clone(), player_id)));
        assert_eq!(hub.room_connection_count(&room_code).await, 0);
    }

    #[tokio::test]
    async fn test_hub_broadcast_to_room() {
        let hub = WebSocketHub::new();
        let room_code = "ROOM01".to_string();

        // 建立兩個連線
        let (tx1, mut rx1) = mpsc::unbounded_channel();
        let (tx2, mut rx2) = mpsc::unbounded_channel();

        let conn1 = hub.register(Uuid::new_v4(), tx1).await;
        let conn2 = hub.register(Uuid::new_v4(), tx2).await;

        hub.join_room(conn1, room_code.clone(), Uuid::new_v4())
            .await;
        hub.join_room(conn2, room_code.clone(), Uuid::new_v4())
            .await;

        // 廣播訊息
        let msg = ServerMessage::info("Test message");
        hub.broadcast_to_room(&room_code, msg).await;

        // 兩個連線都應該收到訊息
        assert!(rx1.try_recv().is_ok());
        assert!(rx2.try_recv().is_ok());
    }

    #[tokio::test]
    async fn test_hub_get_room_connections() {
        let hub = WebSocketHub::new();
        let room_code = "TESTROOM".to_string();

        let (tx1, _rx1) = mpsc::unbounded_channel();
        let (tx2, _rx2) = mpsc::unbounded_channel();

        let conn1 = hub.register(Uuid::new_v4(), tx1).await;
        let conn2 = hub.register(Uuid::new_v4(), tx2).await;

        hub.join_room(conn1, room_code.clone(), Uuid::new_v4())
            .await;
        hub.join_room(conn2, room_code.clone(), Uuid::new_v4())
            .await;

        let connections = hub.get_room_connections(&room_code).await;
        assert_eq!(connections.len(), 2);
        assert!(connections.contains(&conn1));
        assert!(connections.contains(&conn2));
    }

    #[tokio::test]
    async fn test_hub_send_to_player() {
        let hub = WebSocketHub::new();
        let player_id = Uuid::new_v4();
        let room_code = "ROOM".to_string();

        let (tx, mut rx) = mpsc::unbounded_channel();
        let conn_id = hub.register(Uuid::new_v4(), tx).await;
        hub.join_room(conn_id, room_code, player_id).await;

        let msg = ServerMessage::info("Hello player");
        let sent = hub.send_to_player(player_id, msg).await;

        assert!(sent);
        assert!(rx.try_recv().is_ok());
    }

    #[tokio::test]
    async fn test_hub_switch_room() {
        let hub = WebSocketHub::new();
        let user_id = Uuid::new_v4();
        let room1 = "ROOM1".to_string();
        let room2 = "ROOM2".to_string();
        let player_id = Uuid::new_v4();

        let (tx, _rx) = mpsc::unbounded_channel();
        let conn_id = hub.register(user_id, tx).await;

        // 加入房間 1
        hub.join_room(conn_id, room1.clone(), player_id).await;
        assert_eq!(hub.room_connection_count(&room1).await, 1);

        // 直接加入房間 2（應該自動離開房間 1）
        hub.join_room(conn_id, room2.clone(), player_id).await;
        assert_eq!(hub.room_connection_count(&room1).await, 0);
        assert_eq!(hub.room_connection_count(&room2).await, 1);
        assert_eq!(hub.get_room_code(conn_id).await, Some(room2));
    }
}
