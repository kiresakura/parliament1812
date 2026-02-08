//! 遊戲行動處理
//!
//! 定義遊戲行動類型和結果

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::{CharacterType, VoteChoice};

/// 遊戲行動
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum GameAction {
    /// 質詢（攻擊）
    Challenge {
        attacker_id: Uuid,
        target_id: Uuid,
        damage: i32,
        was_countered: bool,
    },
    /// 反駁（防禦）
    Counter { defender_id: Uuid },
    /// 使用技能
    UseSkill {
        player_id: Uuid,
        skill: String,
        target_id: Option<Uuid>,
        effect: String,
    },
    /// 投票
    Vote { player_id: Uuid, choice: VoteChoice },
    /// 聊天
    Chat {
        from_id: Uuid,
        content: String,
        is_private: bool,
        to_id: Option<Uuid>,
    },
    /// 結盟
    FormAlliance { player_a: Uuid, player_b: Uuid },
    /// 背叛
    Betray { betrayer_id: Uuid, target_id: Uuid },
    /// 使用卡牌
    CardUsed {
        player_id: Uuid,
        card_name: String,
        target_id: Option<Uuid>,
        timestamp: chrono::DateTime<chrono::Utc>,
    },
    /// 抽牌
    CardDrawn {
        player_id: Uuid,
        card_name: String,
        timestamp: chrono::DateTime<chrono::Utc>,
    },
    /// 棄牌
    CardDiscarded {
        player_id: Uuid,
        card_name: String,
        timestamp: chrono::DateTime<chrono::Utc>,
    },
}

/// 行動結果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActionResult {
    /// 是否成功
    pub success: bool,
    /// 結果訊息
    pub message: String,
    /// 產生的效果
    pub effects: Vec<GameEffect>,
}

impl ActionResult {
    /// 建立成功結果
    pub fn success(message: impl Into<String>) -> Self {
        Self {
            success: true,
            message: message.into(),
            effects: Vec::new(),
        }
    }

    /// 建立成功結果並附帶效果
    pub fn success_with_effects(message: impl Into<String>, effects: Vec<GameEffect>) -> Self {
        Self {
            success: true,
            message: message.into(),
            effects,
        }
    }

    /// 建立失敗結果
    pub fn failure(message: impl Into<String>) -> Self {
        Self {
            success: false,
            message: message.into(),
            effects: Vec::new(),
        }
    }

    /// 添加效果
    pub fn with_effect(mut self, effect: GameEffect) -> Self {
        self.effects.push(effect);
        self
    }
}

/// 遊戲效果
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum GameEffect {
    /// 聲望變化
    ReputationChange { player_id: Uuid, amount: i32 },
    /// 被沉默
    Silenced { player_id: Uuid },
    /// 技能被揭露
    SkillRevealed {
        player_id: Uuid,
        character: CharacterType,
    },
    /// 政治死亡
    PoliticalDeath { player_id: Uuid },
    /// 金幣變化
    GoldChange { player_id: Uuid, amount: i32 },
    /// 結盟
    AllianceFormed { player_a: Uuid, player_b: Uuid },
    /// 背叛
    AllianceBroken { betrayer_id: Uuid, victim_id: Uuid },
    /// 等待反駁
    PendingCounter {
        defender_id: Uuid,
        attacker_id: Uuid,
        damage: i32,
    },
}

/// 遊戲結果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameResult {
    /// 獲勝選項
    pub winning_choice: Option<VoteChoice>,
    /// 各選項票數
    pub vote_counts: VoteCounts,
    /// 玩家得分
    pub player_scores: Vec<PlayerScore>,
    /// 獲勝派系
    pub winning_faction: Option<String>,
}

/// 投票計數
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteCounts {
    /// 選項 A 票數
    pub option_a: f64,
    /// 選項 B 票數
    pub option_b: f64,
    /// 選項 C 票數
    pub option_c: f64,
}

impl VoteCounts {
    /// 獲取獲勝選項
    pub fn get_winner(&self) -> Option<VoteChoice> {
        if self.option_a == 0.0 && self.option_b == 0.0 && self.option_c == 0.0 {
            None
        } else if self.option_a >= self.option_b && self.option_a >= self.option_c {
            Some(VoteChoice::A)
        } else if self.option_b >= self.option_c {
            Some(VoteChoice::B)
        } else {
            Some(VoteChoice::C)
        }
    }
}

/// 玩家得分
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerScore {
    /// 玩家 ID
    pub player_id: Uuid,
    /// 玩家名稱
    pub player_name: String,
    /// 角色
    pub character: CharacterType,
    /// 最終聲望
    pub final_reputation: i32,
    /// 最終金幣
    pub final_gold: i32,
    /// 總分
    pub total_score: i32,
    /// 是否存活
    pub is_alive: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_action_result_success() {
        let result = ActionResult::success("操作成功");
        assert!(result.success);
        assert_eq!(result.message, "操作成功");
        assert!(result.effects.is_empty());
    }

    #[test]
    fn test_action_result_with_effects() {
        let player_id = Uuid::new_v4();
        let result = ActionResult::success("質詢成功").with_effect(GameEffect::ReputationChange {
            player_id,
            amount: -15,
        });

        assert!(result.success);
        assert_eq!(result.effects.len(), 1);
    }

    #[test]
    fn test_game_action_serialization() {
        let action = GameAction::Challenge {
            attacker_id: Uuid::new_v4(),
            target_id: Uuid::new_v4(),
            damage: 15,
            was_countered: false,
        };

        let json = serde_json::to_string(&action).unwrap();
        assert!(json.contains("challenge"));
    }
}
