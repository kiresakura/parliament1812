//! 故事戰役系統
//!
//! 5 章節的故事戰役模式，提供漸進式的遊戲體驗

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::ai_engine::AiDifficulty;

/// 章節 ID
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ChapterId {
    /// 第一章：初入議會
    Chapter1,
    /// 第二章：黨派之爭
    Chapter2,
    /// 第三章：預算風暴
    Chapter3,
    /// 第四章：彈劾危機
    Chapter4,
    /// 第五章：最終表決
    Chapter5,
}

impl ChapterId {
    /// 取得所有章節
    pub fn all() -> Vec<ChapterId> {
        vec![
            ChapterId::Chapter1,
            ChapterId::Chapter2,
            ChapterId::Chapter3,
            ChapterId::Chapter4,
            ChapterId::Chapter5,
        ]
    }

    /// 取得章節序號（1-5）
    pub fn number(&self) -> i32 {
        match self {
            ChapterId::Chapter1 => 1,
            ChapterId::Chapter2 => 2,
            ChapterId::Chapter3 => 3,
            ChapterId::Chapter4 => 4,
            ChapterId::Chapter5 => 5,
        }
    }

    /// 從序號取得章節
    pub fn from_number(n: i32) -> Option<ChapterId> {
        match n {
            1 => Some(ChapterId::Chapter1),
            2 => Some(ChapterId::Chapter2),
            3 => Some(ChapterId::Chapter3),
            4 => Some(ChapterId::Chapter4),
            5 => Some(ChapterId::Chapter5),
            _ => None,
        }
    }

    /// 取得下一章節
    pub fn next(&self) -> Option<ChapterId> {
        ChapterId::from_number(self.number() + 1)
    }
}

impl std::fmt::Display for ChapterId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "第{}章", self.number())
    }
}

/// 特殊規則
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SpecialRule {
    /// 無特殊規則
    None,
    /// 限制可用卡牌（移除角色專屬卡）
    LimitedCards,
    /// 較短的計時器
    ShorterTimer,
    /// 額外 AI（2v1）
    ExtraAi,
    /// 特殊事件（隨機觸發）
    SpecialEvents,
}

/// 戰役章節定義
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CampaignChapter {
    /// 章節 ID
    pub id: ChapterId,
    /// 標題
    pub title: String,
    /// 描述
    pub description: String,
    /// AI 難度
    pub difficulty: AiDifficulty,
    /// 特殊規則
    pub special_rules: Vec<SpecialRule>,
    /// AI 對手數量
    pub ai_count: usize,
    /// 過場文字（開始前）
    pub intro_text: String,
    /// 過場文字（完成後）
    pub outro_text: String,
    /// 完成獎勵
    pub rewards: ChapterRewards,
    /// 解鎖條件（需要完成的前置章節）
    pub prerequisite: Option<ChapterId>,
}

/// 章節獎勵
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChapterRewards {
    /// 寶石獎勵
    pub gems: i32,
    /// 稱號獎勵
    pub title: Option<String>,
    /// 額外獎勵描述
    pub bonus_description: Option<String>,
}

/// 戰役進度
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CampaignProgress {
    /// 使用者 ID
    pub user_id: Uuid,
    /// 各章節完成狀態
    pub chapters: Vec<ChapterProgress>,
    /// 總獲得寶石
    pub total_gems: i32,
    /// 已獲得稱號
    pub titles: Vec<String>,
    /// 最後更新時間
    pub updated_at: DateTime<Utc>,
}

/// 單一章節進度
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChapterProgress {
    /// 章節 ID
    pub chapter_id: ChapterId,
    /// 是否已完成
    pub completed: bool,
    /// 最佳得分
    pub best_score: Option<i32>,
    /// 完成時間
    pub completed_at: Option<DateTime<Utc>>,
    /// 完成次數
    pub attempts: i32,
    /// 使用的角色
    pub character_used: Option<crate::domain::CharacterType>,
}

/// 戰役系統
pub struct Campaign;

