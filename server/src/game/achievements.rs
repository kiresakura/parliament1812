//! 成就系統
//!
//! 定義 25 個成就及其解鎖條件、獎勵、進度追蹤邏輯。
//! 參考 docs/steam/achievements.md。

use serde::{Deserialize, Serialize};

/// 成就條件類型
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum AchievementCondition {
    /// 完成 N 場對局
    PlayGames { target: i32 },
    /// 贏得 N 場對局
    WinGames { target: i32 },
    /// 收集 N 張不同卡牌
    CollectCards { target: i32 },
    /// ELO 達到 N
    ReachElo { target: i32 },
    /// 連勝 N 場
    WinStreak { target: i32 },
    /// 使用特定角色贏得 N 場
    WinWithCharacter { character: String, target: i32 },
    /// 使用所有角色各贏一場
    WinWithAllCharacters,
    /// 累計造成 N 點傷害
    TotalDamage { target: i32 },
    /// 累計恢復 N 點聲望
    TotalHealing { target: i32 },
    /// 累計獲得 N 金幣
    TotalGold { target: i32 },
    /// 成功防禦 N 次
    TotalDefense { target: i32 },
    /// 在一場中連續出 N 張攻擊卡
    AttackStreak { target: i32 },
    /// 完成新手教學
    CompleteTutorial,
    /// 首次加入多人房間
    JoinMultiplayer,
    /// 首次商店購買
    FirstPurchase,
    /// 一場中 0 張攻擊卡通關
    Pacifist,
    /// 一場中只出攻擊卡
    AllAttack,
    /// 發現彩蛋
    EasterEgg,
    /// 在最後一回合逆轉勝
    ComebackWin,
    /// 在投票階段獲得全數支持
    PerfectVote,
    /// 登上排行榜第一名
    TopLeaderboard,
    /// 一場中成功防禦 10 次
    DefenseMaster { target: i32 },
}

/// 成就獎勵
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum AchievementReward {
    /// 解鎖卡牌
    UnlockCard { card_id: String },
    /// 獲得稱號
    Title { title: String },
    /// 獲得金幣
    Gold { amount: i32 },
}

/// 成就難度
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AchievementDifficulty {
    Easy,
    Medium,
    Hard,
    Hidden,
}

/// 成就定義
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AchievementDefinition {
    /// 成就 ID（與 DB achievement_id 對應）
    pub id: String,
    /// 顯示名稱
    pub name: String,
    /// 英文名稱
    pub name_en: String,
    /// 描述
    pub description: String,
    /// 解鎖條件
    pub condition: AchievementCondition,
    /// 獎勵
    pub rewards: Vec<AchievementReward>,
    /// 難度
    pub difficulty: AchievementDifficulty,
    /// 是否隱藏（在未解鎖時不顯示描述）
    pub is_hidden: bool,
    /// 圖示建議
    pub icon_hint: String,
}

/// 成就進度（對應 DB achievements_progress 表）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AchievementProgress {
    pub achievement_id: String,
    pub progress: i32,
    pub target: i32,
    pub completed: bool,
    pub claimed: bool,
    pub completed_at: Option<String>,
}

