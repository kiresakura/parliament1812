//! 房間管理服務
//!
//! 提供房間的建立、加入、離開等業務邏輯

use rand::seq::SliceRandom;
use uuid::Uuid;

use crate::domain::{CharacterType, Player, Room, RoomStatus};
use crate::error::AppError;
use crate::AppState;

/// 房間服務
///
/// 提供房間管理的業務邏輯
pub struct RoomService;

impl RoomService {
    /// 建立新房間
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `user_id` - 建立者的使用者 ID
    /// * `host_name` - 房主名稱
    ///
    /// # Returns
    /// 回傳建立的房間和房主玩家
    pub async fn create_room(
        state: &AppState,
        user_id: Uuid,
        host_name: String,
    ) -> Result<(Room, Player), AppError> {
        // 檢查使用者是否已在其他房間
        {
            let players = state.players.read().await;
            if players.values().any(|p| p.user_id == user_id) {
                return Err(AppError::BadRequest("您已在其他房間中".to_string()));
            }
        }

        // 生成唯一房間碼
        let room = loop {
            let room = Room::new(user_id);
            let rooms = state.rooms.read().await;

            // 檢查房間碼是否已存在
            let code_exists = rooms.values().any(|r| r.code == room.code);
            if !code_exists {
                break room;
            }
            // 如果碼重複，重新生成
        };

        let room_id = room.id;
        let room_code = room.code.clone();

        // 建立房主玩家
        let player = Player::new(user_id, room_id, host_name, true);
        let player_id = player.id;

        // 儲存房間
        {
            let mut rooms = state.rooms.write().await;
            rooms.insert(room_id, room.clone());
        }

        // 儲存玩家
        {
            let mut players = state.players.write().await;
            players.insert(player_id, player.clone());
        }

        // 更新房間玩家映射
        {
            let mut room_players = state.room_players.write().await;
            room_players.insert(room_code.clone(), vec![player_id]);
        }

        tracing::info!(
            room_id = %room_id,
            room_code = %room_code,
            host_id = %user_id,
            "房間已建立"
        );

        Ok((room, player))
    }

    /// 加入房間
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `user_id` - 加入者的使用者 ID
    /// * `name` - 玩家名稱
    ///
    /// # Returns
    /// 回傳建立的玩家
    pub async fn join_room(
        state: &AppState,
        room_code: &str,
        user_id: Uuid,
        name: String,
    ) -> Result<Player, AppError> {
        // 檢查使用者是否已在其他房間
        {
            let players = state.players.read().await;
            if players.values().any(|p| p.user_id == user_id) {
                return Err(AppError::BadRequest("您已在其他房間中".to_string()));
            }
        }

        // 查詢房間
        let room = {
            let rooms = state.rooms.read().await;
            rooms
                .values()
                .find(|r| r.code == room_code)
                .cloned()
                .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
        };

        // 檢查房間狀態
        if room.status != RoomStatus::Waiting {
            return Err(AppError::BadRequest("遊戲已開始，無法加入".to_string()));
        }

        // 檢查人數
        let current_count = {
            let room_players = state.room_players.read().await;
            room_players.get(&room.code).map(|v| v.len()).unwrap_or(0)
        };

        if current_count >= room.max_players as usize {
            return Err(AppError::BadRequest("房間已滿".to_string()));
        }

        // 建立玩家
        let player = Player::new(user_id, room.id, name, false);
        let player_id = player.id;

        // 儲存玩家
        {
            let mut players = state.players.write().await;
            players.insert(player_id, player.clone());
        }

        // 更新房間玩家映射
        {
            let mut room_players = state.room_players.write().await;
            room_players
                .entry(room.code.clone())
                .or_insert_with(Vec::new)
                .push(player_id);
        }

        tracing::info!(
            room_code = %room_code,
            player_id = %player_id,
            player_name = %player.name,
            "玩家加入房間"
        );

        Ok(player)
    }

