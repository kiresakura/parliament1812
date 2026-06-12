//! WebSocket 連線處理
//!
//! 處理單個 WebSocket 連線的生命週期

use axum::extract::ws::{Message, WebSocket};
use futures::{SinkExt, StreamExt};
use tokio::sync::mpsc;
use uuid::Uuid;

use super::messages::{error_codes, ClientMessage, ServerMessage};
use crate::domain::{GamePhase, PlayerResponse, RoomResponse};
use crate::error::AppError;
use crate::game::cards;
use crate::services::{RoomService, SpectatorService};
use crate::AppState;

/// 處理 WebSocket 連線
///
/// 主要處理流程：
/// 1. 將 WebSocket 分割為 sender 和 receiver
/// 2. 向 Hub 註冊連線，獲取 conn_id
/// 3. 發送 Connected 訊息給客戶端
/// 4. 啟動接收和發送任務
/// 5. 連線關閉時，從 Hub 註銷
pub async fn handle_socket(socket: WebSocket, state: AppState, user_id: Uuid) {
    // 建立訊息通道
    let (tx, mut rx) = mpsc::unbounded_channel::<ServerMessage>();

    // 向 Hub 註冊連線
    let conn_id = state.ws_hub.register(user_id, tx.clone()).await;

    // 更新在線狀態
    crate::services::FriendService::user_came_online(&state, user_id).await;

    tracing::info!(
        conn_id = %conn_id,
        user_id = %user_id,
        "新 WebSocket 連線已註冊"
    );

    // 分割 WebSocket
    let (mut ws_sender, mut ws_receiver) = socket.split();

    // 發送連線成功訊息
    let connected_msg = ServerMessage::Connected {
        player_id: Some(user_id),
        server_version: env!("CARGO_PKG_VERSION").to_string(),
    };

    if let Ok(json) = serde_json::to_string(&connected_msg) {
        if ws_sender.send(Message::Text(json)).await.is_err() {
            tracing::warn!(conn_id = %conn_id, "無法發送連線成功訊息");
            state.ws_hub.unregister(conn_id).await;
            return;
        }
    }

    // 發送任務：從 mpsc channel 讀取 ServerMessage，發送給客戶端
    let send_task = tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            if let Ok(json) = serde_json::to_string(&msg) {
                if ws_sender.send(Message::Text(json)).await.is_err() {
                    break;
                }
            }
        }
    });

    // 接收任務：從 receiver 讀取 ClientMessage，處理後呼叫對應 handler
    let state_clone = state.clone();
    let tx_clone = tx.clone();
    let recv_task = tokio::spawn(async move {
        while let Some(result) = ws_receiver.next().await {
            match result {
                Ok(Message::Text(text)) => {
                    // 解析並處理訊息
                    match serde_json::from_str::<ClientMessage>(&text) {
                        Ok(message) => {
                            tracing::debug!(
                                conn_id = %conn_id,
                                message = ?message,
                                "收到客戶端訊息"
                            );

                            if let Err(e) =
                                process_message(&state_clone, conn_id, user_id, message, &tx_clone)
                                    .await
                            {
                                tracing::warn!(
                                    conn_id = %conn_id,
                                    error = %e,
                                    "處理訊息時發生錯誤"
                                );
                                let _ = tx_clone.send(ServerMessage::error(
                                    error_codes::INTERNAL_ERROR,
                                    format!("處理訊息時發生錯誤: {}", e),
                                ));
                            }
                        }
                        Err(e) => {
                            tracing::warn!(
                                conn_id = %conn_id,
                                error = %e,
                                text = %text,
                                "無法解析客戶端訊息"
                            );
                            let _ = tx_clone.send(ServerMessage::error(
                                error_codes::INVALID_ACTION,
                                format!("無效的訊息格式: {}", e),
                            ));
                        }
                    }
                }
                Ok(Message::Binary(data)) => {
                    // 嘗試將二進位資料當作 UTF-8 文字處理
                    if let Ok(text) = String::from_utf8(data.to_vec()) {
                        if let Ok(message) = serde_json::from_str::<ClientMessage>(&text) {
                            let _ =
                                process_message(&state_clone, conn_id, user_id, message, &tx_clone)
                                    .await;
                        }
                    }
                }
                Ok(Message::Ping(_)) => {
                    tracing::trace!(conn_id = %conn_id, "收到 Ping");
                }
                Ok(Message::Pong(_)) => {
                    tracing::trace!(conn_id = %conn_id, "收到 Pong");
                }
                Ok(Message::Close(_)) => {
                    tracing::debug!(conn_id = %conn_id, "收到關閉訊息");
                    break;
                }
                Err(e) => {
                    tracing::warn!(
                        conn_id = %conn_id,
                        error = %e,
                        "WebSocket 錯誤"
                    );
                    break;
                }
            }
        }
    });

    // 等待任一任務完成
    tokio::select! {
        _ = send_task => {
            tracing::debug!(conn_id = %conn_id, "發送任務結束");
        }
        _ = recv_task => {
            tracing::debug!(conn_id = %conn_id, "接收任務結束");
        }
    }

    // 清理連線
    // 處理觀戰者離開
    if let Some(room_code) = state.ws_hub.remove_spectator(conn_id).await {
        let count = state.ws_hub.get_spectator_count(&room_code).await;
        state
            .ws_hub
            .broadcast_to_spectators(
                &room_code,
                ServerMessage::SpectatorCountUpdate { count },
            )
            .await;
        // 同時通知遊戲內玩家觀戰人數變更
        state
            .ws_hub
            .broadcast_to_room(
                &room_code,
                ServerMessage::SpectatorCountUpdate { count },
            )
            .await;
    }

    // 處理玩家離開房間
    if let Some((room_code, player_id)) = state.ws_hub.leave_room(conn_id).await {
        handle_player_disconnect(&state, &room_code, player_id).await;
    }

    // 取消註冊連線
    state.ws_hub.unregister(conn_id).await;

    // 更新離線狀態（只在沒有其他連線時）
    if !state.ws_hub.is_user_connected(user_id).await {
        crate::services::FriendService::user_went_offline(&state, user_id).await;
    }

    tracing::info!(conn_id = %conn_id, "WebSocket 連線已關閉");
}

