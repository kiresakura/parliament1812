//! 應用程式設定模組
//!
//! 從環境變數載入配置，支援巢狀設定結構

use std::env;

/// 伺服器設定
#[derive(Debug, Clone)]
pub struct ServerSettings {
    /// 綁定主機
    pub host: String,
    /// 綁定埠號
    pub port: u16,
}

impl Default for ServerSettings {
    fn default() -> Self {
        Self {
            host: "0.0.0.0".to_string(),
            port: 8080,
        }
    }
}

/// 資料庫設定
#[derive(Debug, Clone)]
pub struct DatabaseSettings {
    /// 資料庫連接 URL
    pub url: String,
    /// 最大連接數
    pub max_connections: u32,
}

impl Default for DatabaseSettings {
    fn default() -> Self {
        Self {
            url: "postgres://localhost:5432/parliament1812".to_string(),
            max_connections: 10,
        }
    }
}

/// Redis 設定
#[derive(Debug, Clone)]
pub struct RedisSettings {
    /// Redis 連接 URL
    pub url: String,
}

impl Default for RedisSettings {
    fn default() -> Self {
        Self {
            url: "redis://localhost:6379".to_string(),
        }
    }
}

/// JWT 設定
#[derive(Debug, Clone)]
pub struct JwtSettings {
    /// JWT 密鑰
    pub secret: String,
    /// Token 過期時間（小時）
    pub expiration_hours: u64,
}

impl Default for JwtSettings {
    fn default() -> Self {
        Self {
            secret: "default-secret-change-in-production".to_string(),
            expiration_hours: 24,
        }
    }
}

/// 應用程式設定
#[derive(Debug, Clone, Default)]
pub struct Settings {
    /// 伺服器設定
    pub server: ServerSettings,
    /// 資料庫設定
    pub database: DatabaseSettings,
    /// Redis 設定
    pub redis: RedisSettings,
    /// JWT 設定
    pub jwt: JwtSettings,
}

impl Settings {
    /// 從環境變數建立設定
    ///
    /// 自動載入 .env 檔案（如果存在）
    /// 對於未設定的環境變數，使用預設值
    pub fn new() -> Result<Self, SettingsError> {
        // 載入 .env 檔案（忽略錯誤，因為在生產環境可能沒有此檔案）
        dotenvy::dotenv().ok();

        Ok(Self {
            server: ServerSettings {
                host: env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
                port: env::var("PORT")
                    .unwrap_or_else(|_| "8080".to_string())
                    .parse()
                    .map_err(|_| SettingsError::InvalidValue("PORT", "必須是有效的埠號"))?,
            },
            database: DatabaseSettings {
                url: env::var("DATABASE_URL")
                    .unwrap_or_else(|_| "postgres://localhost:5432/parliament1812".to_string()),
                max_connections: env::var("DATABASE_MAX_CONNECTIONS")
                    .unwrap_or_else(|_| "10".to_string())
                    .parse()
                    .map_err(|_| {
                        SettingsError::InvalidValue("DATABASE_MAX_CONNECTIONS", "必須是有效的數字")
                    })?,
            },
            redis: RedisSettings {
                url: env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string()),
            },
            jwt: JwtSettings {
                secret: env::var("JWT_SECRET")
                    .unwrap_or_else(|_| "default-secret-change-in-production".to_string()),
                expiration_hours: env::var("JWT_EXPIRATION_HOURS")
                    .unwrap_or_else(|_| "24".to_string())
                    .parse()
                    .map_err(|_| {
                        SettingsError::InvalidValue("JWT_EXPIRATION_HOURS", "必須是有效的數字")
                    })?,
            },
        })
    }

    /// 取得伺服器綁定地址
    pub fn server_addr(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }

    /// 檢查是否為生產環境
    pub fn is_production(&self) -> bool {
        env::var("RUST_ENV")
            .map(|v| v == "production")
            .unwrap_or(false)
    }
}

/// 設定錯誤
#[derive(Debug, thiserror::Error)]
pub enum SettingsError {
    /// 缺少必要的環境變數
    #[error("缺少環境變數: {0}")]
    MissingEnv(&'static str),

    /// 環境變數值無效
    #[error("環境變數 {0} 的值無效: {1}")]
    InvalidValue(&'static str, &'static str),
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_settings() {
        let settings = Settings::default();
        assert_eq!(settings.server.host, "0.0.0.0");
        assert_eq!(settings.server.port, 8080);
        assert_eq!(settings.database.max_connections, 10);
        assert_eq!(settings.jwt.expiration_hours, 24);
    }

    #[test]
    fn test_server_addr() {
        let settings = Settings::default();
        assert_eq!(settings.server_addr(), "0.0.0.0:8080");
    }
}
