//! 翻譯載入與查詢
//!
//! 從 JSON 檔載入翻譯資料，提供查詢介面。

use std::collections::HashMap;
use std::sync::OnceLock;

use serde_json::Value;

use super::Locale;

/// 全域翻譯實例
static TRANSLATIONS: OnceLock<I18n> = OnceLock::new();

/// 國際化翻譯服務
pub struct I18n {
    data: HashMap<Locale, Value>,
}

impl I18n {
    /// 取得全域翻譯實例
    pub fn global() -> &'static I18n {
        TRANSLATIONS.get_or_init(|| {
            let mut data = HashMap::new();

            let zh_tw: Value = serde_json::from_str(include_str!("messages/zh_TW.json"))
                .expect("Failed to parse zh_TW.json");
            let en: Value = serde_json::from_str(include_str!("messages/en.json"))
                .expect("Failed to parse en.json");
            let zh_cn: Value = serde_json::from_str(include_str!("messages/zh_CN.json"))
                .expect("Failed to parse zh_CN.json");

            data.insert(Locale::ZhTw, zh_tw);
            data.insert(Locale::En, en);
            data.insert(Locale::ZhCn, zh_cn);

            I18n { data }
        })
    }

    /// 取得翻譯文字（路徑用 . 分隔）
    ///
    /// # Example
    /// ```ignore
    /// let i18n = I18n::global();
    /// let name = i18n.get(Locale::En, "cards.common_interrogate.name");
    /// ```
    pub fn get(&self, locale: Locale, path: &str) -> Option<String> {
        let value = self.data.get(&locale)?;
        let result = resolve_path(value, path)?;
        Some(result.as_str()?.to_string())
    }

    /// 取得翻譯文字，找不到時回退到 zh_TW
    pub fn get_or_fallback(&self, locale: Locale, path: &str) -> String {
        self.get(locale, path)
            .or_else(|| self.get(Locale::ZhTw, path))
            .unwrap_or_else(|| path.to_string())
    }

    /// 取得翻譯文字並替換參數
    ///
    /// # Example
    /// ```ignore
    /// let msg = i18n.get_with_args(Locale::En, "game.round_start", &[("round", "3")]);
    /// // → "Round 3 begins"
    /// ```
    pub fn get_with_args(&self, locale: Locale, path: &str, args: &[(&str, &str)]) -> String {
        let mut text = self.get_or_fallback(locale, path);
        for (key, value) in args {
            text = text.replace(&format!("{{{}}}", key), value);
        }
        text
    }

    /// 取得卡牌名稱
    pub fn card_name(&self, locale: Locale, card_id: &str) -> String {
        self.get_or_fallback(locale, &format!("cards.{}.name", card_id))
    }

    /// 取得卡牌描述
    pub fn card_description(&self, locale: Locale, card_id: &str) -> String {
        self.get_or_fallback(locale, &format!("cards.{}.description", card_id))
    }

    /// 取得卡牌風味文字
    pub fn card_flavor_text(&self, locale: Locale, card_id: &str) -> String {
        self.get_or_fallback(locale, &format!("cards.{}.flavor_text", card_id))
    }

    /// 取得成就名稱
    pub fn achievement_name(&self, locale: Locale, achievement_id: &str) -> String {
        self.get_or_fallback(locale, &format!("achievements.{}.name", achievement_id))
    }

    /// 取得成就描述
    pub fn achievement_description(&self, locale: Locale, achievement_id: &str) -> String {
        self.get_or_fallback(locale, &format!("achievements.{}.description", achievement_id))
    }

    /// 取得任務名稱
    pub fn quest_name(&self, locale: Locale, quest_type: &str) -> String {
        self.get_or_fallback(locale, &format!("quests.{}.name", quest_type))
    }

    /// 取得任務描述
    pub fn quest_description(&self, locale: Locale, quest_type: &str) -> String {
        self.get_or_fallback(locale, &format!("quests.{}.description", quest_type))
    }

    /// 取得角色名稱
    pub fn character_name(&self, locale: Locale, character_id: &str) -> String {
        self.get_or_fallback(locale, &format!("characters.{}.name", character_id))
    }

    /// 取得角色描述
    pub fn character_description(&self, locale: Locale, character_id: &str) -> String {
        self.get_or_fallback(locale, &format!("characters.{}.description", character_id))
    }

    /// 取得角色簡稱
    pub fn character_short_name(&self, locale: Locale, character_id: &str) -> String {
        self.get_or_fallback(locale, &format!("characters.{}.short_name", character_id))
    }

    /// 取得遊戲訊息
    pub fn game_message(&self, locale: Locale, key: &str) -> String {
        self.get_or_fallback(locale, &format!("game.{}", key))
    }

    /// 取得錯誤訊息
    pub fn error_message(&self, locale: Locale, key: &str) -> String {
        self.get_or_fallback(locale, &format!("errors.{}", key))
    }
}

