/**
 * Game Actions
 * 遊戲行動類型定義
 */

// 行動類型
export enum ActionType {
  QUERY = 'query',       // 質詢（攻擊）
  REBUT = 'rebut',       // 反駁（防禦）
  SKILL = 'skill',       // 使用技能
  PASS = 'pass',         // 跳過
}

// 基礎行動介面
export interface BaseAction {
  type: ActionType;
  playerId: string;
  timestamp: number;
}

// 質詢行動
export interface QueryAction extends BaseAction {
  type: ActionType.QUERY;
  targetId: string;
}

// 反駁行動
export interface RebutAction extends BaseAction {
  type: ActionType.REBUT;
}

// 技能行動
export interface SkillAction extends BaseAction {
  type: ActionType.SKILL;
  targetId?: string;
  params?: Record<string, unknown>;
}

// 跳過行動
export interface PassAction extends BaseAction {
  type: ActionType.PASS;
}

// 聯合類型
export type GameAction = QueryAction | RebutAction | SkillAction | PassAction;

// 行動結果
export interface ActionResult {
  success: boolean;
  action: GameAction;
  damage?: number;
  message: string;
  affectedPlayers?: string[];
}

// 投票
export interface Vote {
  playerId: string;
  optionId: string;
  weight: number;
  timestamp: number;
}

// 投票結果
export interface VoteResult {
  optionId: string;
  optionText: string;
  totalWeight: number;
  voterIds: string[];
}

// 訊息類型
export enum MessageType {
  PUBLIC = 'public',
  PRIVATE = 'private',
  SYSTEM = 'system',
  FACTION = 'faction',
}

// 遊戲訊息
export interface GameMessage {
  id: string;
  type: MessageType;
  senderId: string;
  senderName: string;
  content: string;
  targetId?: string;
  timestamp: number;
}

// 創建行動的工廠函數
export function createQueryAction(playerId: string, targetId: string): QueryAction {
  return {
    type: ActionType.QUERY,
    playerId,
    targetId,
    timestamp: Date.now(),
  };
}

export function createRebutAction(playerId: string): RebutAction {
  return {
    type: ActionType.REBUT,
    playerId,
    timestamp: Date.now(),
  };
}

export function createSkillAction(
  playerId: string,
  targetId?: string,
  params?: Record<string, unknown>
): SkillAction {
  return {
    type: ActionType.SKILL,
    playerId,
    targetId,
    params,
    timestamp: Date.now(),
  };
}

export function createPassAction(playerId: string): PassAction {
  return {
    type: ActionType.PASS,
    playerId,
    timestamp: Date.now(),
  };
}
