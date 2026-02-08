//! API 處理器模組
//!
//! 包含所有 HTTP 端點的處理器

pub mod auth;
pub mod health;
pub mod rooms;
pub mod websocket;

pub use auth::{login, me, register};
pub use health::{db_health_check, full_health_check, health_check, redis_health_check};
pub use rooms::{create_room, get_room, join_room, leave_room, list_rooms, quick_match, spectate_room, RoomDetailResponse};
pub use websocket::{ws_handler, ws_handler_general};
