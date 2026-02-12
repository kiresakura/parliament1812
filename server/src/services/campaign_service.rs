//! 故事戰役服務
//!
//! 管理 5 章節的故事戰役模式
//! - Chapter 1: 免費
//! - Chapter 2-5: 需要付費解鎖或用寶石解鎖

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;
use crate::services::iap_service::IapService;

/// 寶石解鎖每章的費用
pub const GEMS_PER_CHAPTER_UNLOCK: i64 = 200;

/// 總章節數
pub const TOTAL_CHAPTERS: i32 = 5;

/// 每章的關卡數
pub const STAGES_PER_CHAPTER: i32 = 5;

// ============================================================
// 章節定義
// ============================================================

/// 章節資訊
#[derive(Debug, Clone, Serialize)]
pub struct ChapterInfo {
    pub chapter: i32,
    pub title: String,
    pub title_en: String,
    pub description: String,
    pub description_en: String,
    pub stages: Vec<StageInfo>,
    pub is_free: bool,
    pub gem_cost: i64,
}

/// 關卡資訊
#[derive(Debug, Clone, Serialize)]
pub struct StageInfo {
    pub stage: i32,
    pub title: String,
    pub title_en: String,
    pub objective: String,
    pub difficulty: String,
    pub rewards: StageRewards,
}

/// 關卡獎勵
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StageRewards {
    pub gems: i64,
    pub experience: i32,
    pub card_unlock: Option<String>,
}

/// 使用者的戰役進度
#[derive(Debug, Serialize)]
pub struct CampaignProgressResponse {
    pub chapters: Vec<ChapterProgressEntry>,
    pub total_stars: i32,
    pub max_stars: i32,
}

#[derive(Debug, Serialize)]
pub struct ChapterProgressEntry {
    pub chapter: i32,
    pub title: String,
    pub is_unlocked: bool,
    pub is_free: bool,
    pub stages_completed: i32,
    pub total_stages: i32,
    pub stars: i32,
    pub max_stars: i32,
}

/// 關卡完成請求
#[derive(Debug, Deserialize)]
pub struct CompleteStageRequest {
    pub chapter: i32,
    pub stage: i32,
    pub stars: i32, // 1-3
    pub score: i32,
}

/// 關卡完成回應
#[derive(Debug, Serialize)]
pub struct CompleteStageResponse {
    pub success: bool,
    pub rewards: StageRewards,
    pub new_gem_balance: i64,
    pub is_new_record: bool,
    pub next_stage: Option<NextStageInfo>,
}

#[derive(Debug, Serialize)]
pub struct NextStageInfo {
    pub chapter: i32,
    pub stage: i32,
    pub needs_unlock: bool,
}

/// 章節解鎖請求
#[derive(Debug, Deserialize)]
pub struct UnlockChapterRequest {
    pub chapter: i32,
    /// 使用寶石解鎖（如果 false，則需要已通過 IAP 購買）
    pub use_gems: bool,
}

/// 章節解鎖回應
#[derive(Debug, Serialize)]
pub struct UnlockChapterResponse {
    pub success: bool,
    pub chapter: i32,
    pub remaining_gems: Option<i64>,
}

// ============================================================
// 戰役服務
// ============================================================

pub struct CampaignService;

