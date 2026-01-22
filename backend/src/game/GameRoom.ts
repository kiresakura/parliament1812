/**
 * GameRoom
 * 遊戲房間管理
 */

import { v4 as uuidv4 } from 'uuid';
import { GamePhase, ROOM_CONFIG, ROLES } from '../config/constants';
import { Player, PlayerData } from '../models/Player';
import { GameState, GameStateData } from './GameState';
import { GameEngine } from './GameEngine';
import { GameAction, ActionResult, GameMessage, MessageType } from './actions';

export interface RoomData {
  id: string;
  code: string;
  hostId: string;
  players: PlayerData[];
  gameState: GameStateData;
  createdAt: number;
  updatedAt: number;
}

export class GameRoom {
  readonly id: string;
  readonly code: string;
  private _hostId: string;
  private _players: Map<string, Player>;
  private _gameState: GameState;
  private _createdAt: number;
  private _updatedAt: number;
  private _onStateChange: ((room: GameRoom) => void) | null;
  private _onPhaseChange: ((room: GameRoom, phase: GamePhase) => void) | null;
  private _onGameEnd: ((room: GameRoom, results: unknown) => void) | null;

  constructor(hostId: string, hostName: string) {
    this.id = uuidv4();
    this.code = this.generateRoomCode();
    this._hostId = hostId;
    this._players = new Map();
    this._gameState = new GameState();
    this._createdAt = Date.now();
    this._updatedAt = Date.now();
    this._onStateChange = null;
    this._onPhaseChange = null;
    this._onGameEnd = null;

    // 添加房主
    const host = new Player(hostId, hostName, this.id, true);
    this._players.set(hostId, host);

    // 設置階段結束回調
    this._gameState.setOnPhaseEnd(() => this.handlePhaseEnd());
  }

  private generateRoomCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < ROOM_CONFIG.CODE_LENGTH; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  get hostId(): string {
    return this._hostId;
  }

  get players(): Map<string, Player> {
    return this._players;
  }

  get gameState(): GameState {
    return this._gameState;
  }

  get playerCount(): number {
    return this._players.size;
  }

  get isGameStarted(): boolean {
    return this._gameState.phase !== GamePhase.WAITING;
  }

  get canStart(): boolean {
    // 檢查玩家數量
    if (this.playerCount < ROOM_CONFIG.MIN_PLAYERS) {
      return false;
    }

    // 檢查所有玩家是否準備
    for (const player of this._players.values()) {
      if (!player.isHost && !player.isReady) {
        return false;
      }
    }

    return true;
  }

  // 設置回調
  setOnStateChange(callback: (room: GameRoom) => void): void {
    this._onStateChange = callback;
  }

  setOnPhaseChange(callback: (room: GameRoom, phase: GamePhase) => void): void {
    this._onPhaseChange = callback;
  }

  setOnGameEnd(callback: (room: GameRoom, results: unknown) => void): void {
    this._onGameEnd = callback;
  }

  // 加入房間
  addPlayer(playerId: string, playerName: string): Player | null {
    if (this._players.has(playerId)) {
      return this._players.get(playerId) || null;
    }

    if (this.playerCount >= ROOM_CONFIG.MAX_PLAYERS) {
      return null;
    }

    if (this.isGameStarted) {
      return null;
    }

    const player = new Player(playerId, playerName, this.id, false);
    this._players.set(playerId, player);
    this._updatedAt = Date.now();

    this.notifyStateChange();
    return player;
  }

  // 離開房間
  removePlayer(playerId: string): boolean {
    if (!this._players.has(playerId)) {
      return false;
    }

    this._players.delete(playerId);
    this._updatedAt = Date.now();

    // 如果房主離開，轉移房主
    if (playerId === this._hostId && this._players.size > 0) {
      const newHost = this._players.values().next().value;
      if (newHost) {
        this._hostId = newHost.id;
        newHost.isHost = true;
      }
    }

    this.notifyStateChange();
    return true;
  }

