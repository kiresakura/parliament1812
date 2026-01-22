/**
 * Socket Event Handlers
 * WebSocket 事件處理器
 */

import { Server, Socket } from 'socket.io';
import { EVENTS } from './events';
import { RoomManager, GameRoom } from '../game/GameRoom';
import { GamePhase } from '../config/constants';
import {
  ActionType,
  GameAction,
  MessageType,
  createQueryAction,
  createRebutAction,
  createSkillAction,
  createPassAction,
} from '../game/actions';

interface SocketData {
  playerId: string;
  playerName: string;
  roomId: string | null;
}

export function setupSocketHandlers(io: Server): void {
  io.on('connection', (socket: Socket) => {
    console.log(`Client connected: ${socket.id}`);

    // 初始化 socket 資料
    const socketData: SocketData = {
      playerId: socket.id,
      playerName: '',
      roomId: null,
    };

    // 創建房間
    socket.on(EVENTS.CREATE_ROOM, (data: { playerName: string }) => {
      try {
        const { playerName } = data;

        if (!playerName || playerName.trim().length === 0) {
          socket.emit(EVENTS.ERROR, { message: '請輸入玩家名稱' });
          return;
        }

        socketData.playerName = playerName.trim();
        const room = RoomManager.createRoom(socket.id, socketData.playerName);
        socketData.roomId = room.id;

        // 設置房間回調
        setupRoomCallbacks(io, room);

        // 加入 Socket.IO 房間
        socket.join(room.id);

        socket.emit(EVENTS.ROOM_CREATED, {
          roomId: room.id,
          roomCode: room.code,
          player: room.players.get(socket.id)?.toJSON(),
        });

        console.log(`Room created: ${room.code} by ${playerName}`);
      } catch (error) {
        console.error('Error creating room:', error);
        socket.emit(EVENTS.ERROR, { message: '創建房間失敗' });
      }
    });

    // 加入房間
    socket.on(EVENTS.JOIN_ROOM, (data: { roomCode: string; playerName: string }) => {
      try {
        const { roomCode, playerName } = data;

        if (!roomCode || !playerName) {
          socket.emit(EVENTS.ERROR, { message: '請輸入房間代碼和玩家名稱' });
          return;
        }

        const room = RoomManager.getRoomByCode(roomCode.toUpperCase());
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        if (room.isGameStarted) {
          socket.emit(EVENTS.ERROR, { message: '遊戲已開始，無法加入' });
          return;
        }

        const player = room.addPlayer(socket.id, playerName.trim());
        if (!player) {
          socket.emit(EVENTS.ERROR, { message: '房間已滿' });
          return;
        }

        socketData.playerName = playerName.trim();
        socketData.roomId = room.id;

        // 加入 Socket.IO 房間
        socket.join(room.id);

        // 通知加入者
        socket.emit(EVENTS.ROOM_JOINED, {
          roomId: room.id,
          roomCode: room.code,
          player: player.toJSON(),
          players: Array.from(room.players.values()).map(p => p.toJSON()),
        });

        // 通知其他玩家
        socket.to(room.id).emit(EVENTS.PLAYER_JOINED, {
          player: player.toJSON(),
          playerCount: room.playerCount,
        });

        console.log(`${playerName} joined room ${room.code}`);
      } catch (error) {
        console.error('Error joining room:', error);
        socket.emit(EVENTS.ERROR, { message: '加入房間失敗' });
      }
    });

    // 離開房間
    socket.on(EVENTS.LEAVE_ROOM, () => {
      handleLeaveRoom(io, socket, socketData);
    });

    // 玩家準備
    socket.on(EVENTS.PLAYER_READY, (data: { ready: boolean }) => {
      try {
        if (!socketData.roomId) {
          socket.emit(EVENTS.ERROR, { message: '你不在任何房間中' });
          return;
        }

        const room = RoomManager.getRoom(socketData.roomId);
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        const success = room.setPlayerReady(socket.id, data.ready);
        if (!success) {
          socket.emit(EVENTS.ERROR, { message: '設置準備狀態失敗' });
          return;
        }

        // 通知所有玩家
        io.to(room.id).emit(EVENTS.PLAYER_READY_CHANGED, {
          playerId: socket.id,
          ready: data.ready,
          canStart: room.canStart,
        });
      } catch (error) {
        console.error('Error setting ready:', error);
        socket.emit(EVENTS.ERROR, { message: '操作失敗' });
      }
    });

    // 開始遊戲
    socket.on(EVENTS.START_GAME, () => {
      try {
        if (!socketData.roomId) {
          socket.emit(EVENTS.ERROR, { message: '你不在任何房間中' });
          return;
        }

        const room = RoomManager.getRoom(socketData.roomId);
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        if (room.hostId !== socket.id) {
          socket.emit(EVENTS.ERROR, { message: '只有房主可以開始遊戲' });
          return;
        }

        if (!room.canStart) {
          socket.emit(EVENTS.ERROR, { message: '無法開始遊戲，請確認所有玩家已準備' });
          return;
        }

        const success = room.startGame();
        if (!success) {
          socket.emit(EVENTS.ERROR, { message: '開始遊戲失敗' });
          return;
        }

        // 發送各玩家的角色資訊（私密）
        for (const player of room.players.values()) {
          const playerSocket = io.sockets.sockets.get(player.id);
          if (playerSocket) {
            playerSocket.emit(EVENTS.GAME_STARTED, {
              role: player.role?.toJSON(),
              player: player.toJSON(),
              gameState: room.gameState.toJSON(),
              bill: room.gameState.currentBill?.toJSON(),
            });
          }
        }

        console.log(`Game started in room ${room.code}`);
      } catch (error) {
        console.error('Error starting game:', error);
        socket.emit(EVENTS.ERROR, { message: '開始遊戲失敗' });
      }
    });

    // 遊戲行動
    socket.on(EVENTS.GAME_ACTION, (data: {
      type: ActionType;
      targetId?: string;
      params?: Record<string, unknown>;
    }) => {
      try {
        if (!socketData.roomId) {
          socket.emit(EVENTS.ERROR, { message: '你不在任何房間中' });
          return;
        }

        const room = RoomManager.getRoom(socketData.roomId);
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        // 創建行動
        let action: GameAction;
        switch (data.type) {
          case ActionType.QUERY:
            if (!data.targetId) {
              socket.emit(EVENTS.ERROR, { message: '請選擇目標' });
              return;
            }
            action = createQueryAction(socket.id, data.targetId);
            break;
          case ActionType.REBUT:
            action = createRebutAction(socket.id);
            break;
          case ActionType.SKILL:
            action = createSkillAction(socket.id, data.targetId, data.params);
            break;
          default:
            action = createPassAction(socket.id);
        }

        // 執行行動
        const result = room.processAction(action);

        // 發送結果
        socket.emit(EVENTS.ACTION_RESULT, result);

        // 如果成功，廣播狀態更新
        if (result.success) {
          io.to(room.id).emit(EVENTS.GAME_STATE_UPDATE, {
            players: Array.from(room.players.values()).map(p => p.toPublicJSON()),
            actionResult: result,
          });
        }
      } catch (error) {
        console.error('Error processing action:', error);
        socket.emit(EVENTS.ERROR, { message: '執行行動失敗' });
      }
    });

    // 發送訊息
    socket.on(EVENTS.SEND_MESSAGE, (data: {
      content: string;
      type?: MessageType;
      targetId?: string;
    }) => {
      try {
        if (!socketData.roomId) {
          socket.emit(EVENTS.ERROR, { message: '你不在任何房間中' });
          return;
        }

        const room = RoomManager.getRoom(socketData.roomId);
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        const message = room.sendMessage(
          socket.id,
          data.content,
          data.type || MessageType.PUBLIC,
          data.targetId
        );

        if (!message) {
          socket.emit(EVENTS.ERROR, { message: '無法發送訊息' });
          return;
        }

        // 根據訊息類型發送
        if (data.type === MessageType.PRIVATE && data.targetId) {
          // 私訊只發給發送者和接收者
          socket.emit(EVENTS.MESSAGE_RECEIVED, message);
          const targetSocket = io.sockets.sockets.get(data.targetId);
          if (targetSocket) {
            targetSocket.emit(EVENTS.MESSAGE_RECEIVED, message);
          }
        } else {
          // 公開訊息發給所有人
          io.to(room.id).emit(EVENTS.MESSAGE_RECEIVED, message);
        }
      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit(EVENTS.ERROR, { message: '發送訊息失敗' });
      }
    });

    // 投票
    socket.on(EVENTS.VOTE, (data: { optionId: string }) => {
      try {
        if (!socketData.roomId) {
          socket.emit(EVENTS.ERROR, { message: '你不在任何房間中' });
          return;
        }

        const room = RoomManager.getRoom(socketData.roomId);
        if (!room) {
          socket.emit(EVENTS.ERROR, { message: '房間不存在' });
          return;
        }

        const success = room.processVote(socket.id, data.optionId);
        if (!success) {
          socket.emit(EVENTS.ERROR, { message: '投票失敗' });
          return;
        }

        // 通知所有玩家
        io.to(room.id).emit(EVENTS.VOTE_RECEIVED, {
          playerId: socket.id,
          voteCount: room.gameState.votes.size,
          totalPlayers: room.playerCount,
        });
      } catch (error) {
        console.error('Error voting:', error);
        socket.emit(EVENTS.ERROR, { message: '投票失敗' });
      }
    });

    // 斷線處理
    socket.on('disconnect', () => {
      console.log(`Client disconnected: ${socket.id}`);
      handleLeaveRoom(io, socket, socketData);
    });
  });
}