/// 處理客戶端訊息
///
/// 根據 ClientMessage 類型分發到對應處理函數
pub async fn process_message(
    state: &AppState,
    conn_id: Uuid,
    user_id: Uuid,
    message: ClientMessage,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    match message {
        ClientMessage::Ping => {
            let _ = sender.send(ServerMessage::Pong {
                timestamp: chrono::Utc::now().timestamp(),
            });
        }

        ClientMessage::JoinRoom {
            room_code,
            player_name,
        } => {
            handle_join_room(conn_id, user_id, &room_code, &player_name, state, sender).await?;
        }

        ClientMessage::LeaveRoom => {
            handle_leave_room(conn_id, state, sender).await?;
        }

        ClientMessage::SelectCharacter { character } => {
            handle_select_character(conn_id, character, state, sender).await?;
        }

        ClientMessage::Ready => {
            handle_ready(conn_id, true, state, sender).await?;
        }

        ClientMessage::Unready => {
            handle_ready(conn_id, false, state, sender).await?;
        }

        ClientMessage::StartGame => {
            handle_start_game(conn_id, state, sender).await?;
        }

        ClientMessage::SendChat { content } => {
            handle_chat(conn_id, &content, None, state, sender).await?;
        }

        ClientMessage::SendPrivateChat { target_id, content } => {
            handle_chat(conn_id, &content, Some(target_id), state, sender).await?;
        }

        ClientMessage::Challenge { target_id } => {
            handle_challenge(conn_id, target_id, state, sender).await?;
        }

        ClientMessage::Counter => {
            handle_counter(conn_id, state, sender).await?;
        }

        ClientMessage::UseSkill { target_id } => {
            handle_use_skill(conn_id, target_id, state, sender).await?;
        }

        ClientMessage::Vote { choice } => {
            handle_vote(conn_id, choice, state, sender).await?;
        }

        ClientMessage::UseCard { card_id, target_id } => {
            let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
                Some(ids) => ids,
                None => {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::NOT_IN_ROOM,
                        "未加入房間".to_string(),
                    ));
                    return Ok(());
                }
            };

            {
                let mut games = state.games.write().await;
                if let Some(game) = games.get_mut(&room_code) {
                    match game.use_card(player_id, &card_id, target_id) {
                        Ok(result) => {
                            // 獲取卡牌名稱和目標名稱
                            let card_name = cards::get_card_by_id(&card_id)
                                .map(|c| c.name)
                                .unwrap_or_else(|| "未知卡牌".to_string());
                            let target_name = if let Some(tid) = target_id {
                                // 從遊戲狀態中獲取玩家名稱
                                game.state.get_player(tid).map(|p| p.name.clone())
                            } else {
                                None
                            };
                            let player_name = game
                                .state
                                .get_player(player_id)
                                .map(|p| p.name.clone())
                                .unwrap_or_else(|| "未知玩家".to_string());

                            let _ = state
                                .ws_hub
                                .broadcast_to_room(
                                    &room_code,
                                    ServerMessage::CardUsed {
                                        player_id,
                                        player_name,
                                        card_id: card_id.clone(),
                                        card_name,
                                        target_id,
                                        target_name,
                                        effect_description: result.message.clone(),
                                        value: 0, // 可以根據效果計算實際值
                                    },
                                )
                                .await;

                            // 廣播遊戲效果（聲望變更、政治死亡等）
                            broadcast_game_effects(state, &room_code, &result.effects).await;
                        }
                        Err(e) => {
                            let _ = sender.send(ServerMessage::Error {
                                code: "CARD_USE_FAILED".to_string(),
                                message: e.to_string(),
                            });
                        }
                    }
                } else {
                    let _ = sender.send(ServerMessage::Error {
                        code: "GAME_NOT_FOUND".to_string(),
                        message: "遊戲不存在".to_string(),
                    });
                }
            }
        }

        ClientMessage::DrawCard => {
            let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
                Some(ids) => ids,
                None => {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::NOT_IN_ROOM,
                        "未加入房間".to_string(),
                    ));
                    return Ok(());
                }
            };

            {
                let mut games = state.games.write().await;
                if let Some(game) = games.get_mut(&room_code) {
                    match game.draw_card(player_id) {
                        Ok(card) => {
                            // 只向抽牌玩家發送抽到的卡牌
                            let _ = sender.send(ServerMessage::CardDrawn {
                                card_id: card.id.clone(),
                                card_name: card.name.clone(),
                                card_type: format!("{:?}", card.card_type),
                                description: card.description.clone(),
                                cost: card.influence_cost,
                            });

                            // 向其他玩家廣播手牌數量變化
                            let hand_count = game
                                .state
                                .get_player(player_id)
                                .map(|p| p.hand.count())
                                .unwrap_or(0) as u32;
                            let _ = state
                                .ws_hub
                                .broadcast_to_room_except(
                                    &room_code,
                                    ServerMessage::PlayerHandCountChanged {
                                        player_id,
                                        card_count: hand_count,
                                    },
                                    conn_id,
                                )
                                .await;
                        }
                        Err(e) => {
                            let _ = sender.send(ServerMessage::Error {
                                code: "DRAW_CARD_FAILED".to_string(),
                                message: e.to_string(),
                            });
                        }
                    }
                } else {
                    let _ = sender.send(ServerMessage::Error {
                        code: "GAME_NOT_FOUND".to_string(),
                        message: "遊戲不存在".to_string(),
                    });
                }
            }
        }

        ClientMessage::DiscardCard { card_id } => {
            let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
                Some(ids) => ids,
                None => {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::NOT_IN_ROOM,
                        "未加入房間".to_string(),
                    ));
                    return Ok(());
                }
            };

            {
                let mut games = state.games.write().await;
                if let Some(game) = games.get_mut(&room_code) {
                    match game.discard_card(player_id, &card_id) {
                        Ok(_) => {
                            // 獲取實際手牌數量並廣播變化
                            let hand_count = game
                                .state
                                .get_player(player_id)
                                .map(|p| p.hand.count())
                                .unwrap_or(0) as u32;
                            let _ = state
                                .ws_hub
                                .broadcast_to_room(
                                    &room_code,
                                    ServerMessage::PlayerHandCountChanged {
                                        player_id,
                                        card_count: hand_count,
                                    },
                                )
                                .await;

                            // 棄牌成功
                        }
                        Err(e) => {
                            let _ = sender.send(ServerMessage::Error {
                                code: "DISCARD_CARD_FAILED".to_string(),
                                message: e.to_string(),
                            });
                        }
                    }
                } else {
                    let _ = sender.send(ServerMessage::Error {
                        code: "GAME_NOT_FOUND".to_string(),
                        message: "遊戲不存在".to_string(),
                    });
                }
            }
        }

        ClientMessage::ProposeAlliance { target_id } => {
            handle_propose_alliance(conn_id, target_id, state, sender).await?;
        }

        ClientMessage::RespondToAlliance {
            proposer_id,
            accept,
        } => {
            handle_respond_to_alliance(conn_id, proposer_id, accept, state, sender).await?;
        }

        ClientMessage::EndTurn => {
            handle_end_turn(conn_id, state, sender).await?;
        }

        ClientMessage::ReactToMessage { message_seq, emoji } => {
            handle_message_reaction(conn_id, message_seq, &emoji, state, sender).await?;
        }

        ClientMessage::SpectatorJoin { room_code } => {
            handle_spectator_join(conn_id, user_id, &room_code, state, sender).await?;
        }

        ClientMessage::SpectatorLeave => {
            handle_spectator_leave(conn_id, state, sender).await?;
        }

        ClientMessage::SpectatorChat { message } => {
            handle_spectator_chat(conn_id, &message, state, sender).await?;
        }
    }

    Ok(())
}

