//! API 處理器模組
//!
//! 包含所有 HTTP 端點的處理器

pub mod auth;
pub mod campaign;
pub mod codex;
pub mod friends;
pub mod health;
pub mod iap;
pub mod quests;
pub mod rankings;
pub mod rooms;
pub mod single_player;
pub mod tutorial;
pub mod websocket;
pub mod weekly;

pub use auth::{
    delete_account, forgot_password, get_linked_accounts, link_apple, link_google, login, me,
    oauth_apple, oauth_google, refresh_token, register, reset_password, unlink_provider,
    update_profile,
};
pub use health::{db_health_check, full_health_check, health_check, redis_health_check};
pub use quests::{claim_quest_reward, get_daily_quests, get_quest_history};
pub use rankings::{global_rankings, list_seasons, my_ranking};
pub use rooms::{
    create_room, get_room, join_room, leave_room, list_rooms, quick_match, spectate_room,
    RoomDetailResponse,
};
pub use weekly::{claim_weekly_reward, get_quest_summary, get_weekly_challenges};
pub use websocket::{ws_handler, ws_handler_general};
