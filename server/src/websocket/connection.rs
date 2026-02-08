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
use crate::services::RoomService;
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
    // 處理玩家離開房間
    if let Some((room_code, player_id)) = state.ws_hub.leave_room(conn_id).await {
        handle_player_disconnect(&state, &room_code, player_id).await;
    }

    // 取消註冊連線
    state.ws_hub.unregister(conn_id).await;

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

                            // TODO: 發送更新的遊戲狀態（需要實現 GameStateUpdated ServerMessage）
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
                                    player_id,
                                )
                                .await;

                            // TODO: 發送更新的遊戲狀態（需要實現 GameStateUpdated ServerMessage）
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

                            // 棄牌成功，只需要更新遊戲狀態即可

                            // TODO: 發送更新的遊戲狀態（需要實現 GameStateUpdated ServerMessage）
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

    // 廣播遊戲開始
    state
        .ws_hub
        .broadcast_to_room(
            &room_code,
            ServerMessage::GameStarted {
                phase: GamePhase::Conspiracy,
                duration_secs: 120,
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

    tracing::info!(room_code = %room_code, "遊戲開始");

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

    let chat_msg = ServerMessage::ChatMessage {
        from_id: player_id,
        from_name,
        content: content.to_string(),
        is_private: target_id.is_some(),
        timestamp: chrono::Utc::now().timestamp(),
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
    _target_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (_room_code, _player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // TODO: 實作完整的質詢邏輯
    let _ = sender.send(ServerMessage::info("質詢功能尚未完全實作"));

    Ok(())
}

/// 處理反駁
async fn handle_counter(
    conn_id: Uuid,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (_room_code, _player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // TODO: 實作完整的反駁邏輯
    let _ = sender.send(ServerMessage::info("反駁功能尚未完全實作"));

    Ok(())
}

/// 處理使用技能
async fn handle_use_skill(
    conn_id: Uuid,
    _target_id: Option<Uuid>,
    state: &AppState,
    sender: &mpsc::UnboundedSender<ServerMessage>,
) -> Result<(), AppError> {
    let (_room_code, _player_id) = match get_room_and_player(conn_id, state).await {
        Some(ids) => ids,
        None => {
            let _ = sender.send(ServerMessage::error(
                error_codes::NOT_IN_ROOM,
                "您不在任何房間中",
            ));
            return Ok(());
        }
    };

    // TODO: 實作完整的技能邏輯
    let _ = sender.send(ServerMessage::info("技能功能尚未完全實作"));

    Ok(())
}

/// 處理投票
async fn handle_vote(
    conn_id: Uuid,
    _choice: crate::domain::VoteChoice,
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

    // TODO: 實作完整的投票邏輯
    // 目前只廣播投票收到

    let all_players = RoomService::get_room_players(state, &room_code)
        .await
        .unwrap_or_default();
    let total_players = all_players.len() as u32;

    state
        .ws_hub
        .broadcast_to_room(
            &room_code,
            ServerMessage::VoteReceived {
                player_id,
                votes_count: 1, // TODO: 追蹤實際投票數
                total_players,
            },
        )
        .await;

    Ok(())
}

/// 取得連線的房間代碼和玩家 ID
async fn get_room_and_player(conn_id: Uuid, state: &AppState) -> Option<(String, Uuid)> {
    let info = state.ws_hub.get_connection(conn_id).await?;
    Some((info.room_code?, info.player_id?))
}
