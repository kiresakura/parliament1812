//! 觀戰服務
//!
//! 提供觀戰模式相關功能：
//! - 遊戲狀態淨化（隱藏敏感資訊）
//! - 觀戰資格檢查

use crate::domain::RoomStatus;
use crate::error::AppResult;
use crate::AppState;

/// 觀戰服務
pub struct SpectatorService;

impl SpectatorService {
    /// 淨化遊戲狀態（隱藏敏感資訊）
    ///
    /// 移除觀戰者不應看到的資訊：
    /// - 玩家手牌（hand）
    /// - 隱藏議程（hidden_agenda）
    /// - 私人訊息（private_messages）
    /// - 投票詳情（在投票結束前）
    pub fn sanitize_game_state(state: &serde_json::Value) -> serde_json::Value {
        let mut sanitized = state.clone();

        // 移除 players 陣列中每個玩家的敏感欄位
        if let Some(players) = sanitized.get_mut("players") {
            if let Some(players_arr) = players.as_array_mut() {
                for player in players_arr.iter_mut() {
                    if let Some(obj) = player.as_object_mut() {
                        obj.remove("hand");
                        obj.remove("hidden_agenda");
                        obj.remove("private_messages");
                        obj.remove("secret_objective");
                        obj.remove("cards");
                    }
                }
            }
        }

        // 移除頂層的私人訊息
        if let Some(obj) = sanitized.as_object_mut() {
            obj.remove("private_messages");
            obj.remove("player_hands");
            obj.remove("hidden_agendas");
        }

        sanitized
    }

    /// 檢查房間是否允許觀戰
    ///
    /// 條件：
    /// 1. 房間存在
    /// 2. 遊戲狀態為進行中（Playing）
    pub async fn can_spectate(state: &AppState, room_code: &str) -> AppResult<bool> {
        let rooms = state.rooms.read().await;
        let room = rooms.values().find(|r| r.code == room_code);

        match room {
            Some(room) => {
                // 只有遊戲進行中才允許觀戰
                Ok(room.status == RoomStatus::Playing)
            }
            None => Ok(false),
        }
    }

    /// 取得觀戰用的遊戲狀態快照
    ///
    /// 返回淨化過的遊戲狀態 JSON
    pub async fn get_spectator_game_state(
        state: &AppState,
        room_code: &str,
    ) -> Option<(serde_json::Value, i32, String)> {
        let games = state.games.read().await;
        if let Some(game) = games.get(room_code) {
            // 將遊戲狀態序列化為 JSON
            let game_state_json = serde_json::to_value(&game.state).ok()?;
            let sanitized = Self::sanitize_game_state(&game_state_json);
            let round = game.state.current_round;
            let phase = format!("{:?}", game.state.phase);
            Some((sanitized, round, phase))
        } else {
            None
        }
    }
}
