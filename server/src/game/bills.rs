//! 議案系統
//!
//! 定義議案相關的資料結構和邏輯

use rand::seq::SliceRandom;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use crate::domain::game::VoteChoice;
use crate::domain::player::CharacterType;

/// 議案
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bill {
    /// 議案 ID
    pub id: String,
    /// 議案名稱
    pub name: String,
    /// 議案描述
    pub description: String,
    /// 投票結果影響
    pub effects: BillEffects,
}

/// 議案投票結果的影響
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BillEffects {
    /// 通過時的聲望變化（角色類型 -> 變化量）
    pub passed_reputation_changes: HashMap<CharacterType, i32>,
    /// 否決時的聲望變化（角色類型 -> 變化量）
    pub rejected_reputation_changes: HashMap<CharacterType, i32>,
    /// 特殊效果描述
    pub special_effects: Vec<String>,
}

/// 議案系統
#[derive(Debug)]
pub struct BillSystem {
    /// 所有可用議案
    available_bills: Vec<Bill>,
    /// 當前回合議案
    current_bill: Option<Bill>,
}

impl BillSystem {
    /// 創建新的議案系統
    pub fn new() -> Self {
        Self {
            available_bills: Self::create_default_bills(),
            current_bill: None,
        }
    }

    /// 創建預設議案列表
    fn create_default_bills() -> Vec<Bill> {
        vec![
            Bill {
                id: "factory_act".to_string(),
                name: "《工廠法案》".to_string(),
                description: "限制工廠工時，改善勞工待遇。".to_string(),
                effects: BillEffects {
                    passed_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Thomas, 10); // 工人聲望+10
                        changes.insert(CharacterType::Richard, -10); // 工廠主聲望-10
                        changes
                    },
                    rejected_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Thomas, -5); // 工人聲望-5
                        changes.insert(CharacterType::Richard, 5); // 工廠主聲望+5
                        changes
                    },
                    special_effects: vec!["工人獲得額外抽牌機會".to_string()],
                },
            },
            Bill {
                id: "press_censorship_act".to_string(),
                name: "《新聞審查法》".to_string(),
                description: "限制新聞自由，控制輿論傳播。".to_string(),
                effects: BillEffects {
                    passed_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Edward, -15); // 記者聲望-15
                        changes.insert(CharacterType::Thomas, 5); // 其他人+5
                        changes.insert(CharacterType::Richard, 5);
                        changes.insert(CharacterType::George, 5);
                        changes
                    },
                    rejected_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Edward, 8); // 記者聲望+8
                        changes.insert(CharacterType::Thomas, -2); // 其他人-2
                        changes.insert(CharacterType::Richard, -2);
                        changes.insert(CharacterType::George, -2);
                        changes
                    },
                    special_effects: vec!["記者技能效果減弱".to_string()],
                },
            },
            Bill {
                id: "corn_law_repeal".to_string(),
                name: "《穀物法廢除》".to_string(),
                description: "廢除穀物進口關稅，降低糧食價格。".to_string(),
                effects: BillEffects {
                    passed_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Richard, 10); // 工廠主聲望+10
                        changes.insert(CharacterType::Thomas, 5); // 工人聲望+5
                        changes
                    },
                    rejected_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::Richard, -5); // 工廠主聲望-5
                        changes.insert(CharacterType::Thomas, -3); // 工人聲望-3
                        changes
                    },
                    special_effects: vec!["所有玩家金幣+5".to_string()],
                },
            },
            Bill {
                id: "association_freedom_act".to_string(),
                name: "《結社自由法》".to_string(),
                description: "允許工人組織工會和政治團體。".to_string(),
                effects: BillEffects {
                    passed_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::George, 15); // 盧德派聲望+15
                        changes.insert(CharacterType::Richard, -10); // 工廠主聲望-10
                        changes
                    },
                    rejected_reputation_changes: {
                        let mut changes = HashMap::new();
                        changes.insert(CharacterType::George, -8); // 盧德派聲望-8
                        changes.insert(CharacterType::Richard, 5); // 工廠主聲望+5
                        changes
                    },
                    special_effects: vec!["盧德派技能效果增強".to_string()],
                },
            },
            Bill {
                id: "electoral_reform_act".to_string(),
                name: "《選舉改革法》".to_string(),
                description: "擴大選舉權，改革議會選舉制度。".to_string(),
                effects: BillEffects {
                    passed_reputation_changes: {
                        let mut changes = HashMap::new();
                        // 所有人+5，但最高聲望者-10
                        changes.insert(CharacterType::Thomas, 5);
                        changes.insert(CharacterType::Richard, 5);
                        changes.insert(CharacterType::Edward, 5);
                        changes.insert(CharacterType::George, 5);
                        changes
                    },
                    rejected_reputation_changes: {
                        let mut changes = HashMap::new();
                        // 所有人-3
                        changes.insert(CharacterType::Thomas, -3);
                        changes.insert(CharacterType::Richard, -3);
                        changes.insert(CharacterType::Edward, -3);
                        changes.insert(CharacterType::George, -3);
                        changes
                    },
                    special_effects: vec!["重新分配投票權重".to_string()],
                },
            },
        ]
    }

    /// 隨機選擇一個議案
    pub fn select_random_bill(&mut self, rng: &mut impl rand::Rng) -> Option<&Bill> {
        if let Some(bill) = self.available_bills.choose(rng) {
            self.current_bill = Some(bill.clone());
            self.current_bill.as_ref()
        } else {
            None
        }
    }

    /// 獲取當前議案
    pub fn get_current_bill(&self) -> Option<&Bill> {
        self.current_bill.as_ref()
    }

    /// 計算投票結果對玩家的影響
    pub fn calculate_vote_effects(
        &self,
        vote_result: VoteChoice,
        player_characters: &HashMap<Uuid, CharacterType>,
        player_reputations: &HashMap<Uuid, i32>,
    ) -> VoteEffectResult {
        let current_bill = match &self.current_bill {
            Some(bill) => bill,
            None => return VoteEffectResult::default(),
        };

        let mut reputation_changes = HashMap::new();
        let mut special_effects = Vec::new();

        // 決定議案是通過還是否決
        let bill_passed = matches!(vote_result, VoteChoice::A); // 假設 A 選項是支持，B/C 是反對

        let effects_map = if bill_passed {
            &current_bill.effects.passed_reputation_changes
        } else {
            &current_bill.effects.rejected_reputation_changes
        };

        // 應用聲望變化
        for (player_id, character) in player_characters {
            if let Some(&change) = effects_map.get(character) {
                reputation_changes.insert(*player_id, change);
            }
        }

        // 處理選舉改革法的特殊效果（最高聲望者額外-10）
        if current_bill.id == "electoral_reform_act" && bill_passed {
            if let Some((highest_player, _)) = player_reputations
                .iter()
                .max_by_key(|(_, &reputation)| reputation)
            {
                let current_change = reputation_changes.get(highest_player).unwrap_or(&0);
                reputation_changes.insert(*highest_player, current_change - 10);
            }
        }

        // 添加特殊效果
        if bill_passed {
            special_effects.extend(current_bill.effects.special_effects.clone());
        }

        VoteEffectResult {
            reputation_changes,
            special_effects,
            bill_name: current_bill.name.clone(),
            bill_passed,
        }
    }

    /// 重置當前議案（準備下一回合）
    pub fn reset_current_bill(&mut self) {
        self.current_bill = None;
    }
}

