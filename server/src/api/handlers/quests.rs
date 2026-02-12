//! 每日任務 API 處理器
//!
//! - GET  /api/quests/daily       — 取得今日任務 + 進度
//! - POST /api/quests/claim/:id   — 領取獎勵
//! - GET  /api/quests/history     — 最近 7 天歷史

use axum::{
    extract::{Path, State},
    Json,
};
use serde::Serialize;

use crate::auth::AuthUser;
use crate::error::AppError;
use crate::game::quest_system;
use crate::AppState;

// ============================================================
// GET /api/quests/daily
// ============================================================

/// 今日任務回應
#[derive(Debug, Serialize)]
pub struct GetDailyQuestsResponse {
    pub quests: Vec<QuestItem>,
    pub current_streak: i32,
    pub longest_streak: i32,
    pub all_claimed: bool,
    pub reset_in_secs: i64,
}

#[derive(Debug, Serialize)]
pub struct QuestItem {
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

fn to_reward_item(reward: &crate::game::quests::QuestReward) -> RewardItem {
    use crate::game::quests::QuestReward;
    match reward {
        QuestReward::Gold(n) => RewardItem {
            reward_type: "gold".to_string(),
            amount: *n,
            display: reward.display(),
        },
        QuestReward::Gems(n) => RewardItem {
            reward_type: "gems".to_string(),
            amount: *n,
            display: reward.display(),
        },
        QuestReward::CardPack(n) => RewardItem {
            reward_type: "card_pack".to_string(),
            amount: *n,
            display: reward.display(),
        },
        QuestReward::ExperienceBoost(n) => RewardItem {
            reward_type: "exp_boost".to_string(),
            amount: *n,
            display: reward.display(),
        },
    }
}

pub async fn get_daily_quests(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<GetDailyQuestsResponse>, AppError> {
    let resp = quest_system::get_daily_quests(&state.db, auth_user.user_id)
        .await
        .map_err(|e| AppError::DatabaseError(format!("取得每日任務失敗: {}", e)))?;

    let quests = resp
        .quests
        .iter()
        .map(|q| QuestItem {
            quest_id: q.quest_id.clone(),
            name: q.name.clone(),
            description: q.description.clone(),
            progress: q.progress,
            target: q.target,
            reward: to_reward_item(&q.reward),
            claimed: q.claimed,
            completed: q.is_completed(),
        })
        .collect();

    Ok(Json(GetDailyQuestsResponse {
        quests,
        current_streak: resp.current_streak,
        longest_streak: resp.longest_streak,
        all_claimed: resp.all_claimed,
        reset_in_secs: resp.reset_in_secs,
    }))
}

// ============================================================
// POST /api/quests/claim/:quest_id
// ============================================================

#[derive(Debug, Serialize)]
pub struct ClaimRewardResponse {
    pub success: bool,
    pub reward: String,
    pub bonus_gems: i32,
    pub message: String,
}

pub async fn claim_quest_reward(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Path(quest_id): Path<String>,
) -> Result<Json<ClaimRewardResponse>, AppError> {
    match quest_system::claim_quest_reward(&state.db, auth_user.user_id, &quest_id).await {
        Ok((reward_desc, bonus_gems)) => {
            let mut message = format!("獲得 {}", reward_desc);
            if bonus_gems > 0 {
                message.push_str(&format!("，額外獲得 {} 寶石（全完成獎勵）", bonus_gems));
            }
            Ok(Json(ClaimRewardResponse {
                success: true,
                reward: reward_desc,
                bonus_gems,
                message,
            }))
        }
        Err(quest_system::ClaimError::NotFound) => {
            Err(AppError::NotFound("任務不存在".to_string()))
        }
        Err(quest_system::ClaimError::NotCompleted) => {
            Err(AppError::BadRequest("任務尚未完成".to_string()))
        }
        Err(quest_system::ClaimError::AlreadyClaimed) => {
            Err(AppError::BadRequest("獎勵已領取".to_string()))
        }
        Err(quest_system::ClaimError::Db(e)) => {
            Err(AppError::DatabaseError(format!("領取獎勵失敗: {}", e)))
        }
    }
}

// ============================================================
// GET /api/quests/history
// ============================================================

#[derive(Debug, Serialize)]
pub struct QuestHistoryResponse {
    pub days: Vec<HistoryDay>,
}

#[derive(Debug, Serialize)]
pub struct HistoryDay {
    pub date: String,
    pub quests: Vec<QuestItem>,
    pub all_completed: bool,
}

pub async fn get_quest_history(
    State(state): State<AppState>,
    auth_user: AuthUser,
) -> Result<Json<QuestHistoryResponse>, AppError> {
    let history = quest_system::get_quest_history(&state.db, auth_user.user_id)
        .await
        .map_err(|e| AppError::DatabaseError(format!("取得任務歷史失敗: {}", e)))?;

    let days = history
        .iter()
        .map(|day| HistoryDay {
            date: day.date.to_string(),
            quests: day
                .quests
                .iter()
                .map(|q| QuestItem {
                    quest_id: q.quest_id.clone(),
                    name: q.name.clone(),
                    description: q.description.clone(),
                    progress: q.progress,
                    target: q.target,
                    reward: to_reward_item(&q.reward),
                    claimed: q.claimed,
                    completed: q.is_completed(),
                })
                .collect(),
            all_completed: day.all_completed,
        })
        .collect();

    Ok(Json(QuestHistoryResponse { days }))
}
