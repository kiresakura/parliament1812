//! 傳票邀請服務
//!
//! 提供維多利亞風格「國會傳票」邀請功能：
//! - 生成傳票式邀請連結（結合歸因追蹤系統）
//! - 查詢邀請者戰績統計
//! - 根據 ELO 分配議員頭銜

use crate::domain::summons::{CreateSummonsRequest, InviterStats, SummonsResponse};
use crate::error::{AppError, AppResult};
use crate::services::AttributionService;
use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

/// 傳票邀請服務
pub struct SummonsService;

impl SummonsService {
    /// 建立傳票式邀請
    ///
    /// 透過歸因追蹤系統產生邀請連結，並組合維多利亞風格的分享文字。
    /// 如果 `include_stats` 為 true，會一併查詢邀請者的遊戲統計。
    pub async fn create_summons(
        pool: &PgPool,
        user_id: Uuid,
        request: CreateSummonsRequest,
    ) -> AppResult<SummonsResponse> {
        // 透過歸因追蹤系統產生邀請連結（channel = "summons"）
        let invite_link =
            AttributionService::generate_invite(pool, user_id, "summons").await?;

        // 查詢邀請者的顯示名稱
        let inviter_name = Self::get_inviter_name(pool, user_id).await?;

        // 如果要求包含戰績，查詢邀請者統計
        let inviter_stats = if request.include_stats {
            Some(Self::get_inviter_stats(pool, user_id).await?)
        } else {
            None
        };

        // 組合自訂訊息
        let custom_message_line = request
            .message
            .as_deref()
            .map(|msg| format!("\n「{}」", msg))
            .unwrap_or_default();

        // 產生維多利亞風格分享文字
        let share_text = format!(
            "【國會傳票】\n{} 正式傳喚 {} 出席國會辯論！{}\n立即就任 → {}",
            inviter_name, request.target_name, custom_message_line, invite_link.share_url
        );

        Ok(SummonsResponse {
            summons_id: invite_link.invite_id,
            share_url: invite_link.share_url,
            share_text,
            inviter_stats,
            created_at: Utc::now(),
        })
    }

    /// 取得邀請者戰績統計
    ///
    /// 查詢用戶的 ELO、遊戲場數、勝率、偏好陣營，
    /// 並根據 ELO 分數分配對應的議員頭銜。
    pub async fn get_inviter_stats(pool: &PgPool, user_id: Uuid) -> AppResult<InviterStats> {
        // 從 users 表查詢 ELO 分數
        let elo_rating: i32 = sqlx::query_scalar(
            r#"SELECT COALESCE(elo_rating, 1000) FROM users WHERE id = $1"#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢用戶 ELO 失敗: {}", e)))?;

        // 從 players 表統計遊戲場數和勝率
        // 透過 join rooms 表來判斷已結束的遊戲
        let stats_row = sqlx::query_as::<_, (i64, i64)>(
            r#"
            SELECT
                COUNT(*) AS games_played,
                COUNT(*) FILTER (
                    WHERE r.status = 'finished'
                    AND p.reputation = (
                        SELECT MAX(p2.reputation)
                        FROM players p2
                        WHERE p2.room_id = p.room_id
                    )
                ) AS wins
            FROM players p
            JOIN rooms r ON r.id = p.room_id
            WHERE p.user_id = $1
              AND r.status = 'finished'
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢遊戲統計失敗: {}", e)))?;

        let games_played = stats_row.0;
        let wins = stats_row.1;
        let win_rate = if games_played > 0 {
            wins as f64 / games_played as f64
        } else {
            0.0
        };

        // 從最近 20 場遊戲判斷偏好陣營（最常選擇的角色）
        let faction_preference: Option<String> = sqlx::query_scalar(
            r#"
            SELECT character::text
            FROM players p
            JOIN rooms r ON r.id = p.room_id
            WHERE p.user_id = $1
              AND p.character IS NOT NULL
              AND r.status = 'finished'
            ORDER BY p.created_at DESC
            LIMIT 20
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢陣營偏好失敗: {}", e)))
        .map(|rows: Vec<Option<String>>| Self::most_frequent_faction(&rows))?;

        // 根據 ELO 分配議員頭銜
        let title = Self::elo_to_title(elo_rating);

        Ok(InviterStats {
            games_played,
            win_rate,
            title,
            elo_rating,
            faction_preference,
        })
    }

    /// 查詢邀請者顯示名稱
    async fn get_inviter_name(pool: &PgPool, user_id: Uuid) -> AppResult<String> {
        let name: String = sqlx::query_scalar(
            r#"SELECT COALESCE(display_name, username) FROM users WHERE id = $1"#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢用戶名稱失敗: {}", e)))?;

        Ok(name)
    }

    /// 根據 ELO 分數分配議員頭銜
    fn elo_to_title(elo: i32) -> String {
        match elo {
            elo if elo >= 1800 => "資深議員".to_string(),
            elo if elo >= 1500 => "議員".to_string(),
            elo if elo >= 1200 => "見習議員".to_string(),
            _ => "新進議員".to_string(),
        }
    }

    /// 從角色列表中找出最常出現的陣營
    fn most_frequent_faction(factions: &[Option<String>]) -> Option<String> {
        use std::collections::HashMap;

        let mut counts: HashMap<&str, usize> = HashMap::new();
        for faction in factions.iter().flatten() {
            *counts.entry(faction.as_str()).or_insert(0) += 1;
        }

        counts
            .into_iter()
            .max_by_key(|&(_, count)| count)
            .map(|(faction, _)| faction.to_string())
    }
}
