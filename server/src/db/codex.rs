//! 圖鑑 & 成就資料庫操作
//!
//! 處理 cards_collection 和 achievements_progress 表的讀寫。

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

// ═══════════════════════════════════════════
// 卡牌收藏
// ═══════════════════════════════════════════

/// 收藏記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct CollectionRecord {
    pub user_id: Uuid,
    pub card_id: String,
    pub obtained_at: Option<DateTime<Utc>>,
}

/// 卡牌收藏 DB 操作
pub struct CollectionDb;

impl CollectionDb {
    /// 取得使用者已收藏的所有卡牌 ID
    pub async fn get_user_collection(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<String>, sqlx::Error> {
        let records = sqlx::query_scalar::<_, String>(
            r#"SELECT card_id FROM cards_collection WHERE user_id = $1 ORDER BY obtained_at"#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await?;

        Ok(records)
    }

    /// 取得使用者收藏數量
    pub async fn get_collection_count(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar::<_, i64>(
            r#"SELECT COUNT(*) FROM cards_collection WHERE user_id = $1"#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
    }

    /// 新增卡牌到收藏（如已存在則忽略）
    pub async fn add_card(
        pool: &PgPool,
        user_id: Uuid,
        card_id: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            INSERT INTO cards_collection (user_id, card_id)
            VALUES ($1, $2)
            ON CONFLICT (user_id, card_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(card_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 批量新增卡牌到收藏
    pub async fn add_cards(
        pool: &PgPool,
        user_id: Uuid,
        card_ids: &[&str],
    ) -> Result<u64, sqlx::Error> {
        let mut added = 0u64;
        for card_id in card_ids {
            let result = sqlx::query(
                r#"
                INSERT INTO cards_collection (user_id, card_id)
                VALUES ($1, $2)
                ON CONFLICT (user_id, card_id) DO NOTHING
                "#,
            )
            .bind(user_id)
            .bind(*card_id)
            .execute(pool)
            .await?;
            added += result.rows_affected();
        }
        Ok(added)
    }

    /// 檢查使用者是否擁有某張卡
    pub async fn has_card(
        pool: &PgPool,
        user_id: Uuid,
        card_id: &str,
    ) -> Result<bool, sqlx::Error> {
        let exists = sqlx::query_scalar::<_, bool>(
            r#"SELECT EXISTS(SELECT 1 FROM cards_collection WHERE user_id = $1 AND card_id = $2)"#,
        )
        .bind(user_id)
        .bind(card_id)
        .fetch_one(pool)
        .await?;

        Ok(exists)
    }
}

// ═══════════════════════════════════════════
// 成就進度
// ═══════════════════════════════════════════

/// 成就進度記錄
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct AchievementRecord {
    pub user_id: Uuid,
    pub achievement_id: String,
    pub progress: i32,
    pub completed: bool,
    pub claimed: bool,
    pub completed_at: Option<DateTime<Utc>>,
}

/// 成就 DB 操作
pub struct AchievementDb;

impl AchievementDb {
    /// 取得使用者的所有成就進度
    pub async fn get_user_achievements(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<AchievementRecord>, sqlx::Error> {
        sqlx::query_as::<_, AchievementRecord>(
            r#"
            SELECT user_id, achievement_id, progress, completed, claimed, completed_at
            FROM achievements_progress
            WHERE user_id = $1
            ORDER BY achievement_id
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
    }

    /// 取得特定成就進度
    pub async fn get_achievement_progress(
        pool: &PgPool,
        user_id: Uuid,
        achievement_id: &str,
    ) -> Result<Option<AchievementRecord>, sqlx::Error> {
        sqlx::query_as::<_, AchievementRecord>(
            r#"
            SELECT user_id, achievement_id, progress, completed, claimed, completed_at
            FROM achievements_progress
            WHERE user_id = $1 AND achievement_id = $2
            "#,
        )
        .bind(user_id)
        .bind(achievement_id)
        .fetch_optional(pool)
        .await
    }

    /// 更新成就進度（upsert）
    pub async fn update_progress(
        pool: &PgPool,
        user_id: Uuid,
        achievement_id: &str,
        progress: i32,
        completed: bool,
    ) -> Result<AchievementRecord, sqlx::Error> {
        sqlx::query_as::<_, AchievementRecord>(
            r#"
            INSERT INTO achievements_progress (user_id, achievement_id, progress, completed, completed_at)
            VALUES ($1, $2, $3, $4, CASE WHEN $4 THEN NOW() ELSE NULL END)
            ON CONFLICT (user_id, achievement_id)
            DO UPDATE SET
                progress = GREATEST(achievements_progress.progress, $3),
                completed = achievements_progress.completed OR $4,
                completed_at = CASE
                    WHEN NOT achievements_progress.completed AND $4 THEN NOW()
                    ELSE achievements_progress.completed_at
                END
            RETURNING user_id, achievement_id, progress, completed, claimed, completed_at
            "#,
        )
        .bind(user_id)
        .bind(achievement_id)
        .bind(progress)
        .bind(completed)
        .fetch_one(pool)
        .await
    }

    /// 領取成就獎勵
    pub async fn claim_reward(
        pool: &PgPool,
        user_id: Uuid,
        achievement_id: &str,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            r#"
            UPDATE achievements_progress
            SET claimed = TRUE
            WHERE user_id = $1 AND achievement_id = $2 AND completed = TRUE AND claimed = FALSE
            "#,
        )
        .bind(user_id)
        .bind(achievement_id)
        .execute(pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// 取得已完成但未領取的成就數量
    pub async fn get_unclaimed_count(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM achievements_progress
            WHERE user_id = $1 AND completed = TRUE AND claimed = FALSE
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
    }
}

// ═══════════════════════════════════════════
// 複合查詢：遊戲結束時的解鎖邏輯
// ═══════════════════════════════════════════

/// 遊戲結束時的統計資料（用於解鎖判斷）
pub struct GameEndStats {
    pub user_id: Uuid,
    pub is_winner: bool,
    pub character: String,
    pub total_games: i32,
    pub total_wins: i32,
}

/// 遊戲結束後檢查卡牌解鎖
///
/// 根據玩家的遊戲次數、勝場等條件，自動解鎖對應的卡牌。
/// 返回新解鎖的卡牌 ID 列表。
pub async fn check_card_unlocks(
    pool: &PgPool,
    stats: &GameEndStats,
) -> Result<Vec<String>, sqlx::Error> {
    use crate::game::card_codex::get_all_codex_entries;

    let existing = CollectionDb::get_user_collection(pool, stats.user_id).await?;
    let mut newly_unlocked = Vec::new();

    for entry in get_all_codex_entries() {
        if existing.contains(&entry.id) {
            continue;
        }

        let should_unlock = match entry.unlock_condition.as_str() {
            "初始擁有" => true,
            s if s.starts_with("完成") && s.contains("場對局") => {
                let n = parse_number_from_condition(s);
                stats.total_games >= n
            }
            s if s.starts_with("贏得") && s.contains("場對局") => {
                let n = parse_number_from_condition(s);
                stats.total_wins >= n
            }
            // 其他條件（角色特定、成就特定等）由各自的系統處理
            _ => false,
        };

        if should_unlock {
            if CollectionDb::add_card(pool, stats.user_id, &entry.id).await? {
                newly_unlocked.push(entry.id);
            }
        }
    }

    Ok(newly_unlocked)
}

/// 遊戲結束後檢查成就進度
///
/// 更新可自動追蹤的成就進度（如場次、勝場、收藏數等）。
/// 返回新完成的成就 ID 列表。
pub async fn check_achievements(
    pool: &PgPool,
    stats: &GameEndStats,
) -> Result<Vec<String>, sqlx::Error> {
    use crate::game::achievements::{get_all_achievements, AchievementCondition};

    let collection_count = CollectionDb::get_collection_count(pool, stats.user_id).await?;
    let mut newly_completed = Vec::new();

    for achievement in get_all_achievements() {
        let (progress, target) = match &achievement.condition {
            AchievementCondition::PlayGames { target } => {
                (stats.total_games, *target)
            }
            AchievementCondition::WinGames { target } => {
                (stats.total_wins, *target)
            }
            AchievementCondition::CollectCards { target } => {
                (collection_count as i32, *target)
            }
            // 其他條件需要更多上下文，暫時跳過
            _ => continue,
        };

        let completed = progress >= target;
        let record = AchievementDb::update_progress(
            pool,
            stats.user_id,
            &achievement.id,
            progress,
            completed,
        )
        .await?;

        // 檢查是否新完成
        if record.completed && completed {
            // 用前一次查詢比較（簡化：如果 completed_at 是新的就算）
            newly_completed.push(achievement.id);
        }
    }

    Ok(newly_completed)
}

/// 從解鎖條件字串中解析數字
fn parse_number_from_condition(s: &str) -> i32 {
    s.chars()
        .filter(|c| c.is_ascii_digit())
        .collect::<String>()
        .parse::<i32>()
        .unwrap_or(i32::MAX)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_number() {
        assert_eq!(parse_number_from_condition("完成 1 場對局"), 1);
        assert_eq!(parse_number_from_condition("完成 10 場對局"), 10);
        assert_eq!(parse_number_from_condition("贏得 50 場對局"), 50);
    }
}
