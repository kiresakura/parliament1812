//! 同盟系統
//!
//! 處理玩家之間的同盟關係，包括結盟、背叛等機制

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

/// 同盟狀態
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AllianceState {
    /// 提議中
    Proposed,
    /// 已建立
    Established,
    /// 已背叛
    Betrayed,
}

/// 同盟關係
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Alliance {
    /// 同盟 ID
    pub id: Uuid,
    /// 成員列表
    pub members: Vec<Uuid>,
    /// 同盟狀態
    pub state: AllianceState,
    /// 建立時間
    pub created_at: i64,
    /// 背叛者（如果被背叛）
    pub betrayer: Option<Uuid>,
    /// 背叛時間
    pub betrayed_at: Option<i64>,
}

impl Alliance {
    /// 創建新同盟提議
    pub fn new_proposal(proposer: Uuid, target: Uuid) -> Self {
        Self {
            id: Uuid::new_v4(),
            members: vec![proposer, target],
            state: AllianceState::Proposed,
            created_at: chrono::Utc::now().timestamp_millis(),
            betrayer: None,
            betrayed_at: None,
        }
    }

    /// 接受同盟提議
    pub fn accept(&mut self) {
        if self.state == AllianceState::Proposed {
            self.state = AllianceState::Established;
        }
    }

    /// 背叛同盟
    pub fn betray(&mut self, betrayer: Uuid) {
        if self.state == AllianceState::Established && self.members.contains(&betrayer) {
            self.state = AllianceState::Betrayed;
            self.betrayer = Some(betrayer);
            self.betrayed_at = Some(chrono::Utc::now().timestamp_millis());
        }
    }

    /// 檢查是否包含指定玩家
    pub fn contains_player(&self, player_id: Uuid) -> bool {
        self.members.contains(&player_id)
    }

    /// 獲取另一個成員（假設只有兩個成員）
    pub fn get_partner(&self, player_id: Uuid) -> Option<Uuid> {
        if self.members.len() != 2 {
            return None;
        }
        
        self.members.iter()
            .find(|&&id| id != player_id)
            .copied()
    }

    /// 檢查同盟是否有效（已建立且未被背叛）
    pub fn is_active(&self) -> bool {
        self.state == AllianceState::Established
    }
}

/// 同盟管理器
#[derive(Debug, Default)]
pub struct AllianceManager {
    /// 所有同盟
    alliances: HashMap<Uuid, Alliance>,
    /// 玩家到同盟的映射
    player_alliances: HashMap<Uuid, Vec<Uuid>>,
    /// 待處理的同盟提議
    pending_proposals: HashMap<Uuid, Vec<Uuid>>, // target -> [proposer_ids]
}

impl AllianceManager {
    /// 創建新的同盟管理器
    pub fn new() -> Self {
        Self::default()
    }

    /// 提議同盟
    ///
    /// 返回同盟 ID（如果創建成功）
    pub fn propose_alliance(&mut self, proposer: Uuid, target: Uuid) -> Result<Uuid, AllianceError> {
        // 檢查是否已有同盟關係
        if self.are_allied(proposer, target) {
            return Err(AllianceError::AlreadyAllied);
        }

        // 檢查是否已有待處理的提議
        if let Some(proposals) = self.pending_proposals.get(&target) {
            if proposals.contains(&proposer) {
                return Err(AllianceError::ProposalAlreadyExists);
            }
        }

        // 檢查雙向提議（互相提議）
        if let Some(proposals) = self.pending_proposals.get(&proposer) {
            if proposals.contains(&target) {
                // 雙方都提議了，直接建立同盟
                return self.establish_mutual_alliance(proposer, target);
            }
        }

        // 創建新的同盟提議
        let alliance = Alliance::new_proposal(proposer, target);
        let alliance_id = alliance.id;

        self.alliances.insert(alliance_id, alliance);
        self.pending_proposals.entry(target).or_insert_with(Vec::new).push(proposer);

        Ok(alliance_id)
    }

    /// 接受同盟提議
    pub fn accept_proposal(&mut self, target: Uuid, proposer: Uuid) -> Result<Uuid, AllianceError> {
        // 移除待處理提議
        if let Some(proposals) = self.pending_proposals.get_mut(&target) {
            if let Some(pos) = proposals.iter().position(|&id| id == proposer) {
                proposals.remove(pos);
                if proposals.is_empty() {
                    self.pending_proposals.remove(&target);
                }
            }
        }

        // 找到對應的同盟
        let alliance_id = self.alliances.iter()
            .find(|(_, alliance)| {
                alliance.state == AllianceState::Proposed &&
                alliance.members.contains(&proposer) &&
                alliance.members.contains(&target)
            })
            .map(|(id, _)| *id)
            .ok_or(AllianceError::ProposalNotFound)?;

        // 接受同盟
        if let Some(alliance) = self.alliances.get_mut(&alliance_id) {
            alliance.accept();

            // 更新玩家映射
            for &member in &alliance.members {
                self.player_alliances.entry(member).or_insert_with(Vec::new).push(alliance_id);
            }

            return Ok(alliance_id);
        }

        Err(AllianceError::ProposalNotFound)
    }

