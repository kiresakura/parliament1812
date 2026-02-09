//! API 處理器模組
//!
//! 包含所有 HTTP 端點的處理器

pub mod auth;
pub mod codex;
pub mod friends;
pub mod health;
pub mod quests;
pub mod rankings;
pub mod rooms;
pub mod websocket;

pub use auth::{
    delete_account, forgot_password, login, me, oauth_apple, oauth_google, refresh_token, register,
    reset_password,
};
pub use health::{db_health_check, full_health_check, health_check, redis_health_check};
pub use rankings::{global_rankings, list_seasons, my_ranking};
pub use rooms::{
    create_room, get_room, join_room, leave_room, list_rooms, quick_match, spectate_room,
    RoomDetailResponse,
};
pub use websocket::{ws_handler, ws_handler_general};