/// 投票效果結果
#[derive(Debug, Clone, Default)]
pub struct VoteEffectResult {
    /// 聲望變化（玩家 ID -> 變化量）
    pub reputation_changes: HashMap<Uuid, i32>,
    /// 特殊效果描述
    pub special_effects: Vec<String>,
    /// 議案名稱
    pub bill_name: String,
    /// 議案是否通過
    pub bill_passed: bool,
}

impl Default for BillSystem {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::thread_rng;

    #[test]
    fn test_bill_creation() {
        let system = BillSystem::new();
        assert_eq!(system.available_bills.len(), 5);
        assert!(system.current_bill.is_none());
    }

    #[test]
    fn test_random_bill_selection() {
        let mut system = BillSystem::new();
        let mut rng = thread_rng();

        let bill = system.select_random_bill(&mut rng);
        assert!(bill.is_some());
        assert!(system.current_bill.is_some());
    }

    #[test]
    fn test_factory_act_effects() {
        let system = BillSystem::new();
        let factory_act = system
            .available_bills
            .iter()
            .find(|b| b.id == "factory_act")
            .unwrap();

        assert_eq!(
            factory_act
                .effects
                .passed_reputation_changes
                .get(&CharacterType::Thomas),
            Some(&10)
        );
        assert_eq!(
            factory_act
                .effects
                .passed_reputation_changes
                .get(&CharacterType::Richard),
            Some(&-10)
        );
    }

    #[test]
    fn test_vote_effects_calculation() {
        let mut system = BillSystem::new();
        let mut rng = thread_rng();

        // 選擇工廠法案
        system.current_bill = Some(
            system
                .available_bills
                .iter()
                .find(|b| b.id == "factory_act")
                .unwrap()
                .clone(),
        );

        let mut player_characters = HashMap::new();
        let mut player_reputations = HashMap::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();

        player_characters.insert(player1, CharacterType::Thomas);
        player_characters.insert(player2, CharacterType::Richard);
        player_reputations.insert(player1, 50);
        player_reputations.insert(player2, 60);

        let result = system.calculate_vote_effects(
            VoteChoice::A, // 支持議案
            &player_characters,
            &player_reputations,
        );

        assert_eq!(result.reputation_changes.get(&player1), Some(&10));
        assert_eq!(result.reputation_changes.get(&player2), Some(&-10));
        assert!(result.bill_passed);
    }
}
