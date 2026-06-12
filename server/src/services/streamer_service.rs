//! 實況主服務
//!
//! 提供實況主模式相關功能：
//! - 啟用 / 停用實況主模式
//! - 管理 overlay 設定
//! - 取得 OBS overlay 即時資料

use rand::Rng;
use sqlx::PgPool;
use std::sync::Arc;
use uuid::Uuid;

use crate::domain::streamer::{
    EnableStreamerResponse, OverlayData, OverlayPlayerScore, OverlaySettings,
    StreamerSettings, StreamerSettingsResponse, UpdateStreamerSettingsRequest,
};
use crate::error::{AppError, AppResult};
use crate::services::SpectatorService;
use crate::state::GameStore;
use crate::websocket::WebSocketHub;

/// overlay token 允許的字元
const TOKEN_CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

/// 生成 overlay token（64 字元隨機字串）
fn generate_overlay_token() -> String {
    let mut rng = rand::thread_rng();
    (0..64)
        .map(|_| TOKEN_CHARS[rng.gen_range(0..TOKEN_CHARS.len())] as char)
        .collect()
}

/// 允許的 overlay 主題
const VALID_THEMES: &[&str] = &["classic", "dark", "minimal", "victorian"];

/// 實況主服務
pub struct StreamerService;

impl StreamerService {
    /// 啟用實況主模式
    ///
    /// 如果已有設定 → 重新生成 overlay_token
    /// 如果沒有 → INSERT 新記錄 + 生成 token
    pub async fn enable_streamer_mode(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<EnableStreamerResponse> {
        let token = generate_overlay_token();

        // 嘗試更新已有的記錄
        let updated = sqlx::query_scalar::<_, i64>(
            r#"
            UPDATE streamer_settings
            SET is_streamer = true,
                overlay_token = $2,
                updated_at = NOW()
            WHERE user_id = $1
            RETURNING 1
            "#,
        )
        .bind(user_id)
        .bind(&token)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新實況主設定失敗: {}", e)))?;

        if updated.is_none() {
            // 新記錄
            sqlx::query(
                r#"
                INSERT INTO streamer_settings (user_id, is_streamer, overlay_token)
                VALUES ($1, true, $2)
                "#,
            )
            .bind(user_id)
            .bind(&token)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("建立實況主設定失敗: {}", e)))?;
        }

        let overlay_url = format!("https://1812game.com/obs/{}", token);

