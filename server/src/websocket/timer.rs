//! 遊戲計時器管理
//!
//! 管理遊戲中的各種計時器：
//! - 階段自動推進計時器（Phase Timer）
//! - 反駁超時計時器（Counter Timer）

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::task::JoinHandle;

use crate::domain::GamePhase;
use crate::game::GameEngine;
use crate::state::GameStore;
use crate::websocket::hub::Hub;
use crate::websocket::messages::ServerMessage;

/// 共享的計時器管理器類型
pub type SharedTimerManager = Arc<RwLock<GameTimerManager>>;

/// 遊戲計時器管理器
///
/// 管理每個房間的 phase timer 和 counter timer。
/// 使用 `JoinHandle::abort()` 來取消計時器。
pub struct GameTimerManager {
    /// 房間代碼 -> 階段計時器 JoinHandle
    phase_timers: HashMap<String, JoinHandle<()>>,
    /// 房間代碼 -> 反駁超時計時器 JoinHandle
    counter_timers: HashMap<String, JoinHandle<()>>,
}

impl GameTimerManager {
    /// 建立新的計時器管理器
    pub fn new() -> Self {
        Self {
            phase_timers: HashMap::new(),
            counter_timers: HashMap::new(),
        }
    }

    /// 建立共享的計時器管理器
    pub fn shared() -> SharedTimerManager {
        Arc::new(RwLock::new(Self::new()))
    }

    /// 啟動階段自動推進計時器
    ///
    /// 在 `duration_secs` 秒後自動調用 `game.advance_phase()`
    /// 並廣播 PhaseChanged 給房間所有玩家。
    /// 如果新階段不是 Finished，會自動啟動下一個 phase timer。
    pub fn start_phase_timer(
        &mut self,
        room_code: &str,
        duration_secs: u32,
        hub: Arc<Hub>,
        games: GameStore,
        timers: SharedTimerManager,
    ) {
        // 取消舊的 phase timer
        self.cancel_phase_timer(room_code);

        if duration_secs == 0 {
            return;
        }

        let room_code_owned = room_code.to_string();

        tracing::info!(
            room_code = %room_code,
            duration_secs = duration_secs,
            "啟動 phase timer"
        );

        let handle = tokio::spawn(async move {
            tokio::time::sleep(tokio::time::Duration::from_secs(duration_secs as u64)).await;

            tracing::info!(room_code = %room_code_owned, "Phase timer 觸發");

            // 推進階段
            let phase_info = {
                let mut games_guard = games.write().await;
                if let Some(game) = games_guard.get_mut(&room_code_owned) {
                    let new_phase = game.advance_phase();
                    if new_phase == GamePhase::Finished {
                        Some((new_phase, 0u32, game.state.current_round as u32))
                    } else {
                        let duration = get_phase_duration(game, new_phase);
                        Some((new_phase, duration, game.state.current_round as u32))
                    }
                } else {
                    None
                }
            };

            if let Some((new_phase, next_duration, round)) = phase_info {
                tracing::info!(
                    room_code = %room_code_owned,
                    new_phase = %new_phase,
                    round = round,
                    "階段已推進"
                );

                // 廣播階段變更
                hub.broadcast_to_room(
                    &room_code_owned,
                    ServerMessage::PhaseChanged {
                        phase: new_phase,
                        duration_secs: next_duration,
                        round,
                    },
                )
                .await;

                // 如果遊戲未結束，啟動下一個 phase timer
                if new_phase != GamePhase::Finished && next_duration > 0 {
                    let mut timer_mgr = timers.write().await;
                    timer_mgr.start_phase_timer(
                        &room_code_owned,
                        next_duration,
                        hub,
                        games,
                        timers.clone(),
                    );
                }
            }
        });

        self.phase_timers.insert(room_code.to_string(), handle);
    }

