//! 週挑戰 API 處理器
//!
//! - GET  /api/v1/quests/weekly — 取得本週挑戰 + 進度
//! - POST /api/v1/quests/weekly/claim/:quest_id — 領取週挑戰獎勵
//! - GET  /api/v1/quests/summary — 任務中心摘要（badge 數字用）

use axum::{
    extract::{Path, State},
    Json,
};
use serde::Serialize;

use crate::auth::AuthUser;
use crate::error::AppError;
use crate::game::weekly_system;
use crate::game::quest_system;
use crate::db::codex::AchievementDb;
use crate::AppState;

// ============================================================
// GET /api/v1/quests/weekly
// ============================================================

/// 週挑戰回應（與 weekly_system::WeeklyChallengesResponse 對應）
#[derive(Debug, Serialize)]
pub struct GetWeeklyChallengesResponse {
    pub challenges: Vec<WeeklyChallengeItem>,
    pub reset_in_secs: i64,
    pub week_label: String,
}

#[derive(Debug, Serialize)]
pub struct WeeklyChallengeItem {
    pub quest_id: String,
    pub name: String,
    pub description: String,
    pub progress: i32,
    pub target: i32,
    pub reward: RewardItem,
    pub claimed: bool,
    pub completed: bool,
}

#[derive(Debug, Serialize)]
pub struct RewardItem {
    #[serde(rename = "type")]
    pub reward_type: String,
    pub amount: i32,
    pub display: String,
}

pub async fn get_weekly_challenges(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<GetWeeklyChallengesResponse>, AppError> {
    let resp = weekly_system::get_user_weekly_challenges(&state.db, auth_user.user_id)
        .await
        .map_err(|e| AppError::DatabaseError(format!("取得週挑戰失敗: {}", e)))?;
    
    let challenges = resp.challenges
        .iter()
        .map(|c| WeeklyChallengeItem {
            quest_id: c.quest_id.clone(),
            name: c.name.clone(),
            description: c.description.clone(),
            progress: c.progress,
            target: c.target,
            reward: RewardItem {
                reward_type: c.reward.reward_type.clone(),
                amount: c.reward.amount,
                display: c.reward.display.clone(),
            },
            claimed: c.claimed,
            completed: c.completed,
        })
        .collect();
    
    Ok(Json(GetWeeklyChallengesResponse {
        challenges,
        reset_in_secs: resp.reset_in_secs,
        week_label: resp.week_label,
    }))
}

// ============================================================
// POST /api/v1/quests/weekly/claim/:quest_id
// ============================================================

#[derive(Debug, Serialize)]
pub struct ClaimWeeklyRewardResponse {
    pub success: bool,
    pub reward: String,
    pub message: String,
}

pub async fn claim_weekly_reward(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Path(quest_id): Path<String>,
) -> Result<Json<ClaimWeeklyRewardResponse>, AppError> {
    match weekly_system::claim_weekly_reward(&state.db, auth_user.user_id, &quest_id).await {
        Ok(Some(reward)) => {
            let reward_desc = match reward {
                crate::game::quests::QuestReward::Gold(n) => format!("{} 金幣", n),
                crate::game::quests::QuestReward::Gems(n) => format!("{} 寶石", n),
                crate::game::quests::QuestReward::CardPack(n) => format!("{} 卡包", n),
                crate::game::quests::QuestReward::ExperienceBoost(n) => format!("{}% 經驗加成", n),
            };
            
            Ok(Json(ClaimWeeklyRewardResponse {
                success: true,
                reward: reward_desc.clone(),
                message: format!("獲得 {}", reward_desc),
            }))
        }
        Ok(None) => {
            Err(AppError::BadRequest("無法領取獎勵：挑戰未完成或已領取".to_string()))
        }
        Err(e) => {
            Err(AppError::DatabaseError(format!("領取週挑戰獎勵失敗: {}", e)))
        }
    }
}

// ============================================================
// GET /api/v1/quests/summary
// ============================================================

/// 任務中心摘要回應
#[derive(Debug, Serialize)]
pub struct QuestSummaryResponse {
    pub daily: QuestCategorySummary,
    pub weekly: QuestCategorySummary,
    pub achievements: AchievementSummary,
    pub total_claimable: i32,
}

#[derive(Debug, Serialize)]
pub struct QuestCategorySummary {
    pub total: i32,
    pub completed: i32,
    pub claimable: i32,
    pub all_claimed: bool,
}

#[derive(Debug, Serialize)]
pub struct AchievementSummary {
    pub unclaimed_count: i32,
}

pub async fn get_quest_summary(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<QuestSummaryResponse>, AppError> {
    let user_id = auth_user.user_id;
    
    // 1. 取得每日任務摘要
    let daily_result = quest_system::get_daily_quests(&state.db, user_id).await
        .map_err(|e| AppError::DatabaseError(format!("取得每日任務摘要失敗: {}", e)))?;
    
    let daily_summary = QuestCategorySummary {
        total: daily_result.quests.len() as i32,
        completed: daily_result.quests.iter().filter(|q| q.is_completed()).count() as i32,
        claimable: daily_result.quests.iter().filter(|q| q.is_completed() && !q.claimed).count() as i32,
        all_claimed: daily_result.all_claimed,
    };
    
    // 2. 取得週挑戰摘要
    let weekly_result = weekly_system::get_user_weekly_challenges(&state.db, user_id).await
        .map_err(|e| AppError::DatabaseError(format!("取得週挑戰摘要失敗: {}", e)))?;
    
    let weekly_summary = QuestCategorySummary {
        total: weekly_result.challenges.len() as i32,
        completed: weekly_result.challenges.iter().filter(|c| c.completed).count() as i32,
        claimable: weekly_result.challenges.iter().filter(|c| c.completed && !c.claimed).count() as i32,
        all_claimed: weekly_result.challenges.iter().all(|c| c.completed && c.claimed),
    };
    
    // 3. 取得成就未領取數量
    let achievements = AchievementDb::get_user_achievements(&state.db, user_id).await
        .map_err(|e| AppError::DatabaseError(format!("取得成就摘要失敗: {}", e)))?;
    
    let unclaimed_achievements = achievements.iter()
        .filter(|a| a.completed && !a.claimed)
        .count() as i32;
    
    // 4. 計算總可領取數量
    let total_claimable = daily_summary.claimable + weekly_summary.claimable + unclaimed_achievements;
    
    Ok(Json(QuestSummaryResponse {
        daily: daily_summary,
        weekly: weekly_summary,
        achievements: AchievementSummary {
            unclaimed_count: unclaimed_achievements,
        },
        total_claimable,
    }))
}