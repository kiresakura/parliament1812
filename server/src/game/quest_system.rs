//! 每日任務系統
//!
//! 負責任務的生成、進度追蹤、獎勵領取與連續完成紀錄。
//! 每天 UTC+8 00:00 重置，每位玩家 3 個任務。

use chrono::{NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

use super::quests::{all_quest_templates, QuestReward, QuestTemplate, QuestType};

// ============================================================
// 資料模型
// ============================================================

/// 單筆每日任務（DB 記錄 + 模板資訊）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyQuest {
    pub quest_id: String,
    pub quest_type: QuestType,
    pub name: String,
    pub description: String,
    pub progress: i32,
    pub target: i32,
    pub reward: QuestReward,
    pub claimed: bool,
}

impl DailyQuest {
    /// 是否已完成（進度 >= 目標）
    pub fn is_completed(&self) -> bool {
        self.progress >= self.target
    }
}

/// 今日任務回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyQuestsResponse {
    /// 今日 3 個任務
    pub quests: Vec<DailyQuest>,
    /// 當前連續天數
    pub current_streak: i32,
    /// 最長連續天數
    pub longest_streak: i32,
    /// 全部完成 bonus 是否已領取
    pub all_claimed: bool,
    /// 距離重置的秒數
    pub reset_in_secs: i64,
}

/// 任務歷史
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuestHistoryDay {
    pub date: NaiveDate,
    pub quests: Vec<DailyQuest>,
    pub all_completed: bool,
}

/// DB row for daily_quests
#[derive(Debug, Clone, sqlx::FromRow)]
struct DailyQuestRow {
    pub quest_id: String,
    pub progress: i32,
    pub target: i32,
    pub claimed: bool,
}

/// DB row for quest_streaks
#[derive(Debug, Clone, sqlx::FromRow)]
struct QuestStreakRow {
    pub current_streak: i32,
    pub longest_streak: i32,
    pub last_completed_date: Option<NaiveDate>,
}

// ============================================================
// 日期工具
// ============================================================

/// 取得 UTC+8 的今天日期
pub fn today_utc8() -> NaiveDate {
    let now = Utc::now();
    let utc8 = now + chrono::Duration::hours(8);
    utc8.date_naive()
}

/// 距離下次 UTC+8 00:00 的秒數
pub fn seconds_until_reset() -> i64 {
    let now = Utc::now();
    let utc8_now = now + chrono::Duration::hours(8);
    let tomorrow = utc8_now.date_naive().succ_opt().unwrap_or(utc8_now.date_naive());
    let reset_time = tomorrow
        .and_hms_opt(0, 0, 0)
        .expect("valid time")
        .and_utc()
        - chrono::Duration::hours(8);
    (reset_time - now).num_seconds().max(0)
}

// ============================================================
// 核心功能
// ============================================================

/// 取得玩家今日任務（若不存在則自動生成）
pub async fn get_daily_quests(
    pool: &PgPool,
    user_id: Uuid,
) -> Result<DailyQuestsResponse, sqlx::Error> {
    let today = today_utc8();

    // 查詢今日任務
    let rows = sqlx::query_as::<_, DailyQuestRow>(
        r#"
        SELECT quest_id, progress, target, claimed
        FROM daily_quests
        WHERE user_id = $1 AND quest_date = $2
        ORDER BY quest_id
        "#,
    )
    .bind(user_id)
    .bind(today)
    .fetch_all(pool)
    .await?;

    // 若無任務，生成新的
    let rows = if rows.is_empty() {
        generate_daily_quests(pool, user_id, today).await?
    } else {
        rows
    };

    // 將 DB rows 組合模板資訊
    let templates = all_quest_templates();
    let quests: Vec<DailyQuest> = rows
        .iter()
        .filter_map(|row| {
            let qt = QuestType::from_str(&row.quest_id)?;
            let template = templates.iter().find(|t| t.quest_type == qt)?;
            Some(DailyQuest {
                quest_id: row.quest_id.clone(),
                quest_type: qt,
                name: template.name.clone(),
                description: template.description.clone(),
                progress: row.progress,
                target: row.target,
                reward: template.reward.clone(),
                claimed: row.claimed,
            })
        })
        .collect();

    let all_claimed = quests.iter().all(|q| q.claimed);

    // 查詢連續紀錄
    let streak = get_streak(pool, user_id).await?;

    Ok(DailyQuestsResponse {
        quests,
        current_streak: streak.current_streak,
        longest_streak: streak.longest_streak,
        all_claimed,
        reset_in_secs: seconds_until_reset(),
    })
}

