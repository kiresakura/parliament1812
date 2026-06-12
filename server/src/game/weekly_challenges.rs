//! 週期性挑戰（Weekly Challenges）模板定義
//!
//! 定義每週挑戰的類型、模板和獎勵。

use serde::{Deserialize, Serialize};

/// 週挑戰類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum WeeklyQuestType {
    /// 本週贏得 5 場
    WeeklyWin5,
    /// 本週進行 10 場
    WeeklyPlay10,
    /// 本週投票 15 次
    WeeklyVote15,
    /// 本週使用 15 張攻擊卡
    WeeklyAttack15,
    /// 本週使用 10 張防禦卡
    WeeklyDefense10,
    /// 本週結盟 5 次
    WeeklyAlliance5,
    /// 本週發起 8 次質詢
    WeeklyChallenge8,
    /// 本週造成 100 點聲望傷害
    WeeklyDamage100,
    /// 本週獲得 200 金幣
    WeeklyGold200,
    /// 本週辯論出 30 張牌
    WeeklyCards30,
}

impl WeeklyQuestType {
    /// 取得所有週挑戰類型
    pub fn all() -> &'static [WeeklyQuestType] {
        &[
            WeeklyQuestType::WeeklyWin5,
            WeeklyQuestType::WeeklyPlay10,
            WeeklyQuestType::WeeklyVote15,
            WeeklyQuestType::WeeklyAttack15,
            WeeklyQuestType::WeeklyDefense10,
            WeeklyQuestType::WeeklyAlliance5,
            WeeklyQuestType::WeeklyChallenge8,
            WeeklyQuestType::WeeklyDamage100,
            WeeklyQuestType::WeeklyGold200,
            WeeklyQuestType::WeeklyCards30,
        ]
    }

    /// 取得週挑戰的字串 ID
    pub fn as_str(&self) -> &'static str {
        match self {
            WeeklyQuestType::WeeklyWin5 => "weekly_win_5",
            WeeklyQuestType::WeeklyPlay10 => "weekly_play_10",
            WeeklyQuestType::WeeklyVote15 => "weekly_vote_15",
            WeeklyQuestType::WeeklyAttack15 => "weekly_attack_15",
            WeeklyQuestType::WeeklyDefense10 => "weekly_defense_10",
            WeeklyQuestType::WeeklyAlliance5 => "weekly_alliance_5",
            WeeklyQuestType::WeeklyChallenge8 => "weekly_challenge_8",
            WeeklyQuestType::WeeklyDamage100 => "weekly_damage_100",
            WeeklyQuestType::WeeklyGold200 => "weekly_gold_200",
            WeeklyQuestType::WeeklyCards30 => "weekly_cards_30",
        }
    }

    /// 從字串解析週挑戰類型
    pub fn parse(s: &str) -> Option<WeeklyQuestType> {
        match s {
            "weekly_win_5" => Some(WeeklyQuestType::WeeklyWin5),
            "weekly_play_10" => Some(WeeklyQuestType::WeeklyPlay10),
            "weekly_vote_15" => Some(WeeklyQuestType::WeeklyVote15),
            "weekly_attack_15" => Some(WeeklyQuestType::WeeklyAttack15),
            "weekly_defense_10" => Some(WeeklyQuestType::WeeklyDefense10),
            "weekly_alliance_5" => Some(WeeklyQuestType::WeeklyAlliance5),
            "weekly_challenge_8" => Some(WeeklyQuestType::WeeklyChallenge8),
            "weekly_damage_100" => Some(WeeklyQuestType::WeeklyDamage100),
            "weekly_gold_200" => Some(WeeklyQuestType::WeeklyGold200),
            "weekly_cards_30" => Some(WeeklyQuestType::WeeklyCards30),
            _ => None,
        }
    }
}

/// 週挑戰模板
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyTemplate {
    /// 挑戰類型
    pub quest_type: WeeklyQuestType,
    /// 挑戰名稱
    pub name: String,
    /// 挑戰描述
    pub description: String,
    /// 目標數量
    pub target: i32,
    /// 獎勵
    pub reward: super::quests::QuestReward,
}

/// 取得所有週挑戰模板
pub fn all_weekly_templates() -> Vec<WeeklyTemplate> {
    use super::quests::QuestReward;

    vec![
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyWin5,
            name: "週間霸主".to_string(),
            description: "本週贏得 5 場".to_string(),
            target: 5,
            reward: QuestReward::Gems(20),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyPlay10,
            name: "國會常客".to_string(),
            description: "本週進行 10 場".to_string(),
            target: 10,
            reward: QuestReward::Gems(15),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyVote15,
            name: "投票達人".to_string(),
            description: "本週投票 15 次".to_string(),
            target: 15,
            reward: QuestReward::CardPack(1),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyAttack15,
            name: "攻勢如潮".to_string(),
            description: "本週使用 15 張攻擊卡".to_string(),
            target: 15,
            reward: QuestReward::Gems(15),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyDefense10,
            name: "固若金湯".to_string(),
            description: "本週使用 10 張防禦卡".to_string(),
            target: 10,
            reward: QuestReward::Gems(10),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyAlliance5,
            name: "外交家".to_string(),
            description: "本週結盟 5 次".to_string(),
            target: 5,
            reward: QuestReward::CardPack(1),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyChallenge8,
            name: "質詢風暴".to_string(),
            description: "本週發起 8 次質詢".to_string(),
            target: 8,
            reward: QuestReward::Gems(15),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyDamage100,
            name: "政治殺手".to_string(),
            description: "本週造成 100 點聲望傷害".to_string(),
            target: 100,
            reward: QuestReward::Gems(20),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyGold200,
            name: "國庫豐盈".to_string(),
            description: "本週獲得 200 金幣".to_string(),
            target: 200,
            reward: QuestReward::Gems(15),
        },
        WeeklyTemplate {
            quest_type: WeeklyQuestType::WeeklyCards30,
            name: "牌局不斷".to_string(),
            description: "本週辯論出 30 張牌".to_string(),
            target: 30,
            reward: QuestReward::ExperienceBoost(10),
        },
    ]
}
