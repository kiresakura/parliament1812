//! 單人模式模組
//!
//! 提供 AI 對戰引擎、故事戰役等單人遊戲功能
//!
//! # 子模組
//! - `ai_engine` - 增強版 AI 引擎（Easy/Normal/Hard）
//! - `session` - 單人遊戲 session 管理
//! - `campaign` - 故事戰役系統

pub mod ai_engine;
pub mod campaign;
pub mod session;

pub use ai_engine::{AiDifficulty, AiEngine};
pub use campaign::{Campaign, CampaignChapter, CampaignProgress, ChapterId, SpecialRule};
pub use session::{
    SinglePlayerAction, SinglePlayerResponse, SinglePlayerSession, SinglePlayerState,
};
