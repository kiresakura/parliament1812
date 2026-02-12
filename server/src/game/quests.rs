//! 每日任務模板定義
//!
//! 定義所有可能的任務類型、獎勵類型與模板。

use serde::{Deserialize, Serialize};

// ============================================================
// 任務類型
// ============================================================

/// 任務類型列舉
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum QuestType {
    /// 進行遊戲
    PlayGames,
    /// 贏得遊戲
    WinGames,
    /// 使用指定角色進行遊戲
    PlayAsCharacter,
    /// 使用攻擊卡
    UseAttackCards,
    /// 使用防禦卡
    UseDefenseCards,
    /// 對議案投票
    VoteOnBills,
    /// 結盟
    FormAlliance,
    /// 以高聲望獲勝（結束時聲望 >= 60）
    WinWithReputation,
    /// 觀戰遊戲
    SpectateGames,
    /// 發起質詢
    InitiateChallenge,
    /// 成功反駁
    SuccessfulCounter,
    /// 使用角色技能
    UseCharacterSkill,
    /// 在辯論階段出牌
    PlayCardsInDebate,
    /// 背叛盟友
    BetrayAlliance,
    /// 在投票中投給獲勝方
    VoteForWinner,
    /// 累計造成聲望傷害
    DealReputationDamage,
    /// 累計恢復聲望
    HealReputation,
    /// 累計獲得金幣
    EarnGold,
    /// 抽取卡牌
    DrawCards,
    /// 存活到遊戲結束
    SurviveToEnd,
}

impl QuestType {
    /// 取得所有任務類型
    pub fn all() -> &'static [QuestType] {
        &[
            QuestType::PlayGames,
            QuestType::WinGames,
            QuestType::PlayAsCharacter,
            QuestType::UseAttackCards,
            QuestType::UseDefenseCards,
            QuestType::VoteOnBills,
            QuestType::FormAlliance,
            QuestType::WinWithReputation,
            QuestType::SpectateGames,
            QuestType::InitiateChallenge,
            QuestType::SuccessfulCounter,
            QuestType::UseCharacterSkill,
            QuestType::PlayCardsInDebate,
            QuestType::BetrayAlliance,
            QuestType::VoteForWinner,
            QuestType::DealReputationDamage,
            QuestType::HealReputation,
            QuestType::EarnGold,
            QuestType::DrawCards,
            QuestType::SurviveToEnd,
        ]
    }

    /// 取得任務類型的字串 ID（用於 DB 儲存）
    pub fn as_str(&self) -> &'static str {
        match self {
            QuestType::PlayGames => "play_games",
            QuestType::WinGames => "win_games",
            QuestType::PlayAsCharacter => "play_as_character",
            QuestType::UseAttackCards => "use_attack_cards",
            QuestType::UseDefenseCards => "use_defense_cards",
            QuestType::VoteOnBills => "vote_on_bills",
            QuestType::FormAlliance => "form_alliance",
            QuestType::WinWithReputation => "win_with_reputation",
            QuestType::SpectateGames => "spectate_games",
            QuestType::InitiateChallenge => "initiate_challenge",
            QuestType::SuccessfulCounter => "successful_counter",
            QuestType::UseCharacterSkill => "use_character_skill",
            QuestType::PlayCardsInDebate => "play_cards_in_debate",
            QuestType::BetrayAlliance => "betray_alliance",
            QuestType::VoteForWinner => "vote_for_winner",
            QuestType::DealReputationDamage => "deal_reputation_damage",
            QuestType::HealReputation => "heal_reputation",
            QuestType::EarnGold => "earn_gold",
            QuestType::DrawCards => "draw_cards",
            QuestType::SurviveToEnd => "survive_to_end",
        }
    }

    /// 從字串解析任務類型
    pub fn parse(s: &str) -> Option<QuestType> {
        match s {
            "play_games" => Some(QuestType::PlayGames),
            "win_games" => Some(QuestType::WinGames),
            "play_as_character" => Some(QuestType::PlayAsCharacter),
            "use_attack_cards" => Some(QuestType::UseAttackCards),
            "use_defense_cards" => Some(QuestType::UseDefenseCards),
            "vote_on_bills" => Some(QuestType::VoteOnBills),
            "form_alliance" => Some(QuestType::FormAlliance),
            "win_with_reputation" => Some(QuestType::WinWithReputation),
            "spectate_games" => Some(QuestType::SpectateGames),
            "initiate_challenge" => Some(QuestType::InitiateChallenge),
            "successful_counter" => Some(QuestType::SuccessfulCounter),
            "use_character_skill" => Some(QuestType::UseCharacterSkill),
            "play_cards_in_debate" => Some(QuestType::PlayCardsInDebate),
            "betray_alliance" => Some(QuestType::BetrayAlliance),
            "vote_for_winner" => Some(QuestType::VoteForWinner),
            "deal_reputation_damage" => Some(QuestType::DealReputationDamage),
            "heal_reputation" => Some(QuestType::HealReputation),
            "earn_gold" => Some(QuestType::EarnGold),
            "draw_cards" => Some(QuestType::DrawCards),
            "survive_to_end" => Some(QuestType::SurviveToEnd),
            _ => None,
        }
    }
}