/// 更新任務進度
///
/// 對指定使用者的今日任務中匹配的類型增加進度。
/// 回傳受影響的列數。
pub async fn update_quest_progress(
    pool: &PgPool,
    user_id: Uuid,
    quest_type: QuestType,
    delta: i32,
) -> Result<u64, sqlx::Error> {
    let today = today_utc8();
    let quest_id = quest_type.as_str();

    let result = sqlx::query(
        r#"
        UPDATE daily_quests
        SET progress = LEAST(progress + $4, target)
        WHERE user_id = $1
          AND quest_date = $2
          AND quest_id = $3
          AND claimed = false
        "#,
    )
    .bind(user_id)
    .bind(today)
    .bind(quest_id)
    .bind(delta)
    .execute(pool)
    .await?;

    Ok(result.rows_affected())
}

/// 領取任務獎勵
///
/// 驗證任務已完成且未領取，發放獎勵並記錄交易。
/// 若所有 3 個任務都已領取，額外發放 bonus 10 gems。
/// 回傳 (獎勵描述, bonus_gems)。
pub async fn claim_quest_reward(
    pool: &PgPool,
    user_id: Uuid,
    quest_id: &str,
) -> Result<(String, i32), ClaimError> {
    let today = today_utc8();

    // 查詢該任務
    let row = sqlx::query_as::<_, DailyQuestRow>(
        r#"
        SELECT quest_id, progress, target, claimed
        FROM daily_quests
        WHERE user_id = $1 AND quest_date = $2 AND quest_id = $3
        "#,
    )
    .bind(user_id)
    .bind(today)
    .bind(quest_id)
    .fetch_optional(pool)
    .await
    .map_err(ClaimError::Db)?
    .ok_or(ClaimError::NotFound)?;

    if row.claimed {
        return Err(ClaimError::AlreadyClaimed);
    }
    if row.progress < row.target {
        return Err(ClaimError::NotCompleted);
    }

    // 找到對應模板
    let qt = QuestType::from_str(quest_id).ok_or(ClaimError::NotFound)?;
    let templates = all_quest_templates();
    let template = templates
        .iter()
        .find(|t| t.quest_type == qt)
        .ok_or(ClaimError::NotFound)?;

    // 開始事務
    let mut tx = pool.begin().await.map_err(ClaimError::Db)?;

    // 標記已領取
    sqlx::query(
        r#"
        UPDATE daily_quests
        SET claimed = true
        WHERE user_id = $1 AND quest_date = $2 AND quest_id = $3
        "#,
    )
    .bind(user_id)
    .bind(today)
    .bind(quest_id)
    .execute(&mut *tx)
    .await
    .map_err(ClaimError::Db)?;

    // 發放獎勵（寫入 transactions 表）
    let reward_desc = template.reward.display();
    let (currency, amount) = match &template.reward {
        QuestReward::Gold(n) => ("gold", *n),
        QuestReward::Gems(n) => ("gem", *n),
        QuestReward::CardPack(n) => ("card_pack", *n),
        QuestReward::ExperienceBoost(n) => ("exp_boost", *n),
    };

    sqlx::query(
        r#"
        INSERT INTO transactions (user_id, type, amount, currency, description)
        VALUES ($1, 'quest_reward', $2, $3, $4)
        "#,
    )
    .bind(user_id)
    .bind(amount)
    .bind(currency)
    .bind(format!("每日任務獎勵：{}", template.name))
    .execute(&mut *tx)
    .await
    .map_err(ClaimError::Db)?;

    // 檢查是否所有 3 個今日任務都已領取 → bonus
    let unclaimed_count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM daily_quests
        WHERE user_id = $1 AND quest_date = $2 AND claimed = false
        "#,
    )
    .bind(user_id)
    .bind(today)
    .fetch_one(&mut *tx)
    .await
    .map_err(ClaimError::Db)?;

    let mut bonus_gems = 0i32;

    if unclaimed_count == 0 {
        // 全部完成 → bonus 10 gems
        bonus_gems = 10;

        sqlx::query(
            r#"
            INSERT INTO transactions (user_id, type, amount, currency, description)
            VALUES ($1, 'quest_bonus', 10, 'gem', '每日任務全完成獎勵')
            "#,
        )
        .bind(user_id)
        .execute(&mut *tx)
        .await
        .map_err(ClaimError::Db)?;

        // 更新連續紀錄
        update_streak(&mut tx, user_id, today).await.map_err(ClaimError::Db)?;
    }

    tx.commit().await.map_err(ClaimError::Db)?;

    Ok((reward_desc, bonus_gems))
}

