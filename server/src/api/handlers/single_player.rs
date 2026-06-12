//! 單人模式 API 處理器
//!
//! POST /api/v1/single/start             - 開始 AI 快速對戰
//! POST /api/v1/single/action            - 玩家行動
//! GET  /api/v1/single/state/:session_id - 取得對戰狀態
//! POST /api/v1/single/campaign/start    - 開始戰役章節
//! GET  /api/v1/single/campaign/progress - 取得戰役進度

use axum::{
    extract::{Path, State},
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::middleware::AuthUser;
use crate::domain::CharacterType;
use crate::error::AppError;
use crate::single_player::ai_engine::AiDifficulty;
use crate::single_player::campaign::{Campaign, ChapterId};
use crate::single_player::session::{SinglePlayerAction, SinglePlayerSession, SinglePlayerState};
use crate::AppState;

// ============================================================
// 請求 / 回應
// ============================================================

/// 開始單人對戰請求
#[derive(Debug, Deserialize)]
pub struct StartSinglePlayerRequest {
    /// AI 難度
    pub difficulty: AiDifficulty,
    /// 選擇的角色（可選，預設 Thomas）
    pub character: Option<String>,
    /// 玩家名稱
    pub player_name: Option<String>,
}

/// 開始單人對戰回應
#[derive(Debug, Serialize)]
pub struct StartSinglePlayerResponse {
    pub session_id: Uuid,
    pub state: SinglePlayerState,
}

/// 玩家行動請求
#[derive(Debug, Deserialize)]
pub struct SinglePlayerActionRequest {
    pub session_id: Uuid,
    pub action: SinglePlayerAction,
}

/// 行動回應
#[derive(Debug, Serialize)]
pub struct SinglePlayerActionResponse {
    pub success: bool,
    pub message: String,
    pub state: SinglePlayerState,
    pub ai_actions: Vec<String>,
}

/// 開始戰役請求
#[derive(Debug, Deserialize)]
pub struct StartCampaignRequest {
    pub chapter: i32,
    pub stage: Option<i32>,
    pub player_name: Option<String>,
    pub character: Option<String>,
}

/// 戰役進度回應
#[derive(Debug, Serialize)]
pub struct CampaignProgressApiResponse {
    pub chapters: Vec<ChapterProgressEntry>,
    pub total_stars: i32,
}

#[derive(Debug, Serialize)]
pub struct ChapterProgressEntry {
    pub chapter: i32,
    pub title: String,
    pub is_unlocked: bool,
    pub stages_completed: i32,
    pub total_stages: i32,
    pub stars: i32,
}

// ============================================================
// Helper: 解析角色名稱
// ============================================================

fn parse_character(name: Option<&str>) -> CharacterType {
    match name {
        Some("thomas") | Some("Thomas") => CharacterType::Thomas,
        Some("richard") | Some("Richard") => CharacterType::Richard,
        Some("edward") | Some("Edward") => CharacterType::Edward,
        Some("george") | Some("George") => CharacterType::George,
        _ => CharacterType::Thomas, // 預設
    }
}

// ============================================================
// Handlers
// ============================================================

/// POST /api/v1/single/start
pub async fn start_single_player(
    State(state): State<AppState>,
    _auth_user: AuthUser,
    Json(request): Json<StartSinglePlayerRequest>,
) -> Result<Json<StartSinglePlayerResponse>, AppError> {
    let player_name = request.player_name.unwrap_or_else(|| "Player".to_string());
    let character = parse_character(request.character.as_deref());

    // 建立單人遊戲 session
    let mut session = SinglePlayerSession::new(player_name, character, request.difficulty);

    // 開始遊戲
    let game_state = session
        .start()
        .map_err(|e| AppError::InternalError(format!("無法啟動遊戲: {}", e)))?;

    let session_id = game_state.session_id;

    // 儲存 session 到記憶體
    {
        let mut sessions = state.single_player_sessions.write().await;
        sessions.insert(session_id, session);
    }

    Ok(Json(StartSinglePlayerResponse {
        session_id,
        state: game_state,
    }))
}

/// POST /api/v1/single/action
pub async fn single_player_action(
    State(state): State<AppState>,
    _auth_user: AuthUser,
    Json(request): Json<SinglePlayerActionRequest>,
) -> Result<Json<SinglePlayerActionResponse>, AppError> {
    let mut sessions = state.single_player_sessions.write().await;
    let session = sessions
        .get_mut(&request.session_id)
        .ok_or_else(|| AppError::NotFound("找不到遊戲 session".to_string()))?;

    // 執行行動
    let response = session
        .process_action(request.action)
        .map_err(|e| AppError::BadRequest(format!("行動失敗: {}", e)))?;

    let ai_descriptions: Vec<String> = response
        .ai_actions
        .iter()
        .map(|a| a.description.clone())
        .collect();

    Ok(Json(SinglePlayerActionResponse {
        success: response.success,
        message: response.message,
        state: response.state,
        ai_actions: ai_descriptions,
    }))
}

/// GET /api/v1/single/state/:session_id
pub async fn get_single_player_state(
    State(state): State<AppState>,
    _auth_user: AuthUser,
    Path(session_id): Path<Uuid>,
) -> Result<Json<SinglePlayerState>, AppError> {
    let sessions = state.single_player_sessions.read().await;
    let session = sessions
        .get(&session_id)
        .ok_or_else(|| AppError::NotFound("找不到遊戲 session".to_string()))?;

    Ok(Json(session.get_state()))
}

/// POST /api/v1/single/campaign/start
pub async fn start_campaign_chapter(
    State(state): State<AppState>,
    _auth_user: AuthUser,
    Json(request): Json<StartCampaignRequest>,
) -> Result<Json<StartSinglePlayerResponse>, AppError> {
    let chapter_id = ChapterId::from_number(request.chapter)
        .ok_or_else(|| AppError::BadRequest(format!("無效章節: {}", request.chapter)))?;

    let player_name = request.player_name.unwrap_or_else(|| "Player".to_string());
    let character = parse_character(request.character.as_deref());

    // 取得章節資訊
    let chapter = Campaign::get_chapter(chapter_id)
        .ok_or_else(|| AppError::NotFound(format!("章節 {} 不存在", request.chapter)))?;

    // 建立戰役 session
    let mut session = SinglePlayerSession::new_campaign(
        player_name,
        character,
        chapter_id,
        chapter.difficulty,
        chapter.special_rules.clone(),
        3, // AI 對手數量
    );

    let game_state = session
        .start()
        .map_err(|e| AppError::InternalError(format!("無法啟動戰役: {}", e)))?;

    let session_id = game_state.session_id;

    {
        let mut sessions = state.single_player_sessions.write().await;
        sessions.insert(session_id, session);
    }

    Ok(Json(StartSinglePlayerResponse {
        session_id,
        state: game_state,
    }))
}

/// GET /api/v1/single/campaign/progress
pub async fn get_campaign_progress(
    State(_state): State<AppState>,
    _auth_user: AuthUser,
) -> Result<Json<CampaignProgressApiResponse>, AppError> {
    let chapters = Campaign::get_chapters();

    let entries: Vec<ChapterProgressEntry> = chapters
        .iter()
        .map(|ch| ChapterProgressEntry {
            chapter: ch.id.number(),
            title: ch.title.clone(),
            is_unlocked: ch.id == ChapterId::Chapter1,
            stages_completed: 0,
            total_stages: ch.ai_count as i32,
            stars: 0,
        })
        .collect();

    Ok(Json(CampaignProgressApiResponse {
        chapters: entries,
        total_stars: 0,
    }))
}
