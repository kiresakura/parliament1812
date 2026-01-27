//! 房間相關 API 處理器
//!
//! 提供房間創建、查詢、加入、離開等功能

use axum::{
    extract::{Path, State},
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    auth::AuthUser,
    domain::{CreateRoomRequest, JoinRoomRequest, Player, PlayerResponse, Room, RoomResponse},
    error::{AppError, AppResult},
    AppState,
};

/// 房間詳情回應（包含玩家列表）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomDetailResponse {
    /// 房間資訊
    #[serde(flatten)]
    pub room: RoomResponse,
    /// 玩家列表
    pub players: Vec<PlayerResponse>,
}

/// 創建房間
///
/// POST /api/v1/rooms
pub async fn create_room(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateRoomRequest>,
) -> AppResult<Json<RoomDetailResponse>> {
    // 檢查用戶是否存在
    let user = {
        let users = state.users.read().await;
        users
            .get(&auth.user_id)
            .cloned()
            .ok_or_else(|| AppError::NotFound("用戶不存在".to_string()))?
    };

    // 檢查用戶是否已在其他房間
    {
        let players = state.players.read().await;
        if players.values().any(|p| p.user_id == auth.user_id) {
            return Err(AppError::BadRequest("您已在其他房間中".to_string()));
        }
    }

    // 創建房間
    let room = if let Some(max_players) = req.max_players {
        Room::with_max_players(auth.user_id, max_players)
    } else {
        Room::new(auth.user_id)
    };

    let room_id = room.id;
    let room_code = room.code.clone();

    // 創建房主玩家
    let player = Player::new(auth.user_id, room_id, user.username.clone(), true);
    let player_id = player.id;

    // 儲存房間和玩家
    {
        let mut rooms = state.rooms.write().await;
        rooms.insert(room_id, room.clone());
    }
    {
        let mut players = state.players.write().await;
        players.insert(player_id, player.clone());
    }

    tracing::info!(
        room_id = %room_id,
        room_code = %room_code,
        host_id = %auth.user_id,
        "房間已創建"
    );

    let room_response = RoomResponse::from(room).with_player_count(1);

    Ok(Json(RoomDetailResponse {
        room: room_response,
        players: vec![PlayerResponse::from(player)],
    }))
}

/// 查詢房間資訊
///
/// GET /api/v1/rooms/:code
pub async fn get_room(
    State(state): State<AppState>,
    Path(code): Path<String>,
) -> AppResult<Json<RoomDetailResponse>> {
    // 查詢房間
    let room = {
        let rooms = state.rooms.read().await;
        rooms
            .values()
            .find(|r| r.code == code)
            .cloned()
            .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
    };

    // 查詢房間內的玩家
    let players: Vec<PlayerResponse> = {
        let players = state.players.read().await;
        players
            .values()
            .filter(|p| p.room_id == room.id)
            .map(PlayerResponse::from)
            .collect()
    };

    let room_response = RoomResponse::from(room).with_player_count(players.len() as i32);

    Ok(Json(RoomDetailResponse {
        room: room_response,
        players,
    }))
}

/// 加入房間
///
/// POST /api/v1/rooms/:code/join
pub async fn join_room(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(code): Path<String>,
    Json(req): Json<JoinRoomRequest>,
) -> AppResult<Json<PlayerResponse>> {
    // 驗證請求
    req.validate()
        .map_err(|e| AppError::BadRequest(e.to_string()))?;

    // 檢查用戶是否已在其他房間
    {
        let players = state.players.read().await;
        if players.values().any(|p| p.user_id == auth.user_id) {
            return Err(AppError::BadRequest("您已在其他房間中".to_string()));
        }
    }

    // 查詢房間
    let room = {
        let rooms = state.rooms.read().await;
        rooms
            .values()
            .find(|r| r.code == code)
            .cloned()
            .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
    };

    // 檢查房間是否可加入
    if !room.can_join() {
        return Err(AppError::BadRequest("房間已開始遊戲或已結束".to_string()));
    }

    // 檢查房間是否已滿
    let current_player_count = {
        let players = state.players.read().await;
        players.values().filter(|p| p.room_id == room.id).count()
    };

    if current_player_count >= room.max_players as usize {
        return Err(AppError::BadRequest("房間已滿".to_string()));
    }

    // 創建玩家
    let player = Player::new(auth.user_id, room.id, req.player_name.clone(), false);
    let player_id = player.id;

    // 儲存玩家
    {
        let mut players = state.players.write().await;
        players.insert(player_id, player.clone());
    }

    tracing::info!(
        room_id = %room.id,
        room_code = %code,
        player_id = %player_id,
        player_name = %req.player_name,
        "玩家加入房間"
    );

    Ok(Json(PlayerResponse::from(player)))
}