  // 玩家準備狀態
  setPlayerReady(playerId: string, ready: boolean): boolean {
    const player = this._players.get(playerId);
    if (!player) {
      return false;
    }

    player.isReady = ready;
    this._updatedAt = Date.now();

    this.notifyStateChange();
    return true;
  }

  // 開始遊戲
  startGame(): boolean {
    if (!this.canStart) {
      return false;
    }

    // 分配角色
    this.assignRoles();

    // 開始遊戲
    this._gameState.startGame();
    this._updatedAt = Date.now();

    this.notifyPhaseChange(this._gameState.phase);
    return true;
  }

  // 分配角色
  private assignRoles(): void {
    const roleIds = Object.keys(ROLES);
    const shuffledRoles = [...roleIds].sort(() => Math.random() - 0.5);

    let roleIndex = 0;
    for (const player of this._players.values()) {
      const roleId = shuffledRoles[roleIndex % shuffledRoles.length];
      player.assignRole(roleId);
      roleIndex++;
    }
  }

  // 處理遊戲行動
  processAction(action: GameAction): ActionResult {
    if (this._gameState.phase !== GamePhase.DEBATE) {
      return {
        success: false,
        action,
        message: '只能在辯論階段執行行動',
      };
    }

    const result = GameEngine.processAction(action, this._players);

    if (result.success) {
      this._gameState.recordAction(result);
      this._updatedAt = Date.now();
      this.notifyStateChange();
    }

    return result;
  }

  // 處理投票
  processVote(playerId: string, optionId: string): boolean {
    if (this._gameState.phase !== GamePhase.VOTING) {
      return false;
    }

    const player = this._players.get(playerId);
    if (!player) {
      return false;
    }

    const weight = player.getVoteWeight();
    this._gameState.recordVote(playerId, optionId, weight);
    this._updatedAt = Date.now();

    this.notifyStateChange();
    return true;
  }

  // 發送訊息
  sendMessage(
    senderId: string,
    content: string,
    type: MessageType = MessageType.PUBLIC,
    targetId?: string
  ): GameMessage | null {
    const sender = this._players.get(senderId);
    if (!sender) {
      return null;
    }

    // 密謀階段才能發私訊
    if (type === MessageType.PRIVATE && this._gameState.phase !== GamePhase.CONSPIRACY) {
      return null;
    }

    // 被沉默不能發言（系統訊息除外）
    if (sender.silenced && type !== MessageType.SYSTEM) {
      return null;
    }

    const message: GameMessage = {
      id: uuidv4(),
      type,
      senderId,
      senderName: sender.name,
      content,
      targetId,
      timestamp: Date.now(),
    };

    this._gameState.addMessage(message);
    this._updatedAt = Date.now();

    return message;
  }

  // 處理階段結束
  private handlePhaseEnd(): void {
    const currentPhase = this._gameState.phase;

    // 如果是投票階段結束，計算結果
    if (currentPhase === GamePhase.VOTING) {
      this.processVotingResults();
    }

    // 如果是結算階段結束，檢查遊戲是否結束
    if (currentPhase === GamePhase.RESULT) {
      // MVP 版本只進行一回合
      this.endGame();
      return;
    }

    // 轉換到下一階段
    const nextPhase = this._gameState.getNextPhase();
    this._gameState.transitionToPhase(nextPhase);

    // 辯論階段開始時重置玩家狀態
    if (nextPhase === GamePhase.DEBATE) {
      for (const player of this._players.values()) {
        player.resetTurnState();
      }
    }

    this.notifyPhaseChange(nextPhase);
  }

  // 處理投票結果
  private processVotingResults(): void {
    const winningOption = this._gameState.getWinningOption();

    if (winningOption && this._gameState.currentBill) {
      const option = this._gameState.currentBill.getOption(winningOption.optionId);

      if (option) {
        // 給獲勝陣營加分
        for (const player of this._players.values()) {
          if (player.faction === option.benefitFaction) {
            player.favor += option.points;
          }
        }

        // 發送系統訊息
        this.sendMessage(
          'system',
          `投票結束！${option.text} 獲得通過，${option.benefitFaction} 陣營獲得 ${option.points} 聲望`,
          MessageType.SYSTEM
        );
      }
    }
  }