    /// 離開房間
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_id` - 玩家 ID
    ///
    /// # Returns
    /// 回傳新房主 ID（如果有轉移）和房間是否解散
    pub async fn leave_room(
        state: &AppState,
        room_code: &str,
        player_id: Uuid,
    ) -> Result<LeaveRoomResult, AppError> {
        // 取得玩家資訊
        let player = {
            let players = state.players.read().await;
            players
                .get(&player_id)
                .cloned()
                .ok_or_else(|| AppError::NotFound("玩家不存在".to_string()))?
        };

        let was_host = player.is_host;
        let player_name = player.name.clone();
        let room_id = player.room_id;

        // 移除玩家
        {
            let mut players = state.players.write().await;
            players.remove(&player_id);
        }

        // 更新房間玩家映射
        let remaining_players = {
            let mut room_players = state.room_players.write().await;
            if let Some(player_ids) = room_players.get_mut(room_code) {
                player_ids.retain(|&id| id != player_id);
                player_ids.clone()
            } else {
                Vec::new()
            }
        };

        // 如果沒有剩餘玩家，解散房間
        if remaining_players.is_empty() {
            {
                let mut rooms = state.rooms.write().await;
                rooms.remove(&room_id);
            }
            {
                let mut room_players = state.room_players.write().await;
                room_players.remove(room_code);
            }

            tracing::info!(room_code = %room_code, "房間已解散");

            return Ok(LeaveRoomResult {
                player_id,
                player_name,
                was_host,
                new_host_id: None,
                room_disbanded: true,
            });
        }

        // 如果是房主，轉移房主
        let new_host_id = if was_host {
            let new_host_id = remaining_players[0];

            // 更新新房主
            {
                let mut players = state.players.write().await;
                if let Some(new_host) = players.get_mut(&new_host_id) {
                    new_host.is_host = true;
                }
            }

            // 更新房間的 host_id
            {
                let mut rooms = state.rooms.write().await;
                if let Some(room) = rooms.get_mut(&room_id) {
                    // 找到新房主的 user_id
                    let new_host_user_id = {
                        let players = state.players.read().await;
                        players.get(&new_host_id).map(|p| p.user_id)
                    };
                    if let Some(user_id) = new_host_user_id {
                        room.host_id = user_id;
                    }
                }
            }

            tracing::info!(
                room_code = %room_code,
                new_host_id = %new_host_id,
                "房主已轉移"
            );

            Some(new_host_id)
        } else {
            None
        };

        tracing::info!(
            room_code = %room_code,
            player_id = %player_id,
            "玩家離開房間"
        );

        Ok(LeaveRoomResult {
            player_id,
            player_name,
            was_host,
            new_host_id,
            room_disbanded: false,
        })
    }

    /// 設定玩家準備狀態
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_id` - 玩家 ID
    /// * `ready` - 是否準備
    pub async fn set_ready(
        state: &AppState,
        room_code: &str,
        player_id: Uuid,
        ready: bool,
    ) -> Result<(), AppError> {
        // 檢查玩家是否在房間中
        let player_room_code = {
            let room_players = state.room_players.read().await;
            room_players
                .iter()
                .find(|(_, players)| players.contains(&player_id))
                .map(|(code, _)| code.clone())
        };

        match player_room_code {
            Some(code) if code == room_code => {}
            _ => return Err(AppError::BadRequest("您不在此房間中".to_string())),
        }

        // 更新準備狀態
        {
            let mut players = state.players.write().await;
            if let Some(player) = players.get_mut(&player_id) {
                player.is_ready = ready;
            } else {
                return Err(AppError::NotFound("玩家不存在".to_string()));
            }
        }

        tracing::debug!(
            room_code = %room_code,
            player_id = %player_id,
            ready = ready,
            "玩家準備狀態已更新"
        );

        Ok(())
    }

