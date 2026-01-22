/**
 * Player Model
 * 玩家資料模型
 */

import { Faction, COMBAT } from '../config/constants';
import { Role } from './Role';

export interface PlayerData {
  id: string;
  name: string;
  roomId: string;
  roleId: string | null;
  reputation: number;
  gold: number;
  intel: number;
  favor: number;
  isReady: boolean;
  isHost: boolean;
  isAlive: boolean;
  silenced: boolean;
  protectedBy: string | null;
}

export class Player {
  readonly id: string;
  name: string;
  roomId: string;
  roleId: string | null;
  reputation: number;
  gold: number;
  intel: number;
  favor: number;
  isReady: boolean;
  isHost: boolean;
  isAlive: boolean;
  silenced: boolean;
  protectedBy: string | null;

  private _role: Role | null = null;
  private _isDefending: boolean = false;

  constructor(id: string, name: string, roomId: string, isHost: boolean = false) {
    this.id = id;
    this.name = name;
    this.roomId = roomId;
    this.roleId = null;
    this.reputation = 50;
    this.gold = 0;
    this.intel = 0;
    this.favor = 0;
    this.isReady = false;
    this.isHost = isHost;
    this.isAlive = true;
    this.silenced = false;
    this.protectedBy = null;
  }

  get role(): Role | null {
    if (!this._role && this.roleId) {
      this._role = Role.getById(this.roleId);
    }
    return this._role;
  }

  get faction(): Faction | null {
    return this.role?.faction || null;
  }

  get isDefending(): boolean {
    return this._isDefending;
  }

  assignRole(roleId: string): void {
    const role = Role.getById(roleId);
    if (!role) {
      throw new Error(`Role not found: ${roleId}`);
    }
    this.roleId = roleId;
    this._role = role;
    this.reputation = role.initialReputation;
  }

  // 受到傷害
  takeDamage(amount: number): number {
    const actualDamage = this._isDefending
      ? Math.floor(amount * COMBAT.REBUT_REDUCTION)
      : amount;

    this.reputation = Math.max(
      COMBAT.MIN_REPUTATION,
      this.reputation - actualDamage
    );

    // 檢查政治死亡
    if (this.reputation <= 0) {
      this.isAlive = false;
    }

    return actualDamage;
  }

  // 恢復聲望
  heal(amount: number): void {
    this.reputation = Math.min(
      COMBAT.MAX_REPUTATION,
      this.reputation + amount
    );
  }

  // 消耗聲望（用於攻擊、技能等）
  spendReputation(amount: number): boolean {
    if (this.reputation < amount) {
      return false;
    }
    this.reputation -= amount;

    if (this.reputation <= 0) {
      this.isAlive = false;
    }

    return true;
  }

  // 設置防禦狀態
  setDefending(defending: boolean): void {
    this._isDefending = defending;
  }

  // 沉默效果
  setSilenced(silenced: boolean): void {
    this.silenced = silenced;
  }

  // 重置回合狀態
  resetTurnState(): void {
    this._isDefending = false;
    this.silenced = false;
    this.protectedBy = null;
  }

  // 計算投票權重
  getVoteWeight(): number {
    if (!this.isAlive) return 0;
    if (this.reputation > 80) return 1.5;
    if (this.reputation >= 50) return 1.0;
    if (this.reputation >= 30) return 0.7;
    return 0.5;
  }

  // 轉換為可傳輸的資料格式
  toJSON(): PlayerData {
    return {
      id: this.id,
      name: this.name,
      roomId: this.roomId,
      roleId: this.roleId,
      reputation: this.reputation,
      gold: this.gold,
      intel: this.intel,
      favor: this.favor,
      isReady: this.isReady,
      isHost: this.isHost,
      isAlive: this.isAlive,
      silenced: this.silenced,
      protectedBy: this.protectedBy,
    };
  }

  // 轉換為公開可見的資料（隱藏敏感資訊）
  toPublicJSON(): Partial<PlayerData> {
    return {
      id: this.id,
      name: this.name,
      reputation: this.reputation,
      isReady: this.isReady,
      isHost: this.isHost,
      isAlive: this.isAlive,
      silenced: this.silenced,
    };
  }

  // 從資料恢復
  static fromJSON(data: PlayerData): Player {
    const player = new Player(data.id, data.name, data.roomId, data.isHost);
    player.roleId = data.roleId;
    player.reputation = data.reputation;
    player.gold = data.gold;
    player.intel = data.intel;
    player.favor = data.favor;
    player.isReady = data.isReady;
    player.isAlive = data.isAlive;
    player.silenced = data.silenced;
    player.protectedBy = data.protectedBy;
    return player;
  }
}
