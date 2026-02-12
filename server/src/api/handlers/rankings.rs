//! 排行榜 API 處理器
//!
//! GET /api/rankings/global  - 全球排行榜
//! GET /api/rankings/me      - 我的排名
//! GET /api/rankings/seasons  - 賽季列表

use axum::{
    extract::{Query, State},
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::middleware::AuthUser;
use crate::db::rankings::{LeaderboardEntry, RankingDb};
use crate::error::AppError;
use crate::game::season;
use crate::AppState;

// ============================================================
// Request / Response 結構
// ============================================================

/// 全球排行榜查詢參數
#[derive(Debug, Deserialize)]
pub struct GlobalRankingsQuery {
    /// 賽季 ID（不填則用當前賽季）
    pub season: Option<i32>,
    /// 每頁筆數（預設 50，上限 100）
    pub limit: Option<i64>,
    /// 偏移量
    pub offset: Option<i64>,
}

/// 我的排名查詢參數
#[derive(Debug, Deserialize)]
pub struct MyRankingQuery {
    /// 賽季 ID（不填則用當前賽季）
    pub season: Option<i32>,
}

/// 排行榜回應
#[derive(Debug, Serialize)]
pub struct LeaderboardResponse {
    pub rankings: Vec<RankingEntry>,
    pub total: i64,
    pub season_id: i32,
    pub season_name: String,
}

/// 單筆排行榜記錄
#[derive(Debug, Serialize)]
pub struct RankingEntry {
    pub rank: i64,
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub elo_rating: i32,
    pub games_played: i32,
    pub wins: i32,
    pub win_rate: f64,
}

/// 我的排名回應
#[derive(Debug, Serialize)]
pub struct MyRankingResponse {
    pub rank: Option<i64>,
    pub elo_rating: i32,
    pub games_played: i32,
    pub wins: i32,
    pub win_rate: f64,
    pub total_ranked: i64,
    pub season_id: i32,
    pub season_name: String,
}

/// 賽季列表回應
#[derive(Debug, Serialize)]
pub struct SeasonsResponse {
    pub seasons: Vec<SeasonEntry>,
}

/// 單個賽季
#[derive(Debug, Serialize)]
pub struct SeasonEntry {
    pub id: i32,
    pub name: String,
    pub start_date: String,
    pub end_date: String,
    pub is_active: bool,
}

// ============================================================
// Handlers
// ============================================================

/// GET /api/rankings/global
pub async fn global_rankings(
    State(state): State<AppState>,
    Query(query): Query<GlobalRankingsQuery>,
) -> Result<Json<LeaderboardResponse>, AppError> {
    let limit = query.limit.unwrap_or(50).clamp(1, 100);
    let offset = query.offset.unwrap_or(0).max(0);

    // 取得賽季
    let (season_id, season_name) = resolve_season(&state, query.season).await?;

    // 查詢排行榜
    let entries = RankingDb::get_leaderboard(&state.db, season_id, limit, offset).await?;
    let total = RankingDb::get_total_ranked(&state.db, season_id).await?;

    let rankings: Vec<RankingEntry> = entries
        .into_iter()
        .enumerate()
        .map(|(i, e)| to_ranking_entry(e, offset + i as i64 + 1))
        .collect();

    Ok(Json(LeaderboardResponse {
        rankings,
        total,
        season_id,
        season_name,
    }))
}

/// GET /api/rankings/me
pub async fn my_ranking(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Query(query): Query<MyRankingQuery>,
) -> Result<Json<MyRankingResponse>, AppError> {
    let (season_id, season_name) = resolve_season(&state, query.season).await?;

    let ranking = RankingDb::get_user_ranking(&state.db, auth_user.user_id, season_id).await?;
    let position = RankingDb::get_user_position(&state.db, auth_user.user_id, season_id).await?;
    let total_ranked = RankingDb::get_total_ranked(&state.db, season_id).await?;

    let (elo, games, wins) = match &ranking {
        Some(r) => (
            r.elo_rating.unwrap_or(1000),
            r.games_played.unwrap_or(0),
            r.wins.unwrap_or(0),
        ),
        None => (1000, 0, 0),
    };

    let win_rate = if games > 0 {
        (wins as f64 / games as f64) * 100.0
    } else {
        0.0
    };

    Ok(Json(MyRankingResponse {
        rank: position,
        elo_rating: elo,
        games_played: games,
        wins,
        win_rate: (win_rate * 100.0).round() / 100.0, // 2 decimal places
        total_ranked,
        season_id,
        season_name,
    }))
}

/// GET /api/rankings/seasons
pub async fn list_seasons(
    State(state): State<AppState>,
) -> Result<Json<SeasonsResponse>, AppError> {
    let seasons = season::get_all_seasons(&state.db).await?;

    let entries: Vec<SeasonEntry> = seasons
        .into_iter()
        .map(|s| SeasonEntry {
            id: s.id,
            name: s.name,
            start_date: s.start_date.to_rfc3339(),
            end_date: s.end_date.to_rfc3339(),
            is_active: s.is_active,
        })
        .collect();

    Ok(Json(SeasonsResponse { seasons: entries }))
}

// ============================================================
// Helpers
// ============================================================

/// 解析賽季 ID：指定了就用指定的，否則取當前活躍賽季
async fn resolve_season(
    state: &AppState,
    season_id: Option<i32>,
) -> Result<(i32, String), AppError> {
    if let Some(id) = season_id {
        // 查詢指定賽季的名稱
        let season = sqlx::query_as::<_, season::Season>(
            "SELECT id, name, start_date, end_date, is_active FROM seasons WHERE id = $1",
        )
        .bind(id)
        .fetch_optional(&state.db)
        .await?;

        match season {
            Some(s) => Ok((s.id, s.name)),
            None => Err(AppError::NotFound(format!("賽季 {} 不存在", id))),
        }
    } else {
        // 取當前活躍賽季
        match season::get_current_season(&state.db).await? {
            Some(s) => Ok((s.id, s.name)),
            None => Err(AppError::NotFound("目前沒有活躍賽季".to_string())),
        }
    }
}

/// 將 DB LeaderboardEntry 轉為 API RankingEntry
fn to_ranking_entry(entry: LeaderboardEntry, rank: i64) -> RankingEntry {
    let games = entry.games_played.unwrap_or(0);
    let wins = entry.wins.unwrap_or(0);
    let win_rate = if games > 0 {
        ((wins as f64 / games as f64) * 10000.0).round() / 100.0
    } else {
        0.0
    };

    RankingEntry {
        rank,
        user_id: entry.user_id,
        username: entry.username,
        display_name: entry.display_name,
        elo_rating: entry.elo_rating.unwrap_or(1000),
        games_played: games,
        wins,
        win_rate,
    }
}
