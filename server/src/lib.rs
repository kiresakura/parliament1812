//! 1812 國會風雲 - Rust 後端伺服器
//!
//! 這是遊戲的後端伺服器，提供：
//! - RESTful API
//! - WebSocket 即時通訊
//! - 遊戲邏輯處理
//! - 資料持久化
//!
//! # 模組結構
//!
//! - `api` - HTTP API 路由和處理器
//! - `auth` - 認證模組
//! - `config` - 應用程式設定
//! - `domain` - 領域模型（API 請求/回應）
//! - `error` - 錯誤處理
//! - `game` - 遊戲引擎
//! - `repository` - 資料存取層
//! - `services` - 業務邏輯服務
//! - `state` - 應用程式狀態
//! - `websocket` - WebSocket 模組

pub mod api;
pub mod auth;
pub mod cache;
pub mod config;
pub mod db;
pub mod domain;
pub mod error;
pub mod game;
pub mod repository;
pub mod services;
pub mod state;
pub mod websocket;

// 重新匯出常用類型
pub use api::{create_health_only_router, create_router};
pub use auth::{
    auth_middleware, optional_auth_middleware, AuthError, AuthUser, Claims, JwtManager,
    OptionalAuthUser,
};
pub use cache::GameCache;
pub use config::{
    DatabaseSettings, JwtSettings, RedisSettings, ServerSettings, Settings, SettingsError,
};
pub use domain::{
    ActionType, CharacterType, CreateRoomRequest, CreateUserRequest, GameAction, GameEvent,
    GamePhase, GameResponse, GameState, JoinRoomRequest, LoginRequest, Player, PlayerResponse,
    Room, RoomResponse, RoomStatus, TokenResponse, User, UserResponse, Vote, VoteChoice,
    VoteRequest, VoteResult,
};
pub use error::{AppError, AppResult, ErrorResponse};
pub use game::{
    // Actions
    ActionResult,
    // Characters
    CharacterSkills,
    GameAction as EngineGameAction,
    // Engine
    GameConfig,
    GameEffect,
    GameEngine,
    GameError,
    GameResult as EngineGameResult,
    // State
    GameState as EngineGameState,
    PendingChallenge,
    PlayerScore,
    PlayerState as EnginePlayerState,
    VoteCounts,
};
pub use repository::{PlayerRepository, RoomRepository, UserRepository};
pub use services::{
    room_service::{LeaveRoomResult, StartGameResult},
    GameService, RoomService,
};
pub use state::{AppState, GameStore};
pub use websocket::{
    handle_socket, process_message, ClientMessage, Hub, ServerMessage, WebSocketHub,
};
