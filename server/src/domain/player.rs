//! 玩家領域模型
//!
//! 定義遊戲中玩家相關的資料結構

use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 角色類型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CharacterType {
    /// 工人湯瑪斯
    Thomas,
    /// 工廠主理查
    Richard,
    /// 記者愛德華
    Edward,
    /// 盧德派喬治
    George,
}

impl CharacterType {
    /// 取得初始聲望
    pub fn initial_reputation(&self) -> i32 {
        match self {
            CharacterType::Thomas => 70,
            CharacterType::Richard => 60,
            CharacterType::Edward => 50,
            CharacterType::George => 80,
        }
    }

    /// 取得初始金幣
    pub fn initial_gold(&self) -> i32 {
        match self {
            CharacterType::Thomas => 10,
            CharacterType::Richard => 30,
            CharacterType::Edward => 20,
            CharacterType::George => 5,
        }
    }

    /// 取得技能名稱
    pub fn skill_name(&self) -> &'static str {
        match self {
            CharacterType::Thomas => "團結",
            CharacterType::Richard => "收買",
            CharacterType::Edward => "爆料",
            CharacterType::George => "怒火",
        }
    }

    /// 取得技能描述
    pub fn skill_description(&self) -> &'static str {
        match self {
            CharacterType::Thomas => "每有 1 名工人盟友，防禦 +10",
            CharacterType::Richard => "花費金幣使目標沉默 1 回合",
            CharacterType::Edward => "揭露目標的秘密任務",
            CharacterType::George => "造成雙倍傷害，但自己也扣 10 聲望",
        }
    }

    /// 取得角色名稱
    pub fn name(&self) -> &'static str {
        match self {
            CharacterType::Thomas => "工人湯瑪斯",
            CharacterType::Richard => "工廠主理查",
            CharacterType::Edward => "記者愛德華",
            CharacterType::George => "盧德派喬治",
        }
    }

    /// 取得角色 emoji
    pub fn emoji(&self) -> &'static str {
        match self {
            CharacterType::Thomas => "🔨",
            CharacterType::Richard => "💰",
            CharacterType::Edward => "📰",
            CharacterType::George => "🔥",
        }
    }

    /// 取得所有角色類型
    pub fn all() -> Vec<CharacterType> {
        vec![
            CharacterType::Thomas,
            CharacterType::Richard,
            CharacterType::Edward,
            CharacterType::George,
        ]
    }
}

impl std::fmt::Display for CharacterType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} {}", self.emoji(), self.name())
    }
}

/// 玩家
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Player {
    /// 玩家 ID
    pub id: Uuid,
    /// 使用者 ID
    pub user_id: Uuid,
    /// 房間 ID
    pub room_id: Uuid,
    /// 玩家名稱
    pub name: String,
    /// 角色類型
    pub character: Option<CharacterType>,
    /// 聲望值
    pub reputation: i32,
    /// 金幣
    pub gold: i32,
    /// 是否已準備
    pub is_ready: bool,
    /// 是否為房主
    pub is_host: bool,
}

impl Player {
    /// 建立新玩家
    pub fn new(user_id: Uuid, room_id: Uuid, name: String, is_host: bool) -> Self {
        Self {
            id: Uuid::new_v4(),
            user_id,
            room_id,
            name,
            character: None,
            reputation: 50, // 預設值，選角後會更新
            gold: 0,
            is_ready: false,
            is_host,
        }
    }

    /// 選擇角色
    pub fn select_character(&mut self, character: CharacterType) {
        self.character = Some(character);
        self.reputation = character.initial_reputation();
        self.gold = character.initial_gold();
    }

    /// 設置準備狀態
    pub fn set_ready(&mut self, ready: bool) {
        self.is_ready = ready;
    }

    /// 檢查是否可以執行動作（聲望 > 0）
    pub fn can_act(&self) -> bool {
        self.reputation > 0
    }

    /// 受到傷害
    pub fn take_damage(&mut self, damage: i32) {
        self.reputation = (self.reputation - damage).max(0);
    }

    /// 恢復聲望
    pub fn heal(&mut self, amount: i32) {
        self.reputation = (self.reputation + amount).min(100);
    }

