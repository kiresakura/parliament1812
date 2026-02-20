//! 週挑戰系統核心邏輯
//!
//! 負責週挑戰的生成、進度追蹤、獎勵領取等功能。

use chrono::{Datelike, Utc, Weekday};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::game::quests::QuestReward;
use crate::game::weekly_challenges::{self, WeeklyQuestType, WeeklyTemplate};

/// 週挑戰進度記錄
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct WeeklyChallengeProgress {
    /// 用戶 ID
    pub user_id: Uuid,
    /// 週標籤（如 "2026-W08"）
    pub quest_week: String,
    /// 挑戰 ID
    pub quest_id: String,
    /// 當前進度
    pub progress: i32,
    /// 目標數量
    pub target: i32,
    /// 是否已領取獎勵
    pub claimed: bool,
}

/// 週挑戰詳情（API 回應用）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyChallengeDetail {
    /// 挑戰 ID
    pub quest_id: String,
    /// 挑戰名稱
    pub name: String,
    /// 挑戰描述
    pub description: String,
    /// 當前進度
    pub progress: i32,
    /// 目標數量
    pub target: i32,
    /// 獎勵資訊
    pub reward: QuestRewardDetail,
    /// 是否已領取
    pub claimed: bool,
    /// 是否已完成
    pub completed: bool,
}

/// 獎勵詳情（API 回應用）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuestRewardDetail {
    /// 獎勵類型
    #[serde(rename = "type")]
    pub reward_type: String,
    /// 獎勵數量
    pub amount: i32,
    /// 顯示文字
    pub display: String,
}

/// 週挑戰回應（API 回應用）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyChallengesResponse {
    /// 挑戰列表
    pub challenges: Vec<WeeklyChallengeDetail>,
    /// 距離重置的秒數
    pub reset_in_secs: i64,
    /// 週標籤
    pub week_label: String,
}

/// 取得當前週標籤
pub fn current_week_label() -> String {
    let now = Utc::now();
    let iso_week = now.iso_week();
    format!("{}-W{:02}", iso_week.year(), iso_week.week())
}

/// 取得下週重置的秒數
pub fn seconds_until_reset() -> i64 {
    let now = Utc::now();
    let days_until_monday = (7 - now.weekday().num_days_from_monday()) % 7;
    let days_until_monday = if days_until_monday == 0 { 7 } else { days_until_monday };
    
    // 計算下週一 00:00 UTC+8 的時間戳
    let next_monday = now + chrono::Duration::days(days_until_monday as i64);
    let next_monday_midnight = next_monday.date_naive().and_hms_opt(0, 0, 0).unwrap();
    
    // 轉換為 UTC 並計算秒數差
    let next_monday_utc = next_monday_midnight - chrono::Duration::hours(8);
    let now_utc = now.naive_utc();
    
    (next_monday_utc - now_utc).num_seconds()
}

/// 隨機選擇 3 個不重複的週挑戰
pub fn select_weekly_challenges() -> Vec<WeeklyTemplate> {
    use std::collections::HashSet;
    
    let all_templates = weekly_challenges::all_weekly_templates();
    let mut selected = Vec::with_capacity(3);
    let mut used_indices: HashSet<usize> = HashSet::new();
    
    // 簡單的隨機選擇：依序選擇前 3 個
    // TODO: 未來可以改為真正的隨機選擇
    for template in all_templates.iter().take(3) {
        selected.push(template.clone());
    }
    
    selected
}

/// 初始化用戶的週挑戰（如不存在）
pub async fn init_user_weekly_challenges(
    pool: &sqlx::PgPool,
    user_id: Uuid,
) -> Result<Vec<WeeklyChallengeProgress>, sqlx::Error> {
    let week_label = current_week_label();
    
    // 檢查是否已有本週挑戰
    let existing: Vec<WeeklyChallengeProgress> = sqlx::query_as::<_, WeeklyChallengeProgress>(
        r#"
        SELECT user_id, quest_week, quest_id, progress, target, claimed
        FROM weekly_challenges
        WHERE user_id = $1 AND quest_week = $2
        "#,
    )
    .bind(user_id)
    .bind(&week_label)
    .fetch_all(pool)
    .await?;
    
    if !existing.is_empty() {
        return Ok(existing);
    }
    
    // 生成新挑戰
    let templates = select_weekly_challenges();
    
    let mut challenges = Vec::new();
    for template in templates {
        let result = sqlx::query_as::<_, WeeklyChallengeProgress>(
            r#"
            INSERT INTO weekly_challenges (user_id, quest_week, quest_id, progress, target, claimed)
            VALUES ($1, $2, $3, $4, $5, FALSE)
            RETURNING user_id, quest_week, quest_id, progress, target, claimed
            "#,
        )
        .bind(user_id)
        .bind(&week_label)
        .bind(template.quest_type.as_str())
        .bind(0i32)
        .bind(template.target)
        .fetch_one(pool)
        .await?;
        
        challenges.push(result);
    }
    
    Ok(challenges)
}

