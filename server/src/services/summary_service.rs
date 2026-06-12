//! 遊戲摘要服務
//!
//! 提供遊戲結束後摘要的生成、查詢和分享功能。
//! 基於事件收集器（EventService）的資料，產生精華時刻、報紙資料和回放資料。

use std::collections::HashMap;

use rand::Rng;
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::event::GameEventLog;
use crate::domain::summary::{
    GameSummary, Highlight, NewspaperData, NewspaperQuote, ReplayData, ReplayEvent,
    ReplayHighlight, ReplayPlayerScore,
};
use crate::error::{AppError, AppResult};
use crate::services::EventService;

/// 分享 token 字元集（URL-safe）
const TOKEN_CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/// 回放總時長（秒）
const REPLAY_DURATION_SEC: i32 = 30;

/// 精華時刻最大數量
const MAX_HIGHLIGHTS: usize = 3;

/// 遊戲摘要服務
///
/// 負責遊戲結束後摘要的生成、查詢和分享
pub struct SummaryService;

impl SummaryService {
    /// 生成遊戲摘要
    ///
    /// 從事件日誌中提取資料，計算戲劇指數、精華時刻、MVP 等，
    /// 並產生報紙資料，最後寫入資料庫。
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn generate_summary(pool: &PgPool, game_id: Uuid) -> AppResult<GameSummary> {
        // 1. 取得所有事件
        let events = EventService::get_game_events(pool, game_id).await?;

        if events.is_empty() {
            return Err(AppError::NotFound("該遊戲沒有任何事件記錄".to_string()));
        }

        // 2. 計算戲劇指數
        let drama = EventService::calculate_drama_score(pool, game_id).await?;

        // 3. 提取精華時刻
        let highlights = Self::extract_highlights(&events);

        // 4. 判定 MVP（最多正面事件的玩家）
        let mvp_player_id = Self::determine_mvp(&events);

        // 5. 計算各類事件次數
        let betrayal_count = events
            .iter()
            .filter(|e| e.event_type == "alliance_betrayed")
            .count() as i32;

        let expose_count = events
            .iter()
            .filter(|e| e.event_type == "expose")
            .count() as i32;

        let alliance_count = events
            .iter()
            .filter(|e| e.event_type == "alliance_formed")
            .count() as i32;

        // 6. 計算總回合數
        let total_rounds = events
            .iter()
            .map(|e| e.round_number)
            .max()
            .unwrap_or(1);

        // 7. 判定最大逆轉玩家
        let biggest_comeback_player_id = Self::determine_biggest_comeback(&events);

        // 8. 產生報紙資料
        let newspaper_data = Self::generate_newspaper_data(
            &events,
            drama.score,
            &highlights,
            betrayal_count,
            expose_count,
            alliance_count,
        );

        // 9. 產生分享 token
        let share_token = Self::generate_share_token();

        // 10. 序列化 JSON 資料
        let highlights_json = serde_json::to_value(&highlights)
            .map_err(|e| AppError::InternalError(format!("序列化精華時刻失敗: {}", e)))?;

        let newspaper_json = serde_json::to_value(&newspaper_data)
            .map_err(|e| AppError::InternalError(format!("序列化報紙資料失敗: {}", e)))?;

        // 11. 寫入資料庫
        let summary = sqlx::query_as::<_, GameSummary>(
            r#"
            INSERT INTO game_summaries
                (game_id, drama_score, total_rounds, winning_faction, mvp_player_id,
                 betrayal_count, expose_count, alliance_count, biggest_comeback_player_id,
                 highlights, newspaper_data, share_token)
            VALUES
                ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING id, game_id, drama_score, total_rounds, winning_faction, mvp_player_id,
                      betrayal_count, expose_count, alliance_count, biggest_comeback_player_id,
                      highlights, newspaper_data, share_token, view_count, created_at
            "#,
        )
        .bind(game_id)
        .bind(drama.score)
        .bind(total_rounds)
        .bind(None::<String>) // winning_faction — 需要從遊戲狀態取得
        .bind(mvp_player_id)
        .bind(betrayal_count)
        .bind(expose_count)
        .bind(alliance_count)
        .bind(biggest_comeback_player_id)
        .bind(&highlights_json)
        .bind(&newspaper_json)
        .bind(&share_token)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("寫入遊戲摘要失敗: {}", e)))?;

        Ok(summary)
    }

    /// 提取精華時刻
    ///
    /// 從事件列表中篩選戲劇性分數最高的事件，並分配敘事鍵
    ///
    /// # Arguments
    /// * `events` - 遊戲事件列表
    pub fn extract_highlights(events: &[GameEventLog]) -> Vec<Highlight> {
        // 計算每個事件的加權分數
        let total_rounds = events
            .iter()
            .map(|e| e.round_number)
            .max()
            .unwrap_or(1)
            .max(1);

        let mut scored: Vec<(f64, &GameEventLog)> = events
            .iter()
            .map(|event| {
                let weight = Self::get_event_weight(&event.event_type);
                let recency = 1.0 + (event.round_number as f64 / total_rounds as f64);
                let surprise = Self::get_surprise_factor(&event.metadata);
                (weight * recency * surprise, event)
            })
            .collect();

        // 依分數降序排列
        scored.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

        // 取前 N 個
        scored
            .into_iter()
            .take(MAX_HIGHLIGHTS)
            .map(|(score, event)| {
                let narration_key = Self::assign_narration_key(&event.event_type, &event.metadata);
                let actor_name = event
                    .metadata
                    .get("actor_name")
                    .and_then(|v| v.as_str())
                    .map(String::from);
                let target_name = event
                    .metadata
                    .get("target_name")
                    .and_then(|v| v.as_str())
                    .map(String::from);

                Highlight {
                    round: event.round_number,
                    event_type: event.event_type.clone(),
                    actor_id: event.actor_id,
                    actor_name,
                    target_id: event.target_id,
                    target_name,
                    drama_score: score,
                    narration_key,
                }
            })
            .collect()
    }

    /// 產生報紙資料
    ///
    /// 根據戲劇指數等級選擇標題模板，並產生報紙內文和引言
    fn generate_newspaper_data(
        events: &[GameEventLog],
        drama_score: f64,
        highlights: &[Highlight],
        betrayal_count: i32,
        expose_count: i32,
        alliance_count: i32,
    ) -> NewspaperData {
        // 嘗試從事件中取得 MVP 名稱
        let mvp_name = Self::extract_mvp_name(events);

        // 根據戲劇指數選擇標題
        let headline = if drama_score >= 8.0 {
            format!(
                "{} 在國會掀起腥風血雨！{} 次背叛震驚全場",
                mvp_name.as_deref().unwrap_or("神秘議員"),
                betrayal_count
            )
        } else if drama_score >= 6.0 {
            format!("國會風雲再起：{} 個議程遭揭露", expose_count)
        } else if drama_score >= 4.0 {
            format!(
                "本屆國會波瀾壯闊，{} 次結盟改寫格局",
                alliance_count
            )
        } else {
            "和平的一屆國會：議員們達成罕見共識".to_string()
        };

        // 副標題
        let subheadline = format!(
            "戲劇指數 {:.1} | 背叛 {} 次 | 爆料 {} 次 | 結盟 {} 次",
            drama_score, betrayal_count, expose_count, alliance_count
        );

        // 產生內文段落
        let body_paragraphs = Self::generate_body_paragraphs(highlights, drama_score);

        // 產生引言
        let quotes = Self::generate_quotes(events, highlights);

        NewspaperData {
            headline,
            subheadline,
            body_paragraphs,
            quotes,
            mvp_name,
            bill_result: None,
        }
    }

    /// 產生報紙內文段落
    fn generate_body_paragraphs(highlights: &[Highlight], drama_score: f64) -> Vec<String> {
        let mut paragraphs = Vec::new();

        // 開場段落
        if drama_score >= 6.0 {
            paragraphs.push(
                "本屆國會會議可謂驚心動魄，多位議員在激烈的政治角力中展現了非凡的手腕。"
                    .to_string(),
            );
        } else {
            paragraphs.push(
                "本屆國會會議在相對平穩的氛圍中展開，議員們就多項議題進行了深入討論。"
                    .to_string(),
            );
        }

        // 精華時刻段落
        for highlight in highlights.iter().take(2) {
            let actor = highlight
                .actor_name
                .as_deref()
                .unwrap_or("一位議員");
            let paragraph = match highlight.event_type.as_str() {
                "expose" => format!(
                    "在第 {} 回合，{} 成功揭露了對手的真實身份，此舉令在場所有人震驚不已。",
                    highlight.round, actor
                ),
                "alliance_betrayed" => format!(
                    "第 {} 回合爆出最大醜聞——{} 公然背叛了盟友，政壇信任危機一觸即發。",
                    highlight.round, actor
                ),
                "alliance_formed" => format!(
                    "第 {} 回合見證了一次關鍵結盟，{} 成功拉攏了新的政治夥伴。",
                    highlight.round, actor
                ),
                "challenge_success" => format!(
                    "第 {} 回合，{} 發起的挑戰取得了決定性的勝利，形勢急轉直下。",
                    highlight.round, actor
                ),
                "political_death" => format!(
                    "第 {} 回合，{} 在政治鬥爭中遭到致命打擊，被迫退出了本屆國會。",
                    highlight.round, actor
                ),
                _ => format!(
                    "第 {} 回合，{} 的行動引起了廣泛關注。",
                    highlight.round, actor
                ),
            };
            paragraphs.push(paragraph);
        }

        paragraphs
    }

    /// 產生報紙引言
    fn generate_quotes(events: &[GameEventLog], highlights: &[Highlight]) -> Vec<NewspaperQuote> {
        let mut quotes = Vec::new();

        // 從精華時刻中提取引言
        if let Some(highlight) = highlights.first() {
            let speaker = highlight
                .actor_name
                .as_deref()
                .unwrap_or("匿名議員")
                .to_string();

            let (text, context) = match highlight.event_type.as_str() {
                "expose" => (
                    "真相終將大白於天下！".to_string(),
                    format!("第 {} 回合揭露行動後", highlight.round),
                ),
                "alliance_betrayed" => (
                    "政治就是這麼殘酷，沒有永遠的朋友。".to_string(),
                    format!("第 {} 回合背叛盟友後", highlight.round),
                ),
                "challenge_success" => (
                    "正義或許會遲到，但絕不會缺席。".to_string(),
                    format!("第 {} 回合挑戰成功後", highlight.round),
                ),
                _ => (
                    "這屆國會注定不平凡。".to_string(),
                    format!("第 {} 回合", highlight.round),
                ),
            };

            quotes.push(NewspaperQuote {
                speaker,
                text,
                context,
            });
        }

        // 如果有第二個精華時刻，加入第二個引言
        if let Some(highlight) = highlights.get(1) {
            let speaker = highlight
                .actor_name
                .as_deref()
                .unwrap_or("資深議員")
                .to_string();

            // 從事件的 metadata 中嘗試取得引言
            let text = events
                .iter()
                .find(|e| e.actor_id == highlight.actor_id && e.round_number == highlight.round)
                .and_then(|e| e.metadata.get("quote"))
                .and_then(|v| v.as_str())
                .unwrap_or("歷史會記住今天發生的一切。")
                .to_string();

            quotes.push(NewspaperQuote {
                speaker,
                text,
                context: format!("第 {} 回合", highlight.round),
            });
        }

        quotes
    }

    /// 查詢已生成的摘要
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn get_summary(pool: &PgPool, game_id: Uuid) -> AppResult<GameSummary> {
        let summary = sqlx::query_as::<_, GameSummary>(
            r#"
            SELECT id, game_id, drama_score, total_rounds, winning_faction, mvp_player_id,
                   betrayal_count, expose_count, alliance_count, biggest_comeback_player_id,
                   highlights, newspaper_data, share_token, view_count, created_at
            FROM game_summaries
            WHERE game_id = $1
            "#,
        )
        .bind(game_id)
        .fetch_one(pool)
        .await
        .map_err(|e| match e {
            sqlx::Error::RowNotFound => {
                AppError::NotFound("該遊戲尚未生成摘要".to_string())
            }
            _ => AppError::DatabaseError(format!("查詢遊戲摘要失敗: {}", e)),
        })?;

        Ok(summary)
    }

    /// 透過分享 token 查詢摘要
    ///
    /// 同時將 view_count 加 1
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `token` - 分享 token
    pub async fn get_by_share_token(pool: &PgPool, token: &str) -> AppResult<GameSummary> {
        let summary = sqlx::query_as::<_, GameSummary>(
            r#"
            UPDATE game_summaries
            SET view_count = view_count + 1
            WHERE share_token = $1
            RETURNING id, game_id, drama_score, total_rounds, winning_faction, mvp_player_id,
                      betrayal_count, expose_count, alliance_count, biggest_comeback_player_id,
                      highlights, newspaper_data, share_token, view_count, created_at
            "#,
        )
        .bind(token)
        .fetch_one(pool)
        .await
        .map_err(|e| match e {
            sqlx::Error::RowNotFound => {
                AppError::NotFound("無效的分享連結".to_string())
            }
            _ => AppError::DatabaseError(format!("查詢分享摘要失敗: {}", e)),
        })?;

        Ok(summary)
    }

    /// 產生回放資料
    ///
    /// 從事件日誌產生 30 秒回放資料，每個精華片段平均分配時間
    ///
    /// # Arguments
    /// * `pool` - 資料庫連線池
    /// * `game_id` - 遊戲 ID
    pub async fn get_replay_data(pool: &PgPool, game_id: Uuid) -> AppResult<ReplayData> {
        let events = EventService::get_game_events(pool, game_id).await?;

        if events.is_empty() {
            return Err(AppError::NotFound("該遊戲沒有任何事件記錄".to_string()));
        }

        // 提取精華時刻
        let highlights = Self::extract_highlights(&events);

        let highlight_count = highlights.len().max(1);
        let interval = REPLAY_DURATION_SEC / highlight_count as i32;

        // 將精華時刻轉換為回放格式
        let replay_highlights: Vec<ReplayHighlight> = highlights
            .iter()
            .enumerate()
            .map(|(i, h)| {
                // 從事件中找到對應的原始事件
                let related_events: Vec<ReplayEvent> = events
                    .iter()
                    .filter(|e| {
                        e.round_number == h.round && e.event_type == h.event_type
                    })
                    .map(|e| ReplayEvent {
                        event_type: e.event_type.clone(),
                        actor_id: e.actor_id,
                        actor_name: e
                            .metadata
                            .get("actor_name")
                            .and_then(|v| v.as_str())
                            .map(String::from),
                        target_id: e.target_id,
                        target_name: e
                            .metadata
                            .get("target_name")
                            .and_then(|v| v.as_str())
                            .map(String::from),
                        metadata: e.metadata.clone(),
                    })
                    .collect();

                ReplayHighlight {
                    timestamp_sec: (i as i32) * interval,
                    round: h.round,
                    phase: events
                        .iter()
                        .find(|e| e.round_number == h.round)
                        .map(|e| e.phase.clone())
                        .unwrap_or_else(|| "unknown".to_string()),
                    events: related_events,
                    drama_score: h.drama_score,
                    narration_key: h.narration_key.clone(),
                }
            })
            .collect();

        // 計算最終分數（從事件中提取玩家聲望變化）
        let final_scores = Self::calculate_final_scores(&events);

        Ok(ReplayData {
            game_id,
            total_duration_sec: REPLAY_DURATION_SEC,
            highlights: replay_highlights,
            final_scores,
        })
    }

    // ========================================
    // 內部輔助方法
    // ========================================

    /// 判定 MVP（最多正面事件的玩家）
    fn determine_mvp(events: &[GameEventLog]) -> Option<Uuid> {
        let positive_events = [
            "challenge_success",
            "expose",
            "alliance_formed",
            "skill_used",
        ];

        let mut player_scores: HashMap<Uuid, i32> = HashMap::new();

        for event in events {
            if let Some(actor_id) = event.actor_id {
                if positive_events.contains(&event.event_type.as_str()) {
                    *player_scores.entry(actor_id).or_insert(0) += 1;
                }
                // 聲望變化也納入計算
                if event.reputation_change > 0 {
                    *player_scores.entry(actor_id).or_insert(0) += 1;
                }
            }
        }

        player_scores
            .into_iter()
            .max_by_key(|(_, score)| *score)
            .map(|(id, _)| id)
    }

    /// 判定最大逆轉玩家
    ///
    /// 聲望先降後升幅度最大的玩家
    fn determine_biggest_comeback(events: &[GameEventLog]) -> Option<Uuid> {
        let mut player_trajectories: HashMap<Uuid, Vec<i32>> = HashMap::new();

        for event in events {
            if let Some(actor_id) = event.actor_id {
                if event.reputation_change != 0 {
                    player_trajectories
                        .entry(actor_id)
                        .or_default()
                        .push(event.reputation_change);
                }
            }
        }

        let mut best_comeback: Option<(Uuid, i32)> = None;

        for (player_id, changes) in &player_trajectories {
            let mut cumulative = 0;
            let mut min_point = 0;
            let mut max_comeback = 0;

            for &change in changes {
                cumulative += change;
                if cumulative < min_point {
                    min_point = cumulative;
                }
                let comeback = cumulative - min_point;
                if comeback > max_comeback {
                    max_comeback = comeback;
                }
            }

            // 只有先跌後升才算逆轉
            if min_point < 0 && max_comeback > 0 {
                if best_comeback.is_none() || max_comeback > best_comeback.unwrap().1 {
                    best_comeback = Some((*player_id, max_comeback));
                }
            }
        }

        best_comeback.map(|(id, _)| id)
    }

    /// 從事件中提取 MVP 名稱
    fn extract_mvp_name(events: &[GameEventLog]) -> Option<String> {
        let mvp_id = Self::determine_mvp(events)?;

        events
            .iter()
            .find(|e| e.actor_id == Some(mvp_id))
            .and_then(|e| {
                e.metadata
                    .get("actor_name")
                    .and_then(|v| v.as_str())
                    .map(String::from)
            })
    }

    /// 分配敘事鍵
    ///
    /// 根據事件類型和 metadata 分配對應的敘事模板鍵
    fn assign_narration_key(event_type: &str, metadata: &serde_json::Value) -> String {
        let was_ally = metadata
            .get("was_ally")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);

        let is_underdog = metadata
            .get("is_underdog")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);

        match event_type {
            "expose" if was_ally => "expose_ally".to_string(),
            "expose" => "expose_dramatic".to_string(),
            "alliance_betrayed" if was_ally => "betrayal_dramatic".to_string(),
            "alliance_betrayed" => "betrayal_calculated".to_string(),
            "challenge_success" if is_underdog => "challenge_underdog".to_string(),
            "challenge_success" => "challenge_decisive".to_string(),
            "challenge_blocked" => "challenge_blocked".to_string(),
            "alliance_formed" => "alliance_strategic".to_string(),
            "political_death" => "political_death".to_string(),
            "skill_used" => "skill_critical".to_string(),
            "card_played" => "card_turning_point".to_string(),
            _ => "event_notable".to_string(),
        }
    }

    /// 取得事件類型的權重（與 EventService 保持一致）
    fn get_event_weight(event_type: &str) -> f64 {
        match event_type {
            "expose" => 5.0,
            "alliance_betrayed" => 4.5,
            "challenge_success" => 3.0,
            "challenge_blocked" => 2.5,
            "alliance_formed" => 2.0,
            "vote_cast" => 1.0,
            "speech" => 1.0,
            "card_played" => 1.5,
            "skill_used" => 2.0,
            "political_death" => 4.0,
            _ => 1.0,
        }
    }

    /// 計算驚喜係數（與 EventService 保持一致）
    fn get_surprise_factor(metadata: &serde_json::Value) -> f64 {
        if let Some(was_ally) = metadata.get("was_ally") {
            if was_ally.as_bool().unwrap_or(false) {
                return 1.5;
            }
        }
        1.0
    }

    /// 計算最終玩家分數
    fn calculate_final_scores(events: &[GameEventLog]) -> Vec<ReplayPlayerScore> {
        let mut player_reputations: HashMap<Uuid, i32> = HashMap::new();
        let mut player_names: HashMap<Uuid, String> = HashMap::new();
        let mut player_factions: HashMap<Uuid, String> = HashMap::new();

        for event in events {
            if let Some(actor_id) = event.actor_id {
                *player_reputations.entry(actor_id).or_insert(0) += event.reputation_change;

                // 嘗試從 metadata 提取名稱和陣營
                if let Some(name) = event.metadata.get("actor_name").and_then(|v| v.as_str()) {
                    player_names.entry(actor_id).or_insert_with(|| name.to_string());
                }
                if let Some(faction) = event.metadata.get("faction").and_then(|v| v.as_str()) {
                    player_factions
                        .entry(actor_id)
                        .or_insert_with(|| faction.to_string());
                }
            }
        }

        // 排序
        let mut scores: Vec<(Uuid, i32)> = player_reputations.into_iter().collect();
        scores.sort_by(|a, b| b.1.cmp(&a.1));

        scores
            .into_iter()
            .enumerate()
            .map(|(i, (player_id, reputation))| ReplayPlayerScore {
                player_id,
                player_name: player_names
                    .get(&player_id)
                    .cloned()
                    .unwrap_or_else(|| "未知議員".to_string()),
                faction: player_factions
                    .get(&player_id)
                    .cloned()
                    .unwrap_or_else(|| "unknown".to_string()),
                final_reputation: reputation,
                rank: (i + 1) as i32,
            })
            .collect()
    }

    /// 產生公報 HTML 頁面的模板上下文
    ///
    /// 從 GameSummary 解析 NewspaperData 並填入 Tera 模板變數
    pub fn build_gazette_context(summary: &GameSummary) -> tera::Context {
        let mut context = tera::Context::new();

        // 解析 newspaper_data JSON 為 NewspaperData
        let newspaper: NewspaperData = serde_json::from_value(summary.newspaper_data.clone())
            .unwrap_or_else(|_| NewspaperData {
                headline: "國會會議結束".to_string(),
                subheadline: "一屆精彩的國會".to_string(),
                body_paragraphs: vec!["本屆國會會議已圓滿結束。".to_string()],
                quotes: Vec::new(),
                mvp_name: None,
                bill_result: None,
            });

        // 基本資訊
        context.insert("headline", &newspaper.headline);
        context.insert("subheadline", &newspaper.subheadline);
        context.insert(
            "share_token",
            &summary.share_token.as_deref().unwrap_or(""),
        );

        // 戲劇指數格式化
        context.insert("drama_score", &format!("{:.1}", summary.drama_score));

        // 日期格式化為「西元 YYYY 年 M 月 D 日」
        let date = summary
            .created_at
            .format("西元 %Y 年 %-m 月 %-d 日")
            .to_string();
        context.insert("date", &date);

        // 統計數字
        context.insert("total_rounds", &summary.total_rounds);
        context.insert("betrayal_count", &summary.betrayal_count);
        context.insert("expose_count", &summary.expose_count);
        context.insert("alliance_count", &summary.alliance_count);
        context.insert("view_count", &summary.view_count);

        // 內文段落
        context.insert("body_paragraphs", &newspaper.body_paragraphs);

        // 引言（需要轉為 Tera 可用的序列化格式）
        let quotes: Vec<serde_json::Value> = newspaper
            .quotes
            .iter()
            .map(|q| {
                serde_json::json!({
                    "speaker": q.speaker,
                    "text": q.text,
                    "context": q.context,
                })
            })
            .collect();
        context.insert("quotes", &quotes);

        // MVP 名稱
        if let Some(ref mvp) = newspaper.mvp_name {
            context.insert("mvp_name", mvp);
        }

        context
    }

    /// 產生分享 token（64 字元 URL-safe 隨機字串）
    fn generate_share_token() -> String {
        let mut rng = rand::thread_rng();
        (0..64)
            .map(|_| TOKEN_CHARS[rng.gen_range(0..TOKEN_CHARS.len())] as char)
            .collect()
    }
}