/// 取得全部 25 個成就定義
pub fn get_all_achievements() -> Vec<AchievementDefinition> {
    vec![
        // ═══════════════════════════════════════════
        // 🟢 簡單成就 (8)
        // ═══════════════════════════════════════════
        AchievementDefinition {
            id: "FIRST_MATCH".into(),
            name: "🏆 新手議員".into(),
            name_en: "Freshman Representative".into(),
            description: "完成第一場對局".into(),
            condition: AchievementCondition::PlayGames { target: 1 },
            rewards: vec![
                AchievementReward::Gold { amount: 50 },
                AchievementReward::UnlockCard { card_id: "common_brief_speech".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "議會入口大門".into(),
        },
        AchievementDefinition {
            id: "FIRST_WIN".into(),
            name: "🏆 初嚐勝利".into(),
            name_en: "First Victory".into(),
            description: "贏得第一場對局".into(),
            condition: AchievementCondition::WinGames { target: 1 },
            rewards: vec![
                AchievementReward::Gold { amount: 100 },
                AchievementReward::UnlockCard { card_id: "common_filibuster".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "勝利獎盃".into(),
        },
        AchievementDefinition {
            id: "PLAY_10".into(),
            name: "🏆 常客".into(),
            name_en: "Regular Attendee".into(),
            description: "完成 10 場對局".into(),
            condition: AchievementCondition::PlayGames { target: 10 },
            rewards: vec![
                AchievementReward::Gold { amount: 200 },
                AchievementReward::UnlockCard { card_id: "common_petition".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "議員座椅".into(),
        },
        AchievementDefinition {
            id: "COLLECT_50".into(),
            name: "🏆 收藏入門".into(),
            name_en: "Card Collector".into(),
            description: "收集 50% 的不同卡牌（28 張）".into(),
            condition: AchievementCondition::CollectCards { target: 28 },
            rewards: vec![
                AchievementReward::Gold { amount: 300 },
                AchievementReward::Title { title: "收藏家".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "小型卡冊".into(),
        },
        AchievementDefinition {
            id: "BUILD_DECK".into(),
            name: "🏆 組牌新手".into(),
            name_en: "Deck Builder".into(),
            description: "收集 10 張不同卡牌".into(),
            condition: AchievementCondition::CollectCards { target: 10 },
            rewards: vec![
                AchievementReward::Gold { amount: 100 },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "卡牌堆疊".into(),
        },
        AchievementDefinition {
            id: "FIRST_IAP".into(),
            name: "🏆 贊助者".into(),
            name_en: "Patron".into(),
            description: "完成首次商店購買".into(),
            condition: AchievementCondition::FirstPurchase,
            rewards: vec![
                AchievementReward::Gold { amount: 200 },
                AchievementReward::Title { title: "贊助者".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "金幣袋".into(),
        },
        AchievementDefinition {
            id: "ADD_FRIEND".into(),
            name: "🏆 政治結盟".into(),
            name_en: "Political Alliance".into(),
            description: "首次加入多人房間".into(),
            condition: AchievementCondition::JoinMultiplayer,
            rewards: vec![
                AchievementReward::Gold { amount: 50 },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "握手".into(),
        },
        AchievementDefinition {
            id: "TUTORIAL_DONE".into(),
            name: "🏆 學成出師".into(),
            name_en: "Graduation Day".into(),
            description: "完成新手教學".into(),
            condition: AchievementCondition::CompleteTutorial,
            rewards: vec![
                AchievementReward::Gold { amount: 100 },
                AchievementReward::UnlockCard { card_id: "common_gather_intel".into() },
            ],
            difficulty: AchievementDifficulty::Easy,
            is_hidden: false,
            icon_hint: "畢業帽".into(),
        },

        // ═══════════════════════════════════════════
        // 🟡 中等成就 (9)
        // ═══════════════════════════════════════════
        AchievementDefinition {
            id: "ATTACK_STREAK_5".into(),
            name: "🏆 辯論達人".into(),
            name_en: "Master Debater".into(),
            description: "一場對局中連續出 5 張攻擊牌".into(),
            condition: AchievementCondition::AttackStreak { target: 5 },
            rewards: vec![
                AchievementReward::Gold { amount: 200 },
                AchievementReward::UnlockCard { card_id: "uncommon_propaganda".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "火焰麥克風".into(),
        },
        AchievementDefinition {
            id: "WIN_50".into(),
            name: "🏆 資深議員".into(),
            name_en: "Senior Member".into(),
            description: "贏得 50 場對局".into(),
            condition: AchievementCondition::WinGames { target: 50 },
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::Title { title: "資深議員".into() },
                AchievementReward::UnlockCard { card_id: "rare_blockade".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "銀色議員徽章".into(),
        },
        AchievementDefinition {
            id: "GOLD_10K".into(),
            name: "🏆 金主".into(),
            name_en: "Deep Pockets".into(),
            description: "累積獲得 10,000 金幣".into(),
            condition: AchievementCondition::TotalGold { target: 10000 },
            rewards: vec![
                AchievementReward::Gold { amount: 1000 },
                AchievementReward::UnlockCard { card_id: "uncommon_charity".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "金幣寶箱".into(),
        },
        AchievementDefinition {
            id: "COLLECT_200".into(),
            name: "🏆 卡牌鑑賞家".into(),
            name_en: "Card Connoisseur".into(),
            description: "收集 80% 的不同卡牌（45 張）".into(),
            condition: AchievementCondition::CollectCards { target: 45 },
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::Title { title: "鑑賞家".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "大型卡冊".into(),
        },
        AchievementDefinition {
            id: "PERFECT_VOTE".into(),
            name: "🏆 民意代表".into(),
            name_en: "Voice of the People".into(),
            description: "在投票階段獲得全數支持".into(),
            condition: AchievementCondition::PerfectVote,
            rewards: vec![
                AchievementReward::Gold { amount: 300 },
                AchievementReward::UnlockCard { card_id: "uncommon_royal_favor".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "舉手投票".into(),
        },
        AchievementDefinition {
            id: "WIN_STREAK_5".into(),
            name: "🏆 不敗神話".into(),
            name_en: "Winning Streak".into(),
            description: "連勝 5 場".into(),
            condition: AchievementCondition::WinStreak { target: 5 },
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::UnlockCard { card_id: "rare_no_confidence".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "連續火焰".into(),
        },
        AchievementDefinition {
            id: "ALL_ROLES".into(),
            name: "🏆 百變議員".into(),
            name_en: "Versatile Politician".into(),
            description: "使用所有角色各贏一場".into(),
            condition: AchievementCondition::WinWithAllCharacters,
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::UnlockCard { card_id: "rare_reform_act".into() },
                AchievementReward::Title { title: "百變議員".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "面具集合".into(),
        },
        AchievementDefinition {
            id: "DEFENSE_MASTER".into(),
            name: "🏆 鐵壁防線".into(),
            name_en: "Iron Defense".into(),
            description: "一場對局中成功防禦 10 次攻擊".into(),
            condition: AchievementCondition::DefenseMaster { target: 10 },
            rewards: vec![
                AchievementReward::Gold { amount: 300 },
                AchievementReward::UnlockCard { card_id: "rare_habeas_corpus".into() },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "盾牌".into(),
        },
        AchievementDefinition {
            id: "COMEBACK_WIN".into(),
            name: "🏆 逆轉裁決".into(),
            name_en: "Comeback King".into(),
            description: "在最後一回合逆轉勝".into(),
            condition: AchievementCondition::ComebackWin,
            rewards: vec![
                AchievementReward::Gold { amount: 300 },
            ],
            difficulty: AchievementDifficulty::Medium,
            is_hidden: false,
            icon_hint: "翻轉箭頭".into(),
        },

        // ═══════════════════════════════════════════
        // 🔴 困難成就 (5)
        // ═══════════════════════════════════════════
        AchievementDefinition {
            id: "WIN_100".into(),
            name: "🏆 人民之聲".into(),
            name_en: "Voice of the Nation".into(),
            description: "贏得 100 場對局".into(),
            condition: AchievementCondition::WinGames { target: 100 },
            rewards: vec![
                AchievementReward::Gold { amount: 1000 },
                AchievementReward::Title { title: "人民之聲".into() },
                AchievementReward::UnlockCard { card_id: "legendary_magna_carta".into() },
            ],
            difficulty: AchievementDifficulty::Hard,
            is_hidden: false,
            icon_hint: "金色議員徽章".into(),
        },
        AchievementDefinition {
            id: "WIN_STREAK_10".into(),
            name: "🏆 議會霸主".into(),
            name_en: "Parliament Dominator".into(),
            description: "連勝 10 場".into(),
            condition: AchievementCondition::WinStreak { target: 10 },
            rewards: vec![
                AchievementReward::Gold { amount: 1000 },
                AchievementReward::Title { title: "議會霸主".into() },
            ],
            difficulty: AchievementDifficulty::Hard,
            is_hidden: false,
            icon_hint: "皇冠".into(),
        },
        AchievementDefinition {
            id: "COLLECT_ALL".into(),
            name: "🏆 全卡收藏家".into(),
            name_en: "Complete Collection".into(),
            description: "收集所有 56 張卡牌".into(),
            condition: AchievementCondition::CollectCards { target: 56 },
            rewards: vec![
                AchievementReward::Gold { amount: 2000 },
                AchievementReward::Title { title: "全卡收藏家".into() },
                AchievementReward::UnlockCard { card_id: "legendary_peterloo".into() },
            ],
            difficulty: AchievementDifficulty::Hard,
            is_hidden: false,
            icon_hint: "彩虹卡冊".into(),
        },
        AchievementDefinition {
            id: "GOLD_100K".into(),
            name: "🏆 財閥".into(),
            name_en: "Tycoon".into(),
            description: "累積獲得 100,000 金幣".into(),
            condition: AchievementCondition::TotalGold { target: 100000 },
            rewards: vec![
                AchievementReward::Gold { amount: 5000 },
                AchievementReward::Title { title: "財閥".into() },
            ],
            difficulty: AchievementDifficulty::Hard,
            is_hidden: false,
            icon_hint: "金庫".into(),
        },
        AchievementDefinition {
            id: "TOP_LEADERBOARD".into(),
            name: "🏆 議長".into(),
            name_en: "Speaker of the House".into(),
            description: "登上排行榜第一名".into(),
            condition: AchievementCondition::TopLeaderboard,
            rewards: vec![
                AchievementReward::Gold { amount: 2000 },
                AchievementReward::Title { title: "議長".into() },
            ],
            difficulty: AchievementDifficulty::Hard,
            is_hidden: false,
            icon_hint: "議長木槌".into(),
        },

        // ═══════════════════════════════════════════
        // 🟣 隱藏成就 (3)
        // ═══════════════════════════════════════════
        AchievementDefinition {
            id: "PACIFIST".into(),
            name: "🏆 和平使者".into(),
            name_en: "The Pacifist".into(),
            description: "一場對局中 0 張攻擊牌通關".into(),
            condition: AchievementCondition::Pacifist,
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::UnlockCard { card_id: "uncommon_amnesty".into() },
                AchievementReward::Title { title: "和平使者".into() },
            ],
            difficulty: AchievementDifficulty::Hidden,
            is_hidden: true,
            icon_hint: "和平鴿".into(),
        },
        AchievementDefinition {
            id: "ALL_ATTACK".into(),
            name: "🏆 戰爭狂人".into(),
            name_en: "Warmonger".into(),
            description: "一場對局中只出攻擊牌".into(),
            condition: AchievementCondition::AllAttack,
            rewards: vec![
                AchievementReward::Gold { amount: 500 },
                AchievementReward::UnlockCard { card_id: "rare_political_assassination".into() },
                AchievementReward::Title { title: "戰爭狂人".into() },
            ],
            difficulty: AchievementDifficulty::Hidden,
            is_hidden: true,
            icon_hint: "交叉劍".into(),
        },
        AchievementDefinition {
            id: "EASTER_EGG".into(),
            name: "🏆 歷史學家".into(),
            name_en: "The Historian".into(),
            description: "發現遊戲中的隱藏彩蛋".into(),
            condition: AchievementCondition::EasterEgg,
            rewards: vec![
                AchievementReward::Gold { amount: 1000 },
                AchievementReward::Title { title: "歷史學家".into() },
            ],
            difficulty: AchievementDifficulty::Hidden,
            is_hidden: true,
            icon_hint: "放大鏡".into(),
        },
    ]
}

/// 根據 ID 取得成就定義
pub fn get_achievement(achievement_id: &str) -> Option<AchievementDefinition> {
    get_all_achievements().into_iter().find(|a| a.id == achievement_id)
}

/// 取得成就目標值（用於進度計算）
pub fn get_achievement_target(condition: &AchievementCondition) -> i32 {
    match condition {
        AchievementCondition::PlayGames { target } => *target,
        AchievementCondition::WinGames { target } => *target,
        AchievementCondition::CollectCards { target } => *target,
        AchievementCondition::ReachElo { target } => *target,
        AchievementCondition::WinStreak { target } => *target,
        AchievementCondition::WinWithCharacter { target, .. } => *target,
        AchievementCondition::TotalDamage { target } => *target,
        AchievementCondition::TotalHealing { target } => *target,
        AchievementCondition::TotalGold { target } => *target,
        AchievementCondition::TotalDefense { target } => *target,
        AchievementCondition::AttackStreak { target } => *target,
        AchievementCondition::DefenseMaster { target } => *target,
        // 布林型成就目標為 1
        AchievementCondition::WinWithAllCharacters
        | AchievementCondition::CompleteTutorial
        | AchievementCondition::JoinMultiplayer
        | AchievementCondition::FirstPurchase
        | AchievementCondition::Pacifist
        | AchievementCondition::AllAttack
        | AchievementCondition::EasterEgg
        | AchievementCondition::ComebackWin
        | AchievementCondition::PerfectVote
        | AchievementCondition::TopLeaderboard => 1,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_has_25_achievements() {
        let achievements = get_all_achievements();
        assert_eq!(achievements.len(), 25);
    }

    #[test]
    fn test_unique_ids() {
        let achievements = get_all_achievements();
        let mut ids: Vec<&str> = achievements.iter().map(|a| a.id.as_str()).collect();
        ids.sort();
        ids.dedup();
        assert_eq!(ids.len(), 25, "所有成就 ID 應該唯一");
    }

    #[test]
    fn test_difficulty_distribution() {
        let achievements = get_all_achievements();
        let easy = achievements.iter().filter(|a| a.difficulty == AchievementDifficulty::Easy).count();
        let medium = achievements.iter().filter(|a| a.difficulty == AchievementDifficulty::Medium).count();
        let hard = achievements.iter().filter(|a| a.difficulty == AchievementDifficulty::Hard).count();
        let hidden = achievements.iter().filter(|a| a.difficulty == AchievementDifficulty::Hidden).count();
        assert_eq!(easy, 8, "簡單成就應有 8 個");
        assert_eq!(medium, 9, "中等成就應有 9 個");
        assert_eq!(hard, 5, "困難成就應有 5 個");
        assert_eq!(hidden, 3, "隱藏成就應有 3 個");
    }

    #[test]
    fn test_get_achievement() {
        let a = get_achievement("FIRST_MATCH");
        assert!(a.is_some());
        assert_eq!(a.unwrap().name, "🏆 新手議員");
    }

    #[test]
    fn test_all_have_rewards() {
        let achievements = get_all_achievements();
        for a in &achievements {
            assert!(!a.rewards.is_empty(), "成就 {} 應至少有一個獎勵", a.id);
        }
    }

    #[test]
    fn test_hidden_flag_matches_difficulty() {
        let achievements = get_all_achievements();
        for a in &achievements {
            if a.difficulty == AchievementDifficulty::Hidden {
                assert!(a.is_hidden, "隱藏成就 {} 的 is_hidden 應為 true", a.id);
            }
        }
    }
}