/// 處理加入房間
async fn handle_join_room(
    conn_id: Uuid,
    user_id: Uuid,
    room_code: &str,
    player_name: &str,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    // 檢查是否已在房間中
    if state.ws_hub.get_room_code(conn_id).await.is_some() {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "您已在房間中，請先離開當前房間",
        ));
        return Ok(());
    }

    // 使用 RoomService 加入房間
    let player =
        match RoomService::join_room(state, room_code, user_id, player_name.to_string()).await {
            Ok(p) => p,
            Err(e) => {
                let code = match &e {
                    AppError::NotFound(_) => error_codes::ROOM_NOT_FOUND,
                    AppError::BadRequest(msg) if msg.contains("已滿") => error_codes::ROOM_FULL,
                    AppError::BadRequest(msg) if msg.contains("已開始") => {
                        error_codes::GAME_ALREADY_STARTED
                    }
                    _ => error_codes::INVALID_ACTION,
                };
                let _ = sender.send(ServerMessage::error(code, e.to_string()));
                return Ok(());
            }
        };

    let player_id = player.id;

    // 將連線加入房間
    state
        .ws_hub
        .join_room(conn_id, room_code.to_string(), player_id)
        .await;

    // 取得房間和玩家列表
    let room = RoomService::get_room(state, room_code).await?;
    let all_players = RoomService::get_room_players(state, room_code).await?;
    let all_player_responses: Vec<PlayerResponse> =
        all_players.iter().map(PlayerResponse::from).collect();

    // 發送房間狀態給加入的玩家
    let room_response =
        RoomResponse::from(room.clone()).with_player_count(all_player_responses.len() as i32);
    let _ = sender.send(ServerMessage::RoomState {
        room: room_response,
        players: all_player_responses.clone(),
    });

    // 廣播玩家加入給房間內其他玩家
    let player_response = PlayerResponse::from(&player);
    state
        .ws_hub
        .broadcast_to_room_except(
            room_code,
            ServerMessage::PlayerJoined {
                player: player_response,
            },
            conn_id,
        )
        .await;

    tracing::info!(
        conn_id = %conn_id,
        room_code = %room_code,
        player_id = %player_id,
        player_name = %player_name,
        "玩家加入房間"
    );

    Ok(())
}

/// 處理離開房間
async fn handle_leave_room(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    // 取得房間代碼和玩家 ID
    let (room_code, player_id) = match state.ws_hub.leave_room(conn_id).await {
        Some((r, p)) => (r, p),
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 使用 RoomService 離開房間
    let result = RoomService::leave_room(state, &room_code, player_id).await?;

    // 廣播玩家離開
    if !result.room_disbanded {
        state
            .ws_hub
            .broadcast_to_room(
                &room_code,
                ServerMessage::PlayerLeft {
                    player_id: result.player_id,
                    player_name: result.player_name,
                    was_host: result.was_host,
                    new_host_id: result.new_host_id,
                },
            )
            .await;
    } else {
        // 房間解散時清理所有計時器
        let mut timers = state.timers.write().await;
        timers.cancel_all_timers(&room_code);
    }

    // 發送確認
    let _ = sender.send(ServerMessage::info("已離開房間"));

    Ok(())
}

/// 處理玩家斷線
async fn handle_player_disconnect(state: &AppState, room_code: &str, player_id: Uuid) {
    // 使用 RoomService 離開房間
    match RoomService::leave_room(state, room_code, player_id).await {
        Ok(result) => {
            // 廣播玩家離開
            if !result.room_disbanded {
                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::PlayerLeft {
                            player_id: result.player_id,
                            player_name: result.player_name,
                            was_host: result.was_host,
                            new_host_id: result.new_host_id,
                        },
                    )
                    .await;
            } else {
                // 房間解散時清理所有計時器
                let mut timers = state.timers.write().await;
                timers.cancel_all_timers(room_code);
            }
        }
        Err(e) => {
            tracing::warn!(
                room_code = %room_code,
                player_id = %player_id,
                error = %e,
                "處理玩家斷線時發生錯誤"
            );
        }
    }
}