/// 離開房間
///
/// POST /api/v1/rooms/:code/leave
pub async fn leave_room(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(code): Path<String>,
) -> AppResult<Json<serde_json::Value>> {
    // 查詢房間
    let room = {
        let rooms = state.rooms.read().await;
        rooms
            .values()
            .find(|r| r.code == code)
            .cloned()
            .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
    };

    // 查詢玩家
    let player = {
        let players = state.players.read().await;
        players
            .values()
            .find(|p| p.room_id == room.id && p.user_id == auth.user_id)
            .cloned()
            .ok_or_else(|| AppError::NotFound("您不在此房間中".to_string()))?
    };

    let is_host = player.is_host;
    let player_id = player.id;

    // 移除玩家
    {
        let mut players = state.players.write().await;
        players.remove(&player_id);
    }

    tracing::info!(
        room_id = %room.id,
        room_code = %code,
        player_id = %player_id,
        is_host = %is_host,
        "玩家離開房間"
    );

    // 如果是房主離開
    if is_host {
        // 查詢剩餘玩家
        let remaining_players: Vec<Uuid> = {
            let players = state.players.read().await;
            players
                .values()
                .filter(|p| p.room_id == room.id)
                .map(|p| p.id)
                .collect()
        };

        if remaining_players.is_empty() {
            // 沒有剩餘玩家，解散房間
            let mut rooms = state.rooms.write().await;
            rooms.remove(&room.id);

            tracing::info!(room_id = %room.id, room_code = %code, "房間已解散");

            return Ok(Json(serde_json::json!({
                "message": "已離開房間，房間已解散",
                "room_dissolved": true
            })));
        } else {
            // 指派新房主
            let new_host_id = remaining_players[0];
            let mut players = state.players.write().await;
            if let Some(new_host) = players.get_mut(&new_host_id) {
                new_host.is_host = true;

                tracing::info!(
                    room_id = %room.id,
                    new_host_id = %new_host_id,
                    "新房主已指派"
                );
            }

            return Ok(Json(serde_json::json!({
                "message": "已離開房間，已指派新房主",
                "new_host_id": new_host_id,
                "room_dissolved": false
            })));
        }
    }

    Ok(Json(serde_json::json!({
        "message": "已離開房間",
        "room_dissolved": false
    })))
}

/// 列出所有等待中的房間
///
/// GET /api/v1/rooms
pub async fn list_rooms(State(state): State<AppState>) -> AppResult<Json<Vec<RoomDetailResponse>>> {
    let rooms: Vec<Room> = {
        let rooms = state.rooms.read().await;
        rooms.values().filter(|r| r.can_join()).cloned().collect()
    };

    let mut result = Vec::new();

    for room in rooms {
        let players: Vec<PlayerResponse> = {
            let players = state.players.read().await;
            players
                .values()
                .filter(|p| p.room_id == room.id)
                .map(PlayerResponse::from)
                .collect()
        };

        let room_response = RoomResponse::from(room).with_player_count(players.len() as i32);

        result.push(RoomDetailResponse {
            room: room_response,
            players,
        });
    }

    Ok(Json(result))
}