    /// 消耗金幣
    pub fn spend_gold(&mut self, amount: i32) -> bool {
        if self.gold >= amount {
            self.gold -= amount;
            true
        } else {
            false
        }
    }

    /// 獲得金幣
    pub fn gain_gold(&mut self, amount: i32) {
        self.gold += amount;
    }

    /// 計算投票權重
    pub fn vote_weight(&self) -> f64 {
        if self.reputation <= 0 {
            0.0
        } else if self.reputation > 80 {
            1.5
        } else if self.reputation >= 50 {
            1.0
        } else if self.reputation >= 30 {
            0.7
        } else {
            0.5
        }
    }

    /// 是否已政治死亡
    pub fn is_politically_dead(&self) -> bool {
        self.reputation <= 0
    }
}

/// 玩家回應（公開資訊）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerResponse {
    /// 玩家 ID
    pub id: Uuid,
    /// 玩家名稱
    pub name: String,
    /// 角色類型
    pub character: Option<CharacterType>,
    /// 聲望值
    pub reputation: i32,
    /// 金幣
    pub gold: i32,
    /// 是否已準備
    pub is_ready: bool,
    /// 是否為房主
    pub is_host: bool,
}

impl From<Player> for PlayerResponse {
    fn from(player: Player) -> Self {
        Self {
            id: player.id,
            name: player.name,
            character: player.character,
            reputation: player.reputation,
            gold: player.gold,
            is_ready: player.is_ready,
            is_host: player.is_host,
        }
    }
}

impl From<&Player> for PlayerResponse {
    fn from(player: &Player) -> Self {
        Self {
            id: player.id,
            name: player.name.clone(),
            character: player.character,
            reputation: player.reputation,
            gold: player.gold,
            is_ready: player.is_ready,
            is_host: player.is_host,
        }
    }
}

/// 選擇角色請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SelectCharacterRequest {
    /// 角色類型
    pub character: CharacterType,
}

/// 玩家動作請求
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerActionRequest {
    /// 動作類型
    pub action_type: String,
    /// 目標玩家 ID（可選）
    pub target_id: Option<Uuid>,
    /// 額外資料
    #[serde(default)]
    pub data: serde_json::Value,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_character_stats() {
        assert_eq!(CharacterType::Thomas.initial_reputation(), 70);
        assert_eq!(CharacterType::Richard.initial_gold(), 30);
        assert_eq!(CharacterType::Edward.skill_name(), "爆料");
        assert_eq!(CharacterType::George.name(), "盧德派喬治");
    }

    #[test]
    fn test_player_character_selection() {
        let mut player = Player::new(
            Uuid::new_v4(),
            Uuid::new_v4(),
            "TestPlayer".to_string(),
            false,
        );
        assert!(player.character.is_none());
        assert_eq!(player.reputation, 50);

        player.select_character(CharacterType::Thomas);
        assert_eq!(player.character, Some(CharacterType::Thomas));
        assert_eq!(player.reputation, 70);
        assert_eq!(player.gold, 10);
    }

    #[test]
    fn test_player_damage() {
        let mut player = Player::new(
            Uuid::new_v4(),
            Uuid::new_v4(),
            "TestPlayer".to_string(),
            false,
        );
        player.reputation = 50;

        player.take_damage(20);
        assert_eq!(player.reputation, 30);

        player.take_damage(100);
        assert_eq!(player.reputation, 0);
        assert!(player.is_politically_dead());
    }

    #[test]
    fn test_vote_weight() {
        let mut player = Player::new(
            Uuid::new_v4(),
            Uuid::new_v4(),
            "TestPlayer".to_string(),
            false,
        );

        player.reputation = 90;
        assert_eq!(player.vote_weight(), 1.5);

        player.reputation = 50;
        assert_eq!(player.vote_weight(), 1.0);

        player.reputation = 30;
        assert_eq!(player.vote_weight(), 0.7);

        player.reputation = 20;
        assert_eq!(player.vote_weight(), 0.5);

        player.reputation = 0;
        assert_eq!(player.vote_weight(), 0.0);
    }
}