/// 處理選擇角色
async fn handle_select_character(
    conn_id: Uuid,
    character: crate::domain::CharacterType,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 使用 RoomService 選擇角色
    if let Err(e) = RoomService::select_character(state, &room_code, player_id, character).await {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            e.to_string(),
        ));
        return Ok(());
    }

    // 廣播角色選擇
    state
        .ws_hub
        .broadcast_to_room(
            &room_code,
            ServerMessage::PlayerSelectedCharacter {
                player_id,
                character,
            },
        )
        .await;

    Ok(())
}

/// 處理準備狀態
async fn handle_ready(
    conn_id: Uuid,
    ready: bool,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 使用 RoomService 設定準備狀態
    if let Err(e) = RoomService::set_ready(state, &room_code, player_id, ready).await {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            e.to_string(),
        ));
        return Ok(());
    }

    // 廣播準備狀態
    let msg = if ready {
        ServerMessage::PlayerReady { player_id }
    } else {
        ServerMessage::PlayerUnready { player_id }
    };
    state.ws_hub.broadcast_to_room(&room_code, msg).await;

    Ok(())
}

/// 處理開始遊戲
async fn handle_start_game(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 使用 RoomService 開始遊戲
    let result = match RoomService::start_game(state, &room_code, player_id).await {
        Ok(r) => r,
        Err(e) => {
            let code = match &e {
                AppError::Forbidden(_) => error_codes::NOT_HOST,
                _ => error_codes::INVALID_ACTION,
            };
            let _ = sender.send(ServerMessage::error(code, e.to_string()));
            return Ok(());
        }
    };

    // 取得回合順序
    let turn_order = {
        let games = state.games.read().await;
        games
            .get(&room_code)
            .map(|game| game.state.turn_order.clone())
            .unwrap_or_default()
    };

    // 廣播遊戲開始（回合制：進入 PlayerTurn 階段，無計時）
    state
        .ws_hub
        .broadcast_to_room(
            &room_code,
            ServerMessage::GameStarted {
                phase: GamePhase::PlayerTurn,
                duration_secs: 0, // 回合制不計時
                turn_order,
            },
        )
        .await;

    // 廣播角色分配
    for (pid, character) in &result.character_assignments {
        state
            .ws_hub
            .broadcast_to_room(
                &room_code,
                ServerMessage::PlayerSelectedCharacter {
                    player_id: *pid,
                    character: *character,
                },
            )
            .await;
    }

    // 廣播初始回合（輪到誰行動）
    {
        let games = state.games.read().await;
        if let Some(game) = games.get(&room_code) {
            if let Some(current_player_id) = game.state.current_turn_player() {
                let current_player_name = game
                    .state
                    .get_player(current_player_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string());
                let turn_order = game.state.turn_order.clone();

                state
                    .ws_hub
                    .broadcast_to_room(
                        &room_code,
                        ServerMessage::TurnChanged {
                            current_player_id,
                            current_player_name,
                            action_points: game.state.action_points_remaining,
                            turn_order,
                        },
                    )
                    .await;
            }
        }
    }

    // 回合制不需要啟動 phase timer（PlayerTurn 不計時）

    tracing::info!(room_code = %room_code, "遊戲開始（回合制）");

    Ok(())
}

/// 處理聊天訊息
async fn handle_chat(
    conn_id: Uuid,
    content: &str,
    target_id: Option<Uuid>,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 取得發送者名稱
    let from_name = {
        let players = state.players.read().await;
        players
            .get(&player_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "Unknown".to_string())
    };

    // 獲取消息序列號
    let message_seq = if target_id.is_none() {
        // 只有公開消息才有序列號（用於表情反應）
        Some(state.ws_hub.get_next_sequence(&room_code).await)
    } else {
        None
    };

    let chat_msg = ServerMessage::ChatMessage {
        from_id: player_id,
        from_name,
        content: content.to_string(),
        is_private: target_id.is_some(),
        timestamp: chrono::Utc::now().timestamp(),
        message_seq,
    };

    if let Some(target) = target_id {
        // 私訊
        state.ws_hub.send_to_player(target, chat_msg.clone()).await;
        let _ = sender.send(chat_msg); // 也發給自己
    } else {
        // 公開訊息
        state.ws_hub.broadcast_to_room(&room_code, chat_msg).await;
    }

    Ok(())
}

/// 處理質詢
async fn handle_challenge(
    conn_id: Uuid,
    target_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    let result = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            match game.process_challenge(player_id, target_id) {
                Ok(result) => Ok(result),
                Err(e) => Err(e),
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲不存在",
            ));
            return Ok(());
        }
    };

    match result {
        Ok(action_result) => {
            // 獲取玩家名稱
            let (attacker_name, target_name) = {
                let players = state.players.read().await;
                let a = players
                    .get(&player_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string());
                let t = players
                    .get(&target_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string());
                (a, t)
            };

            // 從效果中取得實際 damage 值
            let damage = action_result
                .effects
                .iter()
                .find_map(|e| {
                    if let crate::game::GameEffect::PendingCounter { damage, .. } = e {
                        Some(*damage)
                    } else {
                        None
                    }
                })
                .unwrap_or(0);

            // 廣播質詢事件
            state
                .ws_hub
                .broadcast_to_room(
                    &room_code,
                    ServerMessage::ChallengeEvent {
                        attacker_id: player_id,
                        attacker_name,
                        target_id,
                        target_name,
                        damage,
                        countered: false,
                    },
                )
                .await;

            // 廣播狀態變更效果
            broadcast_game_effects(state, &room_code, &action_result.effects).await;

            // 啟動反駁超時計時器（P1-4）
            {
                let counter_timeout = {
                    let games = state.games.read().await;
                    games
                        .get(&room_code)
                        .map(|g| g.config.counter_timeout_secs)
                        .unwrap_or(10)
                };
                let mut timers = state.timers.write().await;
                timers.start_counter_timer(
                    &room_code,
                    counter_timeout,
                    state.ws_hub.clone(),
                    state.games.clone(),
                );
            }
        }
        Err(e) => {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                e.to_string(),
            ));
        }
    }

    Ok(())
}