// 處理離開房間
function handleLeaveRoom(io: Server, socket: Socket, socketData: SocketData): void {
  if (!socketData.roomId) return;

  const room = RoomManager.getRoom(socketData.roomId);
  if (!room) return;

  const removed = room.removePlayer(socket.id);
  if (!removed) return;

  socket.leave(room.id);

  // 通知其他玩家
  io.to(room.id).emit(EVENTS.PLAYER_LEFT, {
    playerId: socket.id,
    playerName: socketData.playerName,
    newHostId: room.hostId,
    playerCount: room.playerCount,
  });

  // 如果房間空了，刪除房間
  if (room.playerCount === 0) {
    RoomManager.deleteRoom(room.id);
    console.log(`Room ${room.code} deleted (empty)`);
  }

  socketData.roomId = null;
  console.log(`${socketData.playerName} left room ${room.code}`);
}

// 設置房間回調
function setupRoomCallbacks(io: Server, room: GameRoom): void {
  // 階段變化
  room.setOnPhaseChange((r, phase) => {
    io.to(r.id).emit(EVENTS.PHASE_CHANGED, {
      phase,
      timeRemaining: r.gameState.timeRemaining,
      round: r.gameState.round,
    });

    // 如果是辯論階段，重置玩家狀態
    if (phase === GamePhase.DEBATE) {
      for (const player of r.players.values()) {
        player.resetTurnState();
      }
    }
  });

  // 遊戲結束
  room.setOnGameEnd((r, results) => {
    io.to(r.id).emit(EVENTS.GAME_ENDED, results);
    console.log(`Game ended in room ${r.code}`);
  });

  // 狀態變化（定時廣播時間）
  const timeInterval = setInterval(() => {
    if (room.isGameStarted) {
      io.to(room.id).emit(EVENTS.GAME_STATE_UPDATE, {
        timeRemaining: room.gameState.timeRemaining,
        phase: room.gameState.phase,
      });
    }
  }, 1000);

  // 清理定時器
  room.setOnStateChange((r) => {
    if (r.playerCount === 0) {
      clearInterval(timeInterval);
    }
  });
}