/// 遊戲結束後批次更新所有玩家的任務進度
///
/// 傳入參與遊戲的玩家資訊，自動追蹤相關任務。
pub async fn update_all_quest_progress(
    pool: &PgPool,
    game_result: &GameEndQuestData,
) -> Result<(), sqlx::Error> {
    for player in &game_result.players {
        // PlayGames +1
        update_quest_progress(pool, player.user_id, QuestType::PlayGames, 1).await?;

        // PlayAsCharacter +1
        update_quest_progress(pool, player.user_id, QuestType::PlayAsCharacter, 1).await?;

        // WinGames +1 if won
        if player.is_winner {
            update_quest_progress(pool, player.user_id, QuestType::WinGames, 1).await?;
        }

        // WinWithReputation if won with reputation >= 60
        if player.is_winner && player.final_reputation >= 60 {
            update_quest_progress(pool, player.user_id, QuestType::WinWithReputation, 1).await?;
        }

        // VoteOnBills
        if player.votes_cast > 0 {
            update_quest_progress(pool, player.user_id, QuestType::VoteOnBills, player.votes_cast)
                .await?;
        }

        // UseAttackCards
        if player.attack_cards_used > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::UseAttackCards,
                player.attack_cards_used,
            )
            .await?;
        }

        // UseDefenseCards
        if player.defense_cards_used > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::UseDefenseCards,
                player.defense_cards_used,
            )
            .await?;
        }

        // FormAlliance
        if player.alliances_formed > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::FormAlliance,
                player.alliances_formed,
            )
            .await?;
        }

        // InitiateChallenge
        if player.challenges_initiated > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::InitiateChallenge,
                player.challenges_initiated,
            )
            .await?;
        }

        // SuccessfulCounter
        if player.successful_counters > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::SuccessfulCounter,
                player.successful_counters,
            )
            .await?;
        }

        // UseCharacterSkill
        if player.skills_used > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::UseCharacterSkill,
                player.skills_used,
            )
            .await?;
        }

        // PlayCardsInDebate
        if player.cards_played_in_debate > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::PlayCardsInDebate,
                player.cards_played_in_debate,
            )
            .await?;
        }

        // BetrayAlliance
        if player.betrayals > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::BetrayAlliance,
                player.betrayals,
            )
            .await?;
        }

        // VoteForWinner
        if player.voted_for_winner > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::VoteForWinner,
                player.voted_for_winner,
            )
            .await?;
        }

        // DealReputationDamage
        if player.reputation_damage_dealt > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::DealReputationDamage,
                player.reputation_damage_dealt,
            )
            .await?;
        }

        // HealReputation
        if player.reputation_healed > 0 {
            update_quest_progress(
                pool,
                player.user_id,
                QuestType::HealReputation,
                player.reputation_healed,
            )
            .await?;
        }

        // EarnGold
        if player.gold_earned > 0 {
            update_quest_progress(pool, player.user_id, QuestType::EarnGold, player.gold_earned)
                .await?;
        }

        // DrawCards
        if player.cards_drawn > 0 {
            update_quest_progress(pool, player.user_id, QuestType::DrawCards, player.cards_drawn)
                .await?;
        }

        // SurviveToEnd
        if player.survived {
            update_quest_progress(pool, player.user_id, QuestType::SurviveToEnd, 1).await?;
        }
    }

    // 觀戰者
    for spectator_id in &game_result.spectators {
        update_quest_progress(pool, *spectator_id, QuestType::SpectateGames, 1).await?;
    }

    Ok(())
}

