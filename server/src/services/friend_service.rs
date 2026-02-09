//! 好友服務
//!
//! 好友系統的核心業務邏輯：
//! - 好友請求（發送 / 接受 / 拒絕）
//! - 好友管理（刪除 / 封鎖 / 解鎖）
//! - 在線狀態追蹤
//! - 好友對戰邀請

use crate::db::friends::{FriendDb, FriendInfo, FriendRequest, UserSummary};
use crate::error::{AppError, AppResult};
use crate::websocket::ServerMessage;
use crate::AppState;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 好友對戰邀請資訊
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameInvite {
    pub from_user_id: Uuid,
    pub from_username: String,
    pub from_display_name: Option<String>,
    pub room_code: String,
}

/// 好友服務
pub struct FriendService;

impl FriendService {
    // ============================================================
    // 好友請求
    // ============================================================

    /// 發送好友請求
    pub async fn send_friend_request(
        state: &AppState,
        from_user_id: Uuid,
        to_user_id: Uuid,
    ) -> AppResult<()> {
        if from_user_id == to_user_id {
            return Err(AppError::BadRequest("不能加自己為好友".to_string()));
        }

        // 檢查是否被對方封鎖
        let blocked = FriendDb::is_blocked(&state.db, to_user_id, from_user_id).await?;
        if blocked {
            return Err(AppError::Forbidden("無法發送好友請求".to_string()));
        }

        let sent = FriendDb::send_request(&state.db, from_user_id, to_user_id).await?;
        if !sent {
            return Err(AppError::BadRequest(
                "已發送過好友請求或已是好友".to_string(),
            ));
        }

        // 通過 WebSocket 通知對方（如果在線）
        let notification = ServerMessage::system(
            serde_json::json!({
                "type": "friend_request",
                "from_user_id": from_user_id.to_string(),
            })
            .to_string(),
            crate::websocket::messages::SystemMessageType::Info,
        );
        state.ws_hub.send_to_user(to_user_id, notification).await;

        Ok(())
    }

    /// 接受好友請求
    pub async fn accept_friend_request(
        state: &AppState,
        user_id: Uuid,
        from_user_id: Uuid,
    ) -> AppResult<()> {
        let accepted = FriendDb::accept_request(&state.db, user_id, from_user_id).await?;
        if !accepted {
            return Err(AppError::NotFound("找不到待處理的好友請求".to_string()));
        }

        // 通知對方
        let notification = ServerMessage::system(
            serde_json::json!({
                "type": "friend_accepted",
                "user_id": user_id.to_string(),
            })
            .to_string(),
            crate::websocket::messages::SystemMessageType::Success,
        );
        state
            .ws_hub
            .send_to_user(from_user_id, notification)
            .await;

        Ok(())
    }

    /// 拒絕好友請求
    pub async fn reject_friend_request(
        state: &AppState,
        user_id: Uuid,
        from_user_id: Uuid,
    ) -> AppResult<()> {
        let rejected = FriendDb::reject_request(&state.db, user_id, from_user_id).await?;
        if !rejected {
            return Err(AppError::NotFound("找不到待處理的好友請求".to_string()));
        }
        Ok(())
    }

    // ============================================================
    // 好友管理
    // ============================================================

    /// 刪除好友
    pub async fn remove_friend(
        state: &AppState,
        user_id: Uuid,
        friend_id: Uuid,
    ) -> AppResult<()> {
        let removed = FriendDb::remove_friend(&state.db, user_id, friend_id).await?;
        if !removed {
            return Err(AppError::NotFound("不是好友關係".to_string()));
        }
        Ok(())
    }

    /// 封鎖用戶
    pub async fn block_user(
        state: &AppState,
        user_id: Uuid,
        target_id: Uuid,
    ) -> AppResult<()> {
        if user_id == target_id {
            return Err(AppError::BadRequest("不能封鎖自己".to_string()));
        }
        FriendDb::block_user(&state.db, user_id, target_id).await?;
        Ok(())
    }

    /// 解除封鎖
    pub async fn unblock_user(
        state: &AppState,
        user_id: Uuid,
        target_id: Uuid,
    ) -> AppResult<()> {
        let unblocked = FriendDb::unblock_user(&state.db, user_id, target_id).await?;
        if !unblocked {
            return Err(AppError::NotFound("未封鎖此用戶".to_string()));
        }
        Ok(())
    }

    // ============================================================
    // 查詢
    // ============================================================

