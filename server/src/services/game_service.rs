//! 遊戲服務
//!
//! 提供遊戲進行中的業務邏輯，整合遊戲引擎與應用狀態

use uuid::Uuid;

use crate::domain::{GamePhase, VoteChoice};
use crate::error::AppError;
use crate::game::{ActionResult, GameEngine, GameResult, GameState};
use crate::AppState;

/// 遊戲狀態 Redis 快取 TTL（秒）
const GAME_STATE_TTL: u64 = 7200; // 2 小時

/// 遊戲服務
///
/// 提供遊戲進行的業務邏輯
pub struct GameService;

impl GameService {
    /// 開始遊戲
    ///
    /// 建立遊戲引擎並開始遊戲，同時啟動階段計時器
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳初始遊戲狀態
    pub async fn start_game(state: &AppState, room_code: &str) -> Result<GameState, AppError> {
        // 取得房間內的玩家
        let players = {
            let room_players = state.room_players.read().await;
            let player_ids = room_players
                .get(room_code)
                .ok_or_else(|| AppError::NotFound("房間不存在".to_string()))?
                .clone();

            let players_store = state.players.read().await;
            player_ids
                .iter()
                .filter_map(|id| players_store.get(id).cloned())
                .collect::<Vec<_>>()
        };

        if players.len() < 2 {
            return Err(AppError::BadRequest(
                "至少需要 2 名玩家才能開始遊戲".to_string(),
            ));
        }

        // 建立遊戲引擎
        let mut engine = GameEngine::new(room_code.to_string(), players);

        // 開始遊戲
        engine
            .start_game()
            .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

        let game_state = engine.state.clone();

        // 儲存遊戲引擎
        {
            let mut games = state.games.write().await;
            games.insert(room_code.to_string(), engine);
        }

        // 同步到 Redis 快取
        if let Err(e) = state
            .game_cache()
            .set_game_state(room_code, &game_state, Some(GAME_STATE_TTL))
            .await
        {
            tracing::warn!(room_code = %room_code, error = %e, "無法快取遊戲狀態到 Redis");
        }

        tracing::info!(
            room_code = %room_code,
            phase = ?game_state.phase,
            "遊戲已開始"
        );

        // 啟動階段計時器
        Self::start_phase_timer(state.clone(), room_code.to_string());

        Ok(game_state)
    }

    /// 取得遊戲狀態
    ///
    /// 優先從 Redis 快取讀取，若無則從記憶體讀取
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳當前遊戲狀態
    pub async fn get_game_state(state: &AppState, room_code: &str) -> Result<GameState, AppError> {
        // 優先從 Redis 讀取
        match state.game_cache().get_game_state(room_code).await {
            Ok(Some(cached_state)) => {
                tracing::trace!(room_code = %room_code, "從 Redis 快取取得遊戲狀態");
                return Ok(cached_state);
            }
            Ok(None) => {
                tracing::trace!(room_code = %room_code, "Redis 快取無遊戲狀態，從記憶體讀取");
            }
            Err(e) => {
                tracing::warn!(room_code = %room_code, error = %e, "Redis 讀取失敗，從記憶體讀取");
            }
        }

        // 從記憶體讀取
        let games = state.games.read().await;
        let engine = games
            .get(room_code)
            .ok_or_else(|| AppError::NotFound("遊戲不存在".to_string()))?;

        Ok(engine.state.clone())
    }

