//! 歸因追蹤服務
//!
//! 提供邀請連結生成、解析、轉化追蹤等業務邏輯：
//! - 生成帶有唯一 token 的邀請連結
//! - 解析邀請連結並追蹤點擊
//! - 標記用戶轉化狀態
//! - 統計邀請成效與 K-factor

use crate::domain::attribution::{InviteLink, InviteResolution, InviteStats};
use crate::error::{AppError, AppResult};
use chrono::Utc;
use rand::Rng;
use sqlx::PgPool;
use uuid::Uuid;

/// URL-safe 字元集（用於生成邀請 token）
const URL_SAFE_CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/// 歸因追蹤服務
pub struct AttributionService;

impl AttributionService {
    /// 生成邀請連結
    ///
    /// 產生唯一的 URL-safe token 並寫入資料庫
    pub async fn generate_invite(
        pool: &PgPool,
        inviter_id: Uuid,
        channel: &str,
    ) -> AppResult<InviteLink> {
        // 產生 64 字元的 URL-safe token
        let token = Self::generate_token(64);

        let row = sqlx::query_as::<_, (Uuid,)>(
            r#"
            INSERT INTO attribution_events (inviter_id, channel, deep_link_token, status)
            VALUES ($1, $2, $3, 'pending')
            RETURNING id
            "#,
        )
        .bind(inviter_id)
        .bind(channel)
        .bind(&token)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("建立邀請連結失敗: {}", e)))?;

        let share_url = format!("https://1812game.com/join/{}", token);

        Ok(InviteLink {
            invite_id: row.0,
            token,
            share_url,
        })
    }

    /// 解析邀請連結
    ///
    /// 查詢 token 對應的記錄，增加點擊計數，
    /// 如果狀態為 pending 則更新為 clicked
    pub async fn resolve_invite(pool: &PgPool, token: &str) -> AppResult<InviteResolution> {
        // 查詢並更新點擊數，同時將 pending 狀態更新為 clicked
        let row = sqlx::query_as::<_, (Option<Uuid>, String, String)>(
            r#"
            UPDATE attribution_events
            SET click_count = click_count + 1,
                status = CASE WHEN status = 'pending' THEN 'clicked' ELSE status END
            WHERE deep_link_token = $1
            RETURNING inviter_id, channel, status
            "#,
        )
        .bind(token)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("解析邀請連結失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("邀請連結不存在或已失效".to_string()))?;

        Ok(InviteResolution {
            inviter_id: row.0,
            channel: row.1,
            status: row.2,
        })
    }

    /// 標記轉化狀態
    ///
    /// 更新邀請事件的轉化狀態：
    /// - registered: 被邀請者已註冊
    /// - first_game: 被邀請者完成首場遊戲
    /// - converted: 完全轉化
    pub async fn mark_conversion(
        pool: &PgPool,
        invitee_id: Uuid,
        token: &str,
        conversion_type: &str,
    ) -> AppResult<()> {
        // 驗證 conversion_type 合法性
        match conversion_type {
            "registered" | "first_game" | "converted" => {}
            _ => {
                return Err(AppError::BadRequest(format!(
                    "無效的轉化類型: {}",
                    conversion_type
                )));
            }
        }

        // 根據轉化類型決定是否設置 converted_at
        let converted_at = if conversion_type == "converted" {
            Some(Utc::now())
        } else {
            None
        };

        let result = sqlx::query(
            r#"
            UPDATE attribution_events
            SET invitee_id = $1,
                status = $2,
                converted_at = COALESCE($3, converted_at)
            WHERE deep_link_token = $4
            "#,
        )
        .bind(invitee_id)
        .bind(conversion_type)
        .bind(converted_at)
        .bind(token)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("標記轉化失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("邀請記錄不存在".to_string()));
        }

        Ok(())
    }

    /// 取得用戶的邀請統計
    ///
    /// 統計該用戶所有邀請連結的各狀態數量並計算 K-factor
    pub async fn get_invite_stats(pool: &PgPool, user_id: Uuid) -> AppResult<InviteStats> {
        let row = sqlx::query_as::<_, (i64, i64, i64, i64)>(
            r#"
            SELECT
                COUNT(*) AS total_invites,
                COALESCE(SUM(click_count), 0) AS total_clicks,
                COUNT(*) FILTER (WHERE status IN ('registered', 'first_game', 'converted')) AS total_registered,
                COUNT(*) FILTER (WHERE status = 'converted') AS total_converted
            FROM attribution_events
            WHERE inviter_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢邀請統計失敗: {}", e)))?;

        let total_invites = row.0;
        let total_clicks = row.1;
        let total_registered = row.2;
        let total_converted = row.3;

        // K-factor = 已轉化數 / max(總邀請數, 1)
        let k_factor = total_converted as f64 / total_invites.max(1) as f64;

        Ok(InviteStats {
            total_invites,
            total_clicks,
            total_registered,
            total_converted,
            k_factor,
        })
    }

    /// 計算全站 K-factor
    ///
    /// 統計過去 N 天內的全站病毒傳播係數
    pub async fn calculate_k_factor(pool: &PgPool, days: i64) -> AppResult<f64> {
        let row = sqlx::query_as::<_, (i64, i64)>(
            r#"
            SELECT
                COUNT(*) AS total_invites,
                COUNT(*) FILTER (WHERE status = 'converted') AS total_converted
            FROM attribution_events
            WHERE created_at >= NOW() - make_interval(days => $1::int)
            "#,
        )
        .bind(days as i32)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("計算全站 K-factor 失敗: {}", e)))?;

        let total_invites = row.0;
        let total_converted = row.1;

        Ok(total_converted as f64 / total_invites.max(1) as f64)
    }

    /// 產生 URL-safe 隨機 token
    fn generate_token(length: usize) -> String {
        let mut rng = rand::thread_rng();
        (0..length)
            .map(|_| {
                let idx = rng.gen_range(0..URL_SAFE_CHARS.len());
                URL_SAFE_CHARS[idx] as char
            })
            .collect()
    }
}
