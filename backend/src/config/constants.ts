/**
 * Game Constants
 * 遊戲常數設定
 */

// 遊戲階段時長（秒）
export const PHASE_DURATIONS = {
  CONSPIRACY: 120,  // 密謀階段 2 分鐘
  DEBATE: 300,      // 辯論階段 5 分鐘
  EVENT: 60,        // 事件階段 1 分鐘
  VOTING: 60,       // 投票階段 1 分鐘
  RESULT: 30,       // 結算階段 30 秒
} as const;

// 遊戲階段
export enum GamePhase {
  WAITING = 'waiting',
  CONSPIRACY = 'conspiracy',
  DEBATE = 'debate',
  EVENT = 'event',
  VOTING = 'voting',
  RESULT = 'result',
}

// 陣營類型
export enum Faction {
  WORKER = 'worker',
  FACTORY = 'factory',
  REFORM = 'reform',
  CROWN = 'crown',
}

// 陣營克制關係：Worker > Factory > Reform > Worker (+30% 傷害)
export const FACTION_COUNTERS: Record<Faction, Faction> = {
  [Faction.WORKER]: Faction.FACTORY,
  [Faction.FACTORY]: Faction.REFORM,
  [Faction.REFORM]: Faction.WORKER,
  [Faction.CROWN]: Faction.CROWN, // 皇室不受克制
};

// 傷害加成
export const FACTION_BONUS = 1.3; // 克制時 +30% 傷害

// 戰鬥常數
export const COMBAT = {
  QUERY_COST: 10,         // 質詢消耗聲望
  QUERY_DAMAGE: 15,       // 質詢基礎傷害
  REBUT_COST: 5,          // 反駁消耗聲望
  REBUT_REDUCTION: 0.5,   // 反駁減傷 50%
  MIN_REPUTATION: 0,      // 最低聲望（政治死亡）
  MAX_REPUTATION: 100,    // 最高聲望
} as const;

// 投票權重
export const VOTE_WEIGHTS = {
  HIGH: { threshold: 80, weight: 1.5 },      // 聲望 > 80: 1.5 倍
  NORMAL: { threshold: 50, weight: 1.0 },    // 聲望 50-80: 1.0 倍
  LOW: { threshold: 30, weight: 0.7 },       // 聲望 30-50: 0.7 倍
  VERY_LOW: { threshold: 0, weight: 0.5 },   // 聲望 < 30: 0.5 倍
  DEAD: 0,                                    // 政治死亡: 0 倍
} as const;

// 角色資料
export interface RoleData {
  id: string;
  name: string;
  nameEn: string;
  faction: Faction;
  initialReputation: number;
  skillName: string;
  skillDescription: string;
  rhetoric: number;  // 口才加成
  intel: number;     // 情報加成
}

export const ROLES: Record<string, RoleData> = {
  worker: {
    id: 'worker',
    name: '工人湯瑪斯',
    nameEn: 'Thomas the Worker',
    faction: Faction.WORKER,
    initialReputation: 70,
    skillName: '團結',
    skillDescription: '每有 1 名工人盟友，防禦 +10',
    rhetoric: 1.0,
    intel: 0.8,
  },
  factory: {
    id: 'factory',
    name: '工廠主理查',
    nameEn: 'Richard the Factory Owner',
    faction: Faction.FACTORY,
    initialReputation: 60,
    skillName: '收買',
    skillDescription: '花費金幣使目標沉默 1 回合',
    rhetoric: 1.1,
    intel: 1.2,
  },
  journalist: {
    id: 'journalist',
    name: '記者愛德華',
    nameEn: 'Edward the Journalist',
    faction: Faction.REFORM,
    initialReputation: 50,
    skillName: '爆料',
    skillDescription: '揭露目標的秘密任務',
    rhetoric: 1.2,
    intel: 1.5,
  },
  luddite: {
    id: 'luddite',
    name: '盧德派喬治',
    nameEn: 'George the Luddite',
    faction: Faction.WORKER,
    initialReputation: 80,
    skillName: '怒火',
    skillDescription: '造成雙倍傷害，但自己也扣 10 聲望',
    rhetoric: 0.9,
    intel: 0.7,
  },
};

// 議案資料
export interface BillOption {
  id: string;
  text: string;
  description: string;
  benefitFaction: Faction;
  points: number;
}

export interface BillData {
  id: string;
  name: string;
  description: string;
  options: BillOption[];
}

export const BILLS: Record<string, BillData> = {
  machine_act: {
    id: 'machine_act',
    name: '機器法案',
    description: '關於工廠機器使用的法規提案',
    options: [
      {
        id: 'ban_machines',
        text: 'A. 禁止機器',
        description: '全面禁止工廠使用自動化機器',
        benefitFaction: Faction.WORKER,
        points: 50,
      },
      {
        id: 'protect_property',
        text: 'B. 保護財產',
        description: '保護工廠主的財產權和機器投資',
        benefitFaction: Faction.FACTORY,
        points: 50,
      },
      {
        id: 'compromise_reform',
        text: 'C. 折衷改革',
        description: '逐步引入機器，同時保障工人權益',
        benefitFaction: Faction.REFORM,
        points: 30,
      },
    ],
  },
};

// 房間設定
export const ROOM_CONFIG = {
  MIN_PLAYERS: parseInt(process.env.MIN_PLAYERS || '4', 10),
  MAX_PLAYERS: parseInt(process.env.MAX_PLAYERS || '8', 10),
  TIMEOUT_MINUTES: parseInt(process.env.ROOM_TIMEOUT_MINUTES || '30', 10),
  CODE_LENGTH: 6,
} as const;
