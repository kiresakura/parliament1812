//! 賽季通行證服務
//!
//! 處理賽季通行證的 XP 累積、等級解鎖、獎勵領取、高級通行證購買

use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::season_pass::{
    AddXpResponse, LeaderboardEntry, PurchasePremiumResponse, SeasonPassProgress, SeasonPassResponse,
    SeasonPassTier, TierWithClaimStatus,
};
use crate::error::{AppError, AppResult};

/// XP 上限（防溢出）
const MAX_XP: i32 = 999_999;

pub struct SeasonPassService;

impl SeasonPassService {
    // ============================================================
    // 查詢通行證狀態
    // ============================================================

    /// 取得玩家的賽季通行證完整狀態
    ///
    /// - 如果進度記錄不存在，自動建立
    /// - 查詢所有等級並附帶領取狀態
    /// - 計算下一級所需 XP
    pub async fn get_pass_status(
        pool: &PgPool,
        user_id: Uuid,
        season_id: i32,
    ) -> AppResult<SeasonPassResponse> {
        // 查詢或建立進度記錄
        let progress = Self::get_or_create_progress(pool, user_id, season_id).await?;

        // 查詢所有等級
        let tiers = sqlx::query_as::<_, SeasonPassTier>(
            r#"
            SELECT id, season_id, tier_level, xp_required, free_reward, premium_reward, created_at
            FROM season_pass_tiers
            WHERE season_id = $1
            ORDER BY tier_level ASC
            "#,
        )
        .bind(season_id)
        .fetch_all(pool)
        .await?;

        // 查詢該玩家在此賽季的所有領取記錄
        let claims = sqlx::query_as::<_, ClaimRecord>(
            r#"
            SELECT tier_level, reward_track
            FROM season_reward_claims
            WHERE user_id = $1 AND season_id = $2
            "#,
        )
        .bind(user_id)
        .bind(season_id)
        .fetch_all(pool)
        .await?;

        // 組合等級 + 領取狀態
        let tiers_with_status: Vec<TierWithClaimStatus> = tiers
            .into_iter()
            .map(|tier| {
                let free_claimed = claims
                    .iter()
                    .any(|c| c.tier_level == tier.tier_level && c.reward_track == "free");
                let premium_claimed = claims
                    .iter()
                    .any(|c| c.tier_level == tier.tier_level && c.reward_track == "premium");
                let unlocked = progress.current_tier >= tier.tier_level;

                TierWithClaimStatus {
                    tier,
                    free_claimed,
                    premium_claimed,
                    unlocked,
                }
            })
            .collect();

        // 計算下一級所需 XP
        let next_tier_xp = tiers_with_status
            .iter()
            .find(|t| !t.unlocked)
            .map(|t| t.tier.xp_required);

        Ok(SeasonPassResponse {
            progress,
            tiers: tiers_with_status,
            next_tier_xp,
        })
    }

    // ============================================================
    // 增加 XP
    // ============================================================

    /// 增加玩家的賽季 XP
    ///
    /// - 更新 current_xp（防溢出，上限 999,999）
    /// - 檢查是否升級
    /// - 返回升級資訊和新解鎖的獎勵
    pub async fn add_xp(
        pool: &PgPool,
        user_id: Uuid,
        season_id: i32,
        xp_amount: i32,
        _source: &str,
    ) -> AppResult<AddXpResponse> {
        if xp_amount <= 0 {
            return Err(AppError::BadRequest("XP 數量必須為正數".to_string()));
        }

        // 確保進度記錄存在
        let progress = Self::get_or_create_progress(pool, user_id, season_id).await?;

        // 防溢出：計算新 XP
        let new_xp = progress
            .current_xp
            .saturating_add(xp_amount)
            .min(MAX_XP);

        // 取得所有等級（按等級排序）
        let tiers = sqlx::query_as::<_, SeasonPassTier>(
            r#"
            SELECT id, season_id, tier_level, xp_required, free_reward, premium_reward, created_at
            FROM season_pass_tiers
            WHERE season_id = $1
            ORDER BY tier_level ASC
            "#,
        )
        .bind(season_id)
        .fetch_all(pool)
        .await?;

        // 計算新等級：找到 xp_required <= new_xp 的最高等級
        let new_tier = tiers
            .iter()
            .filter(|t| t.xp_required <= new_xp)
            .map(|t| t.tier_level)
            .max()
            .unwrap_or(0);

        let leveled_up = new_tier > progress.current_tier;

        // 新解鎖的獎勵等級
        let unlocked_rewards: Vec<SeasonPassTier> = if leveled_up {
            tiers
                .into_iter()
                .filter(|t| t.tier_level > progress.current_tier && t.tier_level <= new_tier)
                .collect()
        } else {
            vec![]
        };

        // 更新資料庫
        sqlx::query(
            r#"
            UPDATE season_pass_progress
            SET current_xp = $1, current_tier = $2, updated_at = NOW()
            WHERE user_id = $3 AND season_id = $4
            "#,
        )
        .bind(new_xp)
        .bind(new_tier)
        .bind(user_id)
        .bind(season_id)
        .execute(pool)
        .await?;

        Ok(AddXpResponse {
            new_xp,
            new_tier,
            leveled_up,
            unlocked_rewards,
        })
    }

    // ============================================================
    // 領取獎勵
    // ============================================================

