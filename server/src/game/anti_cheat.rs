//! 防作弊系統
//!
//! - 同一 user 30 秒內不能連續開場
//! - AI 場 ELO 權重 50%
//! - 連續 20 勝 flag 可疑
//! - 投降/斷線 = 敗

use chrono::{DateTime, Utc};
use std::collections::HashMap;
use uuid::Uuid;

/// 防作弊系統配置
const GAME_COOLDOWN_SECS: i64 = 30;
const SUSPICIOUS_WIN_STREAK: u32 = 20;

/// 防作弊檢查結果
#[derive(Debug, Clone, PartialEq)]
pub enum AntiCheatResult {
    /// 通過
    Ok,
    /// 冷卻中（距離上一場太近）
    Cooldown { remaining_secs: i64 },
    /// 可疑連勝，已 flag
    SuspiciousWinStreak { streak: u32 },
}

/// 遊戲結束原因
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GameEndReason {
    /// 正常結束
    Normal,
    /// 投降
    Surrender,
    /// 斷線
    Disconnect,
}

impl GameEndReason {
    /// 投降或斷線視為敗
    pub fn is_loss(&self) -> bool {
        matches!(self, GameEndReason::Surrender | GameEndReason::Disconnect)
    }
}

/// 是否為 AI 場（影響 ELO 權重）
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OpponentType {
    Human,
    AI,
}

impl OpponentType {
    /// AI 場 ELO 權重 50%
    pub fn elo_weight(&self) -> f64 {
        match self {
            OpponentType::Human => 1.0,
            OpponentType::AI => 0.5,
        }
    }
}

/// 防作弊追蹤器
///
/// 追蹤每個玩家的開場時間和連勝記錄。
/// 在 AppState 中以共享狀態存在。
#[derive(Debug, Default)]
pub struct AntiCheatTracker {
    /// 玩家最後一次開場時間
    last_game_start: HashMap<Uuid, DateTime<Utc>>,
    /// 玩家連勝次數
    win_streaks: HashMap<Uuid, u32>,
    /// 被 flag 的可疑玩家
    flagged_players: HashMap<Uuid, Vec<String>>,
}

impl AntiCheatTracker {
    pub fn new() -> Self {
        Self::default()
    }

    /// 檢查玩家是否可以開始新遊戲
    pub fn check_game_start(&self, user_id: Uuid) -> AntiCheatResult {
        if let Some(last_start) = self.last_game_start.get(&user_id) {
            let elapsed = (Utc::now() - *last_start).num_seconds();
            if elapsed < GAME_COOLDOWN_SECS {
                return AntiCheatResult::Cooldown {
                    remaining_secs: GAME_COOLDOWN_SECS - elapsed,
                };
            }
        }
        AntiCheatResult::Ok
    }

    /// 記錄玩家開始遊戲
    pub fn record_game_start(&mut self, user_id: Uuid) {
        self.last_game_start.insert(user_id, Utc::now());
    }

    /// 記錄遊戲結果並檢查連勝
    pub fn record_game_result(&mut self, user_id: Uuid, is_win: bool) -> AntiCheatResult {
        if is_win {
            let streak = self.win_streaks.entry(user_id).or_insert(0);
            *streak += 1;

            if *streak >= SUSPICIOUS_WIN_STREAK {
                let flags = self.flagged_players.entry(user_id).or_default();
                let msg = format!(
                    "連續 {} 勝，時間: {}",
                    streak,
                    Utc::now().format("%Y-%m-%d %H:%M:%S UTC")
                );
                flags.push(msg);

                tracing::warn!(
                    user_id = %user_id,
                    streak = *streak,
                    "可疑連勝：已 flag"
                );

                return AntiCheatResult::SuspiciousWinStreak { streak: *streak };
            }
        } else {
            // 輸了就重置連勝
            self.win_streaks.insert(user_id, 0);
        }

        AntiCheatResult::Ok
    }

    /// 取得玩家是否被 flag
    pub fn is_flagged(&self, user_id: Uuid) -> bool {
        self.flagged_players
            .get(&user_id)
            .map(|flags| !flags.is_empty())
            .unwrap_or(false)
    }

    /// 取得玩家的 flag 記錄
    pub fn get_flags(&self, user_id: Uuid) -> Option<&Vec<String>> {
        self.flagged_players.get(&user_id)
    }

    /// 取得玩家當前連勝數
    pub fn get_win_streak(&self, user_id: Uuid) -> u32 {
        self.win_streaks.get(&user_id).copied().unwrap_or(0)
    }
}

// ============================================================
// Tests
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_game_cooldown() {
        let mut tracker = AntiCheatTracker::new();
        let user_id = Uuid::new_v4();

        // 第一次開場 OK
        assert_eq!(tracker.check_game_start(user_id), AntiCheatResult::Ok);

        // 記錄開場
        tracker.record_game_start(user_id);

        // 馬上再開場應該被擋
        let result = tracker.check_game_start(user_id);
        match result {
            AntiCheatResult::Cooldown { remaining_secs } => {
                assert!(remaining_secs > 0);
                assert!(remaining_secs <= GAME_COOLDOWN_SECS);
            }
            _ => panic!("Expected cooldown, got {:?}", result),
        }
    }

    #[test]
    fn test_win_streak_flag() {
        let mut tracker = AntiCheatTracker::new();
        let user_id = Uuid::new_v4();

        // 連續贏 19 場不被 flag
        for _ in 0..19 {
            let result = tracker.record_game_result(user_id, true);
            assert_eq!(result, AntiCheatResult::Ok);
        }
        assert!(!tracker.is_flagged(user_id));

        // 第 20 場被 flag
        let result = tracker.record_game_result(user_id, true);
        match result {
            AntiCheatResult::SuspiciousWinStreak { streak } => {
                assert_eq!(streak, 20);
            }
            _ => panic!("Expected suspicious win streak"),
        }
        assert!(tracker.is_flagged(user_id));
    }

    #[test]
    fn test_loss_resets_streak() {
        let mut tracker = AntiCheatTracker::new();
        let user_id = Uuid::new_v4();

        // 連贏 10 場
        for _ in 0..10 {
            tracker.record_game_result(user_id, true);
        }
        assert_eq!(tracker.get_win_streak(user_id), 10);

        // 輸一場，重置
        tracker.record_game_result(user_id, false);
        assert_eq!(tracker.get_win_streak(user_id), 0);
    }

    #[test]
    fn test_game_end_reason() {
        assert!(GameEndReason::Surrender.is_loss());
        assert!(GameEndReason::Disconnect.is_loss());
        assert!(!GameEndReason::Normal.is_loss());
    }

    #[test]
    fn test_opponent_type_weight() {
        assert_eq!(OpponentType::Human.elo_weight(), 1.0);
        assert_eq!(OpponentType::AI.elo_weight(), 0.5);
    }

    #[test]
    fn test_different_users_independent() {
        let mut tracker = AntiCheatTracker::new();
        let user_a = Uuid::new_v4();
        let user_b = Uuid::new_v4();

        tracker.record_game_start(user_a);

        // user_b 不受 user_a 冷卻影響
        assert_eq!(tracker.check_game_start(user_b), AntiCheatResult::Ok);
    }
}
