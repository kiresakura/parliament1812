//! 配置模組
//!
//! 提供應用程式設定的載入和管理

mod settings;

pub use settings::{
    DatabaseSettings, JwtSettings, RedisSettings, ServerSettings, Settings, SettingsError,
};