impl Campaign {
    /// 取得所有章節定義
    pub fn get_chapters() -> Vec<CampaignChapter> {
        vec![
            CampaignChapter {
                id: ChapterId::Chapter1,
                title: "初入議會".to_string(),
                description:
                    "你第一次踏入議會大廳，一切都是新的。\n學習基本的政治運作，結交你的第一個盟友。"
                        .to_string(),
                difficulty: AiDifficulty::Easy,
                special_rules: vec![SpecialRule::None],
                ai_count: 3,
                intro_text: concat!(
                    "1812年，英國議會。\n\n",
                    "工業革命的浪潮席捲全國，新機器取代了手工勞動，\n",
                    "工人們怒火中燒，工廠主們貪婪擴張。\n\n",
                    "你，一個新晉議員，踏入了這座古老的議會大廳。\n",
                    "在這裡，每一句話都是武器，每一票都決定命運。\n\n",
                    "歡迎來到國會風雲。"
                )
                .to_string(),
                outro_text: concat!(
                    "第一場辯論結束了。\n\n",
                    "你學會了在議會中生存的基本法則：\n",
                    "質詢是攻擊，反駁是防禦，結盟是保命。\n\n",
                    "但這只是開始。黨派之爭即將到來..."
                )
                .to_string(),
                rewards: ChapterRewards {
                    gems: 50,
                    title: Some("新手議員".to_string()),
                    bonus_description: None,
                },
                prerequisite: None,
            },
            CampaignChapter {
                id: ChapterId::Chapter2,
                title: "黨派之爭".to_string(),
                description: "議會中的黨派紛爭加劇。\n你只能使用基本卡牌，學會在限制中尋找機會。"
                    .to_string(),
                difficulty: AiDifficulty::Easy, // 開始 Easy，AI 會逐漸變強
                special_rules: vec![SpecialRule::LimitedCards],
                ai_count: 3,
                intro_text: concat!(
                    "議會中的黨派紛爭日益激烈。\n\n",
                    "工人派、資方派、改革派——每個陣營都在爭奪控制權。\n",
                    "而你，還沒有足夠的政治資本使用所有手段。\n\n",
                    "用你手中有限的牌，證明你值得留在這個舞台上。"
                )
                .to_string(),
                outro_text: concat!(
                    "在有限的資源下，你依然取得了勝利。\n\n",
                    "議會中的老油條們開始注意到你了。\n",
                    "接下來的預算辯論將是一場更激烈的風暴..."
                )
                .to_string(),
                rewards: ChapterRewards {
                    gems: 100,
                    title: Some("黨派鬥士".to_string()),
                    bonus_description: Some("解鎖快速匹配中的進階卡牌包".to_string()),
                },
                prerequisite: Some(ChapterId::Chapter1),
            },
            CampaignChapter {
                id: ChapterId::Chapter3,
                title: "預算風暴".to_string(),
                description: "國家預算案引發激烈辯論。\n時間緊迫，你必須在更短的時限內做出決策。"
                    .to_string(),
                difficulty: AiDifficulty::Normal,
                special_rules: vec![SpecialRule::ShorterTimer],
                ai_count: 3,
                intro_text: concat!(
                    "年度預算案擺在議會面前。\n\n",
                    "軍費開支、社會福利、工業補貼——每一項都關係到千萬人的命運。\n",
                    "而時間不等人，預算必須在期限前通過。\n\n",
                    "在壓力下做出正確的決策，這是每個政治家的必修課。"
                )
                .to_string(),
                outro_text: concat!(
                    "預算案在最後一刻通過了。\n\n",
                    "你在時間壓力下依然做出了明智的選擇。\n",
                    "但更大的危機正在醞釀——有人要對你發動彈劾。"
                )
                .to_string(),
                rewards: ChapterRewards {
                    gems: 150,
                    title: Some("預算專家".to_string()),
                    bonus_description: None,
                },
                prerequisite: Some(ChapterId::Chapter2),
            },
            CampaignChapter {
                id: ChapterId::Chapter4,
                title: "彈劾危機".to_string(),
                description: "你面臨彈劾威脅。\n兩個 AI 聯手對付你，你必須在逆境中求生。"
                    .to_string(),
                difficulty: AiDifficulty::Normal,
                special_rules: vec![SpecialRule::ExtraAi],
                ai_count: 3, // 但 2 個 AI 會聯手
                intro_text: concat!(
                    "噩耗傳來。\n\n",
                    "工廠主理查和盧德派喬治——這兩個本應水火不容的勢力，\n",
                    "竟然聯手對你發動了彈劾。\n\n",
                    "以一敵二，你能否在這場政治風暴中存活？"
                )
                .to_string(),
                outro_text: concat!(
                    "彈劾失敗了。\n\n",
                    "你的政治智慧讓對手的聯盟土崩瓦解。\n",
                    "現在，只剩下最後一場戰役——\n",
                    "一場決定整個國家命運的最終表決。"
                )
                .to_string(),
                rewards: ChapterRewards {
                    gems: 200,
                    title: Some("不倒翁".to_string()),
                    bonus_description: Some("解鎖困難模式快速匹配".to_string()),
                },
                prerequisite: Some(ChapterId::Chapter3),
            },
            CampaignChapter {
                id: ChapterId::Chapter5,
                title: "最終表決".to_string(),
                description:
                    "最後的決戰。\n全規則、困難 AI、加上隨機特殊事件。\n這是你的終極挑戰。"
                        .to_string(),
                difficulty: AiDifficulty::Hard,
                special_rules: vec![SpecialRule::SpecialEvents],
                ai_count: 3,
                intro_text: concat!(
                    "一切都在這一刻。\n\n",
                    "《機器法案》的最終表決即將開始。\n",
                    "這一票，將決定工人的未來、工業的走向、整個國家的命運。\n\n",
                    "所有的盟友、所有的敵人、所有的計謀——\n",
                    "都將在這場最終表決中見分曉。\n\n",
                    "準備好了嗎？這是你的最終審判。"
                )
                .to_string(),
                outro_text: concat!(
                    "表決結束了。\n\n",
                    "不論結果如何，你已經證明了自己是議會中最出色的政治家。\n",
                    "你的名字將被記錄在歷史之中。\n\n",
                    "恭喜通關！\n",
                    "1812 國會風雲，完。"
                )
                .to_string(),
                rewards: ChapterRewards {
                    gems: 500,
                    title: Some("議會之王".to_string()),
                    bonus_description: Some("解鎖金色邊框頭像和專屬稱號".to_string()),
                },
                prerequisite: Some(ChapterId::Chapter4),
            },
        ]
    }

