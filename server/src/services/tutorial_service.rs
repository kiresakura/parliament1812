//! 教學系統服務
//!
//! 5 步驟新手引導，第一次開遊戲自動觸發

use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;

/// 教學步驟總數
pub const TOTAL_TUTORIAL_STEPS: i32 = 5;

// ============================================================
// 教學步驟定義
// ============================================================

/// 教學步驟
#[derive(Debug, Clone, Serialize)]
pub struct TutorialStep {
    pub step: i32,
    pub title: String,
    pub title_en: String,
    pub description: String,
    pub description_en: String,
    pub action_type: TutorialActionType,
    pub highlight_target: Option<String>,
    pub dialogue: Vec<TutorialDialogue>,
}

/// 教學中的動作類型
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TutorialActionType {
    /// 展示 UI 元素
    ShowUi,
    /// 需要玩家出牌
    PlayCard,
    /// 需要玩家投票
    Vote,
    /// 需要玩家使用技能
    UseSkill,
    /// 需要玩家結盟
    FormAlliance,
}

/// 教學對話
#[derive(Debug, Clone, Serialize)]
pub struct TutorialDialogue {
    pub speaker: String,
    pub text: String,
    pub text_en: String,
}

/// 教學進度回應
#[derive(Debug, Serialize)]
pub struct TutorialProgressResponse {
    pub completed: bool,
    pub current_step: i32,
    pub total_steps: i32,
    pub steps: Vec<TutorialStepStatus>,
}

#[derive(Debug, Serialize)]
pub struct TutorialStepStatus {
    pub step: i32,
    pub title: String,
    pub completed: bool,
}

/// 完成步驟請求
#[derive(Debug, Deserialize)]
pub struct CompleteTutorialStepRequest {
    pub step: i32,
}

// ============================================================
// 教學服務
// ============================================================

pub struct TutorialService;