impl CampaignService {
    /// 取得所有章節資訊
    pub fn get_all_chapters() -> Vec<ChapterInfo> {
        vec![
            ChapterInfo {
                chapter: 1,
                title: "風暴前夕".to_string(),
                title_en: "Before the Storm".to_string(),
                description: "1812年，工業革命的浪潮席捲英國。你作為一名新進議員，必須在各方勢力中站穩腳跟。".to_string(),
                description_en: "1812, the tide of the Industrial Revolution sweeps across Britain. As a newly elected MP, you must find your footing among competing factions.".to_string(),
                stages: Self::chapter_1_stages(),
                is_free: true,
                gem_cost: 0,
            },
            ChapterInfo {
                chapter: 2,
                title: "盧德之怒".to_string(),
                title_en: "Wrath of the Luddites".to_string(),
                description: "盧德運動愈演愈烈，工廠遭到破壞。你必須在工人權益與工業進步之間找到平衡。".to_string(),
                description_en: "The Luddite movement intensifies, factories are under attack. You must balance workers' rights with industrial progress.".to_string(),
                stages: Self::chapter_2_stages(),
                is_free: false,
                gem_cost: GEMS_PER_CHAPTER_UNLOCK,
            },
            ChapterInfo {
                chapter: 3,
                title: "國會暗流".to_string(),
                title_en: "Currents in Parliament".to_string(),
                description: "議會內部的權力鬥爭加劇。托利黨和輝格黨的對立讓每一次投票都充滿變數。".to_string(),
                description_en: "Power struggles within Parliament intensify. The Tory-Whig rivalry makes every vote unpredictable.".to_string(),
                stages: Self::chapter_3_stages(),
                is_free: false,
                gem_cost: GEMS_PER_CHAPTER_UNLOCK,
            },
            ChapterInfo {
                chapter: 4,
                title: "改革之路".to_string(),
                title_en: "Path to Reform".to_string(),
                description: "改革的呼聲越來越高。面對頑固的既得利益者，你需要巧妙運用每一張牌。".to_string(),
                description_en: "Calls for reform grow louder. Facing entrenched interests, you must play every card wisely.".to_string(),
                stages: Self::chapter_4_stages(),
                is_free: false,
                gem_cost: GEMS_PER_CHAPTER_UNLOCK,
            },
            ChapterInfo {
                chapter: 5,
                title: "決戰國會".to_string(),
                title_en: "The Final Vote".to_string(),
                description: "一切在這裡決定。你的選擇將決定整個國家的命運。這是你最後的機會。".to_string(),
                description_en: "Everything comes down to this. Your choices will determine the fate of the nation. This is your final chance.".to_string(),
                stages: Self::chapter_5_stages(),
                is_free: false,
                gem_cost: GEMS_PER_CHAPTER_UNLOCK,
            },
        ]
    }