    /// 取得指定章節
    pub fn get_chapter(chapter_id: ChapterId) -> Option<CampaignChapter> {
        Self::get_chapters()
            .into_iter()
            .find(|c| c.id == chapter_id)
    }

    /// 建立初始進度
    pub fn new_progress(user_id: Uuid) -> CampaignProgress {
        let chapters = ChapterId::all()
            .into_iter()
            .map(|id| ChapterProgress {
                chapter_id: id,
                completed: false,
                best_score: None,
                completed_at: None,
                attempts: 0,
                character_used: None,
            })
            .collect();

        CampaignProgress {
            user_id,
            chapters,
            total_gems: 0,
            titles: Vec::new(),
            updated_at: Utc::now(),
        }
    }

    /// 檢查章節是否已解鎖
    pub fn is_chapter_unlocked(chapter_id: ChapterId, progress: &CampaignProgress) -> bool {
        let chapter = match Self::get_chapter(chapter_id) {
            Some(c) => c,
            None => return false,
        };

        // 第一章永遠解鎖
        match chapter.prerequisite {
            None => true,
            Some(prereq) => progress
                .chapters
                .iter()
                .any(|cp| cp.chapter_id == prereq && cp.completed),
        }
    }

    /// 完成章節，更新進度
    pub fn complete_chapter(
        progress: &mut CampaignProgress,
        chapter_id: ChapterId,
        score: i32,
        character: crate::domain::CharacterType,
    ) -> ChapterRewards {
        let chapter = Self::get_chapter(chapter_id).unwrap();

        if let Some(cp) = progress
            .chapters
            .iter_mut()
            .find(|cp| cp.chapter_id == chapter_id)
        {
            cp.attempts += 1;

            let is_first_clear = !cp.completed;

            cp.completed = true;
            cp.completed_at = Some(Utc::now());
            cp.character_used = Some(character);

            if cp.best_score.is_none_or(|best| score > best) {
                cp.best_score = Some(score);
            }

            // 只有首次通關才給獎勵
            if is_first_clear {
                progress.total_gems += chapter.rewards.gems;
                if let Some(ref title) = chapter.rewards.title {
                    progress.titles.push(title.clone());
                }
            }
        }

        progress.updated_at = Utc::now();
        chapter.rewards
    }