    /// 選擇角色
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_id` - 玩家 ID
    /// * `character` - 角色類型
    pub async fn select_character(
        state: &AppState,
        room_code: &str,
        player_id: Uuid,
        character: CharacterType,
    ) -> Result<(), AppError> {
        // 檢查玩家是否在房間中
        let player_room_code = {
            let room_players = state.room_players.read().await;
            room_players
                .iter()
                .find(|(_, players)| players.contains(&player_id))
                .map(|(code, _)| code.clone())
        };

        match player_room_code {
            Some(code) if code == room_code => {}
            _ => return Err(AppError::BadRequest("您不在此房間中".to_string())),
        }

        // 檢查角色是否已被選擇
        {
            let room_players = state.room_players.read().await;
            let players = state.players.read().await;

            if let Some(player_ids) = room_players.get(room_code) {
                for &pid in player_ids {
                    if pid != player_id {
                        if let Some(p) = players.get(&pid) {
                            if p.character == Some(character) {
                                return Err(AppError::BadRequest(
                                    "此角色已被其他玩家選擇".to_string(),
                                ));
                            }
                        }
                    }
                }
            }
        }

        // 更新角色
        {
            let mut players = state.players.write().await;
            if let Some(player) = players.get_mut(&player_id) {
                player.select_character(character);
            } else {
                return Err(AppError::NotFound("玩家不存在".to_string()));
            }
        }

        tracing::debug!(
            room_code = %room_code,
            player_id = %player_id,
            character = ?character,
            "玩家選擇角色"
        );

        Ok(())
    }

    /// 開始遊戲
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `host_id` - 房主玩家 ID
    ///
    /// # Returns
    /// 回傳角色分配結果
    pub async fn start_game(
        state: &AppState,
        room_code: &str,
        host_player_id: Uuid,
    ) -> Result<StartGameResult, AppError> {
        // 取得房間
        let room = {
            let rooms = state.rooms.read().await;
            rooms
                .values()
                .find(|r| r.code == room_code)
                .cloned()
                .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
        };

        // 取得房間內的玩家
        let player_ids = {
            let room_players = state.room_players.read().await;
            room_players
                .get(room_code)
                .cloned()
                .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
        };

        // 檢查是否為房主
        {
            let players = state.players.read().await;
            let host_player = players
                .get(&host_player_id)
                .ok_or_else(|| AppError::NotFound("玩家不存在".to_string()))?;

            if !host_player.is_host {
                return Err(AppError::Forbidden("只有房主可以開始遊戲".to_string()));
            }
        }

        // 檢查人數
        let player_count = player_ids.len();
        if player_count < 2 {
            return Err(AppError::BadRequest(
                "至少需要 2 名玩家才能開始遊戲".to_string(),
            ));
        }
        if player_count > 4 {
            return Err(AppError::BadRequest("最多只能有 4 名玩家".to_string()));
        }

        // 檢查所有玩家是否都已準備（房主除外）
        {
            let players = state.players.read().await;
            for &pid in &player_ids {
                if let Some(player) = players.get(&pid) {
                    if !player.is_host && !player.is_ready {
                        return Err(AppError::BadRequest("並非所有玩家都已準備".to_string()));
                    }
                }
            }
        }

        // 隨機分配角色給未選擇的玩家
        let character_assignments = Self::assign_characters(state, &player_ids).await?;

        // 更新房間狀態
        {
            let mut rooms = state.rooms.write().await;
            if let Some(r) = rooms.get_mut(&room.id) {
                r.start();
            }
        }

        tracing::info!(
            room_code = %room_code,
            player_count = player_count,
            "遊戲開始"
        );

        Ok(StartGameResult {
            room_code: room_code.to_string(),
            player_count,
            character_assignments,
        })
    }

    /// 隨機分配角色
    async fn assign_characters(
        state: &AppState,
        player_ids: &[Uuid],
    ) -> Result<Vec<(Uuid, CharacterType)>, AppError> {
        let mut assignments = Vec::new();
        let mut available_characters: Vec<CharacterType> = CharacterType::all();

        // 使用隨機數打亂角色順序（必須在 await 之前完成並 drop rng）
        {
            let mut rng = rand::thread_rng();
            available_characters.shuffle(&mut rng);
        }

        // 先收集已選擇角色的玩家
        let mut taken_characters = Vec::new();
        {
            let players = state.players.read().await;
            for &pid in player_ids {
                if let Some(player) = players.get(&pid) {
                    if let Some(character) = player.character {
                        taken_characters.push(character);
                        assignments.push((pid, character));
                    }
                }
            }
        }

        // 移除已被選擇的角色
        available_characters.retain(|c| !taken_characters.contains(c));

        // 分配角色給未選擇的玩家
        {
            let mut players = state.players.write().await;
            let mut char_index = 0;

            for &pid in player_ids {
                if let Some(player) = players.get_mut(&pid) {
                    if player.character.is_none() && char_index < available_characters.len() {
                        let character = available_characters[char_index];
                        player.select_character(character);
                        assignments.push((pid, character));
                        char_index += 1;
                    }
                }
            }
        }

        Ok(assignments)
    }

    /// 取得房間內的所有玩家
    pub async fn get_room_players(
        state: &AppState,
        room_code: &str,
    ) -> Result<Vec<Player>, AppError> {
        let player_ids = {
            let room_players = state.room_players.read().await;
            room_players.get(room_code).cloned().unwrap_or_default()
        };

        let players = state.players.read().await;
        let result: Vec<Player> = player_ids
            .iter()
            .filter_map(|id| players.get(id).cloned())
            .collect();

        Ok(result)
    }

    /// 取得房間資訊
    pub async fn get_room(state: &AppState, room_code: &str) -> Result<Room, AppError> {
        let rooms = state.rooms.read().await;
        rooms
            .values()
            .find(|r| r.code == room_code)
            .cloned()
            .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))
    }

    /// 根據玩家 ID 取得房間代碼
    pub async fn get_player_room_code(state: &AppState, player_id: Uuid) -> Option<String> {
        let room_players = state.room_players.read().await;
        room_players
            .iter()
            .find(|(_, players)| players.contains(&player_id))
            .map(|(code, _)| code.clone())
    }

    /// 檢查使用者是否在房間中
    pub async fn is_user_in_room(state: &AppState, user_id: Uuid) -> bool {
        let players = state.players.read().await;
        players.values().any(|p| p.user_id == user_id)
    }
}

/// 離開房間結果
#[derive(Debug, Clone)]
pub struct LeaveRoomResult {
    /// 離開的玩家 ID
    pub player_id: Uuid,
    /// 離開的玩家名稱
    pub player_name: String,
    /// 是否為房主
    pub was_host: bool,
    /// 新房主 ID（如果有轉移）
    pub new_host_id: Option<Uuid>,
    /// 房間是否解散
    pub room_disbanded: bool,
}

/// 開始遊戲結果
#[derive(Debug, Clone)]
pub struct StartGameResult {
    /// 房間代碼
    pub room_code: String,
    /// 玩家數量
    pub player_count: usize,
    /// 角色分配（玩家 ID, 角色類型）
    pub character_assignments: Vec<(Uuid, CharacterType)>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Settings;

    async fn create_test_state() -> AppState {
        let settings = Settings::default();
        AppState::for_testing(settings)
    }

    #[tokio::test]
    async fn test_create_room() {
        let state = create_test_state().await;
        let user_id = Uuid::new_v4();

        let result = RoomService::create_room(&state, user_id, "TestHost".to_string()).await;
        assert!(result.is_ok());

        let (room, player) = result.unwrap();
        assert_eq!(room.host_id, user_id);
        assert_eq!(player.name, "TestHost");
        assert!(player.is_host);
    }

    #[tokio::test]
    async fn test_join_room() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();
        let player_id = Uuid::new_v4();

        // 建立房間
        let (room, _) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 加入房間
        let result =
            RoomService::join_room(&state, &room.code, player_id, "Player".to_string()).await;
        assert!(result.is_ok());

        let player = result.unwrap();
        assert_eq!(player.name, "Player");
        assert!(!player.is_host);
    }

    #[tokio::test]
    async fn test_leave_room_host_transfer() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();
        let player_id = Uuid::new_v4();

        // 建立房間
        let (room, host_player) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 加入房間
        let player = RoomService::join_room(&state, &room.code, player_id, "Player".to_string())
            .await
            .unwrap();

        // 房主離開
        let result = RoomService::leave_room(&state, &room.code, host_player.id).await;
        assert!(result.is_ok());

        let leave_result = result.unwrap();
        assert!(leave_result.was_host);
        assert_eq!(leave_result.new_host_id, Some(player.id));
        assert!(!leave_result.room_disbanded);
    }

    #[tokio::test]
    async fn test_leave_room_disband() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();

        // 建立房間（只有房主）
        let (room, host_player) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 房主離開（房間應該解散）
        let result = RoomService::leave_room(&state, &room.code, host_player.id).await;
        assert!(result.is_ok());

        let leave_result = result.unwrap();
        assert!(leave_result.room_disbanded);
        assert!(leave_result.new_host_id.is_none());
    }

    #[tokio::test]
    async fn test_start_game() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();
        let player_id = Uuid::new_v4();

        // 建立房間
        let (room, host_player) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 加入房間
        let player = RoomService::join_room(&state, &room.code, player_id, "Player".to_string())
            .await
            .unwrap();

        // 設定準備
        RoomService::set_ready(&state, &room.code, player.id, true)
            .await
            .unwrap();

        // 開始遊戲
        let result = RoomService::start_game(&state, &room.code, host_player.id).await;
        assert!(result.is_ok());

        let start_result = result.unwrap();
        assert_eq!(start_result.player_count, 2);
        assert_eq!(start_result.character_assignments.len(), 2);
    }

    #[tokio::test]
    async fn test_start_game_not_enough_players() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();

        // 建立房間（只有房主）
        let (room, host_player) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 嘗試開始遊戲
        let result = RoomService::start_game(&state, &room.code, host_player.id).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_duplicate_user_join() {
        let state = create_test_state().await;
        let host_id = Uuid::new_v4();

        // 建立房間
        let (room, _) = RoomService::create_room(&state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 嘗試用同一使用者再次加入
        let result = RoomService::join_room(&state, &room.code, host_id, "Host2".to_string()).await;
        assert!(result.is_err());
    }
}