impl TutorialService {
    /// 取得所有教學步驟定義
    pub fn get_tutorial_steps() -> Vec<TutorialStep> {
        vec![
            TutorialStep {
                step: 1,
                title: "歡迎來到國會".to_string(),
                title_en: "Welcome to Parliament".to_string(),
                description: "了解遊戲基本介面與資源系統".to_string(),
                description_en: "Learn the basic interface and resource system".to_string(),
                action_type: TutorialActionType::ShowUi,
                highlight_target: Some("resource_panel".to_string()),
                dialogue: vec![
                    TutorialDialogue {
                        speaker: "旁白".to_string(),
                        text: "歡迎來到 1812 年的英國國會！在這裡，你將扮演一位議員，在政治的漩渦中生存。".to_string(),
                        text_en: "Welcome to the British Parliament of 1812! Here, you'll play as an MP, surviving the political maelstrom.".to_string(),
                    },
                    TutorialDialogue {
                        speaker: "旁白".to_string(),
                        text: "畫面上方是你的三大資源：聲望（❤️）、影響力（⚡）、和金幣（💰）。管理好它們是勝利的關鍵。".to_string(),
                        text_en: "At the top are your three key resources: Reputation (❤️), Influence (⚡), and Gold (💰). Managing them is the key to victory.".to_string(),
                    },
                ],
            },
            TutorialStep {
                step: 2,
                title: "出牌的藝術".to_string(),
                title_en: "The Art of Playing Cards".to_string(),
                description: "學會如何出牌攻擊和防禦".to_string(),
                description_en: "Learn how to play cards for attack and defense".to_string(),
                action_type: TutorialActionType::PlayCard,
                highlight_target: Some("hand_area".to_string()),
                dialogue: vec![
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "你的手牌在畫面下方。每張牌都有不同的效果和消耗。".to_string(),
                        text_en: "Your hand is at the bottom of the screen. Each card has different effects and costs.".to_string(),
                    },
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "現在試試選擇一張攻擊牌（⚔️），對準對手打出去！".to_string(),
                        text_en: "Now try selecting an attack card (⚔️) and play it against your opponent!".to_string(),
                    },
                ],
            },
            TutorialStep {
                step: 3,
                title: "投票的力量".to_string(),
                title_en: "The Power of Voting".to_string(),
                description: "了解投票機制與議案影響".to_string(),
                description_en: "Learn about voting mechanics and bill impacts".to_string(),
                action_type: TutorialActionType::Vote,
                highlight_target: Some("voting_panel".to_string()),
                dialogue: vec![
                    TutorialDialogue {
                        speaker: "議長".to_string(),
                        text: "每回合結束時，議會會對一項議案進行投票。你的投票方向會影響所有人。".to_string(),
                        text_en: "At the end of each round, Parliament votes on a bill. Your vote affects everyone.".to_string(),
                    },
                    TutorialDialogue {
                        speaker: "議長".to_string(),
                        text: "選項 A 偏向勞工、B 偏向資方、C 是溫和改革。選擇對你最有利的！".to_string(),
                        text_en: "Option A favors labor, B favors capital, C is moderate reform. Choose what benefits you most!".to_string(),
                    },
                ],
            },
            TutorialStep {
                step: 4,
                title: "角色技能".to_string(),
                title_en: "Character Skills".to_string(),
                description: "學會使用你的角色專屬技能".to_string(),
                description_en: "Learn to use your character's unique skills".to_string(),
                action_type: TutorialActionType::UseSkill,
                highlight_target: Some("skill_button".to_string()),
                dialogue: vec![
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "每個角色都有獨特技能。工人湯瑪斯可以號召罷工，記者愛德華可以揭發醜聞。".to_string(),
                        text_en: "Each character has unique skills. Worker Thomas can call strikes, Journalist Edward can expose scandals.".to_string(),
                    },
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "技能需要消耗影響力，但效果強大。試試按下技能按鈕！".to_string(),
                        text_en: "Skills cost influence but are powerful. Try pressing the skill button!".to_string(),
                    },
                ],
            },
            TutorialStep {
                step: 5,
                title: "結盟與背叛".to_string(),
                title_en: "Alliances and Betrayal".to_string(),
                description: "學會結盟系統，與人合作或背叛".to_string(),
                description_en: "Learn the alliance system - cooperate or betray".to_string(),
                action_type: TutorialActionType::FormAlliance,
                highlight_target: Some("alliance_button".to_string()),
                dialogue: vec![
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "在密謀階段，你可以向其他議員提出結盟。盟友會在投票時互相幫助。".to_string(),
                        text_en: "During the conspiracy phase, you can propose alliances. Allies help each other during votes.".to_string(),
                    },
                    TutorialDialogue {
                        speaker: "導師".to_string(),
                        text: "但小心——盟友也可能背叛你。在政治中，沒有永遠的朋友。現在試試向 AI 玩家結盟吧！".to_string(),
                        text_en: "But beware — allies can betray you. In politics, there are no permanent friends. Try forming an alliance with an AI player!".to_string(),
                    },
                ],
            },
        ]
    }

    /// 檢查使用者是否已完成教學
    pub async fn is_tutorial_completed(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<bool, AppError> {
        let completed_count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(DISTINCT step)
            FROM tutorial_progress
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(completed_count >= TOTAL_TUTORIAL_STEPS as i64)
    }

    /// 取得教學進度
    pub async fn get_progress(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<TutorialProgressResponse, AppError> {
        let completed_steps = sqlx::query_scalar::<_, i32>(
            r#"
            SELECT step FROM tutorial_progress
            WHERE user_id = $1
            ORDER BY step
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let all_steps = Self::get_tutorial_steps();
        let steps: Vec<TutorialStepStatus> = all_steps
            .iter()
            .map(|s| TutorialStepStatus {
                step: s.step,
                title: s.title.clone(),
                completed: completed_steps.contains(&s.step),
            })
            .collect();

        let completed = completed_steps.len() as i32 >= TOTAL_TUTORIAL_STEPS;
        let current_step = if completed {
            TOTAL_TUTORIAL_STEPS
        } else {
            completed_steps.last().map(|s| s + 1).unwrap_or(1)
        };

        Ok(TutorialProgressResponse {
            completed,
            current_step,
            total_steps: TOTAL_TUTORIAL_STEPS,
            steps,
        })
    }

    /// 完成教學步驟
    pub async fn complete_step(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        step: i32,
    ) -> Result<TutorialProgressResponse, AppError> {
        if !(1..=TOTAL_TUTORIAL_STEPS).contains(&step) {
            return Err(AppError::BadRequest(format!(
                "無效的教學步驟: {}（有效範圍 1-{}）",
                step, TOTAL_TUTORIAL_STEPS
            )));
        }

        // 檢查前一步是否已完成（步驟必須按順序完成）
        if step > 1 {
            let prev_completed = sqlx::query_scalar::<_, bool>(
                r#"
                SELECT EXISTS(
                    SELECT 1 FROM tutorial_progress
                    WHERE user_id = $1 AND step = $2
                )
                "#,
            )
            .bind(user_id)
            .bind(step - 1)
            .fetch_one(pool)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

            if !prev_completed {
                return Err(AppError::BadRequest(format!(
                    "必須先完成步驟 {} 才能進行步驟 {}",
                    step - 1,
                    step
                )));
            }
        }

        // 記錄步驟完成
        sqlx::query(
            r#"
            INSERT INTO tutorial_progress (user_id, step, completed_at)
            VALUES ($1, $2, NOW())
            ON CONFLICT (user_id, step) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(step)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        // 如果完成了所有步驟，給予獎勵
        if step == TOTAL_TUTORIAL_STEPS {
            Self::grant_completion_reward(pool, user_id).await?;
        }

        // 返回更新後的進度
        Self::get_progress(pool, user_id).await
    }

    /// 重置教學（用於測試或重新體驗）
    pub async fn reset_tutorial(pool: &sqlx::PgPool, user_id: Uuid) -> Result<(), AppError> {
        sqlx::query("DELETE FROM tutorial_progress WHERE user_id = $1")
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// 完成教學的獎勵
    async fn grant_completion_reward(pool: &sqlx::PgPool, user_id: Uuid) -> Result<(), AppError> {
        // 獎勵 50 寶石
        sqlx::query("UPDATE users SET gems = COALESCE(gems, 0) + 50 WHERE id = $1")
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        tracing::info!(user_id = %user_id, "教學完成，發放 50 寶石獎勵");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tutorial_has_5_steps() {
        let steps = TutorialService::get_tutorial_steps();
        assert_eq!(steps.len(), TOTAL_TUTORIAL_STEPS as usize);
    }

    #[test]
    fn test_tutorial_steps_ordered() {
        let steps = TutorialService::get_tutorial_steps();
        for (i, step) in steps.iter().enumerate() {
            assert_eq!(step.step, (i + 1) as i32);
        }
    }

    #[test]
    fn test_each_step_has_dialogue() {
        let steps = TutorialService::get_tutorial_steps();
        for step in &steps {
            assert!(
                !step.dialogue.is_empty(),
                "Step {} has no dialogue",
                step.step
            );
        }
    }

    #[test]
    fn test_each_step_has_bilingual_title() {
        let steps = TutorialService::get_tutorial_steps();
        for step in &steps {
            assert!(!step.title.is_empty());
            assert!(!step.title_en.is_empty());
            assert!(!step.description.is_empty());
            assert!(!step.description_en.is_empty());
        }
    }

    #[test]
    fn test_step_action_types() {
        let steps = TutorialService::get_tutorial_steps();
        assert!(matches!(steps[0].action_type, TutorialActionType::ShowUi));
        assert!(matches!(steps[1].action_type, TutorialActionType::PlayCard));
        assert!(matches!(steps[2].action_type, TutorialActionType::Vote));
        assert!(matches!(steps[3].action_type, TutorialActionType::UseSkill));
        assert!(matches!(
            steps[4].action_type,
            TutorialActionType::FormAlliance
        ));
    }

    #[test]
    fn test_total_tutorial_steps_constant() {
        assert_eq!(TOTAL_TUTORIAL_STEPS, 5);
    }
}
