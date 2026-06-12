//! 國際化（i18n）模組
//!
//! 提供多語言支援：
//! - 卡牌名稱/描述/風味文字
//! - 成就名稱/描述
//! - 任務名稱/描述
//! - 角色名稱/描述
//! - 遊戲系統訊息

pub mod translations;

use axum::http::HeaderMap;
use serde::{Deserialize, Serialize};

/// 支援的語言
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub enum Locale {
    /// 繁體中文（預設）
    #[default]
    ZhTw,
    /// English
    En,
    /// 簡體中文
    ZhCn,
}

impl Locale {
    /// 從 Accept-Language header 解析語言
    pub fn from_accept_language(headers: &HeaderMap) -> Self {
        if let Some(value) = headers.get("Accept-Language") {
            if let Ok(s) = value.to_str() {
                return Self::parse(s);
            }
        }
        Locale::ZhTw // 預設繁體中文
    }

    /// 從字串解析語言
    pub fn parse(s: &str) -> Self {
        let lower = s.to_lowercase();
        // 檢查各語言標籤（按優先順序）
        for part in lower.split(',') {
            let tag = part.split(';').next().unwrap_or("").trim();
            if tag.starts_with("zh-tw") || tag.starts_with("zh_tw") || tag == "zh-hant" {
                return Locale::ZhTw;
            }
            if tag.starts_with("zh-cn")
                || tag.starts_with("zh_cn")
                || tag == "zh-hans"
                || tag.starts_with("zh-sg")
            {
                return Locale::ZhCn;
            }
            if tag.starts_with("en") {
                return Locale::En;
            }
            // 純 "zh" 預設繁體
            if tag == "zh" {
                return Locale::ZhTw;
            }
        }
        Locale::ZhTw
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Locale::ZhTw => "zh_TW",
            Locale::En => "en",
            Locale::ZhCn => "zh_CN",
        }
    }
}

impl std::fmt::Display for Locale {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_str())
    }
}

// 重新匯出
pub use translations::I18n;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_locale_parse() {
        assert_eq!(Locale::parse("zh-TW"), Locale::ZhTw);
        assert_eq!(Locale::parse("zh_TW"), Locale::ZhTw);
        assert_eq!(Locale::parse("zh-Hant"), Locale::ZhTw);
        assert_eq!(Locale::parse("en"), Locale::En);
        assert_eq!(Locale::parse("en-US"), Locale::En);
        assert_eq!(Locale::parse("zh-CN"), Locale::ZhCn);
        assert_eq!(Locale::parse("zh_CN"), Locale::ZhCn);
        assert_eq!(Locale::parse("zh-Hans"), Locale::ZhCn);
        assert_eq!(Locale::parse("zh"), Locale::ZhTw);
        assert_eq!(Locale::parse("fr"), Locale::ZhTw); // 不支援的語言 → 預設
    }

    #[test]
    fn test_locale_from_accept_language() {
        let mut headers = HeaderMap::new();
        headers.insert(
            "Accept-Language",
            "en-US,en;q=0.9,zh-TW;q=0.8".parse().unwrap(),
        );
        assert_eq!(Locale::from_accept_language(&headers), Locale::En);

        let mut headers2 = HeaderMap::new();
        headers2.insert("Accept-Language", "zh-TW,zh;q=0.9".parse().unwrap());
        assert_eq!(Locale::from_accept_language(&headers2), Locale::ZhTw);

        // 空 header → 預設
        let empty = HeaderMap::new();
        assert_eq!(Locale::from_accept_language(&empty), Locale::ZhTw);
    }
}