/// 取得最近 7 天的任務歷史
pub async fn get_quest_history(
    pool: &PgPool,
    user_id: Uuid,
) -> Result<Vec<QuestHistoryDay>, sqlx::Error> {
    let today = today_utc8();
    let week_ago = today - chrono::Duration::days(6);

    #[derive(sqlx::FromRow)]
    struct HistoryRow {
        quest_date: NaiveDate,
        quest_id: String,
        progress: i32,
        target: i32,
        claimed: bool,
    }

    let rows = sqlx::query_as::<_, HistoryRow>(
        r#"
        SELECT quest_date, quest_id, progress, target, claimed
        FROM daily_quests
        WHERE user_id = $1 AND quest_date >= $2
        ORDER BY quest_date DESC, quest_id
        "#,
    )
    .bind(user_id)
    .bind(week_ago)
    .fetch_all(pool)
    .await?;

    let templates = all_quest_templates();

    // 按日期分組
    let mut days: Vec<QuestHistoryDay> = Vec::new();
    let mut current_date: Option<NaiveDate> = None;
    let mut current_quests: Vec<DailyQuest> = Vec::new();

    for row in &rows {
        if current_date != Some(row.quest_date) {
            if let Some(date) = current_date {
                let all_completed =
                    current_quests.iter().all(|q| q.progress >= q.target && q.claimed);
                days.push(QuestHistoryDay {
                    date,
                    quests: std::mem::take(&mut current_quests),
                    all_completed,
                });
            }
            current_date = Some(row.quest_date);
        }

        if let Some(qt) = QuestType::from_str(&row.quest_id) {
            if let Some(template) = templates.iter().find(|t| t.quest_type == qt) {
                current_quests.push(DailyQuest {
                    quest_id: row.quest_id.clone(),
                    quest_type: qt,
                    name: template.name.clone(),
                    description: template.description.clone(),
                    progress: row.progress,
                    target: row.target,
                    reward: template.reward.clone(),
                    claimed: row.claimed,
                });
            }
        }
    }

    // 最後一天
    if let Some(date) = current_date {
        let all_completed =
            current_quests.iter().all(|q| q.progress >= q.target && q.claimed);
        days.push(QuestHistoryDay {
            date,
            quests: current_quests,
            all_completed,
        });
    }

    Ok(days)
}

// ============================================================
// 內部工具
// ============================================================