/// 處理反駁
async fn handle_counter(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    let (result, pending_damage) = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            // 在 process_counter 前記錄 pending_challenge 的 damage
            let pending_damage = game
                .state
                .pending_challenge
                .as_ref()
                .map(|pc| pc.damage)
                .unwrap_or(0);
            match game.process_counter(player_id) {
                Ok(result) => (Ok(result), pending_damage),
                Err(e) => (Err(e), 0),
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲不存在",
            ));
            return Ok(());
        }
    };

    match result {
        Ok(action_result) => {
            // 取消反駁超時計時器（P1-4）
            {
                let mut timers = state.timers.write().await;
                timers.cancel_counter_timer(&room_code);
            }

            // 獲取防禦者名稱
            let defender_name = {
                let players = state.players.read().await;
                players
                    .get(&player_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string())
            };

            // 廣播反駁事件
            state
                .ws_hub
                .broadcast_to_room(
                    &room_code,
                    ServerMessage::CounterEvent {
                        defender_id: player_id,
                        defender_name,
                        damage_blocked: pending_damage,
                    },
                )
                .await;

            // 廣播狀態變更效果
            broadcast_game_effects(state, &room_code, &action_result.effects).await;
        }
        Err(e) => {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                e.to_string(),
            ));
        }
    }

    Ok(())
}

/// 處理使用技能
async fn handle_use_skill(
    conn_id: Uuid,
    target_id: Option<Uuid>,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    let result = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            match game.process_skill(player_id, target_id) {
                Ok(result) => Ok(result),
                Err(e) => Err(e),
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲不存在",
            ));
            return Ok(());
        }
    };

    match result {
        Ok(action_result) => {
            // 獲取玩家名稱和技能名稱
            let (player_name, skill_name, target_name) = {
                let players = state.players.read().await;
                let pn = players
                    .get(&player_id)
                    .map(|p| p.name.clone())
                    .unwrap_or_else(|| "未知玩家".to_string());
                let tn = target_id.and_then(|tid| {
                    players.get(&tid).map(|p| p.name.clone())
                });

                // 從遊戲狀態獲取角色名作為技能名
                let games = state.games.read().await;
                let sn = games.get(&room_code).and_then(|game| {
                    game.state.get_player(player_id).map(|p| {
                        match p.character {
                            crate::domain::CharacterType::Thomas => "團結".to_string(),
                            crate::domain::CharacterType::Richard => "收買".to_string(),
                            crate::domain::CharacterType::Edward => "爆料".to_string(),
                            crate::domain::CharacterType::George => "怒火".to_string(),
                        }
                    })
                }).unwrap_or_else(|| "技能".to_string());

                (pn, sn, tn)
            };

            // 廣播技能使用事件
            state
                .ws_hub
                .broadcast_to_room(
                    &room_code,
                    ServerMessage::SkillUsed {
                        player_id,
                        player_name,
                        skill_name,
                        target_id,
                        target_name,
                        effect_description: action_result.message.clone(),
                    },
                )
                .await;

            // 廣播狀態變更效果
            broadcast_game_effects(state, &room_code, &action_result.effects).await;
        }
        Err(e) => {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                e.to_string(),
            ));
        }
    }

    Ok(())
}

/// 處理投票
async fn handle_vote(
    conn_id: Uuid,
    choice: crate::domain::VoteChoice,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 調用 game engine 處理投票
    let (result, votes_count, total_players): (
        Result<crate::game::ActionResult, crate::game::GameError>,
        u32,
        u32,
    ) = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            match game.process_vote(player_id, choice) {
                Ok(action_result) => {
                    let vc = game.state.votes.len() as u32;
                    let tp = game.state.alive_player_count() as u32;
                    (Ok(action_result), vc, tp)
                }
                Err(e) => {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::INVALID_ACTION,
                        e.to_string(),
                    ));
                    return Ok(());
                }
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲不存在",
            ));
            return Ok(());
        }
    };

    if let Ok(action_result) = result {
        // 廣播投票收到
        state
            .ws_hub
            .broadcast_to_room(
                &room_code,
                ServerMessage::VoteReceived {
                    player_id,
                    votes_count,
                    total_players,
                },
            )
            .await;

        // 廣播背叛效果（如果有）
        broadcast_game_effects(state, &room_code, &action_result.effects).await;

        // 檢查是否所有人都已投票
        if votes_count >= total_players {
            // 計算投票結果
            let vote_result = {
                let games = state.games.read().await;
                games.get(&room_code).map(|game| game.calculate_results())
            };

            if let Some(game_result) = vote_result {
                let winner = game_result
                    .winning_choice
                    .unwrap_or(crate::domain::VoteChoice::A);

                let mut votes_map = std::collections::HashMap::new();
                votes_map.insert("A".to_string(), game_result.vote_counts.option_a);
                votes_map.insert("B".to_string(), game_result.vote_counts.option_b);
                votes_map.insert("C".to_string(), game_result.vote_counts.option_c);

                state
                    .ws_hub
                    .broadcast_to_room(
                        &room_code,
                        ServerMessage::VoteResult {
                            votes: votes_map,
                            winner,
                        },
                    )
                    .await;

                // 投票完成後推進階段（P1-7）
                let phase_info = {
                    let mut games = state.games.write().await;
                    if let Some(game) = games.get_mut(&room_code) {
                        let new_phase = game.advance_phase();
                        let duration = match new_phase {
                            GamePhase::Waiting | GamePhase::Finished | GamePhase::PlayerTurn => 0,
                            GamePhase::Voting => game.config.voting_duration_secs,
                            GamePhase::Result => game.config.result_duration_secs,
                        };
                        Some((new_phase, duration, game.state.current_round as u32))
                    } else {
                        None
                    }
                };

                if let Some((new_phase, duration, round)) = phase_info {
                    // 廣播階段變更
                    state
                        .ws_hub
                        .broadcast_to_room(
                            &room_code,
                            ServerMessage::PhaseChanged {
                                phase: new_phase,
                                duration_secs: duration,
                                round,
                            },
                        )
                        .await;

                    // 取消舊 timer 並啟動新的
                    if new_phase != GamePhase::Finished && duration > 0 {
                        let mut timers = state.timers.write().await;
                        timers.start_phase_timer(
                            &room_code,
                            duration,
                            state.ws_hub.clone(),
                            state.games.clone(),
                            state.timers.clone(),
                        );
                    } else {
                        let mut timers = state.timers.write().await;
                        timers.cancel_all_timers(&room_code);
                    }
                }
            }
        }
    }

    Ok(())
}

