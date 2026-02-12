//! 應用程式狀態
//!
//! 共享的應用程式狀態，包含資料庫連接池、Redis 連接池等

use crate::auth::JwtManager;
use crate::cache::GameCache;
use crate::config::Settings;
use crate::domain::{Player, Room, User};
use crate::error::AppError;
use crate::game::GameEngine;
use crate::repository::{PlayerRepository, RoomRepository, UserRepository};
use crate::single_player::session::SinglePlayerSession;
use crate::websocket::WebSocketHub;
use deadpool_redis::{Config as RedisConfig, Pool as RedisPool, Runtime};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// 用戶儲存（記憶體）
pub type UserStore = Arc<RwLock<HashMap<Uuid, User>>>;

/// 房間儲存（記憶體）
pub type RoomStore = Arc<RwLock<HashMap<Uuid, Room>>>;

/// 玩家儲存（記憶體）
pub type PlayerStore = Arc<RwLock<HashMap<Uuid, Player>>>;

/// 房間玩家映射（room_code -> player_ids）
pub type RoomPlayersStore = Arc<RwLock<HashMap<String, Vec<Uuid>>>>;

/// 遊戲引擎儲存（room_code -> GameEngine）
pub type GameStore = Arc<RwLock<HashMap<String, GameEngine>>>;

/// 單人遊戲 Session 儲存
pub type SinglePlayerStore = Arc<RwLock<HashMap<Uuid, SinglePlayerSession>>>;

/// 應用程式狀態
///
/// 包含所有共享資源，通過 Arc 實現克隆
#[derive(Clone)]
pub struct AppState {
    /// PostgreSQL 資料庫連接池
    pub db: PgPool,
    /// Redis 連接池
    pub redis: RedisPool,
    /// JWT 管理器
    pub jwt: Arc<JwtManager>,
    /// 應用設定
    pub settings: Arc<Settings>,
    /// 用戶儲存（記憶體）
    pub users: UserStore,
    /// 房間儲存（記憶體）
    pub rooms: RoomStore,
    /// 玩家儲存（記憶體）
    pub players: PlayerStore,
    /// 房間玩家映射（room_code -> player_ids）
    pub room_players: RoomPlayersStore,
    /// 遊戲引擎儲存（room_code -> GameEngine）
    pub games: GameStore,
    /// 單人遊戲 Session 儲存
    pub single_player_sessions: SinglePlayerStore,
    /// WebSocket Hub
    pub ws_hub: Arc<WebSocketHub>,
}

impl AppState {
    /// 建立新的應用程式狀態
    ///
    /// 初始化資料庫和 Redis 連接池
    pub async fn new(settings: Settings) -> Result<Self, AppError> {
        // 建立 PostgreSQL 連接池
        let db = PgPoolOptions::new()
            .max_connections(settings.database.max_connections)
            .connect(&settings.database.url)
            .await
            .map_err(|e| AppError::DatabaseError(format!("無法連接資料庫: {}", e)))?;

        tracing::info!("已連接到 PostgreSQL 資料庫");

        // 建立 Redis 連接池
        let redis_config = RedisConfig::from_url(&settings.redis.url);
        let redis = redis_config
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| AppError::InternalError(format!("無法建立 Redis 連接池: {}", e)))?;

        // 測試 Redis 連接
        {
            let mut conn = redis
                .get()
                .await
                .map_err(|e| AppError::InternalError(format!("無法連接 Redis: {}", e)))?;

            let _: String = redis::cmd("PING")
                .query_async(&mut conn)
                .await
                .map_err(|e| AppError::InternalError(format!("Redis PING 失敗: {}", e)))?;
        }

        tracing::info!("已連接到 Redis");

        // 建立 JWT 管理器
        let jwt = JwtManager::new(
            settings.jwt.secret.clone(),
            settings.jwt.expiration_hours as i64,
        );

        tracing::info!("JWT 管理器已初始化");

