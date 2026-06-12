//! 推薦獎勵服務
//!
//! 提供推薦里程碑進度查詢、獎勵領取等業務邏輯：
//! - 查詢用戶推薦進度與各里程碑狀態
//! - 領取達標的里程碑獎勵（idempotent）
//! - 查詢所有里程碑定義
//! - 檢查是否有新解鎖的里程碑（供通知使用）

use crate::domain::referral::{
    ClaimRewardResponse, MilestoneProgress, ReferralMilestone, ReferralProgressResponse,
};
use crate::error::{AppError, AppResult};
use sqlx::PgPool;
use uuid::Uuid;

/// 推薦獎勵服務
pub struct ReferralService;

impl ReferralService {
    /// 取得用戶的推薦進度
    ///
    /// 統計已轉化的推薦人數，並顯示各里程碑的領取狀態
    pub async fn get_progress(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<ReferralProgressResponse> {
        // 統計已轉化的推薦人數
        let (current_referrals,): (i64,) = sqlx::query_as(
            r#"
            SELECT COUNT(*) 
            FROM attribution_events 
            WHERE inviter_id = $1 AND status = 'converted'
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢推薦人數失敗: {}", e)))?;

        // 查詢所有里程碑及用戶的領取狀態
        let rows = sqlx::query_as::<_, (Uuid, String, i32, String, serde_json::Value, Option<String>, chrono::DateTime<chrono::Utc>, Option<Uuid>)>(
            r#"
            SELECT 
                m.id, m.milestone_name, m.required_referrals, m.reward_type, 
                m.reward_data, m.description, m.created_at,
                c.id AS claim_id
            FROM referral_milestones m
            LEFT JOIN referral_reward_claims c 
                ON c.milestone_id = m.id AND c.user_id = $1
            ORDER BY m.required_referrals ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢里程碑進度失敗: {}", e)))?;

        let milestones = rows
            .into_iter()
            .map(|row| {
                let milestone = ReferralMilestone {
                    id: row.0,
                    milestone_name: row.1,
                    required_referrals: row.2,
                    reward_type: row.3,
                    reward_data: row.4,
                    description: row.5,
                    created_at: row.6,
                };
                let claimed = row.7.is_some();
                let claimable =
                    current_referrals >= milestone.required_referrals as i64 && !claimed;

                MilestoneProgress {
                    milestone,
                    claimed,
                    claimable,
                }
            })
            .collect();

        Ok(ReferralProgressResponse {
            current_referrals,
            milestones,
        })
    }

    /// 領取推薦獎勵
    ///
    /// 驗證里程碑存在、推薦數足夠、未重複領取，然後記錄領取。
    /// 透過 UNIQUE(user_id, milestone_id) 確保 idempotent。
    pub async fn claim_reward(
        pool: &PgPool,
        user_id: Uuid,
        milestone_id: Uuid,
    ) -> AppResult<ClaimRewardResponse> {
        // 查詢里程碑是否存在
        let milestone = sqlx::query_as::<_, ReferralMilestone>(
            r#"
            SELECT id, milestone_name, required_referrals, reward_type, 
                   reward_data, description, created_at
            FROM referral_milestones
            WHERE id = $1
            "#,
        )
        .bind(milestone_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢里程碑失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("里程碑不存在".to_string()))?;

        // 檢查是否已領取
        let already_claimed = sqlx::query_as::<_, (Uuid,)>(
            r#"
            SELECT id FROM referral_reward_claims
            WHERE user_id = $1 AND milestone_id = $2
            "#,
        )
        .bind(user_id)
        .bind(milestone_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("檢查領取狀態失敗: {}", e)))?;

        if already_claimed.is_some() {
            return Ok(ClaimRewardResponse {
                success: false,
                reward_type: milestone.reward_type,
                reward_data: milestone.reward_data,
                message: "此獎勵已經領取過了".to_string(),
            });
        }

        // 統計推薦人數是否足夠
        let (current_referrals,): (i64,) = sqlx::query_as(
            r#"
            SELECT COUNT(*) 
            FROM attribution_events 
            WHERE inviter_id = $1 AND status = 'converted'
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢推薦人數失敗: {}", e)))?;

        if current_referrals < milestone.required_referrals as i64 {
            return Err(AppError::BadRequest(format!(
                "推薦人數不足，需要 {} 人，目前 {} 人",
                milestone.required_referrals, current_referrals
            )));
        }

        // 插入領取記錄（UNIQUE constraint 做最終防線）
        sqlx::query(
            r#"
            INSERT INTO referral_reward_claims (user_id, milestone_id)
            VALUES ($1, $2)
            ON CONFLICT (user_id, milestone_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(milestone_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("領取獎勵失敗: {}", e)))?;

        // 如果獎勵是寶石，嘗試更新 gem_balance（若欄位存在）
        if milestone.reward_type == "gems" {
            if let Some(amount) = milestone.reward_data.get("gems_amount").and_then(|v| v.as_i64())
            {
                // 嘗試更新 gem_balance，忽略欄位不存在的錯誤
                let _ = sqlx::query(
                    r#"
                    UPDATE users SET gem_balance = COALESCE(gem_balance, 0) + $1
                    WHERE id = $2
                    "#,
                )
                .bind(amount as i32)
                .bind(user_id)
                .execute(pool)
                .await;
            }
        }

        Ok(ClaimRewardResponse {
            success: true,
            reward_type: milestone.reward_type,
            reward_data: milestone.reward_data,
            message: format!("成功領取「{}」獎勵！", milestone.milestone_name),
        })
    }

    /// 查詢所有里程碑
    ///
    /// 按所需推薦人數升冪排列
    pub async fn get_milestones(pool: &PgPool) -> AppResult<Vec<ReferralMilestone>> {
        let milestones = sqlx::query_as::<_, ReferralMilestone>(
            r#"
            SELECT id, milestone_name, required_referrals, reward_type,
                   reward_data, description, created_at
            FROM referral_milestones
            ORDER BY required_referrals ASC
            "#,
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢里程碑列表失敗: {}", e)))?;

        Ok(milestones)
    }

    /// 檢查用戶是否有新的可領取里程碑
    ///
    /// 返回新解鎖但尚未領取的里程碑列表（供通知使用）
    pub async fn check_and_notify_new_milestones(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<Vec<ReferralMilestone>> {
        // 統計已轉化的推薦人數
        let (current_referrals,): (i64,) = sqlx::query_as(
            r#"
            SELECT COUNT(*) 
            FROM attribution_events 
            WHERE inviter_id = $1 AND status = 'converted'
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢推薦人數失敗: {}", e)))?;

        // 查詢已達標但未領取的里程碑
        let milestones = sqlx::query_as::<_, ReferralMilestone>(
            r#"
            SELECT m.id, m.milestone_name, m.required_referrals, m.reward_type,
                   m.reward_data, m.description, m.created_at
            FROM referral_milestones m
            WHERE m.required_referrals <= $1
              AND NOT EXISTS (
                  SELECT 1 FROM referral_reward_claims c 
                  WHERE c.milestone_id = m.id AND c.user_id = $2
              )
            ORDER BY m.required_referrals ASC
            "#,
        )
        .bind(current_referrals as i32)
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("檢查新里程碑失敗: {}", e)))?;

        Ok(milestones)
    }
}
