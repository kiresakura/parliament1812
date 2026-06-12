//! Discord 整合服務
//!
//! 提供 Discord Bot 整合的業務邏輯：帳號綁定、統計查詢、
//! 挑戰建立、每週資訊、Guild 管理、Webhook 推送等。

use chrono::{Datelike, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::discord::{
    DiscordChallengeResponse, DiscordGuild, DiscordStatsResponse, DiscordWeeklyResponse,
    LinkDiscordResponse, RegisterGuildRequest, WebhookPayload,
};
use crate::error::{AppError, AppResult};

/// Discord 整合服務
pub struct DiscordService;

impl DiscordService {
    // ============================================================
    // 帳號綁定
    // ============================================================

    /// 綁定遊戲帳號與 Discord 帳號
    ///
    /// 若已綁定則更新 discord_username。
    pub async fn link_account(
        pool: &PgPool,
        user_id: Uuid,
        discord_user_id: &str,
        discord_username: Option<&str>,
    ) -> AppResult<LinkDiscordResponse> {
        // 檢查此 discord_user_id 是否已被其他 user 綁定
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT user_id FROM discord_user_links WHERE discord_user_id = $1",
        )
        .bind(discord_user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢 Discord 綁定失敗: {}", e)))?;

        if let Some(existing_user_id) = existing {
            if existing_user_id != user_id {
                return Ok(LinkDiscordResponse {
                    success: false,
                    message: "此 Discord 帳號已被其他玩家綁定".to_string(),
                });
            }
            // 同一使用者，更新 username
            sqlx::query(
                "UPDATE discord_user_links SET discord_username = $1 WHERE user_id = $2",
            )
            .bind(discord_username)
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("更新 Discord 綁定失敗: {}", e)))?;

            return Ok(LinkDiscordResponse {
                success: true,
                message: "已更新 Discord 帳號資訊".to_string(),
            });
        }

        // 檢查此 user_id 是否已綁定其他 discord 帳號
        let user_linked = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM discord_user_links WHERE user_id = $1",
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢使用者綁定失敗: {}", e)))?;

        if user_linked.is_some() {
            // 使用者已綁定其他 Discord，替換
            sqlx::query(
                r#"
                UPDATE discord_user_links
                SET discord_user_id = $1, discord_username = $2, linked_at = NOW()
                WHERE user_id = $3
                "#,
            )
            .bind(discord_user_id)
            .bind(discord_username)
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("更新 Discord 綁定失敗: {}", e)))?;

            return Ok(LinkDiscordResponse {
                success: true,
                message: "已替換為新的 Discord 帳號".to_string(),
            });
        }

        // 新建綁定
        sqlx::query(
            r#"
            INSERT INTO discord_user_links (user_id, discord_user_id, discord_username)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(user_id)
        .bind(discord_user_id)
        .bind(discord_username)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("建立 Discord 綁定失敗: {}", e)))?;

        Ok(LinkDiscordResponse {
            success: true,
            message: "成功綁定 Discord 帳號".to_string(),
        })
    }

    /// 解除 Discord 帳號綁定
    pub async fn unlink_account(pool: &PgPool, user_id: Uuid) -> AppResult<()> {
        let result = sqlx::query("DELETE FROM discord_user_links WHERE user_id = $1")
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("解除 Discord 綁定失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("未找到 Discord 綁定".to_string()));
        }

        Ok(())
    }

    // ============================================================
    // 統計查詢
    // ============================================================

    /// 透過 Discord ID 取得玩家統計
    ///
    /// discord_user_id → user_id → 查詢遊戲統計
    pub async fn get_stats_by_discord_id(
        pool: &PgPool,
        discord_user_id: &str,
    ) -> AppResult<DiscordStatsResponse> {
        // 查找綁定的 user_id 和 username
        let link = sqlx::query_as::<_, (Uuid, )>(
            "SELECT user_id FROM discord_user_links WHERE discord_user_id = $1",
        )
        .bind(discord_user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢 Discord 綁定失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("此 Discord 帳號未綁定遊戲帳號".to_string()))?;

        let user_id = link.0;

        // 取得使用者名稱
        let username = sqlx::query_scalar::<_, String>(
            "SELECT COALESCE(display_name, username) FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢使用者失敗: {}", e)))?
        .unwrap_or_else(|| "未知玩家".to_string());

        // 取得 ELO 和頭銜（從 player_rankings 表）
        let ranking = sqlx::query_as::<_, (i32, String)>(
            r#"
            SELECT COALESCE(elo_rating, 1000), COALESCE(title, '庶民')
            FROM player_rankings
            WHERE user_id = $1
            ORDER BY season_id DESC
            LIMIT 1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢排名失敗: {}", e)))?
        .unwrap_or((1000, "庶民".to_string()));

        // 取得遊戲統計（games_played, wins）
        let stats = sqlx::query_as::<_, (i64, i64)>(
            r#"
            SELECT
                COUNT(*) as games_played,
                COUNT(*) FILTER (WHERE is_winner = true) as wins
            FROM game_players
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢遊戲統計失敗: {}", e)))?;

        let games_played = stats.0;
        let wins = stats.1;
        let win_rate = if games_played > 0 {
            (wins as f64 / games_played as f64) * 100.0
        } else {
            0.0
        };

        // 取得最近 5 場結果
        let recent = sqlx::query_as::<_, (bool,)>(
            r#"
            SELECT is_winner
            FROM game_players
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT 5
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢最近戰績失敗: {}", e)))?;

        let recent_results = recent
            .into_iter()
            .map(|(w,)| if w { "win".to_string() } else { "lose".to_string() })
            .collect();

        Ok(DiscordStatsResponse {
            username,
            games_played,
            win_rate: (win_rate * 100.0).round() / 100.0, // 保留兩位小數
            elo: ranking.0,
            title: ranking.1,
            recent_results,
        })
    }

    // ============================================================
    // 挑戰
    // ============================================================

    /// 透過 Discord ID 建立對戰挑戰
    ///
    /// 找到兩位玩家，建立新房間，返回 room_code 和 join_url。
    pub async fn create_challenge(
        pool: &PgPool,
        challenger_discord_id: &str,
        target_discord_id: &str,
    ) -> AppResult<DiscordChallengeResponse> {
        // 查找挑戰者
        let challenger_user_id = sqlx::query_scalar::<_, Uuid>(
            "SELECT user_id FROM discord_user_links WHERE discord_user_id = $1",
        )
        .bind(challenger_discord_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢挑戰者失敗: {}", e)))?
        .ok_or_else(|| {
            AppError::NotFound("挑戰者的 Discord 帳號未綁定遊戲帳號".to_string())
        })?;

        // 查找目標玩家
        let target_user_id = sqlx::query_scalar::<_, Uuid>(
            "SELECT user_id FROM discord_user_links WHERE discord_user_id = $1",
        )
        .bind(target_discord_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢目標玩家失敗: {}", e)))?
        .ok_or_else(|| {
            AppError::NotFound("目標玩家的 Discord 帳號未綁定遊戲帳號".to_string())
        })?;

        if challenger_user_id == target_user_id {
            return Err(AppError::BadRequest("不能挑戰自己".to_string()));
        }

        // 生成房間代碼（6 碼大寫英數）
        let room_code = generate_room_code();

        // 取得挑戰者名稱
        let challenger_name = sqlx::query_scalar::<_, String>(
            "SELECT COALESCE(display_name, username) FROM users WHERE id = $1",
        )
        .bind(challenger_user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢挑戰者名稱失敗: {}", e)))?
        .unwrap_or_else(|| "未知玩家".to_string());

        let target_name = sqlx::query_scalar::<_, String>(
            "SELECT COALESCE(display_name, username) FROM users WHERE id = $1",
        )
        .bind(target_user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢目標玩家名稱失敗: {}", e)))?
        .unwrap_or_else(|| "未知玩家".to_string());

        // 注意：實際的房間建立是在記憶體中（RoomService），
        // 這裡只回傳房間代碼，讓玩家透過 App 加入。
        // 如果需要持久化挑戰紀錄，可以另建表。
        let join_url = format!("parliament1812://join/{}", room_code);

        Ok(DiscordChallengeResponse {
            room_code: Some(room_code),
            message: format!(
                "⚔️ {} 向 {} 發起挑戰！請在遊戲中使用房間代碼加入。",
                challenger_name, target_name
            ),
            join_url: Some(join_url),
        })
    }

    // ============================================================
    // 每週資訊
    // ============================================================

    /// 取得當週法案資訊 + 參與統計
    pub async fn get_weekly_info(pool: &PgPool) -> AppResult<DiscordWeeklyResponse> {
        let now = Utc::now();
        let iso_week = now.iso_week();
        let week_number = iso_week.week() as i32;
        let year = iso_week.year();
        let week_label = format!("{} 第 {} 週", year, week_number);

        // 計算距離本週日剩餘天數
        let current_weekday = now.weekday().num_days_from_monday(); // 0=Mon, 6=Sun
        let days_remaining = (6 - current_weekday) as i64;

        // 嘗試查詢當週法案
        let bill = sqlx::query_as::<_, (String, Option<String>)>(
            r#"
            SELECT bill_name, bill_description
            FROM weekly_bills
            WHERE week_number = $1 AND year = $2
            "#,
        )
        .bind(week_number)
        .bind(year)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢當週法案失敗: {}", e)))?;

        let (bill_name, bill_description) = match bill {
            Some((name, desc)) => (Some(name), desc),
            None => (None, None),
        };

        // 本週參與人數（本週一 00:00 之後的不同玩家數）
        let participants = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(DISTINCT user_id)
            FROM game_players
            WHERE created_at >= date_trunc('week', NOW())
            "#,
        )
        .fetch_one(pool)
        .await
        .unwrap_or(0);

        Ok(DiscordWeeklyResponse {
            bill_name,
            bill_description,
            week_label,
            days_remaining,
            participants_this_week: participants,
        })
    }

    // ============================================================
    // Guild 管理
    // ============================================================

    /// 註冊 Discord 伺服器
    ///
    /// 使用 UPSERT：如果 guild_id 已存在則更新。
    pub async fn register_guild(
        pool: &PgPool,
        request: &RegisterGuildRequest,
    ) -> AppResult<DiscordGuild> {
        let guild = sqlx::query_as::<_, DiscordGuild>(
            r#"
            INSERT INTO discord_guilds (guild_id, guild_name, webhook_url, notification_channel_id)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (guild_id) DO UPDATE SET
                guild_name = COALESCE(EXCLUDED.guild_name, discord_guilds.guild_name),
                webhook_url = COALESCE(EXCLUDED.webhook_url, discord_guilds.webhook_url),
                notification_channel_id = COALESCE(EXCLUDED.notification_channel_id, discord_guilds.notification_channel_id),
                is_active = true,
                updated_at = NOW()
            RETURNING id, guild_id, guild_name, webhook_url, notification_channel_id,
                      is_active, settings, created_at, updated_at
            "#,
        )
        .bind(&request.guild_id)
        .bind(&request.guild_name)
        .bind(&request.webhook_url)
        .bind(&request.notification_channel_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("註冊 Discord Guild 失敗: {}", e)))?;

        Ok(guild)
    }

    // ============================================================
    // Webhook 推送
    // ============================================================

    /// 向指定 Guild 的 webhook_url 推送 Discord Embed 訊息
    pub async fn send_webhook(
        pool: &PgPool,
        guild_id: &str,
        payload: &WebhookPayload,
    ) -> AppResult<()> {
        // 取得 Guild 的 webhook_url
        let webhook_url = sqlx::query_scalar::<_, String>(
            "SELECT webhook_url FROM discord_guilds WHERE guild_id = $1 AND is_active = true",
        )
        .bind(guild_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢 Guild webhook 失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("找不到此 Guild 或尚未設定 webhook".to_string()))?;

        // 建構 Discord Embed 格式
        let embed = build_discord_embed(payload);

        let client = reqwest::Client::new();
        let response = client
            .post(&webhook_url)
            .json(&embed)
            .send()
            .await
            .map_err(|e| AppError::InternalError(format!("推送 webhook 失敗: {}", e)))?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            tracing::warn!(
                guild_id = guild_id,
                status = %status,
                body = body,
                "Webhook 推送回應非 2xx"
            );
            return Err(AppError::InternalError(format!(
                "Webhook 回應 {} : {}",
                status, body
            )));
        }

        Ok(())
    }

    /// 遊戲結束後向所有相關 Guild 推送結果
    ///
    /// 查詢所有啟用了 auto_post_results 的 Guild 並推送。
    pub async fn notify_game_result(pool: &PgPool, game_id: Uuid) -> AppResult<()> {
        // 取得遊戲資訊
        let game_info = sqlx::query_as::<_, (String, Option<String>)>(
            r#"
            SELECT
                COALESCE(room_code, id::text) as room_label,
                bill_name
            FROM games
            WHERE id = $1
            "#,
        )
        .bind(game_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢遊戲資訊失敗: {}", e)))?;

        let (room_label, bill_name) = match game_info {
            Some(info) => info,
            None => {
                tracing::warn!(game_id = %game_id, "找不到遊戲記錄，跳過推送");
                return Ok(());
            }
        };

        // 取得遊戲玩家結果
        let players = sqlx::query_as::<_, (String, bool)>(
            r#"
            SELECT
                COALESCE(u.display_name, u.username) as player_name,
                gp.is_winner
            FROM game_players gp
            JOIN users u ON u.id = gp.user_id
            WHERE gp.game_id = $1
            "#,
        )
        .bind(game_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢遊戲玩家失敗: {}", e)))?;

        // 格式化結果文字
        let mut winners = Vec::new();
        let mut losers = Vec::new();
        for (name, is_winner) in &players {
            if *is_winner {
                winners.push(name.as_str());
            } else {
                losers.push(name.as_str());
            }
        }

        let result_text = format!(
            "🏆 勝者: {}\n💀 敗者: {}",
            if winners.is_empty() {
                "（無）".to_string()
            } else {
                winners.join(", ")
            },
            if losers.is_empty() {
                "（無）".to_string()
            } else {
                losers.join(", ")
            },
        );

        let payload = WebhookPayload {
            event_type: "game_result".to_string(),
            data: serde_json::json!({
                "room": room_label,
                "bill": bill_name.unwrap_or_else(|| "未知法案".to_string()),
                "result": result_text,
                "player_count": players.len(),
            }),
        };

        // 取得所有啟用 auto_post_results 的 Guild
        let guilds = sqlx::query_as::<_, (String,)>(
            r#"
            SELECT guild_id
            FROM discord_guilds
            WHERE is_active = true
              AND webhook_url IS NOT NULL
              AND (settings->>'auto_post_results')::boolean = true
            "#,
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢 Guild 列表失敗: {}", e)))?;

        // 逐一推送（失敗不中斷）
        for (gid,) in guilds {
            if let Err(e) = Self::send_webhook(pool, &gid, &payload).await {
                tracing::warn!(guild_id = gid, error = %e, "推送遊戲結果失敗，略過");
            }
        }

        Ok(())
    }
}

// ============================================================
// 輔助函式
// ============================================================

/// 生成 6 碼房間代碼
fn generate_room_code() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let chars: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 排除易混淆字元
    (0..6)
        .map(|_| {
            let idx = rng.gen_range(0..chars.len());
            chars[idx] as char
        })
        .collect()
}

/// 將 WebhookPayload 轉換為 Discord Webhook Embed 格式
fn build_discord_embed(payload: &WebhookPayload) -> serde_json::Value {
    let (title, color, description) = match payload.event_type.as_str() {
        "game_result" => {
            let room = payload.data.get("room").and_then(|v| v.as_str()).unwrap_or("?");
            let bill = payload.data.get("bill").and_then(|v| v.as_str()).unwrap_or("?");
            let result = payload.data.get("result").and_then(|v| v.as_str()).unwrap_or("");
            (
                format!("🏛️ 對局結束 — {}", room),
                0x2F3136, // 深色
                format!("**法案**: {}\n\n{}", bill, result),
            )
        }
        "weekly_bill" => {
            let bill = payload.data.get("bill_name").and_then(|v| v.as_str()).unwrap_or("?");
            let desc = payload.data.get("description").and_then(|v| v.as_str()).unwrap_or("");
            (
                format!("📜 本週新法案: {}", bill),
                0xF1C40F, // 金色
                desc.to_string(),
            )
        }
        _ => (
            format!("1812 國會風雲 — {}", payload.event_type),
            0x3498DB, // 藍色
            serde_json::to_string_pretty(&payload.data).unwrap_or_default(),
        ),
    };

    serde_json::json!({
        "embeds": [{
            "title": title,
            "description": description,
            "color": color,
            "footer": {
                "text": "1812 國會風雲"
            },
            "timestamp": Utc::now().to_rfc3339()
        }]
    })
}