    /// 領取賽季獎勵
    ///
    /// - 驗證等級已解鎖
    /// - 如果是 premium 軌道，驗證已購買高級通行證
    /// - 使用 UNIQUE constraint 確保冪等性
    /// - 返回獎勵資料（JSONB）
    pub async fn claim_reward(
        pool: &PgPool,
        user_id: Uuid,
        season_id: i32,
        tier_level: i32,
        track: &str,
    ) -> AppResult<serde_json::Value> {
        // 驗證 track 值
        if track != "free" && track != "premium" {
            return Err(AppError::BadRequest(
                "獎勵軌道必須為 'free' 或 'premium'".to_string(),
            ));
        }

        // 取得玩家進度
        let progress = Self::get_or_create_progress(pool, user_id, season_id).await?;

        // 驗證等級已解鎖
        if progress.current_tier < tier_level {
            return Err(AppError::BadRequest(format!(
                "等級 {} 尚未解鎖（目前等級: {}）",
                tier_level, progress.current_tier
            )));
        }

        // 如果是 premium 軌道，驗證已購買高級通行證
        if track == "premium" && !progress.is_premium {
            return Err(AppError::Forbidden(
                "需要購買高級通行證才能領取高級獎勵".to_string(),
            ));
        }

        // 取得該等級的獎勵資料
        let tier = sqlx::query_as::<_, SeasonPassTier>(
            r#"
            SELECT id, season_id, tier_level, xp_required, free_reward, premium_reward, created_at
            FROM season_pass_tiers
            WHERE season_id = $1 AND tier_level = $2
            "#,
        )
        .bind(season_id)
        .bind(tier_level)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("賽季 {} 等級 {} 不存在", season_id, tier_level)))?;

        // 取得對應軌道的獎勵
        let reward = match track {
            "free" => tier.free_reward.clone(),
            "premium" => tier.premium_reward.clone(),
            _ => unreachable!(),
        };

        let reward = reward.unwrap_or(serde_json::json!({"type": "none", "message": "此等級無獎勵"}));

        // INSERT 領取記錄（UNIQUE constraint 保證冪等）
        let result = sqlx::query(
            r#"
            INSERT INTO season_reward_claims (user_id, season_id, tier_level, reward_track)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_id, season_id, tier_level, reward_track) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(season_id)
        .bind(tier_level)
        .bind(track)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            // 已經領取過了，仍返回獎勵資料（冪等）
            tracing::debug!(
                user_id = %user_id,
                season_id = season_id,
                tier_level = tier_level,
                track = track,
                "獎勵已領取過（冪等返回）"
            );
        }

        Ok(reward)
    }

    // ============================================================
    // 購買高級通行證
    // ============================================================

    /// 購買高級通行證
    ///
    /// 設定 is_premium = true 和購買時間
    pub async fn purchase_premium(
        pool: &PgPool,
        user_id: Uuid,
        season_id: i32,
    ) -> AppResult<PurchasePremiumResponse> {
        // 確保進度記錄存在
        let progress = Self::get_or_create_progress(pool, user_id, season_id).await?;

        if progress.is_premium {
            return Ok(PurchasePremiumResponse {
                success: true,
                message: "已擁有高級通行證".to_string(),
            });
        }

        sqlx::query(
            r#"
            UPDATE season_pass_progress
            SET is_premium = true, premium_purchased_at = NOW(), updated_at = NOW()
            WHERE user_id = $1 AND season_id = $2
            "#,
        )
        .bind(user_id)
        .bind(season_id)
        .execute(pool)
        .await?;

        tracing::info!(
            user_id = %user_id,
            season_id = season_id,
            "玩家購買了高級通行證"
        );

        Ok(PurchasePremiumResponse {
            success: true,
            message: "高級通行證購買成功".to_string(),
        })
    }

    // ============================================================
    // 排行榜
    // ============================================================

    /// 取得賽季 XP 排行榜
    ///
    /// 按 current_xp 降序排列
    pub async fn get_leaderboard(
        pool: &PgPool,
        season_id: i32,
        limit: i64,
    ) -> AppResult<Vec<LeaderboardEntry>> {
        let limit = limit.min(100).max(1); // 限制 1~100

        let entries = sqlx::query_as::<_, LeaderboardEntry>(
            r#"
            SELECT
                p.user_id,
                u.username,
                p.current_xp,
                p.current_tier,
                p.is_premium
            FROM season_pass_progress p
            JOIN users u ON u.id = p.user_id
            WHERE p.season_id = $1
            ORDER BY p.current_xp DESC
            LIMIT $2
            "#,
        )
        .bind(season_id)
        .bind(limit)
        .fetch_all(pool)
        .await?;

        Ok(entries)
    }

    // ============================================================
    // 內部工具
    // ============================================================

    /// 查詢或建立玩家的賽季進度記錄
    ///
    /// 如果記錄不存在，自動建立預設值
    async fn get_or_create_progress(
        pool: &PgPool,
        user_id: Uuid,
        season_id: i32,
    ) -> AppResult<SeasonPassProgress> {
        let progress = sqlx::query_as::<_, SeasonPassProgress>(
            r#"
            INSERT INTO season_pass_progress (user_id, season_id)
            VALUES ($1, $2)
            ON CONFLICT (user_id, season_id) DO UPDATE SET updated_at = NOW()
            RETURNING id, user_id, season_id, current_xp, current_tier,
                      is_premium, premium_purchased_at, created_at, updated_at
            "#,
        )
        .bind(user_id)
        .bind(season_id)
        .fetch_one(pool)
        .await?;

        Ok(progress)
    }
}

// ============================================================
// 內部結構
// ============================================================

/// 領取記錄查詢結果（僅查需要的欄位）
#[derive(Debug, sqlx::FromRow)]
struct ClaimRecord {
    pub tier_level: i32,
    pub reward_track: String,
}