/// 生成今日 3 個隨機任務（加權不重複）
async fn generate_daily_quests(
    pool: &PgPool,
    user_id: Uuid,
    date: NaiveDate,
) -> Result<Vec<DailyQuestRow>, sqlx::Error> {
    let templates = all_quest_templates();
    let selected = weighted_random_pick(&templates, 3);

    let mut rows = Vec::new();

    for template in &selected {
        let quest_id = template.quest_type.as_str();

        sqlx::query(
            r#"
            INSERT INTO daily_quests (user_id, quest_date, quest_id, progress, target, claimed)
            VALUES ($1, $2, $3, 0, $4, false)
            ON CONFLICT (user_id, quest_date, quest_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(date)
        .bind(quest_id)
        .bind(template.target)
        .execute(pool)
        .await?;

        rows.push(DailyQuestRow {
            quest_id: quest_id.to_string(),
            progress: 0,
            target: template.target,
            claimed: false,
        });
    }

    Ok(rows)
}

/// 加權隨機不重複選取
fn weighted_random_pick(templates: &[QuestTemplate], count: usize) -> Vec<QuestTemplate> {
    let mut rng = rand::thread_rng();
    let mut remaining: Vec<(usize, &QuestTemplate)> =
        templates.iter().enumerate().collect();
    let mut selected = Vec::new();

    for _ in 0..count {
        if remaining.is_empty() {
            break;
        }

        // 建立加權列表
        let weights: Vec<u32> = remaining.iter().map(|(_, t)| t.weight).collect();
        let total: u32 = weights.iter().sum();

        if total == 0 {
            break;
        }

        // 加權隨機選擇
        let roll = rand::Rng::gen_range(&mut rng, 0..total);
        let mut cumulative = 0u32;
        let mut chosen_idx = 0;

        for (i, w) in weights.iter().enumerate() {
            cumulative += w;
            if roll < cumulative {
                chosen_idx = i;
                break;
            }
        }

        selected.push(remaining[chosen_idx].1.clone());
        remaining.remove(chosen_idx);
    }

    selected
}

/// 取得連續紀錄
async fn get_streak(pool: &PgPool, user_id: Uuid) -> Result<QuestStreakRow, sqlx::Error> {
    let row = sqlx::query_as::<_, QuestStreakRow>(
        r#"
        SELECT current_streak, longest_streak, last_completed_date
        FROM quest_streaks
        WHERE user_id = $1
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await?;

    Ok(row.unwrap_or(QuestStreakRow {
        current_streak: 0,
        longest_streak: 0,
        last_completed_date: None,
    }))
}

/// 更新連續紀錄（在全部任務完成時呼叫）
async fn update_streak(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    user_id: Uuid,
    today: NaiveDate,
) -> Result<(), sqlx::Error> {
    let existing = sqlx::query_as::<_, QuestStreakRow>(
        r#"
        SELECT current_streak, longest_streak, last_completed_date
        FROM quest_streaks
        WHERE user_id = $1
        "#,
    )
    .bind(user_id)
    .fetch_optional(&mut **tx)
    .await?;

    let (new_streak, new_longest) = match existing {
        Some(row) => {
            let yesterday = today - chrono::Duration::days(1);
            if row.last_completed_date == Some(today) {
                // 今天已經更新過了
                return Ok(());
            } else if row.last_completed_date == Some(yesterday) {
                // 連續
                let s = row.current_streak + 1;
                (s, s.max(row.longest_streak))
            } else {
                // 斷了，重新開始
                (1, row.longest_streak.max(1))
            }
        }
        None => (1, 1),
    };

    sqlx::query(
        r#"
        INSERT INTO quest_streaks (user_id, current_streak, longest_streak, last_completed_date, updated_at)
        VALUES ($1, $2, $3, $4, NOW())
        ON CONFLICT (user_id) DO UPDATE
        SET current_streak = $2,
            longest_streak = $3,
            last_completed_date = $4,
            updated_at = NOW()
        "#,
    )
    .bind(user_id)
    .bind(new_streak)
    .bind(new_longest)
    .bind(today)
    .execute(&mut **tx)
    .await?;

    // 連續 7 天 bonus 獎勵
    if new_streak > 0 && new_streak % 7 == 0 {
        sqlx::query(
            r#"
            INSERT INTO transactions (user_id, type, amount, currency, description)
            VALUES ($1, 'streak_bonus', 25, 'gem', $2)
            "#,
        )
        .bind(user_id)
        .bind(format!("連續 {} 天全完成獎勵", new_streak))
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}

// ============================================================
// 遊戲結束資料
// ============================================================

/// 遊戲結束時的任務追蹤資料
#[derive(Debug, Clone)]
pub struct GameEndQuestData {
    pub players: Vec<PlayerQuestStats>,
    pub spectators: Vec<Uuid>,
}

/// 單一玩家的遊戲統計（用於任務追蹤）
#[derive(Debug, Clone)]
pub struct PlayerQuestStats {
    pub user_id: Uuid,
    pub is_winner: bool,
    pub final_reputation: i32,
    pub survived: bool,
    pub votes_cast: i32,
    pub attack_cards_used: i32,
    pub defense_cards_used: i32,
    pub alliances_formed: i32,
    pub challenges_initiated: i32,
    pub successful_counters: i32,
    pub skills_used: i32,
    pub cards_played_in_debate: i32,
    pub betrayals: i32,
    pub voted_for_winner: i32,
    pub reputation_damage_dealt: i32,
    pub reputation_healed: i32,
    pub gold_earned: i32,
    pub cards_drawn: i32,
}

// ============================================================
// 錯誤
// ============================================================

/// 領取獎勵錯誤
#[derive(Debug, thiserror::Error)]
pub enum ClaimError {
    #[error("任務不存在")]
    NotFound,
    #[error("任務尚未完成")]
    NotCompleted,
    #[error("獎勵已領取")]
    AlreadyClaimed,
    #[error("資料庫錯誤: {0}")]
    Db(sqlx::Error),
}

// ============================================================
// 測試
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Datelike;

    #[test]
    fn test_today_utc8() {
        let today = today_utc8();
        // 只確認不會 panic，日期合理
        assert!(today.year() >= 2024);
    }

    #[test]
    fn test_seconds_until_reset() {
        let secs = seconds_until_reset();
        assert!(secs >= 0);
        assert!(secs <= 86400); // 最多 24 小時
    }

    #[test]
    fn test_weighted_random_pick_no_duplicates() {
        let templates = all_quest_templates();
        let selected = weighted_random_pick(&templates, 3);
        assert_eq!(selected.len(), 3);

        // 確認無重複
        let types: Vec<QuestType> = selected.iter().map(|t| t.quest_type).collect();
        let mut unique = types.clone();
        unique.sort_by_key(|t| t.as_str().to_string());
        unique.dedup();
        assert_eq!(types.len(), unique.len());
    }

    #[test]
    fn test_weighted_random_pick_respects_count() {
        let templates = all_quest_templates();
        for count in [1, 2, 3, 5] {
            let selected = weighted_random_pick(&templates, count);
            assert_eq!(selected.len(), count);
        }
    }

    #[test]
    fn test_daily_quest_is_completed() {
        let q = DailyQuest {
            quest_id: "play_games".to_string(),
            quest_type: QuestType::PlayGames,
            name: "test".to_string(),
            description: "test".to_string(),
            progress: 2,
            target: 2,
            reward: QuestReward::Gold(50),
            claimed: false,
        };
        assert!(q.is_completed());

        let q2 = DailyQuest {
            progress: 1,
            ..q
        };
        assert!(!q2.is_completed());
    }
}
