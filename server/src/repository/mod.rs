//! 資料存取層
//!
//! 提供資料庫操作的抽象層，使用 Repository 模式

pub mod player_repo;
pub mod room_repo;
pub mod user_repo;

pub use player_repo::PlayerRepository;
pub use room_repo::RoomRepository;
pub use user_repo::{FullUserRecord, UserRepository};