  // 結束遊戲
  private endGame(): void {
    // 計算各陣營分數
    const factionScores = new Map<string, number>();

    for (const player of this._players.values()) {
      if (player.faction) {
        const current = factionScores.get(player.faction) || 0;
        factionScores.set(player.faction, current + player.favor + player.reputation);
      }
    }

    // 找出獲勝陣營
    let winningFaction = '';
    let highestScore = 0;

    for (const [faction, score] of factionScores) {
      if (score > highestScore) {
        highestScore = score;
        winningFaction = faction;
      }
    }

    const results = {
      winningFaction,
      factionScores: Object.fromEntries(factionScores),
      players: Array.from(this._players.values()).map(p => ({
        id: p.id,
        name: p.name,
        roleId: p.roleId,
        faction: p.faction,
        reputation: p.reputation,
        favor: p.favor,
        isAlive: p.isAlive,
      })),
    };

    if (this._onGameEnd) {
      this._onGameEnd(this, results);
    }

    // 重置遊戲狀態
    this._gameState.reset();
  }

  // 通知狀態變化
  private notifyStateChange(): void {
    if (this._onStateChange) {
      this._onStateChange(this);
    }
  }

  // 通知階段變化
  private notifyPhaseChange(phase: GamePhase): void {
    if (this._onPhaseChange) {
      this._onPhaseChange(this, phase);
    }
  }

  // 檢查房間是否超時
  isExpired(): boolean {
    const timeoutMs = ROOM_CONFIG.TIMEOUT_MINUTES * 60 * 1000;
    return Date.now() - this._updatedAt > timeoutMs;
  }

  // 轉換為可傳輸的資料
  toJSON(): RoomData {
    return {
      id: this.id,
      code: this.code,
      hostId: this._hostId,
      players: Array.from(this._players.values()).map(p => p.toJSON()),
      gameState: this._gameState.toJSON(),
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // 轉換為公開資料（隱藏敏感資訊）
  toPublicJSON(): Partial<RoomData> {
    return {
      id: this.id,
      code: this.code,
      hostId: this._hostId,
      players: Array.from(this._players.values()).map(p => p.toPublicJSON() as PlayerData),
      gameState: this._gameState.toJSON(),
    };
  }
}

// 房間管理器
export class RoomManager {
  private static _rooms: Map<string, GameRoom> = new Map();
  private static _roomsByCode: Map<string, string> = new Map(); // code -> roomId
  private static _cleanupInterval: NodeJS.Timeout | null = null;

  static createRoom(hostId: string, hostName: string): GameRoom {
    const room = new GameRoom(hostId, hostName);
    this._rooms.set(room.id, room);
    this._roomsByCode.set(room.code, room.id);

    // 啟動清理定時器
    if (!this._cleanupInterval) {
      this._cleanupInterval = setInterval(() => this.cleanup(), 60000);
    }

    return room;
  }

  static getRoom(roomId: string): GameRoom | null {
    return this._rooms.get(roomId) || null;
  }

  static getRoomByCode(code: string): GameRoom | null {
    const roomId = this._roomsByCode.get(code.toUpperCase());
    if (!roomId) return null;
    return this._rooms.get(roomId) || null;
  }

  static deleteRoom(roomId: string): boolean {
    const room = this._rooms.get(roomId);
    if (!room) return false;

    this._roomsByCode.delete(room.code);
    this._rooms.delete(roomId);
    return true;
  }

  static cleanup(): void {
    for (const [roomId, room] of this._rooms) {
      if (room.isExpired() || room.playerCount === 0) {
        this.deleteRoom(roomId);
        console.log(`Room ${room.code} cleaned up`);
      }
    }
  }

  static getRoomCount(): number {
    return this._rooms.size;
  }

  static getAllRooms(): GameRoom[] {
    return Array.from(this._rooms.values());
  }
}
