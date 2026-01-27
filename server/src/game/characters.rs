//! 角色技能系統
//!
//! 為每個角色提供技能計算邏輯

use uuid::Uuid;

use super::state::GameState;
use crate::domain::CharacterType;
use crate::error::AppError;

/// 遊戲錯誤
#[derive(Debug, Clone)]
pub enum GameError {
    /// 玩家不存在
    PlayerNotFound,
    /// 目標不存在
    TargetNotFound,
    /// 金幣不足
    InsufficientGold,
    /// 技能已使用
    SkillAlreadyUsed,
    /// 玩家被沉默
    PlayerSilenced,
    /// 玩家已政治死亡
    PoliticallyDead,
    /// 無效操作
    InvalidAction(String),
}

impl From<GameError> for AppError {
    fn from(err: GameError) -> Self {
        match err {
            GameError::PlayerNotFound => AppError::NotFound("玩家不存在".to_string()),
            GameError::TargetNotFound => AppError::NotFound("目標不存在".to_string()),
            GameError::InsufficientGold => AppError::BadRequest("金幣不足".to_string()),
            GameError::SkillAlreadyUsed => AppError::BadRequest("技能已在本回合使用".to_string()),
            GameError::PlayerSilenced => AppError::BadRequest("您已被沉默，無法行動".to_string()),
            GameError::PoliticallyDead => AppError::BadRequest("您已政治死亡".to_string()),
            GameError::InvalidAction(msg) => AppError::BadRequest(msg),
        }
    }
}

/// 角色技能處理器
///
/// 提供技能計算的靜態方法，實際執行在 GameEngine 中
pub struct CharacterSkills;

impl CharacterSkills {
    // ==================== Thomas（工人湯瑪斯）技能 ====================

    /// 團結：計算防禦加成
    ///
    /// 每有一個盟友，防禦 +10
    ///
    /// # Arguments
    /// * `state` - 遊戲狀態
    /// * `player_id` - 玩家 ID
    ///
    /// # Returns
    /// 防禦加成值
    pub fn calculate_defense_bonus(state: &GameState, player_id: Uuid) -> i32 {
        let player = match state.get_player(player_id) {
            Some(p) => p,
            None => return 0,
        };

        // 只有 Thomas 有團結技能
        if player.character != CharacterType::Thomas {
            return 0;
        }

        // 計算存活的盟友數量
        let allies = state.get_allies(player_id);
        let alive_allies = allies
            .iter()
            .filter(|&ally_id| {
                state
                    .get_player(*ally_id)
                    .map(|p| !p.is_politically_dead)
                    .unwrap_or(false)
            })
            .count();

        // 每個盟友 +10 防禦
        (alive_allies as i32) * 10
    }

    /// 計算 Thomas 受到的實際傷害（考慮團結技能）
    pub fn calculate_thomas_damage(state: &GameState, player_id: Uuid, base_damage: i32) -> i32 {
        let defense_bonus = Self::calculate_defense_bonus(state, player_id);
        (base_damage - defense_bonus).max(0)
    }

    // ==================== Richard（工廠主理查）技能 ====================

    /// 取得收買費用
    pub fn get_bribe_cost() -> i32 {
        30
    }

    // ==================== George（盧德派喬治）技能 ====================

    /// 怒火：計算傷害
    ///
    /// 攻擊傷害翻倍，但自己也扣 10 聲望
    ///
    /// # Arguments
    /// * `base_damage` - 基礎傷害
    ///
    /// # Returns
    /// (對敵傷害, 自傷)
    pub fn calculate_rage_damage(base_damage: i32) -> (i32, i32) {
        let enemy_damage = base_damage * 2;
        let self_damage = 10;
        (enemy_damage, self_damage)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::game::state::PlayerState;

    fn create_test_game() -> GameState {
        let players = vec![
            PlayerState::new(Uuid::new_v4(), "Thomas".to_string(), CharacterType::Thomas),
            PlayerState::new(
                Uuid::new_v4(),
                "Richard".to_string(),
                CharacterType::Richard,
            ),
            PlayerState::new(Uuid::new_v4(), "Edward".to_string(), CharacterType::Edward),
            PlayerState::new(Uuid::new_v4(), "George".to_string(), CharacterType::George),
        ];
        GameState::new("TEST123".to_string(), players)
    }

    fn find_player_by_character(state: &GameState, character: CharacterType) -> Uuid {
        state
            .players
            .values()
            .find(|p| p.character == character)
            .unwrap()
            .id
    }

    #[test]
    fn test_thomas_defense_bonus() {
        let mut state = create_test_game();
        let thomas_id = find_player_by_character(&state, CharacterType::Thomas);
        let richard_id = find_player_by_character(&state, CharacterType::Richard);

        // No allies -> no bonus
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, thomas_id),
            0
        );

        // Add one ally
        state.form_alliance(thomas_id, richard_id);
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, thomas_id),
            10
        );

        // Add another ally
        let edward_id = find_player_by_character(&state, CharacterType::Edward);
        state.form_alliance(thomas_id, edward_id);
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, thomas_id),
            20
        );
    }

    #[test]
    fn test_thomas_damage_reduction() {
        let mut state = create_test_game();
        let thomas_id = find_player_by_character(&state, CharacterType::Thomas);
        let richard_id = find_player_by_character(&state, CharacterType::Richard);

        // No allies -> full damage
        assert_eq!(
            CharacterSkills::calculate_thomas_damage(&state, thomas_id, 15),
            15
        );

        // One ally -> 15 - 10 = 5 damage
        state.form_alliance(thomas_id, richard_id);
        assert_eq!(
            CharacterSkills::calculate_thomas_damage(&state, thomas_id, 15),
            5
        );

        // Damage cannot go below 0
        let edward_id = find_player_by_character(&state, CharacterType::Edward);
        state.form_alliance(thomas_id, edward_id);
        assert_eq!(
            CharacterSkills::calculate_thomas_damage(&state, thomas_id, 15),
            0
        );
    }

    #[test]
    fn test_calculate_rage_damage() {
        let (enemy, self_dmg) = CharacterSkills::calculate_rage_damage(15);
        assert_eq!(enemy, 30);
        assert_eq!(self_dmg, 10);

        let (enemy2, self_dmg2) = CharacterSkills::calculate_rage_damage(10);
        assert_eq!(enemy2, 20);
        assert_eq!(self_dmg2, 10);
    }

    #[test]
    fn test_bribe_cost() {
        assert_eq!(CharacterSkills::get_bribe_cost(), 30);
    }

    #[test]
    fn test_non_thomas_no_bonus() {
        let state = create_test_game();
        let richard_id = find_player_by_character(&state, CharacterType::Richard);

        // Richard doesn't have the unity skill
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, richard_id),
            0
        );
    }

    #[test]
    fn test_dead_ally_no_bonus() {
        let mut state = create_test_game();
        let thomas_id = find_player_by_character(&state, CharacterType::Thomas);
        let richard_id = find_player_by_character(&state, CharacterType::Richard);

        // Form alliance
        state.form_alliance(thomas_id, richard_id);
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, thomas_id),
            10
        );

        // Kill Richard
        if let Some(richard) = state.get_player_mut(richard_id) {
            richard.take_damage(100);
        }

        // Dead ally gives no bonus
        assert_eq!(
            CharacterSkills::calculate_defense_bonus(&state, thomas_id),
            0
        );
    }
}