        Ok(Self {
            db,
            redis,
            jwt: Arc::new(jwt),
            settings: Arc::new(settings),
            users: Arc::new(RwLock::new(HashMap::new())),
            rooms: Arc::new(RwLock::new(HashMap::new())),
            players: Arc::new(RwLock::new(HashMap::new())),
            room_players: Arc::new(RwLock::new(HashMap::new())),
            games: Arc::new(RwLock::new(HashMap::new())),
            single_player_sessions: Arc::new(RwLock::new(HashMap::new())),
            ws_hub: WebSocketHub::new(),
        })
    }

    /// 建立僅包含資料庫的狀態（不連接 Redis）
    ///
    /// 適用於不需要 Redis 的場景或測試
    pub async fn with_db_only(settings: Settings) -> Result<Self, AppError> {
        let db = PgPoolOptions::new()
            .max_connections(settings.database.max_connections)
            .connect(&settings.database.url)
            .await
            .map_err(|e| AppError::DatabaseError(format!("無法連接資料庫: {}", e)))?;

        // 建立一個空的 Redis 池（不會實際連接）
        let redis_config = RedisConfig::from_url(&settings.redis.url);
        let redis = redis_config
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| AppError::InternalError(format!("無法建立 Redis 連接池: {}", e)))?;

        // 建立 JWT 管理器
        let jwt = JwtManager::new(
            settings.jwt.secret.clone(),
            settings.jwt.expiration_hours as i64,
        );

        Ok(Self {
            db,
            redis,
            jwt: Arc::new(jwt),
            settings: Arc::new(settings),
            users: Arc::new(RwLock::new(HashMap::new())),
            rooms: Arc::new(RwLock::new(HashMap::new())),
            players: Arc::new(RwLock::new(HashMap::new())),
            room_players: Arc::new(RwLock::new(HashMap::new())),
            games: Arc::new(RwLock::new(HashMap::new())),
            single_player_sessions: Arc::new(RwLock::new(HashMap::new())),
            ws_hub: WebSocketHub::new(),
        })
    }

    /// 建立僅供測試的狀態（不需要資料庫和 Redis）
    pub fn for_testing(settings: Settings) -> Self {
        // 建立假的資料庫池（不會實際使用）
        // 這需要一個有效的 URL，但不會實際連接
        let redis_config = RedisConfig::from_url(&settings.redis.url);
        let redis = redis_config
            .create_pool(Some(Runtime::Tokio1))
            .expect("無法建立測試 Redis 連接池");

        // 建立 JWT 管理器
        let jwt = JwtManager::new(
            settings.jwt.secret.clone(),
            settings.jwt.expiration_hours as i64,
        );

        // 建立假的資料庫池
        // 注意：這會在第一次使用時失敗，但對於不需要資料庫的測試來說足夠了
        let db_url = &settings.database.url;
        let db_pool = sqlx::pool::PoolOptions::new()
            .max_connections(1)
            .connect_lazy(db_url)
            .expect("無法建立測試資料庫連接池");

        Self {
            db: db_pool,
            redis,
            jwt: Arc::new(jwt),
            settings: Arc::new(settings),
            users: Arc::new(RwLock::new(HashMap::new())),
            rooms: Arc::new(RwLock::new(HashMap::new())),
            players: Arc::new(RwLock::new(HashMap::new())),
            room_players: Arc::new(RwLock::new(HashMap::new())),
            games: Arc::new(RwLock::new(HashMap::new())),
            single_player_sessions: Arc::new(RwLock::new(HashMap::new())),
            ws_hub: WebSocketHub::new(),
        }
    }

    /// 取得資料庫連接池的參考
    pub fn db(&self) -> &PgPool {
        &self.db
    }

    /// 取得 Redis 連接池的參考
    pub fn redis(&self) -> &RedisPool {
        &self.redis
    }

    /// 取得設定的參考
    pub fn settings(&self) -> &Settings {
        &self.settings
    }

    /// 取得 JWT 管理器的參考
    pub fn jwt(&self) -> &JwtManager {
        &self.jwt
    }

    /// 檢查資料庫連接是否正常
    pub async fn check_db_health(&self) -> Result<(), AppError> {
        sqlx::query("SELECT 1")
            .execute(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(format!("資料庫健康檢查失敗: {}", e)))?;
        Ok(())
    }

    /// 檢查 Redis 連接是否正常
    pub async fn check_redis_health(&self) -> Result<(), AppError> {
        let mut conn = self
            .redis
            .get()
            .await
            .map_err(|e| AppError::InternalError(format!("無法取得 Redis 連接: {}", e)))?;

        let _: String = redis::cmd("PING")
            .query_async(&mut conn)
            .await
            .map_err(|e| AppError::InternalError(format!("Redis 健康檢查失敗: {}", e)))?;

        Ok(())
    }

    // ==================== Repository 存取器 ====================

    /// 取得使用者資料存取器
    pub fn user_repo(&self) -> UserRepository {
        UserRepository::new(self.db.clone())
    }

    /// 取得房間資料存取器
    pub fn room_repo(&self) -> RoomRepository {
        RoomRepository::new(self.db.clone())
    }

    /// 取得玩家資料存取器
    pub fn player_repo(&self) -> PlayerRepository {
        PlayerRepository::new(self.db.clone())
    }

    /// 取得遊戲快取
    pub fn game_cache(&self) -> GameCache {
        GameCache::new(self.redis.clone())
    }
}

impl std::fmt::Debug for AppState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AppState")
            .field("db", &"PgPool { ... }")
            .field("redis", &"RedisPool { ... }")
            .field("jwt", &"JwtManager { ... }")
            .field("settings", &self.settings)
            .field("users", &"UserStore { ... }")
            .field("rooms", &"RoomStore { ... }")
            .field("players", &"PlayerStore { ... }")
            .field("room_players", &"RoomPlayersStore { ... }")
            .field("games", &"GameStore { ... }")
            .field("single_player_sessions", &"SinglePlayerStore { ... }")
            .field("ws_hub", &"WebSocketHub { ... }")
            .finish()
    }
}