    /// 拒絕同盟提議
    pub fn reject_proposal(&mut self, target: Uuid, proposer: Uuid) -> Result<(), AllianceError> {
        // 移除待處理提議
        if let Some(proposals) = self.pending_proposals.get_mut(&target) {
            if let Some(pos) = proposals.iter().position(|&id| id == proposer) {
                proposals.remove(pos);
                if proposals.is_empty() {
                    self.pending_proposals.remove(&target);
                }
            }
        }

        // 移除同盟記錄
        let alliance_id = self.alliances.iter()
            .find(|(_, alliance)| {
                alliance.state == AllianceState::Proposed &&
                alliance.members.contains(&proposer) &&
                alliance.members.contains(&target)
            })
            .map(|(id, _)| *id);

        if let Some(id) = alliance_id {
            self.alliances.remove(&id);
        }

        Ok(())
    }

    /// 背叛同盟
    pub fn betray_alliance(&mut self, betrayer: Uuid, target: Uuid) -> Result<Uuid, AllianceError> {
        let alliance_id = self.find_active_alliance(betrayer, target)
            .ok_or(AllianceError::NoActiveAlliance)?;

        if let Some(alliance) = self.alliances.get_mut(&alliance_id) {
            alliance.betray(betrayer);

            // 移除玩家映射
            for &member in &alliance.members {
                if let Some(alliances) = self.player_alliances.get_mut(&member) {
                    alliances.retain(|&id| id != alliance_id);
                    if alliances.is_empty() {
                        self.player_alliances.remove(&member);
                    }
                }
            }

            return Ok(alliance_id);
        }

        Err(AllianceError::AllianceNotFound)
    }

    /// 檢查兩個玩家是否有有效同盟
    pub fn are_allied(&self, player1: Uuid, player2: Uuid) -> bool {
        self.find_active_alliance(player1, player2).is_some()
    }

    /// 計算盟友間傷害減免
    pub fn calculate_damage_reduction(&self, attacker: Uuid, target: Uuid, damage: i32) -> i32 {
        if self.are_allied(attacker, target) {
            // 盟友間傷害減少 50%
            damage / 2
        } else {
            damage
        }
    }

    /// 獲取玩家的所有有效同盟
    pub fn get_player_alliances(&self, player_id: Uuid) -> Vec<&Alliance> {
        if let Some(alliance_ids) = self.player_alliances.get(&player_id) {
            alliance_ids.iter()
                .filter_map(|id| self.alliances.get(id))
                .filter(|alliance| alliance.is_active())
                .collect()
        } else {
            Vec::new()
        }
    }

    /// 獲取玩家的待處理提議
    pub fn get_pending_proposals_for(&self, player_id: Uuid) -> Vec<Uuid> {
        self.pending_proposals.get(&player_id).cloned().unwrap_or_default()
    }

    /// 獲取所有有效同盟
    pub fn get_all_active_alliances(&self) -> Vec<&Alliance> {
        self.alliances.values()
            .filter(|alliance| alliance.is_active())
            .collect()
    }

    /// 清理過期提議（超過 5 分鐘自動過期）
    pub fn cleanup_expired_proposals(&mut self) {
        let now = chrono::Utc::now().timestamp_millis();
        let expired_alliances: Vec<Uuid> = self.alliances.iter()
            .filter(|(_, alliance)| {
                alliance.state == AllianceState::Proposed &&
                (now - alliance.created_at) > 300_000 // 5 分鐘
            })
            .map(|(id, _)| *id)
            .collect();

        for alliance_id in expired_alliances {
            if let Some(alliance) = self.alliances.remove(&alliance_id) {
                // 清理待處理提議
                for member in &alliance.members {
                    if let Some(proposals) = self.pending_proposals.get_mut(member) {
                        proposals.retain(|&proposer| !alliance.members.contains(&proposer));
                        if proposals.is_empty() {
                            self.pending_proposals.remove(member);
                        }
                    }
                }
            }
        }
    }

    // 私有方法

    /// 尋找兩個玩家間的有效同盟
    fn find_active_alliance(&self, player1: Uuid, player2: Uuid) -> Option<Uuid> {
        if let Some(alliance_ids) = self.player_alliances.get(&player1) {
            for &alliance_id in alliance_ids {
                if let Some(alliance) = self.alliances.get(&alliance_id) {
                    if alliance.is_active() && alliance.contains_player(player2) {
                        return Some(alliance_id);
                    }
                }
            }
        }
        None
    }