/// 取得用戶的週挑戰進度
pub async fn get_user_weekly_challenges(
    pool: &sqlx::PgPool,
    user_id: Uuid,
) -> Result<WeeklyChallengesResponse, sqlx::Error> {
    // 確保用戶有本週挑戰
    init_user_weekly_challenges(pool, user_id).await?;
    
    let week_label = current_week_label();
    
    // 查詢本週挑戰
    let challenges: Vec<WeeklyChallengeProgress> = sqlx::query_as::<_, WeeklyChallengeProgress>(
        r#"
        SELECT user_id, quest_week, quest_id, progress, target, claimed
        FROM weekly_challenges
        WHERE user_id = $1 AND quest_week = $2
        "#,
    )
    .bind(user_id)
    .bind(&week_label)
    .fetch_all(pool)
    .await?;
    
    let all_templates = weekly_challenges::all_weekly_templates();
    let mut details = Vec::new();
    
    for progress in challenges {
        // 找到對應的模板
        let template = all_templates.iter()
            .find(|t| t.quest_type.as_str() == progress.quest_id);
        
        if let Some(t) = template {
            let reward_detail = match &t.reward {
                QuestReward::Gold(n) => QuestRewardDetail {
                    reward_type: "gold".to_string(),
                    amount: *n,
                    display: format!("{} 金幣", n),
                },
                QuestReward::Gems(n) => QuestRewardDetail {
                    reward_type: "gems".to_string(),
                    amount: *n,
                    display: format!("{} 寶石", n),
                },
                QuestReward::CardPack(n) => QuestRewardDetail {
                    reward_type: "card_pack".to_string(),
                    amount: *n,
                    display: format!("{} 卡包", n),
                },
                QuestReward::ExperienceBoost(n) => QuestRewardDetail {
                    reward_type: "exp_boost".to_string(),
                    amount: *n,
                    display: format!("{}% 經驗加成", n),
                },
            };
            
            details.push(WeeklyChallengeDetail {
                quest_id: progress.quest_id.clone(),
                name: t.name.clone(),
                description: t.description.clone(),
                progress: progress.progress,
                target: progress.target,
                reward: reward_detail,
                claimed: progress.claimed,
                completed: progress.progress >= progress.target,
            });
        }
    }
    
    Ok(WeeklyChallengesResponse {
        challenges: details,
        reset_in_secs: seconds_until_reset(),
        week_label,
    })
}

/// 領取週挑戰獎勵
pub async fn claim_weekly_reward(
    pool: &sqlx::PgPool,
    user_id: Uuid,
    quest_id: &str,
) -> Result<Option<QuestReward>, sqlx::Error> {
    let week_label = current_week_label();
    
    // 查詢挑戰狀態
    let challenge: Option<WeeklyChallengeProgress> = sqlx::query_as::<_, WeeklyChallengeProgress>(
        r#"
        SELECT user_id, quest_week, quest_id, progress, target, claimed
        FROM weekly_challenges
        WHERE user_id = $1 AND quest_week = $2 AND quest_id = $3
        "#,
    )
    .bind(user_id)
    .bind(&week_label)
    .bind(quest_id)
    .fetch_optional(pool)
    .await?;
    
    let challenge = match challenge {
        Some(c) => c,
        None => return Ok(None),
    };
    
    // 檢查是否已完成且未領取
    if challenge.progress < challenge.target {
        return Ok(None);
    }
    if challenge.claimed {
        return Ok(None);
    }
    
    // 標記為已領取
    sqlx::query(
        r#"
        UPDATE weekly_challenges
        SET claimed = TRUE
        WHERE user_id = $1 AND quest_week = $2 AND quest_id = $3
        "#,
    )
    .bind(user_id)
    .bind(&week_label)
    .bind(quest_id)
    .execute(pool)
    .await?;
    
    // 取得獎勵內容
    let all_templates = weekly_challenges::all_weekly_templates();
    let template = all_templates.iter()
        .find(|t| t.quest_type.as_str() == quest_id);
    
    Ok(template.map(|t| t.reward.clone()))
}

/// 更新週挑戰進度
pub async fn update_weekly_progress(
    pool: &sqlx::PgPool,
    user_id: Uuid,
    quest_type: WeeklyQuestType,
    amount: i32,
) -> Result<(), sqlx::Error> {
    let week_label = current_week_label();
    let quest_id = quest_type.as_str();
    
    sqlx::query(
        r#"
        INSERT INTO weekly_challenges (user_id, quest_week, quest_id, progress, target, claimed)
        VALUES ($1, $2, $3, $4, 0, FALSE)
        ON CONFLICT (user_id, quest_week, quest_id)
        DO UPDATE SET progress = weekly_challenges.progress + $4
        "#,
    )
    .bind(user_id)
    .bind(&week_label)
    .bind(quest_id)
    .bind(amount)
    .execute(pool)
    .await?;
    
    Ok(())
}
