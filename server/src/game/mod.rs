//! 遊戲引擎模組
//!
//! 提供遊戲核心邏輯，包括：
//! - 遊戲狀態管理
//! - 角色技能系統
//! - 遊戲行動處理
//! - 遊戲流程控制
//! - 卡牌系統

pub mod actions;
pub mod ai;
pub mod alliance;
pub mod bills;
pub mod cards;
pub mod characters;
pub mod engine;
pub mod state;

// 重新匯出常用類型
pub use actions::{ActionResult, GameAction, GameEffect, GameResult, PlayerScore, VoteCounts};
pub use characters::{CharacterSkills, GameError};
pub use engine::{GameConfig, GameEngine};
pub use state::{GameState, PendingChallenge, PlayerState};