    /// 建立雙向提議的同盟
    fn establish_mutual_alliance(&mut self, player1: Uuid, player2: Uuid) -> Result<Uuid, AllianceError> {
        let mut alliance = Alliance::new_proposal(player1, player2);
        alliance.accept(); // 直接建立
        let alliance_id = alliance.id;

        // 清理雙向待處理提議
        if let Some(proposals) = self.pending_proposals.get_mut(&player1) {
            proposals.retain(|&id| id != player2);
            if proposals.is_empty() {
                self.pending_proposals.remove(&player1);
            }
        }
        if let Some(proposals) = self.pending_proposals.get_mut(&player2) {
            proposals.retain(|&id| id != player1);
            if proposals.is_empty() {
                self.pending_proposals.remove(&player2);
            }
        }

        // 儲存同盟
        self.alliances.insert(alliance_id, alliance);

        // 更新玩家映射
        self.player_alliances.entry(player1).or_insert_with(Vec::new).push(alliance_id);
        self.player_alliances.entry(player2).or_insert_with(Vec::new).push(alliance_id);

        Ok(alliance_id)
    }
}

/// 同盟錯誤
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AllianceError {
    /// 已有同盟關係
    AlreadyAllied,
    /// 提議已存在
    ProposalAlreadyExists,
    /// 提議不存在
    ProposalNotFound,
    /// 沒有有效同盟
    NoActiveAlliance,
    /// 同盟不存在
    AllianceNotFound,
}

impl std::fmt::Display for AllianceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AllianceError::AlreadyAllied => write!(f, "已有同盟關係"),
            AllianceError::ProposalAlreadyExists => write!(f, "同盟提議已存在"),
            AllianceError::ProposalNotFound => write!(f, "同盟提議不存在"),
            AllianceError::NoActiveAlliance => write!(f, "沒有有效的同盟關係"),
            AllianceError::AllianceNotFound => write!(f, "同盟不存在"),
        }
    }
}

impl std::error::Error for AllianceError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_alliance_proposal() {
        let mut manager = AllianceManager::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();

        // 提議同盟
        let alliance_id = manager.propose_alliance(player1, player2).unwrap();
        assert!(!manager.are_allied(player1, player2));

        // 接受提議
        manager.accept_proposal(player2, player1).unwrap();
        assert!(manager.are_allied(player1, player2));

        // 檢查同盟狀態
        let alliance = manager.alliances.get(&alliance_id).unwrap();
        assert_eq!(alliance.state, AllianceState::Established);
    }

    #[test]
    fn test_mutual_proposal() {
        let mut manager = AllianceManager::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();

        // 雙方互相提議
        manager.propose_alliance(player1, player2).unwrap();
        let alliance_id = manager.propose_alliance(player2, player1).unwrap();

        // 應該直接建立同盟
        assert!(manager.are_allied(player1, player2));
        
        let alliance = manager.alliances.get(&alliance_id).unwrap();
        assert_eq!(alliance.state, AllianceState::Established);
    }

    #[test]
    fn test_alliance_betrayal() {
        let mut manager = AllianceManager::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();

        // 建立同盟
        let alliance_id = manager.propose_alliance(player1, player2).unwrap();
        manager.accept_proposal(player2, player1).unwrap();
        assert!(manager.are_allied(player1, player2));

        // 背叛同盟
        manager.betray_alliance(player1, player2).unwrap();
        assert!(!manager.are_allied(player1, player2));

        let alliance = manager.alliances.get(&alliance_id).unwrap();
        assert_eq!(alliance.state, AllianceState::Betrayed);
        assert_eq!(alliance.betrayer, Some(player1));
    }

    #[test]
    fn test_damage_reduction() {
        let mut manager = AllianceManager::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();
        let player3 = Uuid::new_v4();

        // 建立同盟
        manager.propose_alliance(player1, player2).unwrap();
        manager.accept_proposal(player2, player1).unwrap();

        // 盟友間傷害減半
        assert_eq!(manager.calculate_damage_reduction(player1, player2, 100), 50);
        
        // 非盟友傷害不變
        assert_eq!(manager.calculate_damage_reduction(player1, player3, 100), 100);
    }

    #[test]
    fn test_proposal_rejection() {
        let mut manager = AllianceManager::new();
        let player1 = Uuid::new_v4();
        let player2 = Uuid::new_v4();

        // 提議同盟
        let alliance_id = manager.propose_alliance(player1, player2).unwrap();
        assert!(manager.alliances.contains_key(&alliance_id));

        // 拒絕提議
        manager.reject_proposal(player2, player1).unwrap();
        assert!(!manager.alliances.contains_key(&alliance_id));
        assert!(!manager.are_allied(player1, player2));
    }
}