    /// 取得遊戲引擎（可變）
    async fn get_engine_mut<'a>(
        games: &'a mut tokio::sync::RwLockWriteGuard<
            '_,
            std::collections::HashMap<String, GameEngine>,
        >,
        room_code: &str,
    ) -> Result<&'a mut GameEngine, AppError> {
        games
            .get_mut(room_code)
            .ok_or_else(|| AppError::NotFound("遊戲不存在".to_string()))
    }

    /// 同步遊戲狀態到 Redis 快取
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `game_state` - 遊戲狀態
    async fn sync_to_redis(state: &AppState, room_code: &str, game_state: &GameState) {
        if let Err(e) = state
            .game_cache()
            .set_game_state(room_code, game_state, Some(GAME_STATE_TTL))
            .await
        {
            tracing::warn!(room_code = %room_code, error = %e, "無法同步遊戲狀態到 Redis");
        }
    }

    /// 處理質詢（攻擊）
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `attacker_id` - 攻擊者 ID
    /// * `target_id` - 目標 ID
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_challenge(
        state: &AppState,
        room_code: &str,
        attacker_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 檢查階段
            if engine.state.phase != GamePhase::Debate {
                return Err(AppError::BadRequest("只能在辯論階段發起質詢".to_string()));
            }

            let result = engine
                .process_challenge(attacker_id, target_id)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            attacker_id = %attacker_id,
            target_id = %target_id,
            success = result.success,
            "質詢處理完成"
        );

        Ok(result)
    }

    /// 處理反駁（防禦）
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `defender_id` - 防禦者 ID
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_counter(
        state: &AppState,
        room_code: &str,
        defender_id: Uuid,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 檢查階段
            if engine.state.phase != GamePhase::Debate {
                return Err(AppError::BadRequest("只能在辯論階段反駁".to_string()));
            }

            let result = engine
                .process_counter(defender_id)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            defender_id = %defender_id,
            success = result.success,
            "反駁處理完成"
        );

        Ok(result)
    }

    /// 處理技能使用
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_id` - 玩家 ID
    /// * `target_id` - 目標 ID（部分技能需要）
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_skill(
        state: &AppState,
        room_code: &str,
        player_id: Uuid,
        target_id: Option<Uuid>,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 檢查階段（技能可在多個階段使用）
            if engine.state.phase == GamePhase::Waiting || engine.state.phase == GamePhase::Finished
            {
                return Err(AppError::BadRequest("當前階段無法使用技能".to_string()));
            }

            let result = engine
                .process_skill(player_id, target_id)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            player_id = %player_id,
            target_id = ?target_id,
            success = result.success,
            "技能處理完成"
        );

        Ok(result)
    }

    /// 處理投票
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_id` - 玩家 ID
    /// * `choice` - 投票選項
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_vote(
        state: &AppState,
        room_code: &str,
        player_id: Uuid,
        choice: VoteChoice,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 檢查階段
            if engine.state.phase != GamePhase::Voting {
                return Err(AppError::BadRequest("只能在投票階段投票".to_string()));
            }

            let result = engine
                .process_vote(player_id, choice)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            player_id = %player_id,
            choice = ?choice,
            success = result.success,
            "投票處理完成"
        );

        Ok(result)
    }

    /// 處理結盟
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `player_a` - 玩家 A ID
    /// * `player_b` - 玩家 B ID
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_alliance(
        state: &AppState,
        room_code: &str,
        player_a: Uuid,
        player_b: Uuid,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 結盟可在密謀或辯論階段進行
            if engine.state.phase != GamePhase::Conspiracy
                && engine.state.phase != GamePhase::Debate
            {
                return Err(AppError::BadRequest("只能在密謀或辯論階段結盟".to_string()));
            }

            let result = engine
                .process_alliance(player_a, player_b)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            player_a = %player_a,
            player_b = %player_b,
            success = result.success,
            "結盟處理完成"
        );

        Ok(result)
    }

    /// 處理背叛
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    /// * `betrayer_id` - 背叛者 ID
    /// * `target_id` - 目標 ID
    ///
    /// # Returns
    /// 回傳行動結果
    pub async fn handle_betray(
        state: &AppState,
        room_code: &str,
        betrayer_id: Uuid,
        target_id: Uuid,
    ) -> Result<ActionResult, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            let result = engine
                .process_betray(betrayer_id, target_id)
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::debug!(
            room_code = %room_code,
            betrayer_id = %betrayer_id,
            target_id = %target_id,
            success = result.success,
            "背叛處理完成"
        );

        Ok(result)
    }

    /// 計算並取得遊戲結果
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳遊戲結果
    pub async fn get_game_result(
        state: &AppState,
        room_code: &str,
    ) -> Result<GameResult, AppError> {
        let games = state.games.read().await;
        let engine = games
            .get(room_code)
            .ok_or_else(|| AppError::NotFound("遊戲不存在".to_string()))?;

        Ok(engine.calculate_results())
    }

    /// 推進遊戲階段
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳新的遊戲階段
    pub async fn advance_phase(state: &AppState, room_code: &str) -> Result<GamePhase, AppError> {
        let (new_phase, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;
            let new_phase = engine.advance_phase();
            (new_phase, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        tracing::info!(
            room_code = %room_code,
            new_phase = ?new_phase,
            "遊戲階段已推進"
        );

        Ok(new_phase)
    }

    /// 取得階段剩餘時間
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳剩餘秒數
    pub async fn get_phase_remaining(state: &AppState, room_code: &str) -> Result<u32, AppError> {
        let games = state.games.read().await;
        let engine = games
            .get(room_code)
            .ok_or_else(|| AppError::NotFound("遊戲不存在".to_string()))?;

        Ok(engine.get_phase_remaining_secs())
    }

    /// 啟動階段計時器
    ///
    /// 在背景執行，當階段時間結束時自動推進階段
    fn start_phase_timer(state: AppState, room_code: String) {
        tokio::spawn(async move {
            loop {
                // 取得當前階段和剩餘時間
                let (current_phase, remaining_secs) = {
                    let games = state.games.read().await;
                    match games.get(&room_code) {
                        Some(engine) => (engine.state.phase, engine.get_phase_remaining_secs()),
                        None => {
                            tracing::debug!(room_code = %room_code, "遊戲不存在，停止計時器");
                            return;
                        }
                    }
                };

                // 如果遊戲結束，停止計時器
                if current_phase == GamePhase::Finished {
                    tracing::info!(room_code = %room_code, "遊戲結束，停止計時器");
                    return;
                }

                // 等待剩餘時間（最少 1 秒避免忙迴圈）
                let wait_secs = remaining_secs.max(1);
                tokio::time::sleep(tokio::time::Duration::from_secs(wait_secs as u64)).await;

                // 再次檢查遊戲是否存在
                let should_advance = {
                    let games = state.games.read().await;
                    match games.get(&room_code) {
                        Some(engine) => {
                            // 確認時間確實已經到了
                            engine.get_phase_remaining_secs() == 0
                        }
                        None => {
                            tracing::debug!(room_code = %room_code, "遊戲不存在，停止計時器");
                            return;
                        }
                    }
                };

                if should_advance {
                    // 推進階段
                    let (new_phase, game_state) = {
                        let mut games = state.games.write().await;
                        match games.get_mut(&room_code) {
                            Some(engine) => {
                                let new_phase = engine.advance_phase();
                                tracing::info!(
                                    room_code = %room_code,
                                    new_phase = ?new_phase,
                                    "計時器觸發階段推進"
                                );
                                (new_phase, engine.state.clone())
                            }
                            None => return,
                        }
                    };

                    // 同步到 Redis
                    Self::sync_to_redis(&state, &room_code, &game_state).await;

                    // 廣播階段變更
                    Self::broadcast_phase_change(&state, &room_code, new_phase).await;

                    // 如果進入結果階段，處理遊戲結果
                    if new_phase == GamePhase::Result {
                        Self::handle_game_result(&state, &room_code).await;
                    }
                }
            }
        });
    }

    /// 廣播階段變更
    async fn broadcast_phase_change(state: &AppState, room_code: &str, new_phase: GamePhase) {
        use crate::websocket::ServerMessage;

        // 取得遊戲狀態和階段持續時間
        let (game_state, duration_secs) = {
            let games = state.games.read().await;
            match games.get(room_code) {
                Some(engine) => {
                    let duration = match new_phase {
                        GamePhase::Conspiracy => engine.config.conspiracy_duration_secs,
                        GamePhase::Debate => engine.config.debate_duration_secs,
                        GamePhase::Voting => engine.config.voting_duration_secs,
                        GamePhase::Result => engine.config.result_duration_secs,
                        _ => 0,
                    };
                    (Some(engine.state.clone()), duration)
                }
                None => (None, 0),
            }
        };

        if let Some(game_state) = game_state {
            let message = ServerMessage::PhaseChanged {
                phase: new_phase,
                duration_secs,
                round: game_state.current_round as u32,
            };

            // 透過 WebSocket Hub 廣播
            state.ws_hub.broadcast_to_room(room_code, message).await;
        }
    }

    /// 處理遊戲結果
    async fn handle_game_result(state: &AppState, room_code: &str) {
        use crate::websocket::{PlayerRanking, ServerMessage};
        use std::collections::HashMap;

        // 計算遊戲結果
        let result = {
            let games = state.games.read().await;
            games.get(room_code).map(|e| e.calculate_results())
        };

        if let Some(result) = result {
            // 轉換投票結果為 HashMap<String, f64>
            let mut votes: HashMap<String, f64> = HashMap::new();
            votes.insert("A".to_string(), result.vote_counts.option_a);
            votes.insert("B".to_string(), result.vote_counts.option_b);
            votes.insert("C".to_string(), result.vote_counts.option_c);

            // 轉換玩家排名
            let rankings: Vec<PlayerRanking> = result
                .player_scores
                .iter()
                .enumerate()
                .map(|(idx, ps)| PlayerRanking {
                    player_id: ps.player_id,
                    player_name: ps.player_name.clone(),
                    character: ps.character,
                    final_reputation: ps.final_reputation,
                    rank: (idx + 1) as u32,
                    score: ps.total_score,
                })
                .collect();

            // 決定獲勝陣營
            let winner_faction = match result.winning_choice {
                Some(VoteChoice::A) => "工人派",
                Some(VoteChoice::B) => "資方派",
                Some(VoteChoice::C) => "改革派",
                None => "無",
            };

            // 廣播遊戲結果
            let message = ServerMessage::GameResult {
                winner_faction: winner_faction.to_string(),
                votes,
                rankings,
            };

            state.ws_hub.broadcast_to_room(room_code, message).await;

            tracing::info!(
                room_code = %room_code,
                winning_choice = ?result.winning_choice,
                winner_faction = winner_faction,
                "遊戲結果已廣播"
            );
        }
    }

    /// 解決待處理的質詢（當計時器超時時）
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    ///
    /// # Returns
    /// 回傳行動結果（如果有待處理的質詢）
    pub async fn resolve_pending_challenge(
        state: &AppState,
        room_code: &str,
    ) -> Result<Option<ActionResult>, AppError> {
        let (result, game_state) = {
            let mut games = state.games.write().await;
            let engine = Self::get_engine_mut(&mut games, room_code).await?;

            // 檢查是否有待處理的質詢
            if engine.state.pending_challenge.is_none() {
                return Ok(None);
            }

            let result = engine
                .resolve_challenge()
                .map_err(|e| AppError::BadRequest(format!("{:?}", e)))?;

            (result, engine.state.clone())
        };

        // 同步到 Redis
        Self::sync_to_redis(state, room_code, &game_state).await;

        Ok(Some(result))
    }

    /// 清理遊戲
    ///
    /// 從記憶體和 Redis 中移除遊戲狀態
    ///
    /// # Arguments
    /// * `state` - 應用程式狀態
    /// * `room_code` - 房間代碼
    pub async fn cleanup_game(state: &AppState, room_code: &str) {
        // 從記憶體移除
        let removed = {
            let mut games = state.games.write().await;
            games.remove(room_code).is_some()
        };

        // 從 Redis 移除
        if let Err(e) = state.game_cache().cleanup_room(room_code).await {
            tracing::warn!(room_code = %room_code, error = %e, "清理 Redis 快取失敗");
        }

        if removed {
            tracing::info!(room_code = %room_code, "遊戲已清理（記憶體和 Redis）");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Settings;
    use crate::domain::CharacterType;
    use crate::services::RoomService;

    async fn create_test_state() -> AppState {
        let settings = Settings::default();
        AppState::for_testing(settings)
    }

    async fn setup_game_room(state: &AppState) -> (String, Vec<Uuid>) {
        let host_id = Uuid::new_v4();
        let player_id = Uuid::new_v4();

        // 建立房間
        let (room, host_player) = RoomService::create_room(state, host_id, "Host".to_string())
            .await
            .unwrap();

        // 加入房間
        let player = RoomService::join_room(state, &room.code, player_id, "Player".to_string())
            .await
            .unwrap();

        // 設定準備
        RoomService::set_ready(state, &room.code, player.id, true)
            .await
            .unwrap();

        // 選擇角色
        RoomService::select_character(state, &room.code, host_player.id, CharacterType::Thomas)
            .await
            .unwrap();
        RoomService::select_character(state, &room.code, player.id, CharacterType::George)
            .await
            .unwrap();

        // 開始遊戲（房間服務）
        RoomService::start_game(state, &room.code, host_player.id)
            .await
            .unwrap();

        (room.code, vec![host_player.id, player.id])
    }

    #[tokio::test]
    async fn test_start_game() {
        let state = create_test_state().await;
        let (room_code, _) = setup_game_room(&state).await;

        // 啟動遊戲引擎
        let result = GameService::start_game(&state, &room_code).await;
        assert!(result.is_ok());

        let game_state = result.unwrap();
        assert_eq!(game_state.phase, GamePhase::Conspiracy);
        assert_eq!(game_state.current_round, 1);
    }

    #[tokio::test]
    async fn test_get_game_state() {
        let state = create_test_state().await;
        let (room_code, _) = setup_game_room(&state).await;

        // 啟動遊戲引擎
        GameService::start_game(&state, &room_code).await.unwrap();

        // 取得遊戲狀態
        let result = GameService::get_game_state(&state, &room_code).await;
        assert!(result.is_ok());

        let game_state = result.unwrap();
        assert_eq!(game_state.room_code, room_code);
    }

    #[tokio::test]
    async fn test_handle_vote() {
        let state = create_test_state().await;
        let (room_code, player_ids) = setup_game_room(&state).await;

        // 啟動遊戲引擎
        GameService::start_game(&state, &room_code).await.unwrap();

        // 推進到投票階段
        {
            let mut games = state.games.write().await;
            let engine = games.get_mut(&room_code).unwrap();
            engine.advance_phase(); // Conspiracy -> Debate
            engine.advance_phase(); // Debate -> Voting
        }

        // 投票
        let result =
            GameService::handle_vote(&state, &room_code, player_ids[0], VoteChoice::A).await;
        assert!(result.is_ok());
        assert!(result.unwrap().success);
    }

    #[tokio::test]
    async fn test_game_not_found() {
        let state = create_test_state().await;

        let result = GameService::get_game_state(&state, "NONEXISTENT").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_cleanup_game() {
        let state = create_test_state().await;
        let (room_code, _) = setup_game_room(&state).await;

        // 啟動遊戲引擎
        GameService::start_game(&state, &room_code).await.unwrap();

        // 確認遊戲存在
        assert!(GameService::get_game_state(&state, &room_code)
            .await
            .is_ok());

        // 清理遊戲
        GameService::cleanup_game(&state, &room_code).await;

        // 確認遊戲已移除
        assert!(GameService::get_game_state(&state, &room_code)
            .await
            .is_err());
    }
}