/// 處理結束回合（回合制）
async fn handle_end_turn(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 呼叫引擎結束回合
    let end_result: Result<bool, String> = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            match game.end_turn(player_id) {
                Ok(all_done) => Ok(all_done),
                Err(e) => Err(e.to_string()),
            }
        } else {
            Err("遊戲不存在".to_string())
        }
    };

    match end_result {
        Ok(all_players_done) => {
            if all_players_done {
                // 所有玩家行動完畢，已進入投票階段
                let phase_info = {
                    let games = state.games.read().await;
                    games.get(&room_code).map(|game| {
                        (
                            game.state.phase,
                            game.config.voting_duration_secs,
                            game.state.current_round as u32,
                        )
                    })
                };

                if let Some((phase, duration, round)) = phase_info {
                    state
                        .ws_hub
                        .broadcast_to_room(
                            &room_code,
                            ServerMessage::PhaseChanged {
                                phase,
                                duration_secs: duration,
                                round,
                            },
                        )
                        .await;

                    // 啟動投票計時器
                    if duration > 0 {
                        let mut timers = state.timers.write().await;
                        timers.start_phase_timer(
                            &room_code,
                            duration,
                            state.ws_hub.clone(),
                            state.games.clone(),
                            state.timers.clone(),
                        );
                    }
                }
            } else {
                // 還有玩家需要行動，廣播回合變更
                let turn_info = {
                    let games = state.games.read().await;
                    games.get(&room_code).and_then(|game| {
                        game.state.current_turn_player().map(|pid| {
                            let name = game
                                .state
                                .get_player(pid)
                                .map(|p| p.name.clone())
                                .unwrap_or_else(|| "未知玩家".to_string());
                            (pid, name, game.state.action_points_remaining, game.state.turn_order.clone())
                        })
                    })
                };

                if let Some((current_player_id, current_player_name, action_points, turn_order)) = turn_info {
                    state
                        .ws_hub
                        .broadcast_to_room(
                            &room_code,
                            ServerMessage::TurnChanged {
                                current_player_id,
                                current_player_name,
                                action_points,
                                turn_order,
                            },
                        )
                        .await;
                }
            }
        }
        Err(e) => {
            let _ = sender.send(ServerMessage::error(error_codes::INVALID_ACTION, e));
        }
    }

    Ok(())
}

// ============================================================
// 觀戰者訊息處理
// ============================================================

/// 處理觀戰者加入
async fn handle_spectator_join(
    conn_id: Uuid,
    user_id: Uuid,
    room_code: &str,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    // 檢查是否已經是觀戰者
    if state.ws_hub.is_spectator(conn_id).await {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "您已經在觀戰中",
        ));
        return Ok(());
    }

    // 檢查房間是否存在且允許觀戰
    let can_spectate = SpectatorService::can_spectate(state, room_code).await?;
    if !can_spectate {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "房間不存在或遊戲尚未開始，無法觀戰",
        ));
        return Ok(());
    }

    // 取得使用者名稱
    let user_name = {
        let users = state.users.read().await;
        users
            .get(&user_id)
            .map(|u| u.username.clone())
            .unwrap_or_else(|| format!("觀戰者_{}", &user_id.to_string()[..8]))
    };

    // 加入觀戰者集合
    state
        .ws_hub
        .add_spectator(room_code, conn_id, user_id, user_name, sender.clone())
        .await;

    let spectator_count = state.ws_hub.get_spectator_count(room_code).await;

    // 發送加入確認給觀戰者
    let _ = sender.send(ServerMessage::SpectatorJoined {
        room_code: room_code.to_string(),
        spectator_count,
    });

    // 廣播觀戰人數更新給所有觀戰者
    state
        .ws_hub
        .broadcast_to_spectators(
            room_code,
            ServerMessage::SpectatorCountUpdate {
                count: spectator_count,
            },
        )
        .await;

    // 同時通知遊戲內玩家觀戰人數變更
    state
        .ws_hub
        .broadcast_to_room(
            room_code,
            ServerMessage::SpectatorCountUpdate {
                count: spectator_count,
            },
        )
        .await;

    // 發送當前遊戲狀態（延遲 10 秒後推送）
    let state_clone = state.clone();
    let room_code_owned = room_code.to_string();
    let sender_clone = sender.clone();
    tokio::spawn(async move {
        // 延遲 10 秒推送遊戲狀態
        tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;

        if let Some((game_state, round, phase)) =
            SpectatorService::get_spectator_game_state(&state_clone, &room_code_owned).await
        {
            let count = state_clone
                .ws_hub
                .get_spectator_count(&room_code_owned)
                .await;
            let _ = sender_clone.send(ServerMessage::SpectatorUpdate {
                game_state,
                spectator_count: count,
                round,
                phase,
            });
        }
    });

    tracing::info!(
        conn_id = %conn_id,
        room_code = %room_code,
        user_id = %user_id,
        "觀戰者加入房間"
    );

    Ok(())
}