    /// 取得戰役摘要
    pub fn get_campaign_summary(progress: &CampaignProgress) -> CampaignSummary {
        let total_chapters = ChapterId::all().len();
        let completed_chapters = progress.chapters.iter().filter(|cp| cp.completed).count();
        let total_attempts: i32 = progress.chapters.iter().map(|cp| cp.attempts).sum();

        CampaignSummary {
            total_chapters,
            completed_chapters,
            completion_percentage: (completed_chapters as f64 / total_chapters as f64 * 100.0)
                as i32,
            total_gems: progress.total_gems,
            titles_earned: progress.titles.len(),
            total_attempts,
            is_completed: completed_chapters == total_chapters,
        }
    }
}

/// 戰役摘要
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CampaignSummary {
    pub total_chapters: usize,
    pub completed_chapters: usize,
    pub completion_percentage: i32,
    pub total_gems: i32,
    pub titles_earned: usize,
    pub total_attempts: i32,
    pub is_completed: bool,
}

/// 章節狀態（供客戶端顯示）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChapterStatus {
    pub chapter: CampaignChapter,
    pub is_unlocked: bool,
    pub is_completed: bool,
    pub best_score: Option<i32>,
    pub attempts: i32,
}

impl Campaign {
    /// 取得所有章節的狀態（包含進度資訊）
    pub fn get_chapter_statuses(progress: &CampaignProgress) -> Vec<ChapterStatus> {
        Self::get_chapters()
            .into_iter()
            .map(|chapter| {
                let cp = progress
                    .chapters
                    .iter()
                    .find(|cp| cp.chapter_id == chapter.id);
                let is_unlocked = Self::is_chapter_unlocked(chapter.id, progress);

                ChapterStatus {
                    chapter,
                    is_unlocked,
                    is_completed: cp.is_some_and(|cp| cp.completed),
                    best_score: cp.and_then(|cp| cp.best_score),
                    attempts: cp.map_or(0, |cp| cp.attempts),
                }
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chapter_id_ordering() {
        assert_eq!(ChapterId::Chapter1.number(), 1);
        assert_eq!(ChapterId::Chapter5.number(), 5);
    }

    #[test]
    fn test_chapter_id_from_number() {
        assert_eq!(ChapterId::from_number(1), Some(ChapterId::Chapter1));
        assert_eq!(ChapterId::from_number(5), Some(ChapterId::Chapter5));
        assert_eq!(ChapterId::from_number(0), None);
        assert_eq!(ChapterId::from_number(6), None);
    }

    #[test]
    fn test_chapter_id_next() {
        assert_eq!(ChapterId::Chapter1.next(), Some(ChapterId::Chapter2));
        assert_eq!(ChapterId::Chapter4.next(), Some(ChapterId::Chapter5));
        assert_eq!(ChapterId::Chapter5.next(), None);
    }

    #[test]
    fn test_chapter_id_display() {
        assert_eq!(format!("{}", ChapterId::Chapter1), "第1章");
        assert_eq!(format!("{}", ChapterId::Chapter5), "第5章");
    }

    #[test]
    fn test_get_all_chapters() {
        let chapters = Campaign::get_chapters();
        assert_eq!(chapters.len(), 5);

        assert_eq!(chapters[0].title, "初入議會");
        assert_eq!(chapters[1].title, "黨派之爭");
        assert_eq!(chapters[2].title, "預算風暴");
        assert_eq!(chapters[3].title, "彈劾危機");
        assert_eq!(chapters[4].title, "最終表決");
    }

    #[test]
    fn test_chapter_difficulties() {
        let chapters = Campaign::get_chapters();
        assert_eq!(chapters[0].difficulty, AiDifficulty::Easy);
        assert_eq!(chapters[1].difficulty, AiDifficulty::Easy);
        assert_eq!(chapters[2].difficulty, AiDifficulty::Normal);
        assert_eq!(chapters[3].difficulty, AiDifficulty::Normal);
        assert_eq!(chapters[4].difficulty, AiDifficulty::Hard);
    }

    #[test]
    fn test_chapter_special_rules() {
        let chapters = Campaign::get_chapters();
        assert!(chapters[0].special_rules.contains(&SpecialRule::None));
        assert!(chapters[1]
            .special_rules
            .contains(&SpecialRule::LimitedCards));
        assert!(chapters[2]
            .special_rules
            .contains(&SpecialRule::ShorterTimer));
        assert!(chapters[3].special_rules.contains(&SpecialRule::ExtraAi));
        assert!(chapters[4]
            .special_rules
            .contains(&SpecialRule::SpecialEvents));
    }

    #[test]
    fn test_chapter_prerequisites() {
        let chapters = Campaign::get_chapters();
        assert_eq!(chapters[0].prerequisite, None);
        assert_eq!(chapters[1].prerequisite, Some(ChapterId::Chapter1));
        assert_eq!(chapters[2].prerequisite, Some(ChapterId::Chapter2));
        assert_eq!(chapters[3].prerequisite, Some(ChapterId::Chapter3));
        assert_eq!(chapters[4].prerequisite, Some(ChapterId::Chapter4));
    }

    #[test]
    fn test_chapter_rewards() {
        let chapters = Campaign::get_chapters();
        assert_eq!(chapters[0].rewards.gems, 50);
        assert_eq!(chapters[1].rewards.gems, 100);
        assert_eq!(chapters[2].rewards.gems, 150);
        assert_eq!(chapters[3].rewards.gems, 200);
        assert_eq!(chapters[4].rewards.gems, 500);
    }

    #[test]
    fn test_new_progress() {
        let user_id = Uuid::new_v4();
        let progress = Campaign::new_progress(user_id);

        assert_eq!(progress.user_id, user_id);
        assert_eq!(progress.chapters.len(), 5);
        assert_eq!(progress.total_gems, 0);
        assert!(progress.titles.is_empty());

        for cp in &progress.chapters {
            assert!(!cp.completed);
            assert_eq!(cp.attempts, 0);
        }
    }

    #[test]
    fn test_chapter_unlock_first() {
        let user_id = Uuid::new_v4();
        let progress = Campaign::new_progress(user_id);

        // 第一章永遠解鎖
        assert!(Campaign::is_chapter_unlocked(
            ChapterId::Chapter1,
            &progress
        ));
        // 第二章需要完成第一章
        assert!(!Campaign::is_chapter_unlocked(
            ChapterId::Chapter2,
            &progress
        ));
    }

    #[test]
    fn test_chapter_unlock_progression() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        // 完成第一章
        Campaign::complete_chapter(
            &mut progress,
            ChapterId::Chapter1,
            100,
            crate::domain::CharacterType::Thomas,
        );

        assert!(Campaign::is_chapter_unlocked(
            ChapterId::Chapter1,
            &progress
        ));
        assert!(Campaign::is_chapter_unlocked(
            ChapterId::Chapter2,
            &progress
        ));
        assert!(!Campaign::is_chapter_unlocked(
            ChapterId::Chapter3,
            &progress
        ));
    }

    #[test]
    fn test_complete_chapter() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        let rewards = Campaign::complete_chapter(
            &mut progress,
            ChapterId::Chapter1,
            100,
            crate::domain::CharacterType::Thomas,
        );

        assert_eq!(rewards.gems, 50);
        assert_eq!(rewards.title, Some("新手議員".to_string()));

        let cp = progress
            .chapters
            .iter()
            .find(|cp| cp.chapter_id == ChapterId::Chapter1)
            .unwrap();
        assert!(cp.completed);
        assert_eq!(cp.best_score, Some(100));
        assert_eq!(cp.attempts, 1);
        assert_eq!(
            cp.character_used,
            Some(crate::domain::CharacterType::Thomas)
        );

        assert_eq!(progress.total_gems, 50);
        assert!(progress.titles.contains(&"新手議員".to_string()));
    }

    #[test]
    fn test_complete_chapter_twice() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        // 第一次完成
        Campaign::complete_chapter(
            &mut progress,
            ChapterId::Chapter1,
            80,
            crate::domain::CharacterType::Thomas,
        );
        assert_eq!(progress.total_gems, 50);

        // 第二次完成（更高分）—— 不重複給獎勵
        Campaign::complete_chapter(
            &mut progress,
            ChapterId::Chapter1,
            120,
            crate::domain::CharacterType::Richard,
        );
        assert_eq!(progress.total_gems, 50); // 寶石不重複

        let cp = progress
            .chapters
            .iter()
            .find(|cp| cp.chapter_id == ChapterId::Chapter1)
            .unwrap();
        assert_eq!(cp.best_score, Some(120)); // 但最佳分數更新了
        assert_eq!(cp.attempts, 2);
    }

