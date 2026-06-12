//! 單人模式服務
//!
//! 管理 AI 快速對戰和每日限制

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;
use crate::game::ai::AIDifficulty;
use crate::services::iap_service::IapService;

/// 每日免費 AI 對戰次數
pub const DAILY_FREE_AI_MATCHES: i32 = 10;

/// AI 難度映射（API 層使用）
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum ApiDifficulty {
    Easy,
    Medium,
    Hard,
    Expert,
}

impl ApiDifficulty {
    /// 轉換為引擎 AI 難度
    pub fn to_engine_difficulty(self) -> AIDifficulty {
        match self {
            ApiDifficulty::Easy => AIDifficulty::Easy,
            ApiDifficulty::Medium => AIDifficulty::Normal,
            ApiDifficulty::Hard => AIDifficulty::Hard,
            // Expert 使用 Hard + 額外策略增強
            ApiDifficulty::Expert => AIDifficulty::Hard,
        }
    }

    /// Expert 是否開啟進階策略
    pub fn is_expert(&self) -> bool {
        matches!(self, ApiDifficulty::Expert)
    }

    /// 顯示名稱
    pub fn display_name(&self) -> &str {
        match self {
            ApiDifficulty::Easy => "簡單",
            ApiDifficulty::Medium => "普通",
            ApiDifficulty::Hard => "困難",
            ApiDifficulty::Expert => "專家",
        }
    }
}

/// 快速對戰請求
#[derive(Debug, Deserialize)]
pub struct QuickMatchRequest {
    /// 難度
    pub difficulty: ApiDifficulty,
    /// 選擇的角色（可選）
    pub character: Option<String>,
}

/// 快速對戰回應
#[derive(Debug, Serialize)]
pub struct QuickMatchResponse {
    /// 對戰 ID
    pub match_id: Uuid,
    /// 剩餘免費次數
    pub remaining_free: i32,
    /// 是否有無限次權限
    pub has_unlimited: bool,
}

/// 每日對戰狀態
#[derive(Debug, Serialize)]
pub struct DailyAiStatusResponse {
    /// 今日已用次數
    pub matches_today: i32,
    /// 每日免費上限
    pub daily_limit: i32,
    /// 剩餘免費次數
    pub remaining_free: i32,
    /// 是否有無限次權限
    pub has_unlimited: bool,
    /// 無限次到期時間（如果有）
    pub unlimited_until: Option<DateTime<Utc>>,
}

/// 單人模式服務
pub struct SinglePlayerService;

