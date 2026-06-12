//! 串流整合服務
//!
//! 串流平台（Twitch / YouTube）整合的核心業務邏輯：
//! - 帳號綁定 / 解綁
//! - 直播狀態管理
//! - 串流事件記錄
//! - 精華片段通知
//! - 串流數據分析

use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::streaming::{
    LinkStreamingRequest, LinkStreamingResponse, StreamHighlightPayload, StreamingAccountInfo,
    StreamingStatusResponse, UpdateStreamingSettingsRequest,
};
use crate::error::{AppError, AppResult};

/// 有效的串流平台
const VALID_PLATFORMS: &[&str] = &["twitch", "youtube"];

/// 串流整合服務
pub struct StreamingService;

impl StreamingService {
    // ============================================================
    // 帳號綁定
    // ============================================================

    /// 綁定串流平台帳號
    ///
    /// 如果用戶已綁定該平台，則更新現有記錄；否則建立新記錄。
    /// Token 欄位供未來 OAuth 整合使用。
    pub async fn link_account(
        pool: &PgPool,
        user_id: Uuid,
        request: LinkStreamingRequest,
    ) -> AppResult<LinkStreamingResponse> {
        // 驗證平台有效值
        let platform = request.platform.to_lowercase();
        if !VALID_PLATFORMS.contains(&platform.as_str()) {
            return Err(AppError::BadRequest(format!(
                "不支援的串流平台：{}，僅支援 twitch / youtube",
                platform
            )));
        }

        // INSERT 或 UPDATE（使用 UNIQUE(user_id, platform) 約束）
        let record = sqlx::query_scalar::<_, Uuid>(
            r#"
            INSERT INTO streaming_accounts (user_id, platform, platform_user_id, platform_username, access_token, refresh_token)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (user_id, platform) DO UPDATE SET
                platform_user_id = EXCLUDED.platform_user_id,
                platform_username = EXCLUDED.platform_username,
                access_token = EXCLUDED.access_token,
                refresh_token = EXCLUDED.refresh_token,
                updated_at = NOW()
            RETURNING id
            "#,
        )
        .bind(user_id)
        .bind(&platform)
        .bind(&request.platform_user_id)
        .bind(&request.platform_username)
        .bind(&request.access_token)
        .bind(&request.refresh_token)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("綁定串流帳號失敗: {}", e)))?;

        Ok(LinkStreamingResponse {
            success: true,
            message: format!("已成功綁定 {} 帳號", platform),
            account_id: record,
        })
    }

    /// 解除串流平台帳號綁定
    pub async fn unlink_account(
        pool: &PgPool,
        user_id: Uuid,
        platform: &str,
    ) -> AppResult<()> {
        let platform = platform.to_lowercase();
        if !VALID_PLATFORMS.contains(&platform.as_str()) {
            return Err(AppError::BadRequest(format!(
                "不支援的串流平台：{}",
                platform
            )));
        }

        let result = sqlx::query(
            "DELETE FROM streaming_accounts WHERE user_id = $1 AND platform = $2",
        )
        .bind(user_id)
        .bind(&platform)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("解除綁定失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound(format!(
                "未找到 {} 平台的綁定記錄",
                platform
            )));
        }

        Ok(())
    }

    // ============================================================
    // 狀態查詢
    // ============================================================

    /// 查詢用戶所有綁定的串流帳號
    pub async fn get_status(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<StreamingStatusResponse> {
        let accounts = sqlx::query_as::<_, StreamingAccountInfo>(
            r#"
            SELECT platform, platform_username AS username, is_live, created_at AS linked_at
            FROM streaming_accounts
            WHERE user_id = $1
            ORDER BY created_at ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢串流狀態失敗: {}", e)))?;

        Ok(StreamingStatusResponse { accounts })
    }

    // ============================================================
    // 設定管理
    // ============================================================

    /// 更新串流帳號設定
    ///
    /// 部分更新 settings JSONB 欄位
    pub async fn update_settings(
        pool: &PgPool,
        user_id: Uuid,
        platform: &str,
        request: UpdateStreamingSettingsRequest,
    ) -> AppResult<()> {
        let platform = platform.to_lowercase();

        // 組合要更新的設定值
        let mut updates = serde_json::Map::new();
        if let Some(auto_post) = request.auto_post_results {
            updates.insert(
                "auto_post_results".to_string(),
                serde_json::Value::Bool(auto_post),
            );
        }
        if let Some(highlight) = request.highlight_clips {
            updates.insert(
                "highlight_clips".to_string(),
                serde_json::Value::Bool(highlight),
            );
        }

        let settings_json = serde_json::Value::Object(updates);

        let result = sqlx::query(
            r#"
            UPDATE streaming_accounts
            SET settings = settings || $1, updated_at = NOW()
            WHERE user_id = $2 AND platform = $3
            "#,
        )
        .bind(&settings_json)
        .bind(user_id)
        .bind(&platform)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新設定失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound(format!(
                "未找到 {} 平台的綁定記錄",
                platform
            )));
        }

        Ok(())
    }

    // ============================================================
    // 直播狀態
    // ============================================================

    /// 設定直播狀態
    ///
    /// 同時記錄 stream_start / stream_end 事件
    pub async fn set_live_status(
        pool: &PgPool,
        user_id: Uuid,
        platform: &str,
        is_live: bool,
    ) -> AppResult<()> {
        let platform = platform.to_lowercase();

        // 更新直播狀態並取得帳號 ID
        let account_id = sqlx::query_scalar::<_, Uuid>(
            r#"
            UPDATE streaming_accounts
            SET is_live = $1, updated_at = NOW()
            WHERE user_id = $2 AND platform = $3
            RETURNING id
            "#,
        )
        .bind(is_live)
        .bind(user_id)
        .bind(&platform)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新直播狀態失敗: {}", e)))?
        .ok_or_else(|| {
            AppError::NotFound(format!("未找到 {} 平台的綁定記錄", platform))
        })?;

        // 記錄串流事件
        let event_type = if is_live {
            "stream_start"
        } else {
            "stream_end"
        };

        Self::log_event(pool, account_id, event_type, None, serde_json::json!({})).await?;

        Ok(())
    }

    // ============================================================
    // 事件記錄
    // ============================================================

    /// 記錄串流事件
    pub async fn log_event(
        pool: &PgPool,
        account_id: Uuid,
        event_type: &str,
        game_id: Option<Uuid>,
        metadata: serde_json::Value,
    ) -> AppResult<()> {
        sqlx::query(
            r#"
            INSERT INTO streaming_events (streaming_account_id, event_type, game_id, metadata)
            VALUES ($1, $2, $3, $4)
            "#,
        )
        .bind(account_id)
        .bind(event_type)
        .bind(game_id)
        .bind(&metadata)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("記錄串流事件失敗: {}", e)))?;

        Ok(())
    }

    // ============================================================
    // 公開查詢
    // ============================================================

    /// 查詢所有正在直播的玩家
    ///
    /// 公開端點，JOIN users 表取得遊戲內資訊
    pub async fn get_live_streamers(
        pool: &PgPool,
    ) -> AppResult<Vec<StreamingAccountInfo>> {
        let streamers = sqlx::query_as::<_, StreamingAccountInfo>(
            r#"
            SELECT sa.platform,
                   sa.platform_username AS username,
                   sa.is_live,
                   sa.created_at AS linked_at
            FROM streaming_accounts sa
            JOIN users u ON u.id = sa.user_id
            WHERE sa.is_live = true
            ORDER BY sa.updated_at DESC
            "#,
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢直播中玩家失敗: {}", e)))?;

        Ok(streamers)
    }

    // ============================================================
    // 精華片段
    // ============================================================

    /// 通知精華片段
    ///
    /// 當遊戲中出現精華時刻時，記錄事件。
    /// TODO: 未來可擴充為呼叫 Twitch Create Clip API
    pub async fn notify_highlight(
        pool: &PgPool,
        account_id: Uuid,
        game_id: Option<Uuid>,
        highlight_data: StreamHighlightPayload,
    ) -> AppResult<()> {
        let metadata = serde_json::json!({
            "title": highlight_data.title,
            "description": highlight_data.description,
            "timestamp": highlight_data.timestamp.to_rfc3339(),
            "extra": highlight_data.metadata,
        });

        Self::log_event(pool, account_id, "game_highlight", game_id, metadata).await?;

        // TODO: 未來在此呼叫 Twitch / YouTube API 建立 clip
        // 例如：TwitchApi::create_clip(account.access_token, ...).await?;

        Ok(())
    }

    // ============================================================
    // 數據分析
    // ============================================================

    /// 取得串流數據分析
    ///
    /// 統計過去 N 天的串流數據：直播次數、精華片段數等
    pub async fn get_streaming_analytics(
        pool: &PgPool,
        user_id: Uuid,
        days: i32,
    ) -> AppResult<serde_json::Value> {
        let since = Utc::now() - chrono::Duration::days(days as i64);

        // 查詢直播次數與精華片段數
        let stats = sqlx::query_as::<_, AnalyticsRow>(
            r#"
            SELECT
                COUNT(*) FILTER (WHERE se.event_type = 'stream_start') AS stream_count,
                COUNT(*) FILTER (WHERE se.event_type = 'game_highlight') AS highlight_count,
                COUNT(*) FILTER (WHERE se.event_type = 'viewer_peak') AS viewer_peak_count
            FROM streaming_events se
            JOIN streaming_accounts sa ON sa.id = se.streaming_account_id
            WHERE sa.user_id = $1 AND se.created_at >= $2
            "#,
        )
        .bind(user_id)
        .bind(since)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢串流分析失敗: {}", e)))?;

        // 查詢各平台的直播次數
        let platform_stats = sqlx::query_as::<_, PlatformStatsRow>(
            r#"
            SELECT sa.platform,
                   COUNT(*) FILTER (WHERE se.event_type = 'stream_start') AS stream_count
            FROM streaming_events se
            JOIN streaming_accounts sa ON sa.id = se.streaming_account_id
            WHERE sa.user_id = $1 AND se.created_at >= $2
            GROUP BY sa.platform
            "#,
        )
        .bind(user_id)
        .bind(since)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢平台統計失敗: {}", e)))?;

        let platform_breakdown: serde_json::Value = platform_stats
            .iter()
            .map(|p| {
                (
                    p.platform.clone(),
                    serde_json::json!({ "stream_count": p.stream_count }),
                )
            })
            .collect::<serde_json::Map<String, serde_json::Value>>()
            .into();

        Ok(serde_json::json!({
            "period_days": days,
            "total_streams": stats.stream_count,
            "total_highlights": stats.highlight_count,
            "viewer_peaks": stats.viewer_peak_count,
            "platform_breakdown": platform_breakdown,
        }))
    }
}

// ============================================================
// 內部輔助結構
// ============================================================

/// 分析統計行（內部使用）
#[derive(Debug, sqlx::FromRow)]
struct AnalyticsRow {
    stream_count: Option<i64>,
    highlight_count: Option<i64>,
    viewer_peak_count: Option<i64>,
}

/// 平台統計行（內部使用）
#[derive(Debug, sqlx::FromRow)]
struct PlatformStatsRow {
    platform: String,
    stream_count: Option<i64>,
}