/// 處理觀戰者離開
async fn handle_spectator_leave(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    if let Some(room_code) = state.ws_hub.remove_spectator(conn_id).await {
        let count = state.ws_hub.get_spectator_count(&room_code).await;

        // 廣播觀戰人數更新
        state
            .ws_hub
            .broadcast_to_spectators(
                &room_code,
                ServerMessage::SpectatorCountUpdate { count },
            )
            .await;

        // 同時通知遊戲內玩家
        state
            .ws_hub
            .broadcast_to_room(
                &room_code,
                ServerMessage::SpectatorCountUpdate { count },
            )
            .await;

        let _ = sender.send(ServerMessage::info("已離開觀戰"));
    } else {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "您不在觀戰中",
        ));
    }

    Ok(())
}

/// 處理觀戰者聊天
async fn handle_spectator_chat(
    conn_id: Uuid,
    message: &str,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    // 檢查是否為觀戰者
    let room_code = match state.ws_hub.get_spectator_room(conn_id).await {
        Some(code) => code,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "您不在觀戰中",
            ));
            return Ok(());
        }
    };

    // 限制訊息長度（最多 200 字）
    if message.chars().count() > 200 {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "觀戰聊天訊息不能超過 200 字",
        ));
        return Ok(());
    }

    // 空訊息檢查
    let trimmed = message.trim();
    if trimmed.is_empty() {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "訊息不能為空",
        ));
        return Ok(());
    }

    // 取得觀戰者名稱
    let user_name = state
        .ws_hub
        .get_spectator_name(conn_id)
        .await
        .unwrap_or_else(|| "匿名觀戰者".to_string());

    // 廣播聊天訊息給所有觀戰者（聊天隔離：只在觀戰者之間可見）
    let chat_msg = ServerMessage::SpectatorChatBroadcast {
        user_name,
        message: trimmed.to_string(),
        timestamp: chrono::Utc::now().to_rfc3339(),
    };

    state
        .ws_hub
        .broadcast_to_spectators(&room_code, chat_msg)
        .await;

    Ok(())
}

/// 取得連線的房間代碼和玩家 ID
async fn get_room_and_player(conn_id: Uuid, state: &AppState) -> Option<(String, Uuid)> {
    let info = state.ws_hub.get_connection(conn_id).await?;
    Some((info.room_code?, info.player_id?))
}

/// 處理同盟提議
async fn handle_propose_alliance(
    conn_id: Uuid,
    target_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 檢查遊戲狀態（只能在行動階段提議同盟）
    {
        let games = state.games.read().await;
        if let Some(game) = games.get(&room_code) {
            use crate::domain::GamePhase;
            if game.state.phase != GamePhase::PlayerTurn {
                let _ = sender.send(ServerMessage::error(
                    error_codes::INVALID_ACTION,
                    "只能在行動階段提議同盟",
                ));
                return Ok(());
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲尚未開始",
            ));
            return Ok(());
        }
    }

    // 獲取玩家名稱
    let (proposer_name, target_name) = {
        let players = state.players.read().await;
        let proposer_name = players
            .get(&player_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "未知玩家".to_string());
        let target_name = players
            .get(&target_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "未知玩家".to_string());
        (proposer_name, target_name)
    };

    // 使用同盟管理器處理提議
    let alliance_id = {
        let mut games = state.games.write().await;
        if let Some(game) = games.get_mut(&room_code) {
            match game.propose_alliance(player_id, target_id) {
                Ok(id) => id,
                Err(e) => {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::INVALID_ACTION,
                        format!("提議同盟失敗: {}", e),
                    ));
                    return Ok(());
                }
            }
        } else {
            let _ = sender.send(ServerMessage::error(
                error_codes::INVALID_ACTION,
                "遊戲不存在",
            ));
            return Ok(());
        }
    };

    // 廣播同盟提議
    state
        .ws_hub
        .broadcast_to_room_with_sequence(
            &room_code,
            ServerMessage::AllianceProposed {
                alliance_id,
                proposer_id: player_id,
                proposer_name,
                target_id,
                target_name,
            },
        )
        .await;

    Ok(())
}