impl SinglePlayerService {
    /// 檢查使用者今日 AI 對戰次數
    pub async fn get_daily_status(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<DailyAiStatusResponse, AppError> {
        let has_unlimited = IapService::has_ai_unlimited(pool, user_id).await?;

        let matches_today = Self::count_today_matches(pool, user_id).await?;

        let unlimited_until = sqlx::query_scalar::<_, Option<DateTime<Utc>>>(
            "SELECT ai_unlimited_until FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let remaining = if has_unlimited {
            DAILY_FREE_AI_MATCHES // 顯示上限值（實際無限）
        } else {
            (DAILY_FREE_AI_MATCHES - matches_today).max(0)
        };

        Ok(DailyAiStatusResponse {
            matches_today,
            daily_limit: DAILY_FREE_AI_MATCHES,
            remaining_free: remaining,
            has_unlimited,
            unlimited_until,
        })
    }

    /// 建立快速對戰
    pub async fn create_quick_match(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        request: &QuickMatchRequest,
    ) -> Result<QuickMatchResponse, AppError> {
        let has_unlimited = IapService::has_ai_unlimited(pool, user_id).await?;
        let matches_today = Self::count_today_matches(pool, user_id).await?;

        // 檢查次數限制
        if !has_unlimited && matches_today >= DAILY_FREE_AI_MATCHES {
            return Err(AppError::Forbidden(format!(
                "今日免費 AI 對戰次數已用完（{}/{}）。購買月卡可無限對戰。",
                matches_today, DAILY_FREE_AI_MATCHES
            )));
        }

        // 建立對戰記錄
        let match_id = Uuid::new_v4();
        sqlx::query(
            r#"
            INSERT INTO ai_matches (id, user_id, difficulty, character_choice, started_at)
            VALUES ($1, $2, $3, $4, NOW())
            "#,
        )
        .bind(match_id)
        .bind(user_id)
        .bind(format!("{:?}", request.difficulty))
        .bind(&request.character)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let remaining = if has_unlimited {
            DAILY_FREE_AI_MATCHES
        } else {
            (DAILY_FREE_AI_MATCHES - matches_today - 1).max(0)
        };

        Ok(QuickMatchResponse {
            match_id,
            remaining_free: remaining,
            has_unlimited,
        })
    }

    /// 記錄對戰結果
    pub async fn record_match_result(
        pool: &sqlx::PgPool,
        match_id: Uuid,
        user_id: Uuid,
        won: bool,
        score: i32,
    ) -> Result<(), AppError> {
        sqlx::query(
            r#"
            UPDATE ai_matches
            SET finished_at = NOW(), won = $1, score = $2
            WHERE id = $3 AND user_id = $4
            "#,
        )
        .bind(won)
        .bind(score)
        .bind(match_id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// 計算使用者今日的 AI 對戰次數
    async fn count_today_matches(pool: &sqlx::PgPool, user_id: Uuid) -> Result<i32, AppError> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*)
            FROM ai_matches
            WHERE user_id = $1
              AND started_at >= CURRENT_DATE
              AND started_at < CURRENT_DATE + INTERVAL '1 day'
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(count as i32)
    }

    /// 取得使用者 AI 對戰歷史
    pub async fn get_match_history(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        limit: i64,
    ) -> Result<Vec<AiMatchRecord>, AppError> {
        let records = sqlx::query_as::<_, AiMatchRecord>(
            r#"
            SELECT id, user_id, difficulty, character_choice,
                   started_at, finished_at, won, score
            FROM ai_matches
            WHERE user_id = $1
            ORDER BY started_at DESC
            LIMIT $2
            "#,
        )
        .bind(user_id)
        .bind(limit)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(records)
    }
}

/// AI 對戰記錄
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct AiMatchRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub difficulty: String,
    pub character_choice: Option<String>,
    pub started_at: DateTime<Utc>,
    pub finished_at: Option<DateTime<Utc>>,
    pub won: Option<bool>,
    pub score: Option<i32>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_api_difficulty_to_engine() {
        assert_eq!(
            ApiDifficulty::Easy.to_engine_difficulty(),
            AIDifficulty::Easy
        );
        assert_eq!(
            ApiDifficulty::Medium.to_engine_difficulty(),
            AIDifficulty::Normal
        );
        assert_eq!(
            ApiDifficulty::Hard.to_engine_difficulty(),
            AIDifficulty::Hard
        );
        assert_eq!(
            ApiDifficulty::Expert.to_engine_difficulty(),
            AIDifficulty::Hard
        );
    }

    #[test]
    fn test_expert_flag() {
        assert!(!ApiDifficulty::Easy.is_expert());
        assert!(!ApiDifficulty::Medium.is_expert());
        assert!(!ApiDifficulty::Hard.is_expert());
        assert!(ApiDifficulty::Expert.is_expert());
    }

    #[test]
    fn test_display_names() {
        assert_eq!(ApiDifficulty::Easy.display_name(), "簡單");
        assert_eq!(ApiDifficulty::Medium.display_name(), "普通");
        assert_eq!(ApiDifficulty::Hard.display_name(), "困難");
        assert_eq!(ApiDifficulty::Expert.display_name(), "專家");
    }

    #[test]
    fn test_daily_free_limit() {
        assert_eq!(DAILY_FREE_AI_MATCHES, 10);
    }
}
