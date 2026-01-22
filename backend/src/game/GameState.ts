/**
 * GameState
 * 遊戲狀態管理
 */

import { GamePhase, PHASE_DURATIONS } from '../config/constants';
import { Player, PlayerData } from '../models/Player';
import { Bill } from '../models/Bill';
import { GameAction, ActionResult, Vote, VoteResult, GameMessage } from './actions';

export interface GameStateData {
  phase: GamePhase;
  round: number;
  timeRemaining: number;
  currentBillId: string | null;
  votes: Record<string, string>;
  messages: GameMessage[];
  actionHistory: ActionResult[];
}

export class GameState {
  private _phase: GamePhase;
  private _round: number;
  private _timeRemaining: number;
  private _currentBill: Bill | null;
  private _votes: Map<string, Vote>;
  private _messages: GameMessage[];
  private _actionHistory: ActionResult[];
  private _phaseTimer: NodeJS.Timeout | null;
  private _onPhaseEnd: (() => void) | null;

  constructor() {
    this._phase = GamePhase.WAITING;
    this._round = 0;
    this._timeRemaining = 0;
    this._currentBill = null;
    this._votes = new Map();
    this._messages = [];
    this._actionHistory = [];
    this._phaseTimer = null;
    this._onPhaseEnd = null;
  }

  get phase(): GamePhase {
    return this._phase;
  }

  get round(): number {
    return this._round;
  }

  get timeRemaining(): number {
    return this._timeRemaining;
  }

  get currentBill(): Bill | null {
    return this._currentBill;
  }

  get votes(): Map<string, Vote> {
    return this._votes;
  }

  get messages(): GameMessage[] {
    return this._messages;
  }

  get actionHistory(): ActionResult[] {
    return this._actionHistory;
  }

  // 開始遊戲
  startGame(): void {
    this._round = 1;
    this._currentBill = Bill.getRandom();
    this.transitionToPhase(GamePhase.CONSPIRACY);
  }

  // 階段轉換
  transitionToPhase(newPhase: GamePhase): void {
    // 清除現有計時器
    if (this._phaseTimer) {
      clearInterval(this._phaseTimer);
      this._phaseTimer = null;
    }

    this._phase = newPhase;

    // 設定階段時間
    switch (newPhase) {
      case GamePhase.CONSPIRACY:
        this._timeRemaining = PHASE_DURATIONS.CONSPIRACY;
        break;
      case GamePhase.DEBATE:
        this._timeRemaining = PHASE_DURATIONS.DEBATE;
        break;
      case GamePhase.EVENT:
        this._timeRemaining = PHASE_DURATIONS.EVENT;
        break;
      case GamePhase.VOTING:
        this._timeRemaining = PHASE_DURATIONS.VOTING;
        this._votes.clear(); // 清除上回合投票
        break;
      case GamePhase.RESULT:
        this._timeRemaining = PHASE_DURATIONS.RESULT;
        break;
      default:
        this._timeRemaining = 0;
    }

    // 啟動計時器
    if (this._timeRemaining > 0) {
      this._phaseTimer = setInterval(() => {
        this._timeRemaining--;
        if (this._timeRemaining <= 0) {
          this.endPhase();
        }
      }, 1000);
    }
  }

  // 結束當前階段
  private endPhase(): void {
    if (this._phaseTimer) {
      clearInterval(this._phaseTimer);
      this._phaseTimer = null;
    }

    if (this._onPhaseEnd) {
      this._onPhaseEnd();
    }
  }

  // 設置階段結束回調
  setOnPhaseEnd(callback: () => void): void {
    this._onPhaseEnd = callback;
  }

  // 下一個階段
  getNextPhase(): GamePhase {
    switch (this._phase) {
      case GamePhase.CONSPIRACY:
        return GamePhase.DEBATE;
      case GamePhase.DEBATE:
        return GamePhase.EVENT;
      case GamePhase.EVENT:
        return GamePhase.VOTING;
      case GamePhase.VOTING:
        return GamePhase.RESULT;
      case GamePhase.RESULT:
        return GamePhase.CONSPIRACY; // 下一回合
      default:
        return GamePhase.WAITING;
    }
  }

  // 記錄行動結果
  recordAction(result: ActionResult): void {
    this._actionHistory.push(result);
  }

  // 記錄投票
  recordVote(playerId: string, optionId: string, weight: number): void {
    this._votes.set(playerId, {
      playerId,
      optionId,
      weight,
      timestamp: Date.now(),
    });
  }

  // 計算投票結果
  calculateVoteResults(): VoteResult[] {
    const results = new Map<string, VoteResult>();

    // 初始化選項
    if (this._currentBill) {
      for (const option of this._currentBill.options) {
        results.set(option.id, {
          optionId: option.id,
          optionText: option.text,
          totalWeight: 0,
          voterIds: [],
        });
      }
    }

    // 統計投票
    for (const vote of this._votes.values()) {
      const result = results.get(vote.optionId);
      if (result) {
        result.totalWeight += vote.weight;
        result.voterIds.push(vote.playerId);
      }
    }

    return Array.from(results.values()).sort(
      (a, b) => b.totalWeight - a.totalWeight
    );
  }

  // 獲取獲勝選項
  getWinningOption(): VoteResult | null {
    const results = this.calculateVoteResults();
    return results.length > 0 ? results[0] : null;
  }

  // 添加訊息
  addMessage(message: GameMessage): void {
    this._messages.push(message);
    // 限制訊息數量
    if (this._messages.length > 100) {
      this._messages.shift();
    }
  }

  // 進入下一回合
  nextRound(): void {
    this._round++;
    this._currentBill = Bill.getRandom();
    this._votes.clear();
    this._actionHistory = [];
  }

  // 重置狀態
  reset(): void {
    if (this._phaseTimer) {
      clearInterval(this._phaseTimer);
      this._phaseTimer = null;
    }
    this._phase = GamePhase.WAITING;
    this._round = 0;
    this._timeRemaining = 0;
    this._currentBill = null;
    this._votes.clear();
    this._messages = [];
    this._actionHistory = [];
  }

  // 轉換為可傳輸的資料
  toJSON(): GameStateData {
    const votes: Record<string, string> = {};
    for (const [playerId, vote] of this._votes) {
      votes[playerId] = vote.optionId;
    }

    return {
      phase: this._phase,
      round: this._round,
      timeRemaining: this._timeRemaining,
      currentBillId: this._currentBill?.id || null,
      votes,
      messages: this._messages,
      actionHistory: this._actionHistory,
    };
  }
}