    /// 取得使用者的戰役進度
    pub async fn get_progress(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<CampaignProgressResponse, AppError> {
        // 取得已解鎖的章節
        let unlocked = Self::get_unlocked_chapters(pool, user_id).await?;

        // 取得各關卡進度
        let stage_progress = Self::get_stage_progress(pool, user_id).await?;

        let chapters = Self::get_all_chapters();
        let mut entries = Vec::new();
        let mut total_stars = 0;
        let max_stars = TOTAL_CHAPTERS * STAGES_PER_CHAPTER * 3;

        for chapter in &chapters {
            let is_unlocked = chapter.is_free || unlocked.contains(&chapter.chapter);

            let chapter_stages: Vec<&StageProgress> = stage_progress
                .iter()
                .filter(|s| s.chapter == chapter.chapter)
                .collect();

            let stages_completed = chapter_stages.len() as i32;
            let chapter_stars: i32 = chapter_stages.iter().map(|s| s.stars).sum();
            let chapter_max_stars = STAGES_PER_CHAPTER * 3;

            total_stars += chapter_stars;

            entries.push(ChapterProgressEntry {
                chapter: chapter.chapter,
                title: chapter.title.clone(),
                is_unlocked,
                is_free: chapter.is_free,
                stages_completed,
                total_stages: STAGES_PER_CHAPTER,
                stars: chapter_stars,
                max_stars: chapter_max_stars,
            });
        }

        Ok(CampaignProgressResponse {
            chapters: entries,
            total_stars,
            max_stars,
        })
    }

    /// 完成關卡
    pub async fn complete_stage(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        request: &CompleteStageRequest,
    ) -> Result<CompleteStageResponse, AppError> {
        // 驗證章節和關卡
        if request.chapter < 1 || request.chapter > TOTAL_CHAPTERS {
            return Err(AppError::BadRequest(format!(
                "無效的章節: {}",
                request.chapter
            )));
        }
        if request.stage < 1 || request.stage > STAGES_PER_CHAPTER {
            return Err(AppError::BadRequest(format!(
                "無效的關卡: {}",
                request.stage
            )));
        }
        if request.stars < 1 || request.stars > 3 {
            return Err(AppError::BadRequest(format!(
                "星數必須在 1-3 之間，收到: {}",
                request.stars
            )));
        }

        // 檢查章節是否已解鎖
        if request.chapter > 1 {
            let unlocked = Self::get_unlocked_chapters(pool, user_id).await?;
            if !unlocked.contains(&request.chapter) {
                return Err(AppError::Forbidden(format!(
                    "章節 {} 尚未解鎖",
                    request.chapter
                )));
            }
        }

        // 檢查前一關是否已通過（除了第一關）
        if request.stage > 1 {
            let prev =
                Self::get_stage_record(pool, user_id, request.chapter, request.stage - 1).await?;
            if prev.is_none() {
                return Err(AppError::BadRequest(format!(
                    "必須先通過第 {} 章第 {} 關",
                    request.chapter,
                    request.stage - 1
                )));
            }
        }

        // 取得現有記錄
        let existing =
            Self::get_stage_record(pool, user_id, request.chapter, request.stage).await?;
        let is_new_record = existing
            .as_ref()
            .map(|e| request.stars > e.stars || request.score > e.score)
            .unwrap_or(true);

        // 更新或建立記錄
        sqlx::query(
            r#"
            INSERT INTO campaign_progress (user_id, chapter, stage, stars, score, completed_at)
            VALUES ($1, $2, $3, $4, $5, NOW())
            ON CONFLICT (user_id, chapter, stage)
            DO UPDATE SET
                stars = GREATEST(campaign_progress.stars, $4),
                score = GREATEST(campaign_progress.score, $5),
                completed_at = NOW()
            "#,
        )
        .bind(user_id)
        .bind(request.chapter)
        .bind(request.stage)
        .bind(request.stars)
        .bind(request.score)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        // 計算獎勵（僅首次通過或提升星數時發放）
        let rewards = Self::calculate_stage_rewards(request.chapter, request.stage);

        // 首次通關才發放寶石獎勵
        if existing.is_none() && rewards.gems > 0 {
            sqlx::query("UPDATE users SET gems = COALESCE(gems, 0) + $1 WHERE id = $2")
                .bind(rewards.gems)
                .bind(user_id)
                .execute(pool)
                .await
                .map_err(|e| AppError::DatabaseError(e.to_string()))?;
        }

        let new_gem_balance = IapService::get_gem_balance(pool, user_id).await?;

        // 計算下一關
        let next_stage = if request.stage < STAGES_PER_CHAPTER {
            Some(NextStageInfo {
                chapter: request.chapter,
                stage: request.stage + 1,
                needs_unlock: false,
            })
        } else if request.chapter < TOTAL_CHAPTERS {
            let next_chapter = request.chapter + 1;
            let unlocked = Self::get_unlocked_chapters(pool, user_id).await?;
            Some(NextStageInfo {
                chapter: next_chapter,
                stage: 1,
                needs_unlock: !unlocked.contains(&next_chapter),
            })
        } else {
            None // 已全部通關
        };

        Ok(CompleteStageResponse {
            success: true,
            rewards,
            new_gem_balance,
            is_new_record,
            next_stage,
        })
    }

    /// 用寶石解鎖章節
    pub async fn unlock_chapter(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        request: &UnlockChapterRequest,
    ) -> Result<UnlockChapterResponse, AppError> {
        if request.chapter < 2 || request.chapter > TOTAL_CHAPTERS {
            return Err(AppError::BadRequest(format!(
                "無效的章節: {}（第 1 章免費，可解鎖 2-5）",
                request.chapter
            )));
        }

        // 檢查是否已解鎖
        let unlocked = Self::get_unlocked_chapters(pool, user_id).await?;
        if unlocked.contains(&request.chapter) {
            return Err(AppError::BadRequest(format!(
                "章節 {} 已解鎖",
                request.chapter
            )));
        }

        // 檢查前一章是否已完成至少一關
        if request.chapter > 2 {
            let prev_progress =
                Self::get_chapter_progress(pool, user_id, request.chapter - 1).await?;
            if prev_progress.is_empty() {
                return Err(AppError::BadRequest(format!(
                    "必須先通過第 {} 章至少一關才能解鎖第 {} 章",
                    request.chapter - 1,
                    request.chapter
                )));
            }
        }

        let remaining_gems = if request.use_gems {
            // 用寶石解鎖
            let remaining = IapService::spend_gems(
                pool,
                user_id,
                GEMS_PER_CHAPTER_UNLOCK,
                &format!("解鎖戰役第 {} 章", request.chapter),
            )
            .await?;

            // 記錄解鎖
            Self::record_unlock(pool, user_id, request.chapter).await?;

            Some(remaining)
        } else {
            // 通過 IAP 購買（檢查是否已購買）
            let purchased = Self::check_iap_unlock(pool, user_id, request.chapter).await?;
            if !purchased {
                return Err(AppError::BadRequest(
                    "尚未購買此章節解鎖。請先完成購買或使用寶石解鎖。".to_string(),
                ));
            }

            Self::record_unlock(pool, user_id, request.chapter).await?;
            None
        };

        Ok(UnlockChapterResponse {
            success: true,
            chapter: request.chapter,
            remaining_gems,
        })
    }

    /// 取得單個章節的資訊
    pub async fn get_chapter_detail(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        chapter: i32,
    ) -> Result<ChapterDetailResponse, AppError> {
        if !(1..=TOTAL_CHAPTERS).contains(&chapter) {
            return Err(AppError::NotFound(format!("章節 {} 不存在", chapter)));
        }

        let chapters = Self::get_all_chapters();
        let chapter_info = &chapters[(chapter - 1) as usize];

        let unlocked = Self::get_unlocked_chapters(pool, user_id).await?;
        let is_unlocked = chapter_info.is_free || unlocked.contains(&chapter);

        let progress = Self::get_chapter_progress(pool, user_id, chapter).await?;

        let stages_detail: Vec<StageDetailEntry> = chapter_info
            .stages
            .iter()
            .map(|s| {
                let stage_progress = progress.iter().find(|p| p.stage == s.stage);
                StageDetailEntry {
                    stage: s.stage,
                    title: s.title.clone(),
                    objective: s.objective.clone(),
                    difficulty: s.difficulty.clone(),
                    rewards: s.rewards.clone(),
                    is_completed: stage_progress.is_some(),
                    best_stars: stage_progress.map(|p| p.stars).unwrap_or(0),
                    best_score: stage_progress.map(|p| p.score).unwrap_or(0),
                }
            })
            .collect();

        Ok(ChapterDetailResponse {
            chapter: chapter_info.chapter,
            title: chapter_info.title.clone(),
            title_en: chapter_info.title_en.clone(),
            description: chapter_info.description.clone(),
            description_en: chapter_info.description_en.clone(),
            is_unlocked,
            is_free: chapter_info.is_free,
            gem_cost: chapter_info.gem_cost,
            stages: stages_detail,
        })
    }

    // ==================== 內部方法 ====================

    fn chapter_1_stages() -> Vec<StageInfo> {
        vec![
            StageInfo {
                stage: 1,
                title: "初入議會".to_string(),
                title_en: "First Day in Parliament".to_string(),
                objective: "學會基本操作：出牌、投票、使用技能".to_string(),
                difficulty: "tutorial".to_string(),
                rewards: StageRewards {
                    gems: 20,
                    experience: 50,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 2,
                title: "新手之聲".to_string(),
                title_en: "A Newcomer's Voice".to_string(),
                objective: "在辯論中取得 3 次質詢成功".to_string(),
                difficulty: "easy".to_string(),
                rewards: StageRewards {
                    gems: 25,
                    experience: 75,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 3,
                title: "結盟試煉".to_string(),
                title_en: "Alliance Trial".to_string(),
                objective: "成功結盟並通過投票".to_string(),
                difficulty: "easy".to_string(),
                rewards: StageRewards {
                    gems: 30,
                    experience: 100,
                    card_unlock: Some("propaganda".to_string()),
                },
            },
            StageInfo {
                stage: 4,
                title: "工廠風波".to_string(),
                title_en: "Factory Troubles".to_string(),
                objective: "在工廠議案中勝出（對手：Richard）".to_string(),
                difficulty: "medium".to_string(),
                rewards: StageRewards {
                    gems: 35,
                    experience: 125,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 5,
                title: "首場大戰".to_string(),
                title_en: "First Grand Battle".to_string(),
                objective: "4 人對戰中排名前 2".to_string(),
                difficulty: "medium".to_string(),
                rewards: StageRewards {
                    gems: 50,
                    experience: 200,
                    card_unlock: Some("backroom_deal".to_string()),
                },
            },
        ]
    }

    fn chapter_2_stages() -> Vec<StageInfo> {
        vec![
            StageInfo {
                stage: 1,
                title: "盧德起義".to_string(),
                title_en: "Luddite Uprising".to_string(),
                objective: "擊敗盧德派首領 George".to_string(),
                difficulty: "medium".to_string(),
                rewards: StageRewards {
                    gems: 30,
                    experience: 150,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 2,
                title: "工人的呼聲".to_string(),
                title_en: "Workers' Cry".to_string(),
                objective: "在投票中為工人爭取到權益".to_string(),
                difficulty: "medium".to_string(),
                rewards: StageRewards {
                    gems: 35,
                    experience: 175,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 3,
                title: "暗夜行動".to_string(),
                title_en: "Night Operation".to_string(),
                objective: "使用情報卡揭發對手的計畫".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 40,
                    experience: 200,
                    card_unlock: Some("spy_network".to_string()),
                },
            },
            StageInfo {
                stage: 4,
                title: "雙面間諜".to_string(),
                title_en: "Double Agent".to_string(),
                objective: "先結盟再背叛，同時保持聲望 > 50".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 45,
                    experience: 225,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 5,
                title: "盧德審判".to_string(),
                title_en: "Luddite Trial".to_string(),
                objective: "在審判議案中獲勝並保住所有盟友".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 60,
                    experience: 300,
                    card_unlock: Some("royal_decree".to_string()),
                },
            },
        ]
    }

    fn chapter_3_stages() -> Vec<StageInfo> {
        vec![
            StageInfo {
                stage: 1,
                title: "黨派之爭".to_string(),
                title_en: "Party Rivalry".to_string(),
                objective: "在黨派對立中生存 5 回合".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 35,
                    experience: 200,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 2,
                title: "密室交易".to_string(),
                title_en: "Backroom Deals".to_string(),
                objective: "使用 3 張社交卡牌完成交易".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 40,
                    experience: 225,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 3,
                title: "輿論風暴".to_string(),
                title_en: "Media Storm".to_string(),
                objective: "使用記者 Edward 的技能改變投票結果".to_string(),
                difficulty: "hard".to_string(),
                rewards: StageRewards {
                    gems: 45,
                    experience: 250,
                    card_unlock: Some("press_conference".to_string()),
                },
            },
            StageInfo {
                stage: 4,
                title: "信任危機".to_string(),
                title_en: "Crisis of Trust".to_string(),
                objective: "在所有盟友背叛後仍獲得勝利".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 50,
                    experience: 275,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 5,
                title: "國會之夜".to_string(),
                title_en: "Parliament Night".to_string(),
                objective: "在限時辯論中擊敗 William 議員".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 70,
                    experience: 350,
                    card_unlock: Some("filibuster".to_string()),
                },
            },
        ]
    }

    fn chapter_4_stages() -> Vec<StageInfo> {
        vec![
            StageInfo {
                stage: 1,
                title: "改革先鋒".to_string(),
                title_en: "Reform Vanguard".to_string(),
                objective: "連續通過 3 個改革議案".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 40,
                    experience: 250,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 2,
                title: "反對之聲".to_string(),
                title_en: "Voice of Opposition".to_string(),
                objective: "在 Expert AI 的阻撓下通過議案".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 45,
                    experience: 275,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 3,
                title: "三方角力".to_string(),
                title_en: "Three-Way Struggle".to_string(),
                objective: "在三個陣營的角力中勝出".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 50,
                    experience: 300,
                    card_unlock: Some("coalition".to_string()),
                },
            },
            StageInfo {
                stage: 4,
                title: "皇家介入".to_string(),
                title_en: "Royal Intervention".to_string(),
                objective: "面對國王 George 的干預仍取得勝利".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 55,
                    experience: 325,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 5,
                title: "改革法案".to_string(),
                title_en: "The Reform Act".to_string(),
                objective: "以超過 60% 的支持率通過改革法案".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 80,
                    experience: 400,
                    card_unlock: Some("peoples_champion".to_string()),
                },
            },
        ]
    }

    fn chapter_5_stages() -> Vec<StageInfo> {
        vec![
            StageInfo {
                stage: 1,
                title: "最後集結".to_string(),
                title_en: "Final Assembly".to_string(),
                objective: "在最終議會中建立最強聯盟".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 50,
                    experience: 300,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 2,
                title: "叛徒清洗".to_string(),
                title_en: "Purge of Traitors".to_string(),
                objective: "識別並擊敗所有叛徒 AI".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 55,
                    experience: 325,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 3,
                title: "絕地反擊".to_string(),
                title_en: "Last Stand".to_string(),
                objective: "在聲望低於 20 的情況下逆轉勝".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 60,
                    experience: 350,
                    card_unlock: Some("coup_detat".to_string()),
                },
            },
            StageInfo {
                stage: 4,
                title: "王者對決".to_string(),
                title_en: "King's Gambit".to_string(),
                objective: "在 1v1 決鬥中擊敗國王的代理人".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 65,
                    experience: 375,
                    card_unlock: None,
                },
            },
            StageInfo {
                stage: 5,
                title: "新時代".to_string(),
                title_en: "A New Era".to_string(),
                objective: "在最終投票中以壓倒性優勢獲勝".to_string(),
                difficulty: "expert".to_string(),
                rewards: StageRewards {
                    gems: 100,
                    experience: 500,
                    card_unlock: Some("prime_minister".to_string()),
                },
            },
        ]
    }

    /// 計算關卡獎勵
    fn calculate_stage_rewards(chapter: i32, stage: i32) -> StageRewards {
        let chapters = Self::get_all_chapters();
        if let Some(ch) = chapters.get((chapter - 1) as usize) {
            if let Some(st) = ch.stages.get((stage - 1) as usize) {
                return st.rewards.clone();
            }
        }
        StageRewards {
            gems: 10,
            experience: 50,
            card_unlock: None,
        }
    }

    /// 取得使用者已解鎖的章節
    async fn get_unlocked_chapters(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<Vec<i32>, AppError> {
        let chapters =
            sqlx::query_scalar::<_, i32>("SELECT chapter FROM campaign_unlocks WHERE user_id = $1")
                .bind(user_id)
                .fetch_all(pool)
                .await
                .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(chapters)
    }

    /// 取得使用者的關卡進度
    async fn get_stage_progress(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<Vec<StageProgress>, AppError> {
        let progress = sqlx::query_as::<_, StageProgress>(
            r#"
            SELECT chapter, stage, stars, score, completed_at
            FROM campaign_progress
            WHERE user_id = $1
            ORDER BY chapter, stage
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(progress)
    }

    /// 取得特定章節的進度
    async fn get_chapter_progress(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        chapter: i32,
    ) -> Result<Vec<StageProgress>, AppError> {
        let progress = sqlx::query_as::<_, StageProgress>(
            r#"
            SELECT chapter, stage, stars, score, completed_at
            FROM campaign_progress
            WHERE user_id = $1 AND chapter = $2
            ORDER BY stage
            "#,
        )
        .bind(user_id)
        .bind(chapter)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(progress)
    }

    /// 取得特定關卡記錄
    async fn get_stage_record(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        chapter: i32,
        stage: i32,
    ) -> Result<Option<StageProgress>, AppError> {
        let record = sqlx::query_as::<_, StageProgress>(
            r#"
            SELECT chapter, stage, stars, score, completed_at
            FROM campaign_progress
            WHERE user_id = $1 AND chapter = $2 AND stage = $3
            "#,
        )
        .bind(user_id)
        .bind(chapter)
        .bind(stage)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(record)
    }

    /// 記錄章節解鎖
    async fn record_unlock(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        chapter: i32,
    ) -> Result<(), AppError> {
        sqlx::query(
            r#"
            INSERT INTO campaign_unlocks (user_id, chapter, unlocked_at)
            VALUES ($1, $2, NOW())
            ON CONFLICT (user_id, chapter) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(chapter)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// 檢查是否通過 IAP 購買了章節
    async fn check_iap_unlock(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        chapter: i32,
    ) -> Result<bool, AppError> {
        let product_id = format!("campaign_ch{}", chapter);
        let exists = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM iap_transactions
                WHERE user_id = $1 AND product_id LIKE '%' || $2
                AND verified = true
            )
            "#,
        )
        .bind(user_id)
        .bind(product_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(exists)
    }
}

/// 關卡進度記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct StageProgress {
    pub chapter: i32,
    pub stage: i32,
    pub stars: i32,
    pub score: i32,
    pub completed_at: DateTime<Utc>,
}

/// 章節詳情回應
#[derive(Debug, Serialize)]
pub struct ChapterDetailResponse {
    pub chapter: i32,
    pub title: String,
    pub title_en: String,
    pub description: String,
    pub description_en: String,
    pub is_unlocked: bool,
    pub is_free: bool,
    pub gem_cost: i64,
    pub stages: Vec<StageDetailEntry>,
}

#[derive(Debug, Serialize)]
pub struct StageDetailEntry {
    pub stage: i32,
    pub title: String,
    pub objective: String,
    pub difficulty: String,
    pub rewards: StageRewards,
    pub is_completed: bool,
    pub best_stars: i32,
    pub best_score: i32,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_total_chapters() {
        let chapters = CampaignService::get_all_chapters();
        assert_eq!(chapters.len(), TOTAL_CHAPTERS as usize);
    }

    #[test]
    fn test_chapter_1_is_free() {
        let chapters = CampaignService::get_all_chapters();
        assert!(chapters[0].is_free);
        assert_eq!(chapters[0].gem_cost, 0);
    }

    #[test]
    fn test_chapters_2_to_5_are_paid() {
        let chapters = CampaignService::get_all_chapters();
        for ch in &chapters[1..] {
            assert!(!ch.is_free);
            assert_eq!(ch.gem_cost, GEMS_PER_CHAPTER_UNLOCK);
        }
    }

    #[test]
    fn test_each_chapter_has_5_stages() {
        let chapters = CampaignService::get_all_chapters();
        for ch in &chapters {
            assert_eq!(ch.stages.len(), STAGES_PER_CHAPTER as usize);
        }
    }

    #[test]
    fn test_stage_rewards_positive() {
        let chapters = CampaignService::get_all_chapters();
        for ch in &chapters {
            for stage in &ch.stages {
                assert!(stage.rewards.gems > 0);
                assert!(stage.rewards.experience > 0);
            }
        }
    }

    #[test]
    fn test_difficulty_progression() {
        let chapters = CampaignService::get_all_chapters();
        // Chapter 1 should start with tutorial/easy
        assert_eq!(chapters[0].stages[0].difficulty, "tutorial");
        // Chapter 5 should be all expert
        for stage in &chapters[4].stages {
            assert_eq!(stage.difficulty, "expert");
        }
    }

    #[test]
    fn test_calculate_stage_rewards() {
        let rewards = CampaignService::calculate_stage_rewards(1, 1);
        assert_eq!(rewards.gems, 20);
        assert_eq!(rewards.experience, 50);
    }

    #[test]
    fn test_calculate_stage_rewards_last_stage() {
        let rewards = CampaignService::calculate_stage_rewards(5, 5);
        assert_eq!(rewards.gems, 100);
        assert_eq!(rewards.experience, 500);
        assert!(rewards.card_unlock.is_some());
    }

    #[test]
    fn test_chapter_titles_bilingual() {
        let chapters = CampaignService::get_all_chapters();
        for ch in &chapters {
            assert!(!ch.title.is_empty());
            assert!(!ch.title_en.is_empty());
            assert!(!ch.description.is_empty());
            assert!(!ch.description_en.is_empty());
        }
    }

    #[test]
    fn test_gems_cost_constant() {
        assert_eq!(GEMS_PER_CHAPTER_UNLOCK, 200);
    }
}