// ============================================================
// 獎勵類型
// ============================================================

/// 任務獎勵
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "amount")]
#[serde(rename_all = "snake_case")]
pub enum QuestReward {
    /// 金幣
    Gold(i32),
    /// 寶石
    Gems(i32),
    /// 卡包
    CardPack(i32),
    /// 經驗加成（百分比）
    ExperienceBoost(i32),
}

impl QuestReward {
    /// 取得獎勵的顯示文字
    pub fn display(&self) -> String {
        match self {
            QuestReward::Gold(n) => format!("{} 金幣", n),
            QuestReward::Gems(n) => format!("{} 寶石", n),
            QuestReward::CardPack(n) => format!("{} 卡包", n),
            QuestReward::ExperienceBoost(n) => format!("{}% 經驗加成", n),
        }
    }
}

// ============================================================
// 任務模板
// ============================================================

/// 任務模板
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuestTemplate {
    /// 任務類型
    pub quest_type: QuestType,
    /// 任務名稱
    pub name: String,
    /// 任務描述
    pub description: String,
    /// 目標數量
    pub target: i32,
    /// 獎勵
    pub reward: QuestReward,
    /// 權重（用於隨機選取，越高越常出現）
    pub weight: u32,
}

/// 取得所有任務模板
pub fn all_quest_templates() -> Vec<QuestTemplate> {
    vec![
        // --- 基礎類（高權重）---
        QuestTemplate {
            quest_type: QuestType::PlayGames,
            name: "國會日常".to_string(),
            description: "進行 2 場遊戲".to_string(),
            target: 2,
            reward: QuestReward::Gold(50),
            weight: 15,
        },
        QuestTemplate {
            quest_type: QuestType::WinGames,
            name: "勝者為王".to_string(),
            description: "贏得 1 場遊戲".to_string(),
            target: 1,
            reward: QuestReward::Gems(5),
            weight: 12,
        },
        QuestTemplate {
            quest_type: QuestType::PlayAsCharacter,
            name: "角色體驗".to_string(),
            description: "使用任意角色進行 1 場遊戲".to_string(),
            target: 1,
            reward: QuestReward::Gold(30),
            weight: 10,
        },
        QuestTemplate {
            quest_type: QuestType::VoteOnBills,
            name: "民主之聲".to_string(),
            description: "對議案投票 3 次".to_string(),
            target: 3,
            reward: QuestReward::Gold(40),
            weight: 12,
        },
        // --- 卡牌類 ---
        QuestTemplate {
            quest_type: QuestType::UseAttackCards,
            name: "舌戰群雄".to_string(),
            description: "使用 3 張攻擊卡".to_string(),
            target: 3,
            reward: QuestReward::Gold(40),
            weight: 10,
        },
        QuestTemplate {
            quest_type: QuestType::UseDefenseCards,
            name: "銅牆鐵壁".to_string(),
            description: "使用 2 張防禦卡".to_string(),
            target: 2,
            reward: QuestReward::Gold(35),
            weight: 10,
        },
        QuestTemplate {
            quest_type: QuestType::PlayCardsInDebate,
            name: "辯論高手".to_string(),
            description: "在辯論階段出 5 張牌".to_string(),
            target: 5,
            reward: QuestReward::Gold(45),
            weight: 8,
        },
        QuestTemplate {
            quest_type: QuestType::DrawCards,
            name: "牌運亨通".to_string(),
            description: "抽取 6 張卡牌".to_string(),
            target: 6,
            reward: QuestReward::Gold(30),
            weight: 8,
        },
        // --- 戰鬥類 ---
        QuestTemplate {
            quest_type: QuestType::InitiateChallenge,
            name: "挑戰者".to_string(),
            description: "發起 2 次質詢".to_string(),
            target: 2,
            reward: QuestReward::Gold(40),
            weight: 8,
        },
        QuestTemplate {
            quest_type: QuestType::SuccessfulCounter,
            name: "見招拆招".to_string(),
            description: "成功反駁 1 次質詢".to_string(),
            target: 1,
            reward: QuestReward::Gems(3),
            weight: 7,
        },
        QuestTemplate {
            quest_type: QuestType::DealReputationDamage,
            name: "政治打擊".to_string(),
            description: "累計造成 30 點聲望傷害".to_string(),
            target: 30,
            reward: QuestReward::Gold(50),
            weight: 7,
        },
        QuestTemplate {
            quest_type: QuestType::HealReputation,
            name: "名譽修復".to_string(),
            description: "累計恢復 20 點聲望".to_string(),
            target: 20,
            reward: QuestReward::Gold(40),
            weight: 6,
        },
        // --- 社交類 ---
        QuestTemplate {
            quest_type: QuestType::FormAlliance,
            name: "結盟之道".to_string(),
            description: "與其他玩家結盟 1 次".to_string(),
            target: 1,
            reward: QuestReward::Gold(35),
            weight: 8,
        },
        QuestTemplate {
            quest_type: QuestType::BetrayAlliance,
            name: "背叛者".to_string(),
            description: "背叛 1 次同盟".to_string(),
            target: 1,
            reward: QuestReward::Gems(3),
            weight: 4,
        },
        // --- 技能類 ---
        QuestTemplate {
            quest_type: QuestType::UseCharacterSkill,
            name: "技能大師".to_string(),
            description: "使用角色技能 2 次".to_string(),
            target: 2,
            reward: QuestReward::Gold(45),
            weight: 7,
        },
        // --- 挑戰類（低權重，高獎勵）---
        QuestTemplate {
            quest_type: QuestType::WinWithReputation,
            name: "名望加冕".to_string(),
            description: "以聲望 ≥ 60 贏得遊戲".to_string(),
            target: 1,
            reward: QuestReward::Gems(8),
            weight: 4,
        },
        QuestTemplate {
            quest_type: QuestType::VoteForWinner,
            name: "押對寶".to_string(),
            description: "投票給最終獲勝選項 2 次".to_string(),
            target: 2,
            reward: QuestReward::Gold(50),
            weight: 6,
        },
        QuestTemplate {
            quest_type: QuestType::SurviveToEnd,
            name: "屹立不搖".to_string(),
            description: "存活到遊戲結束 2 場".to_string(),
            target: 2,
            reward: QuestReward::Gold(45),
            weight: 8,
        },
        // --- 資源類 ---
        QuestTemplate {
            quest_type: QuestType::EarnGold,
            name: "聚財有道".to_string(),
            description: "累計獲得 50 金幣".to_string(),
            target: 50,
            reward: QuestReward::Gems(5),
            weight: 6,
        },
        // --- 觀戰類 ---
        QuestTemplate {
            quest_type: QuestType::SpectateGames,
            name: "旁觀者清".to_string(),
            description: "觀戰 1 場遊戲".to_string(),
            target: 1,
            reward: QuestReward::Gold(20),
            weight: 5,
        },
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_all_quest_types_count() {
        assert_eq!(QuestType::all().len(), 20);
    }

    #[test]
    fn test_all_quest_templates_count() {
        assert_eq!(all_quest_templates().len(), 20);
    }

    #[test]
    fn test_quest_type_roundtrip() {
        for qt in QuestType::all() {
            let s = qt.as_str();
            let parsed = QuestType::parse(s).expect("should parse");
            assert_eq!(*qt, parsed);
        }
    }

    #[test]
    fn test_quest_reward_display() {
        assert_eq!(QuestReward::Gold(50).display(), "50 金幣");
        assert_eq!(QuestReward::Gems(10).display(), "10 寶石");
        assert_eq!(QuestReward::CardPack(1).display(), "1 卡包");
        assert_eq!(QuestReward::ExperienceBoost(20).display(), "20% 經驗加成");
    }

    #[test]
    fn test_templates_have_unique_types() {
        let templates = all_quest_templates();
        let mut seen = std::collections::HashSet::new();
        for t in &templates {
            assert!(
                seen.insert(t.quest_type),
                "Duplicate quest type: {:?}",
                t.quest_type
            );
        }
    }

    #[test]
    fn test_all_templates_have_positive_weight() {
        for t in all_quest_templates() {
            assert!(t.weight > 0, "Template {:?} has zero weight", t.quest_type);
        }
    }

    #[test]
    fn test_all_templates_have_positive_target() {
        for t in all_quest_templates() {
            assert!(t.target > 0, "Template {:?} has zero target", t.quest_type);
        }
    }
}
