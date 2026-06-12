//! 玩家關係領域模型
//!
//! 定義跨局玩家關係系統的資料結構，包含信任分數、盟友、宿敵等

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 玩家關係
///
/// 對應資料庫 `player_relationships` 表，追蹤兩個玩家之間的跨局關係
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PlayerRelationship {
    /// 關係唯一識別碼
    pub id: Uuid,
    /// 玩家 A（UUID 較小者）
    pub player_a: Uuid,
    /// 玩家 B（UUID 較大者）
    pub player_b: Uuid,
    /// 結盟次數
    pub alliance_count: i32,
    /// 背叛次數
    pub betrayal_count: i32,
    /// 挑戰次數
    pub challenge_count: i32,
    /// 一起遊戲的次數
    pub games_together: i32,
    /// 信任分數（0.0 ~ 100.0）
    pub trust_score: f64,
    /// 關係類型（nemesis / rival / neutral / trusted / sworn_ally）
    pub relationship_type: String,
    /// 最後一場共同遊戲的 ID
    pub last_game_id: Option<Uuid>,
    /// 最後更新時間
    pub updated_at: DateTime<Utc>,
}

/// 關係回應（包含對方的名字與 ELO）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelationshipResponse {
    /// 關係資料
    pub relationship: PlayerRelationship,
    /// 對方玩家 ID
    pub other_player_id: Uuid,
    /// 對方玩家名稱
    pub other_player_name: String,
    /// 對方玩家 ELO 分數
    pub other_player_elo: i32,
}

/// 關係列表回應
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelationshipListResponse {
    /// 關係列表
    pub relationships: Vec<RelationshipResponse>,
    /// 總數
    pub total: i64,
}

/// 根據信任分數判斷關係類型
///
/// - > 80: sworn_ally（堅定盟友）
/// - > 60: trusted（信任）
/// - > 40: neutral（中立）
/// - > 20: rival（對手）
/// - ≤ 20: nemesis（宿敵）
pub fn relationship_type_from_trust(trust: f64) -> &'static str {
    match trust {
        t if t > 80.0 => "sworn_ally",
        t if t > 60.0 => "trusted",
        t if t > 40.0 => "neutral",
        t if t > 20.0 => "rival",
        _ => "nemesis",
    }
}
