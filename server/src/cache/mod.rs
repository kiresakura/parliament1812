//! Redis 快取層
//!
//! 提供遊戲狀態和連線資訊的 Redis 快取功能

pub mod game_cache;

pub use game_cache::GameCache;
