//! 房間領域模型
//!
//! 定義遊戲房間相關的資料結構

use chrono::{DateTime, Utc};
use rand::Rng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 房間狀態
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RoomStatus {
    /// 等待中
    #[default]
    Waiting,
    /// 遊戲進行中
    Playing,
    /// 已結束
    Finished,
}

impl std::fmt::Display for RoomStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RoomStatus::Waiting => write!(f, "等待中"),
            RoomStatus::Playing => write!(f, "遊戲中"),
            RoomStatus::Finished => write!(f, "已結束"),
        }
    }
}

/// 房間
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Room {
    /// 房間 ID
    pub id: Uuid,
    /// 房間代碼（6 位）
    pub code: String,
    /// 房主 ID
    pub host_id: Uuid,
    /// 房間狀態
    pub status: RoomStatus,
    /// 最大玩家數
    pub max_players: i32,
    /// 最大觀戰者數
    pub max_spectators: i32,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

impl Room {
    /// 建立新房間
    pub fn new(host_id: Uuid) -> Self {
        Self {
            id: Uuid::new_v4(),
            code: Self::generate_room_code(),
            host_id,
            status: RoomStatus::Waiting,
            max_players: 4,
            max_spectators: 10,
            created_at: Utc::now(),
        }
    }

    /// 使用指定最大玩家數建立房間
    pub fn with_max_players(host_id: Uuid, max_players: i32) -> Self {
        let mut room = Self::new(host_id);
        room.max_players = max_players.clamp(2, 8);
        room
    }

    /// 檢查是否可以觀戰
    pub fn can_spectate(&self, current_spectator_count: usize) -> bool {
        (current_spectator_count as i32) < self.max_spectators
            && (self.status == RoomStatus::Waiting || self.status == RoomStatus::Playing)
    }

    /// 生成 6 位房間代碼
    fn generate_room_code() -> String {
        let mut rng = rand::thread_rng();
        let chars: Vec<char> = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".chars().collect();
        (0..6)
            .map(|_| chars[rng.gen_range(0..chars.len())])
            .collect()
    }

    /// 檢查房間是否可加入
    pub fn can_join(&self) -> bool {
        self.status == RoomStatus::Waiting
    }

    /// 檢查是否可以開始遊戲
    pub fn can_start(&self, player_count: usize) -> bool {
        self.status == RoomStatus::Waiting && player_count >= 2
    }

    /// 開始遊戲
    pub fn start(&mut self) {
        self.status = RoomStatus::Playing;
    }

    /// 結束遊戲
    pub fn finish(&mut self) {
        self.status = RoomStatus::Finished;
    }
}

/// 房間回應（包含玩家列表）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomResponse {
    /// 房間 ID
    pub id: Uuid,
    /// 房間代碼
    pub code: String,
    /// 房主 ID
    pub host_id: Uuid,
    /// 房間狀態
    pub status: RoomStatus,
    /// 最大玩家數
    pub max_players: i32,
    /// 當前玩家數
    pub player_count: i32,
    /// 建立時間
    pub created_at: DateTime<Utc>,
}

impl From<Room> for RoomResponse {
    fn from(room: Room) -> Self {
        Self {
            id: room.id,
            code: room.code,
            host_id: room.host_id,
            status: room.status,
            max_players: room.max_players,
            player_count: 0, // 需要另外填入
            created_at: room.created_at,
        }
    }
}

impl RoomResponse {
    /// 設定玩家數量
    pub fn with_player_count(mut self, count: i32) -> Self {
        self.player_count = count;
        self
    }
}

/// 建立房間請求
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CreateRoomRequest {
    /// 最大玩家數（可選，預設 4）
    #[serde(default)]
    pub max_players: Option<i32>,
}

/// 加入房間請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JoinRoomRequest {
    /// 玩家名稱
    pub player_name: String,
}

impl JoinRoomRequest {
    /// 驗證請求
    pub fn validate(&self) -> Result<(), &'static str> {
        if self.player_name.is_empty() {
            return Err("玩家名稱不能為空");
        }
        if self.player_name.len() > 20 {
            return Err("玩家名稱不能超過 20 個字元");
        }
        Ok(())
    }
}

/// 房間代碼請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomCodeRequest {
    /// 房間代碼
    pub code: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_room_code_generation() {
        let room = Room::new(Uuid::new_v4());
        assert_eq!(room.code.len(), 6);
        // 確保只包含允許的字元
        for c in room.code.chars() {
            assert!(
                "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains(c),
                "Invalid character in room code: {}",
                c
            );
        }
    }

    #[test]
    fn test_room_status_flow() {
        let mut room = Room::new(Uuid::new_v4());
        assert_eq!(room.status, RoomStatus::Waiting);
        assert!(room.can_join());

        room.start();
        assert_eq!(room.status, RoomStatus::Playing);
        assert!(!room.can_join());

        room.finish();
        assert_eq!(room.status, RoomStatus::Finished);
        assert!(!room.can_join());
    }

    #[test]
    fn test_max_players_clamping() {
        let room = Room::with_max_players(Uuid::new_v4(), 100);
        assert_eq!(room.max_players, 8);

        let room = Room::with_max_players(Uuid::new_v4(), 1);
        assert_eq!(room.max_players, 2);
    }
}
