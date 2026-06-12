//! 好友系統 API 處理器
//!
//! - GET    /api/v1/friends              — 好友列表（含在線狀態）
//! - GET    /api/v1/friends/pending      — 待處理的好友請求
//! - POST   /api/v1/friends/request      — 發送好友請求
//! - POST   /api/v1/friends/accept       — 接受好友請求
//! - POST   /api/v1/friends/reject       — 拒絕好友請求
//! - DELETE /api/v1/friends/:user_id     — 刪除好友
//! - POST   /api/v1/friends/block        — 封鎖用戶
//! - POST   /api/v1/friends/unblock      — 解除封鎖
//! - POST   /api/v1/friends/invite-game  — 邀請好友對戰
//! - GET    /api/v1/users/search?q=      — 搜尋用戶

use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::db::friends::{FriendInfo, FriendRequest, UserSummary};
use crate::error::{AppError, AppResult};
use crate::services::FriendService;
use crate::AppState;

// ============================================================
// 請求 / 回應結構
// ============================================================

#[derive(Debug, Deserialize)]
pub struct TargetUserRequest {
    pub target_user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct FriendUserRequest {
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    pub q: Option<String>,
    pub limit: Option<u32>,
}

#[derive(Debug, Serialize)]
pub struct FriendsListResponse {
    pub friends: Vec<FriendInfo>,
    pub count: usize,
}

#[derive(Debug, Serialize)]
pub struct PendingRequestsResponse {
    pub requests: Vec<FriendRequest>,
    pub count: usize,
}

#[derive(Debug, Serialize)]
pub struct SearchUsersResponse {
    pub users: Vec<UserSummary>,
    pub count: usize,
}

#[derive(Debug, Serialize)]
pub struct FriendActionResponse {
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct InviteGameResponse {
    pub message: String,
    pub room_code: String,
}

// ============================================================
// 好友列表
// ============================================================

/// GET /api/v1/friends
pub async fn get_friends(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<FriendsListResponse>> {
    let friends = FriendService::get_friends_list(&state, auth.user_id).await?;
    let count = friends.len();
    Ok(Json(FriendsListResponse { friends, count }))
}

// ============================================================
// 待處理請求
// ============================================================

/// GET /api/v1/friends/pending
pub async fn get_pending_requests(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<PendingRequestsResponse>> {
    let requests = FriendService::get_pending_requests(&state, auth.user_id).await?;
    let count = requests.len();
    Ok(Json(PendingRequestsResponse { requests, count }))
}

// ============================================================
// 發送好友請求
// ============================================================

/// POST /api/v1/friends/request
pub async fn send_friend_request(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<TargetUserRequest>,
) -> AppResult<Json<FriendActionResponse>> {
    let target_id = Uuid::parse_str(&req.target_user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::send_friend_request(&state, auth.user_id, target_id).await?;

    Ok(Json(FriendActionResponse {
        message: "好友請求已發送".to_string(),
    }))
}

// ============================================================
// 接受好友請求
// ============================================================

/// POST /api/v1/friends/accept
pub async fn accept_friend_request(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<FriendUserRequest>,
) -> AppResult<Json<FriendActionResponse>> {
    let from_user_id = Uuid::parse_str(&req.user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::accept_friend_request(&state, auth.user_id, from_user_id).await?;

    Ok(Json(FriendActionResponse {
        message: "已接受好友請求".to_string(),
    }))
}

// ============================================================
// 拒絕好友請求
// ============================================================

/// POST /api/v1/friends/reject
pub async fn reject_friend_request(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<FriendUserRequest>,
) -> AppResult<Json<FriendActionResponse>> {
    let from_user_id = Uuid::parse_str(&req.user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::reject_friend_request(&state, auth.user_id, from_user_id).await?;

    Ok(Json(FriendActionResponse {
        message: "已拒絕好友請求".to_string(),
    }))
}

// ============================================================
// 刪除好友
// ============================================================

/// DELETE /api/v1/friends/:user_id
pub async fn remove_friend(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(friend_id_str): Path<String>,
) -> AppResult<Json<FriendActionResponse>> {
    let friend_id = Uuid::parse_str(&friend_id_str)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::remove_friend(&state, auth.user_id, friend_id).await?;

    Ok(Json(FriendActionResponse {
        message: "已刪除好友".to_string(),
    }))
}

// ============================================================
// 封鎖
// ============================================================

/// POST /api/v1/friends/block
pub async fn block_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<TargetUserRequest>,
) -> AppResult<Json<FriendActionResponse>> {
    let target_id = Uuid::parse_str(&req.target_user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::block_user(&state, auth.user_id, target_id).await?;

    Ok(Json(FriendActionResponse {
        message: "已封鎖用戶".to_string(),
    }))
}

/// POST /api/v1/friends/unblock
pub async fn unblock_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<TargetUserRequest>,
) -> AppResult<Json<FriendActionResponse>> {
    let target_id = Uuid::parse_str(&req.target_user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    FriendService::unblock_user(&state, auth.user_id, target_id).await?;

    Ok(Json(FriendActionResponse {
        message: "已解除封鎖".to_string(),
    }))
}

// ============================================================
// 邀請對戰
// ============================================================

/// POST /api/v1/friends/invite-game
pub async fn invite_game(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<TargetUserRequest>,
) -> AppResult<Json<InviteGameResponse>> {
    let friend_id = Uuid::parse_str(&req.target_user_id)
        .map_err(|_| AppError::BadRequest("無效的用戶 ID".to_string()))?;

    let room_code = FriendService::invite_friend_to_game(&state, auth.user_id, friend_id).await?;

    Ok(Json(InviteGameResponse {
        message: "對戰邀請已發送".to_string(),
        room_code,
    }))
}

// ============================================================
// 搜尋用戶
// ============================================================

/// GET /api/v1/users/search?q=xxx&limit=20
pub async fn search_users(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<SearchQuery>,
) -> AppResult<Json<SearchUsersResponse>> {
    let query = params.q.unwrap_or_default();
    let limit = params.limit.unwrap_or(20);

    let users = FriendService::search_users(&state, &query, auth.user_id, limit).await?;
    let count = users.len();

    Ok(Json(SearchUsersResponse { users, count }))
}