/// 處理回應同盟提議
async fn handle_respond_to_alliance(
    conn_id: Uuid,
    proposer_id: Uuid,
    accept: bool,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 獲取玩家名稱
    let (proposer_name, responder_name) = {
        let players = state.players.read().await;
        let proposer_name = players
            .get(&proposer_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "未知玩家".to_string());
        let responder_name = players
            .get(&player_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "未知玩家".to_string());
        (proposer_name, responder_name)
    };

    if accept {
        // 接受同盟
        let alliance_id = {
            let mut games = state.games.write().await;
            if let Some(game) = games.get_mut(&room_code) {
                match game.accept_alliance(player_id, proposer_id) {
                    Ok(id) => id,
                    Err(e) => {
                        let _ = sender.send(ServerMessage::error(
                            error_codes::INVALID_ACTION,
                            format!("接受同盟失敗: {}", e),
                        ));
                        return Ok(());
                    }
                }
            } else {
                let _ = sender.send(ServerMessage::error(
                    error_codes::INVALID_ACTION,
                    "遊戲不存在",
                ));
                return Ok(());
            }
        };

        // 廣播同盟建立
        state
            .ws_hub
            .broadcast_to_room_with_sequence(
                &room_code,
                ServerMessage::AllianceAccepted {
                    alliance_id,
                    members: vec![proposer_id, player_id],
                    member_names: vec![proposer_name, responder_name],
                },
            )
            .await;
    } else {
        // 拒絕同盟
        {
            let mut games = state.games.write().await;
            if let Some(game) = games.get_mut(&room_code) {
                if let Err(e) = game.reject_alliance(player_id, proposer_id) {
                    let _ = sender.send(ServerMessage::error(
                        error_codes::INVALID_ACTION,
                        format!("拒絕同盟失敗: {}", e),
                    ));
                    return Ok(());
                }
            }
        }

        // 廣播同盟拒絕
        state
            .ws_hub
            .broadcast_to_room_with_sequence(
                &room_code,
                ServerMessage::AllianceRejected {
                    proposer_id,
                    proposer_name,
                    rejecter_id: player_id,
                    rejecter_name: responder_name,
                },
            )
            .await;
    }

    Ok(())
}

/// 廣播遊戲效果到房間
///
/// 將 GameEffect 轉換為對應的 ServerMessage 並廣播
async fn broadcast_game_effects(
    state: &AppState,
    room_code: &str,
    effects: &[crate::game::GameEffect],
) {
    for effect in effects {
        match effect {
            crate::game::GameEffect::ReputationChange { player_id, amount } => {
                let (player_name, new_reputation) = {
                    let games = state.games.read().await;
                    if let Some(game) = games.get(room_code) {
                        game.state
                            .get_player(*player_id)
                            .map(|p| (p.name.clone(), p.reputation))
                            .unwrap_or_else(|| ("未知玩家".to_string(), 0))
                    } else {
                        continue;
                    }
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::ReputationChanged {
                            player_id: *player_id,
                            new_reputation,
                            change: *amount,
                            reason: if *amount > 0 {
                                "聲望恢復".to_string()
                            } else {
                                "受到傷害".to_string()
                            },
                        },
                    )
                    .await;
            }
            crate::game::GameEffect::GoldChange { player_id, amount } => {
                let new_gold = {
                    let games = state.games.read().await;
                    games
                        .get(room_code)
                        .and_then(|g| g.state.get_player(*player_id).map(|p| p.gold))
                        .unwrap_or(0)
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::GoldChanged {
                            player_id: *player_id,
                            new_gold,
                            change: *amount,
                            reason: "技能效果".to_string(),
                        },
                    )
                    .await;
            }
            crate::game::GameEffect::PoliticalDeath { player_id } => {
                let player_name = {
                    let players = state.players.read().await;
                    players
                        .get(player_id)
                        .map(|p| p.name.clone())
                        .unwrap_or_else(|| "未知玩家".to_string())
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::PlayerPoliticalDeath {
                            player_id: *player_id,
                            player_name,
                        },
                    )
                    .await;
            }
            crate::game::GameEffect::Silenced { player_id } => {
                let player_name = {
                    let players = state.players.read().await;
                    players
                        .get(player_id)
                        .map(|p| p.name.clone())
                        .unwrap_or_else(|| "未知玩家".to_string())
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::info(format!("{} 被沉默了", player_name)),
                    )
                    .await;
            }
            crate::game::GameEffect::SkillRevealed {
                player_id,
                character,
            } => {
                let player_name = {
                    let players = state.players.read().await;
                    players
                        .get(player_id)
                        .map(|p| p.name.clone())
                        .unwrap_or_else(|| "未知玩家".to_string())
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::info(format!(
                            "{} 的身份被揭露：{}",
                            player_name,
                            character.name()
                        )),
                    )
                    .await;
            }
            crate::game::GameEffect::AllianceBroken {
                betrayer_id,
                victim_id,
            } => {
                let (betrayer_name, victim_name) = {
                    let players = state.players.read().await;
                    let bn = players
                        .get(betrayer_id)
                        .map(|p| p.name.clone())
                        .unwrap_or_else(|| "未知玩家".to_string());
                    let vn = players
                        .get(victim_id)
                        .map(|p| p.name.clone())
                        .unwrap_or_else(|| "未知玩家".to_string());
                    (bn, vn)
                };

                state
                    .ws_hub
                    .broadcast_to_room(
                        room_code,
                        ServerMessage::AllianceBetrayed {
                            alliance_id: Uuid::new_v4(),
                            betrayer_id: *betrayer_id,
                            betrayer_name,
                            victim_id: *victim_id,
                            victim_name,
                        },
                    )
                    .await;
            }
            _ => {} // PendingCounter, AllianceFormed handled elsewhere
        }
    }
}

/// 處理表情反應
async fn handle_message_reaction(
    conn_id: Uuid,
    target_message_seq: u64,
    emoji: &str,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (room_code, player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // 驗證表情（只允許特定的表情）
    let allowed_emojis = ["👍", "👎", "😂", "🔥", "❤️", "😮"];
    if !allowed_emojis.contains(&emoji) {
        let _ = sender.send(ServerMessage::error(
            error_codes::INVALID_ACTION,
            "不支援的表情反應",
        ));
        return Ok(());
    }

    // 取得反應者名稱
    let from_name = {
        let players = state.players.read().await;
        players
            .get(&player_id)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| "Unknown".to_string())
    };

    let reaction_msg = ServerMessage::MessageReaction {
        from_id: player_id,
        from_name,
        target_message_seq,
        emoji: emoji.to_string(),
        timestamp: chrono::Utc::now().timestamp(),
    };

    // 廣播表情反應到房間
    state
        .ws_hub
        .broadcast_to_room_with_sequence(&room_code, reaction_msg)
        .await;

    Ok(())
}