        Ok(EnableStreamerResponse {
            overlay_token: token,
            overlay_url,
        })
    }

    /// 停用實況主模式
    ///
    /// 設定 is_streamer = false, overlay_token = NULL
    pub async fn disable_streamer_mode(pool: &PgPool, user_id: Uuid) -> AppResult<()> {
        sqlx::query(
            r#"
            UPDATE streamer_settings
            SET is_streamer = false,
                overlay_token = NULL,
                updated_at = NOW()
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("停用實況主模式失敗: {}", e)))?;

        Ok(())
    }

    /// 取得實況主設定
    pub async fn get_settings(
        pool: &PgPool,
        user_id: Uuid,
    ) -> AppResult<StreamerSettingsResponse> {
        let settings = sqlx::query_as::<_, StreamerSettings>(
            r#"
            SELECT id, user_id, is_streamer, overlay_token, overlay_theme,
                   show_spectator_count, show_chat, show_drama_score,
                   show_round_timer, custom_title, created_at, updated_at
            FROM streamer_settings
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢實況主設定失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("尚未設定實況主模式".to_string()))?;

        Ok(StreamerSettingsResponse::from_settings(settings))
    }

    /// 部分更新實況主設定
    ///
    /// 只更新請求中非 None 的欄位
    pub async fn update_settings(
        pool: &PgPool,
        user_id: Uuid,
        request: UpdateStreamerSettingsRequest,
    ) -> AppResult<StreamerSettingsResponse> {
        // 驗證主題
        if let Some(ref theme) = request.overlay_theme {
            if !VALID_THEMES.contains(&theme.as_str()) {
                return Err(AppError::ValidationError(format!(
                    "無效的主題: {}，允許的主題: {:?}",
                    theme, VALID_THEMES
                )));
            }
        }

        // 驗證自訂標題長度
        if let Some(ref title) = request.custom_title {
            if title.len() > 100 {
                return Err(AppError::ValidationError(
                    "自訂標題不得超過 100 字元".to_string(),
                ));
            }
        }

        // 取得現有設定
        let existing = sqlx::query_as::<_, StreamerSettings>(
            r#"
            SELECT id, user_id, is_streamer, overlay_token, overlay_theme,
                   show_spectator_count, show_chat, show_drama_score,
                   show_round_timer, custom_title, created_at, updated_at
            FROM streamer_settings
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢實況主設定失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("尚未設定實況主模式".to_string()))?;

        // 合併更新值
        let theme = request.overlay_theme.unwrap_or(existing.overlay_theme);
        let show_spectator = request
            .show_spectator_count
            .unwrap_or(existing.show_spectator_count);
        let show_chat = request.show_chat.unwrap_or(existing.show_chat);
        let show_drama = request
            .show_drama_score
            .unwrap_or(existing.show_drama_score);
        let show_timer = request
            .show_round_timer
            .unwrap_or(existing.show_round_timer);
        let title = request.custom_title.or(existing.custom_title);

        let updated = sqlx::query_as::<_, StreamerSettings>(
            r#"
            UPDATE streamer_settings
            SET overlay_theme = $2,
                show_spectator_count = $3,
                show_chat = $4,
                show_drama_score = $5,
                show_round_timer = $6,
                custom_title = $7,
                updated_at = NOW()
            WHERE user_id = $1
            RETURNING id, user_id, is_streamer, overlay_token, overlay_theme,
                      show_spectator_count, show_chat, show_drama_score,
                      show_round_timer, custom_title, created_at, updated_at
            "#,
        )
        .bind(user_id)
        .bind(&theme)
        .bind(show_spectator)
        .bind(show_chat)
        .bind(show_drama)
        .bind(show_timer)
        .bind(&title)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新實況主設定失敗: {}", e)))?;

        Ok(StreamerSettingsResponse::from_settings(updated))
    }

    /// 取得 OBS overlay 即時資料
    ///
    /// 透過 overlay_token 找到使用者，
    /// 再找到使用者目前所在的房間，取得淨化後的遊戲狀態
    pub async fn get_overlay_data(
        pool: &PgPool,
        overlay_token: &str,
        ws_hub: &Arc<WebSocketHub>,
        games: &GameStore,
    ) -> AppResult<OverlayData> {
        // 透過 token 找到設定
        let settings = sqlx::query_as::<_, StreamerSettings>(
            r#"
            SELECT id, user_id, is_streamer, overlay_token, overlay_theme,
                   show_spectator_count, show_chat, show_drama_score,
                   show_round_timer, custom_title, created_at, updated_at
            FROM streamer_settings
            WHERE overlay_token = $1 AND is_streamer = true
            "#,
        )
        .bind(overlay_token)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢 overlay 設定失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("無效的 overlay token".to_string()))?;

        // 透過 WebSocket Hub 找到使用者目前所在的房間
        let conn_id = ws_hub.get_user_connection_id(settings.user_id).await;
        let room_code = match conn_id {
            Some(cid) => ws_hub.get_room_code(cid).await,
            None => None,
        };

        let room_code = room_code.ok_or_else(|| {
            AppError::NotFound("實況主目前未在任何遊戲房間中".to_string())
        })?;

        // 取得遊戲狀態
        let games_read = games.read().await;
        let game = games_read.get(&room_code).ok_or_else(|| {
            AppError::NotFound("找不到對應的遊戲引擎".to_string())
        })?;

        // 序列化並淨化遊戲狀態
        let game_state_json = serde_json::to_value(&game.state)
            .map_err(|e| AppError::InternalError(format!("序列化遊戲狀態失敗: {}", e)))?;
        let sanitized = SpectatorService::sanitize_game_state(&game_state_json);

        // 取得遊戲資訊
        let round = game.state.current_round;
        let phase = format!("{:?}", game.state.phase);

        // 取得觀戰人數
        let spectator_count = ws_hub.get_spectator_count(&room_code).await;

        // 取得玩家公開分數
        let player_scores: Vec<OverlayPlayerScore> = game
            .state
            .players
            .values()
            .map(|p| OverlayPlayerScore {
                name: p.name.clone(),
                character: format!("{:?}", p.character),
                reputation: p.reputation,
                influence: p.influence,
            })
            .collect();

        // 戲劇分數（從 sanitized game_state 中提取，如果有的話）
        let drama_score = sanitized
            .get("drama_score")
            .and_then(|v| v.as_f64());

        // 組合 overlay 設定
        let overlay_settings = OverlaySettings {
            theme: settings.overlay_theme,
            show_spectator_count: settings.show_spectator_count,
            show_chat: settings.show_chat,
            show_drama_score: settings.show_drama_score,
            show_round_timer: settings.show_round_timer,
            custom_title: settings.custom_title,
        };

        Ok(OverlayData {
            room_code,
            game_state: sanitized,
            spectator_count,
            round,
            phase,
            drama_score,
            player_scores,
            settings: overlay_settings,
        })
    }

    /// 重新生成 overlay token
    ///
    /// 用於安全更換已洩露的 token
    pub async fn regenerate_token(pool: &PgPool, user_id: Uuid) -> AppResult<String> {
        let new_token = generate_overlay_token();

        let result = sqlx::query(
            r#"
            UPDATE streamer_settings
            SET overlay_token = $2,
                updated_at = NOW()
            WHERE user_id = $1 AND is_streamer = true
            "#,
        )
        .bind(user_id)
        .bind(&new_token)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("重新生成 token 失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::BadRequest(
                "請先啟用實況主模式".to_string(),
            ));
        }

        Ok(new_token)
    }
}