/// 解析 JSON 路徑（用 . 分隔）
fn resolve_path<'a>(value: &'a Value, path: &str) -> Option<&'a Value> {
    let mut current = value;
    for key in path.split('.') {
        current = current.get(key)?;
    }
    Some(current)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_translations() {
        let i18n = I18n::global();
        // zh_TW
        assert_eq!(
            i18n.card_name(Locale::ZhTw, "common_interrogate"),
            "質詢"
        );
        // en
        assert_eq!(
            i18n.card_name(Locale::En, "common_interrogate"),
            "Interrogation"
        );
        // zh_CN
        assert_eq!(
            i18n.card_name(Locale::ZhCn, "common_interrogate"),
            "质询"
        );
    }

    #[test]
    fn test_card_translations() {
        let i18n = I18n::global();
        // 確認所有 56 張卡牌都有翻譯
        let card_ids = [
            "common_interrogate", "common_rebut", "common_brief_speech",
            "common_procedural_motion", "common_gather_intel", "common_public_appeal",
            "common_pamphlet", "common_lobby", "common_filibuster",
            "common_point_of_order", "common_withdraw", "common_petition",
            "common_compromise", "common_rumor", "common_tax_debate",
            "common_moral_appeal", "common_backroom_deal", "common_call_to_order",
            "common_quick_wit", "common_opening_statement",
            "common_expose_scandal", "common_endorse",
            "uncommon_coalition", "uncommon_whip", "uncommon_propaganda",
            "uncommon_double_agent", "uncommon_crisis", "uncommon_amnesty",
            "uncommon_royal_favor", "uncommon_press_leak", "uncommon_strike",
            "uncommon_embargo", "uncommon_charity", "uncommon_inspection",
            "uncommon_war_debt",
            "rare_impeachment", "rare_martial_law", "rare_revolution",
            "rare_political_assassination", "rare_reform_act", "rare_corn_law",
            "rare_factory_act", "rare_habeas_corpus", "rare_no_confidence",
            "rare_grand_coalition", "rare_espionage", "rare_public_trial",
            "rare_royal_decree", "rare_blockade", "rare_diplomatic_immunity",
            "thomas_unity", "richard_bribe", "edward_scoop", "george_fury",
            "legendary_peterloo", "legendary_magna_carta",
        ];

        for id in &card_ids {
            for locale in [Locale::ZhTw, Locale::En, Locale::ZhCn] {
                let name = i18n.card_name(locale, id);
                assert!(!name.starts_with("cards."), "Missing card name for {} in {:?}: got '{}'", id, locale, name);
                let desc = i18n.card_description(locale, id);
                assert!(!desc.starts_with("cards."), "Missing card description for {} in {:?}", id, locale);
            }
        }
    }

    #[test]
    fn test_achievement_translations() {
        let i18n = I18n::global();
        let ids = [
            "FIRST_MATCH", "FIRST_WIN", "PLAY_10", "COLLECT_50", "BUILD_DECK",
            "FIRST_IAP", "ADD_FRIEND", "TUTORIAL_DONE", "ATTACK_STREAK_5",
            "WIN_50", "GOLD_10K", "COLLECT_200", "PERFECT_VOTE", "WIN_STREAK_5",
            "ALL_ROLES", "DEFENSE_MASTER", "COMEBACK_WIN", "WIN_100",
            "WIN_STREAK_10", "COLLECT_ALL", "GOLD_100K", "TOP_LEADERBOARD",
            "PACIFIST", "ALL_ATTACK", "EASTER_EGG",
        ];
        for id in &ids {
            for locale in [Locale::ZhTw, Locale::En, Locale::ZhCn] {
                let name = i18n.achievement_name(locale, id);
                assert!(!name.contains("achievements."), "Missing achievement {} in {:?}", id, locale);
            }
        }
    }

    #[test]
    fn test_quest_translations() {
        let i18n = I18n::global();
        let types = [
            "play_games", "win_games", "play_as_character", "vote_on_bills",
            "use_attack_cards", "use_defense_cards", "play_cards_in_debate",
            "draw_cards", "initiate_challenge", "successful_counter",
            "deal_reputation_damage", "heal_reputation", "form_alliance",
            "betray_alliance", "use_character_skill", "win_with_reputation",
            "vote_for_winner", "survive_to_end", "earn_gold", "spectate_games",
        ];
        for qt in &types {
            for locale in [Locale::ZhTw, Locale::En, Locale::ZhCn] {
                let name = i18n.quest_name(locale, qt);
                assert!(!name.contains("quests."), "Missing quest {} in {:?}", qt, locale);
            }
        }
    }

    #[test]
    fn test_character_translations() {
        let i18n = I18n::global();
        for id in ["thomas", "richard", "edward", "george"] {
            for locale in [Locale::ZhTw, Locale::En, Locale::ZhCn] {
                let name = i18n.character_name(locale, id);
                assert!(!name.contains("characters."), "Missing character {} in {:?}", id, locale);
            }
        }
    }

    #[test]
    fn test_get_with_args() {
        let i18n = I18n::global();
        let msg = i18n.get_with_args(Locale::En, "game.round_start", &[("round", "3")]);
        assert_eq!(msg, "Round 3 begins");

        let msg_tw = i18n.get_with_args(Locale::ZhTw, "game.round_start", &[("round", "3")]);
        assert_eq!(msg_tw, "第 3 回合開始");
    }

    #[test]
    fn test_fallback() {
        let i18n = I18n::global();
        // 不存在的 key 回退到 path 本身
        let result = i18n.get_or_fallback(Locale::En, "nonexistent.key");
        assert_eq!(result, "nonexistent.key");
    }
}