    #[test]
    fn test_campaign_summary() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        let summary = Campaign::get_campaign_summary(&progress);
        assert_eq!(summary.total_chapters, 5);
        assert_eq!(summary.completed_chapters, 0);
        assert_eq!(summary.completion_percentage, 0);
        assert!(!summary.is_completed);

        // 完成所有章節
        for chapter_id in ChapterId::all() {
            Campaign::complete_chapter(
                &mut progress,
                chapter_id,
                100,
                crate::domain::CharacterType::Thomas,
            );
        }

        let summary = Campaign::get_campaign_summary(&progress);
        assert_eq!(summary.completed_chapters, 5);
        assert_eq!(summary.completion_percentage, 100);
        assert!(summary.is_completed);
        assert_eq!(summary.total_gems, 50 + 100 + 150 + 200 + 500);
    }

    #[test]
    fn test_chapter_statuses() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        Campaign::complete_chapter(
            &mut progress,
            ChapterId::Chapter1,
            100,
            crate::domain::CharacterType::Thomas,
        );

        let statuses = Campaign::get_chapter_statuses(&progress);
        assert_eq!(statuses.len(), 5);

        // 第一章：已解鎖，已完成
        assert!(statuses[0].is_unlocked);
        assert!(statuses[0].is_completed);
        assert_eq!(statuses[0].best_score, Some(100));

        // 第二章：已解鎖（前置完成），未完成
        assert!(statuses[1].is_unlocked);
        assert!(!statuses[1].is_completed);

        // 第三章：未解鎖
        assert!(!statuses[2].is_unlocked);
        assert!(!statuses[2].is_completed);
    }

    #[test]
    fn test_get_chapter() {
        let ch1 = Campaign::get_chapter(ChapterId::Chapter1);
        assert!(ch1.is_some());
        assert_eq!(ch1.unwrap().title, "初入議會");

        let ch5 = Campaign::get_chapter(ChapterId::Chapter5);
        assert!(ch5.is_some());
        assert_eq!(ch5.unwrap().title, "最終表決");
    }

    #[test]
    fn test_full_campaign_flow() {
        let user_id = Uuid::new_v4();
        let mut progress = Campaign::new_progress(user_id);

        // 按順序完成所有章節
        for chapter_id in ChapterId::all() {
            assert!(Campaign::is_chapter_unlocked(chapter_id, &progress));

            let chapter = Campaign::get_chapter(chapter_id).unwrap();
            let rewards = Campaign::complete_chapter(
                &mut progress,
                chapter_id,
                100,
                crate::domain::CharacterType::Thomas,
            );

            assert_eq!(rewards.gems, chapter.rewards.gems);
        }

        let summary = Campaign::get_campaign_summary(&progress);
        assert!(summary.is_completed);
        assert_eq!(summary.titles_earned, 5);
    }

    #[test]
    fn test_chapter_intro_outro_text() {
        for chapter in Campaign::get_chapters() {
            assert!(
                !chapter.intro_text.is_empty(),
                "章節 {} 應該有開場文字",
                chapter.title
            );
            assert!(
                !chapter.outro_text.is_empty(),
                "章節 {} 應該有結束文字",
                chapter.title
            );
        }
    }

    #[test]
    fn test_all_chapter_ids() {
        let all = ChapterId::all();
        assert_eq!(all.len(), 5);
        assert_eq!(all[0], ChapterId::Chapter1);
        assert_eq!(all[4], ChapterId::Chapter5);
    }
}