    /// 啟動反駁超時計時器
    ///
    /// 在 `timeout_secs` 秒後自動調用 `game.resolve_challenge()`
    /// 並廣播結果給房間所有玩家。
    pub fn start_counter_timer(
        &mut self,
        room_code: &str,
        timeout_secs: u32,
        hub: Arc<Hub>,
        games: GameStore,
    ) {
        // 取消舊的 counter timer
        self.cancel_counter_timer(room_code);

        if timeout_secs == 0 {
            return;
        }

        let room_code_owned = room_code.to_string();

        tracing::info!(
            room_code = %room_code,
            timeout_secs = timeout_secs,
            "啟動 counter timer"
        );

        let handle = tokio::spawn(async move {
            tokio::time::sleep(tokio::time::Duration::from_secs(timeout_secs as u64)).await;

            tracing::info!(room_code = %room_code_owned, "Counter timer 觸發（反駁超時）");

            // 解決超時質詢
            let resolve_result = {
                let mut games_guard = games.write().await;
                if let Some(game) = games_guard.get_mut(&room_code_owned) {
                    game.resolve_challenge().ok()
                } else {
                    None
                }
            };

            if let Some(action_result) = resolve_result {
                // 從 games 中讀取玩家資訊來廣播效果
                broadcast_timer_effects(&hub, &room_code_owned, &games, &action_result.effects)
                    .await;

                // 廣播系統訊息
                hub.broadcast_to_room(
                    &room_code_owned,
                    ServerMessage::info(format!("反駁超時！{}", action_result.message)),
                )
                .await;
            }
        });

        self.counter_timers.insert(room_code.to_string(), handle);
    }

    /// 取消房間的 phase timer
    pub fn cancel_phase_timer(&mut self, room_code: &str) {
        if let Some(handle) = self.phase_timers.remove(room_code) {
            handle.abort();
            tracing::debug!(room_code = %room_code, "Phase timer 已取消");
        }
    }

    /// 取消房間的 counter timer
    pub fn cancel_counter_timer(&mut self, room_code: &str) {
        if let Some(handle) = self.counter_timers.remove(room_code) {
            handle.abort();
            tracing::debug!(room_code = %room_code, "Counter timer 已取消");
        }
    }

    /// 取消房間的所有計時器
    pub fn cancel_all_timers(&mut self, room_code: &str) {
        self.cancel_phase_timer(room_code);
        self.cancel_counter_timer(room_code);
        tracing::debug!(room_code = %room_code, "所有計時器已取消");
    }
}

impl Default for GameTimerManager {
    fn default() -> Self {
        Self::new()
    }
}

/// 取得指定階段的持續時間（回合制：僅投票/結果階段有計時）
fn get_phase_duration(game: &GameEngine, phase: GamePhase) -> u32 {
    match phase {
        GamePhase::Waiting => 0,
        GamePhase::PlayerTurn => 0, // 回合制不計時
        GamePhase::Voting => game.config.voting_duration_secs,
        GamePhase::Result => game.config.result_duration_secs,
        GamePhase::Finished => 0,
    }
}

/// 廣播計時器觸發的遊戲效果
///
/// 從 games store 中讀取玩家資訊來生成完整的廣播訊息。
async fn broadcast_timer_effects(
    hub: &Arc<Hub>,
    room_code: &str,
    games: &GameStore,
    effects: &[crate::game::GameEffect],
) {
    // 讀取遊戲狀態以取得玩家資訊
    let games_guard = games.read().await;
    let game = match games_guard.get(room_code) {
        Some(g) => g,
        None => return,
    };

    for effect in effects {
        match effect {
            crate::game::GameEffect::ReputationChange { player_id, amount } => {
                let (player_name, new_reputation) = game
                    .state
                    .get_player(*player_id)
                    .map(|p| (p.name.clone(), p.reputation))
                    .unwrap_or_else(|| ("未知玩家".to_string(), 0));

                let _ = player_name; // 用於未來擴展

                hub.broadcast_to_room(
                    room_code,
                    ServerMessage::ReputationChanged {
                        player_id: *player_id,
                        new_reputation,
                        change: *amount,
                        reason: "質詢傷害結算".to_string(),
                    },
                )
                .await;
            }
            crate::game::GameEffect::PoliticalDeath { player_id } => {
                let player_name = game
                    .state
                    .get_player(*player_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string());

                hub.broadcast_to_room(
                    room_code,
                    ServerMessage::PlayerPoliticalDeath {
                        player_id: *player_id,
                        player_name,
                    },
                )
                .await;
            }
            _ => {}
        }
    }
}