    /// 取得好友列表（含在線狀態）
    ///
    /// 同時以 WebSocket Hub 的即時連線狀態覆蓋 DB 中的 is_online。
    pub async fn get_friends_list(
        state: &AppState,
        user_id: Uuid,
    ) -> AppResult<Vec<FriendInfo>> {
        let mut friends = FriendDb::get_friends_list(&state.db, user_id).await?;

        // 用 WebSocket Hub 即時狀態覆蓋
        for friend in &mut friends {
            let connected = state.ws_hub.is_user_connected(friend.user_id).await;
            friend.is_online = Some(connected);
        }

        // 重新排序：在線優先
        friends.sort_by(|a, b| {
            let a_online = a.is_online.unwrap_or(false);
            let b_online = b.is_online.unwrap_or(false);
            b_online.cmp(&a_online).then(a.username.cmp(&b.username))
        });

        Ok(friends)
    }

    /// 取得待處理的好友請求
    pub async fn get_pending_requests(
        state: &AppState,
        user_id: Uuid,
    ) -> AppResult<Vec<FriendRequest>> {
        let requests = FriendDb::get_pending_requests(&state.db, user_id).await?;
        Ok(requests)
    }

    /// 搜尋用戶
    pub async fn search_users(
        state: &AppState,
        query: &str,
        current_user_id: Uuid,
        limit: u32,
    ) -> AppResult<Vec<UserSummary>> {
        if query.trim().is_empty() {
            return Ok(vec![]);
        }
        let limit = limit.min(50) as i64;
        let users = FriendDb::search_users(&state.db, query, current_user_id, limit).await?;
        Ok(users)
    }

    // ============================================================
    // 好友對戰邀請
    // ============================================================

    /// 邀請好友對戰
    ///
    /// 建立私人房間並發送 WebSocket 通知給好友。
    pub async fn invite_friend_to_game(
        state: &AppState,
        from_user_id: Uuid,
        friend_id: Uuid,
    ) -> AppResult<String> {
        // 確認是好友
        let are_friends = FriendDb::are_friends(&state.db, from_user_id, friend_id).await?;
        if !are_friends {
            return Err(AppError::BadRequest("只能邀請好友對戰".to_string()));
        }

        // 確認好友在線
        let is_online = state.ws_hub.is_user_connected(friend_id).await;
        if !is_online {
            return Err(AppError::BadRequest("好友不在線".to_string()));
        }

        // 取得邀請者資訊
        let from_user = crate::db::users::UserDb::find_extended_by_id(&state.db, from_user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("用戶不存在".to_string()))?;

        // 建立私人房間（自動生成代碼）
        let room = crate::domain::Room::new(from_user_id);
        let room_id = room.id;
        let room_code_str = room.code.clone();

        {
            let mut rooms = state.rooms.write().await;
            rooms.insert(room_id, room);
        }

        // 建立房主玩家
        let player = crate::domain::Player::new(
            from_user_id,
            room_id,
            from_user.display_name.clone().unwrap_or(from_user.username.clone()),
            true,
        );
        {
            let mut players = state.players.write().await;
            players.insert(player.id, player);
        }

        // 發送 WebSocket 邀請
        let invite_msg = ServerMessage::system(
            serde_json::json!({
                "type": "game_invite",
                "from": {
                    "user_id": from_user_id.to_string(),
                    "username": from_user.username,
                    "display_name": from_user.display_name,
                },
                "room_code": room_code_str,
            })
            .to_string(),
            crate::websocket::messages::SystemMessageType::Info,
        );
        state.ws_hub.send_to_user(friend_id, invite_msg).await;

        tracing::info!(
            from = %from_user_id,
            to = %friend_id,
            room = %room_code_str,
            "好友對戰邀請已發送"
        );

        Ok(room_code_str)
    }

    // ============================================================
    // 在線狀態
    // ============================================================

    /// 使用者上線（WebSocket 連接時呼叫）
    pub async fn user_came_online(state: &AppState, user_id: Uuid) {
        if let Err(e) = FriendDb::set_online(&state.db, user_id).await {
            tracing::warn!(user_id = %user_id, error = %e, "設定用戶在線狀態失敗");
        }
    }

    /// 使用者離線（WebSocket 斷開時呼叫）
    pub async fn user_went_offline(state: &AppState, user_id: Uuid) {
        if let Err(e) = FriendDb::set_offline(&state.db, user_id).await {
            tracing::warn!(user_id = %user_id, error = %e, "設定用戶離線狀態失敗");
        }
    }
}
