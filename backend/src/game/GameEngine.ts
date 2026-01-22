/**
 * GameEngine
 * 戰鬥與傷害計算引擎
 */

import {
  COMBAT,
  FACTION_COUNTERS,
  FACTION_BONUS,
  Faction,
} from '../config/constants';
import { Player } from '../models/Player';
import {
  GameAction,
  ActionType,
  ActionResult,
  QueryAction,
  RebutAction,
  SkillAction,
} from './actions';

export class GameEngine {
  /**
   * 計算傷害
   * 公式: baseDamage × rhetoricMultiplier × intelBonus × factionMultiplier - defenseReduction
   */
  static calculateDamage(
    attacker: Player,
    defender: Player,
    baseDamage: number = COMBAT.QUERY_DAMAGE
  ): number {
    // 口才加成
    const rhetoricMultiplier = attacker.role?.rhetoric || 1.0;

    // 情報加成 (每點情報 +5%)
    const intelBonus = 1 + (attacker.intel * 0.05);

    // 陣營克制加成
    let factionMultiplier = 1.0;
    if (attacker.faction && defender.faction) {
      const counters = FACTION_COUNTERS[attacker.faction];
      if (counters === defender.faction) {
        factionMultiplier = FACTION_BONUS;
      }
    }

    // 計算基礎傷害
    let damage = baseDamage * rhetoricMultiplier * intelBonus * factionMultiplier;

    // 防禦減免
    if (defender.isDefending) {
      damage *= COMBAT.REBUT_REDUCTION;
    }

    return Math.floor(damage);
  }

  /**
   * 執行質詢行動
   */
  static executeQuery(
    attacker: Player,
    defender: Player,
    players: Map<string, Player>
  ): ActionResult {
    // 檢查攻擊者是否存活
    if (!attacker.isAlive) {
      return {
        success: false,
        action: { type: ActionType.QUERY, playerId: attacker.id, targetId: defender.id, timestamp: Date.now() },
        message: '政治死亡者無法發起質詢',
      };
    }

    // 檢查攻擊者是否被沉默
    if (attacker.silenced) {
      return {
        success: false,
        action: { type: ActionType.QUERY, playerId: attacker.id, targetId: defender.id, timestamp: Date.now() },
        message: '你已被沉默，無法發言',
      };
    }

    // 檢查聲望是否足夠
    if (attacker.reputation < COMBAT.QUERY_COST) {
      return {
        success: false,
        action: { type: ActionType.QUERY, playerId: attacker.id, targetId: defender.id, timestamp: Date.now() },
        message: '聲望不足，無法發起質詢',
      };
    }

    // 消耗聲望
    attacker.spendReputation(COMBAT.QUERY_COST);

    // 計算傷害
    const damage = this.calculateDamage(attacker, defender);

    // 造成傷害
    const actualDamage = defender.takeDamage(damage);

    const action: QueryAction = {
      type: ActionType.QUERY,
      playerId: attacker.id,
      targetId: defender.id,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      damage: actualDamage,
      message: `${attacker.name} 對 ${defender.name} 發起質詢，造成 ${actualDamage} 點聲望傷害`,
      affectedPlayers: [attacker.id, defender.id],
    };
  }

  /**
   * 執行反駁行動
   */
  static executeRebut(player: Player): ActionResult {
    // 檢查是否存活
    if (!player.isAlive) {
      return {
        success: false,
        action: { type: ActionType.REBUT, playerId: player.id, timestamp: Date.now() },
        message: '政治死亡者無法反駁',
      };
    }

    // 檢查是否被沉默
    if (player.silenced) {
      return {
        success: false,
        action: { type: ActionType.REBUT, playerId: player.id, timestamp: Date.now() },
        message: '你已被沉默，無法反駁',
      };
    }

    // 檢查聲望是否足夠
    if (player.reputation < COMBAT.REBUT_COST) {
      return {
        success: false,
        action: { type: ActionType.REBUT, playerId: player.id, timestamp: Date.now() },
        message: '聲望不足，無法反駁',
      };
    }

    // 消耗聲望並進入防禦狀態
    player.spendReputation(COMBAT.REBUT_COST);
    player.setDefending(true);

    const action: RebutAction = {
      type: ActionType.REBUT,
      playerId: player.id,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      message: `${player.name} 進入反駁姿態，下次受到的傷害減半`,
      affectedPlayers: [player.id],
    };
  }

  /**
   * 執行技能
   */
  static executeSkill(
    player: Player,
    targetId: string | undefined,
    players: Map<string, Player>
  ): ActionResult {
    if (!player.isAlive) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '政治死亡者無法使用技能',
      };
    }

    if (player.silenced) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '你已被沉默，無法使用技能',
      };
    }

    const role = player.role;
    if (!role) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '未分配角色',
      };
    }

    // 根據角色執行不同技能
    switch (role.id) {
      case 'worker':
        return this.executeWorkerSkill(player, players);
      case 'factory':
        return this.executeFactorySkill(player, targetId, players);
      case 'journalist':
        return this.executeJournalistSkill(player, targetId, players);
      case 'luddite':
        return this.executeLudditeSkill(player, targetId, players);
      default:
        return {
          success: false,
          action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
          message: '未知技能',
        };
    }
  }

  /**
   * 工人技能：團結 - 每有 1 名工人盟友，防禦 +10
   */
  private static executeWorkerSkill(
    player: Player,
    players: Map<string, Player>
  ): ActionResult {
    // 計算工人盟友數量
    let allyCount = 0;
    for (const p of players.values()) {
      if (p.id !== player.id && p.isAlive && p.faction === Faction.WORKER) {
        allyCount++;
      }
    }

    // 增加防禦（透過暫時提升聲望模擬）
    const bonusDefense = allyCount * 10;
    player.setDefending(true);

    const action: SkillAction = {
      type: ActionType.SKILL,
      playerId: player.id,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      message: `${player.name} 發動【團結】！${allyCount} 名工人盟友提供 +${bonusDefense} 防禦`,
      affectedPlayers: [player.id],
    };
  }

  /**
   * 工廠主技能：收買 - 花費金幣使目標沉默 1 回合
   */
  private static executeFactorySkill(
    player: Player,
    targetId: string | undefined,
    players: Map<string, Player>
  ): ActionResult {
    if (!targetId) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '請選擇收買目標',
      };
    }

    const target = players.get(targetId);
    if (!target) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '目標不存在',
      };
    }

    // 檢查金幣
    if (player.gold < 1) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '金幣不足',
      };
    }

    player.gold--;
    target.setSilenced(true);

    const action: SkillAction = {
      type: ActionType.SKILL,
      playerId: player.id,
      targetId,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      message: `${player.name} 使用【收買】使 ${target.name} 沉默一回合`,
      affectedPlayers: [player.id, targetId],
    };
  }

  /**
   * 記者技能：爆料 - 揭露目標的秘密任務
   */
  private static executeJournalistSkill(
    player: Player,
    targetId: string | undefined,
    players: Map<string, Player>
  ): ActionResult {
    if (!targetId) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '請選擇爆料目標',
      };
    }

    const target = players.get(targetId);
    if (!target) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '目標不存在',
      };
    }

    // 揭露目標角色
    const targetRole = target.role;

    const action: SkillAction = {
      type: ActionType.SKILL,
      playerId: player.id,
      targetId,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      message: `${player.name} 使用【爆料】揭露 ${target.name} 的身份：${targetRole?.name || '未知'}`,
      affectedPlayers: [player.id, targetId],
    };
  }

  /**
   * 盧德派技能：怒火 - 造成雙倍傷害，但自己也扣 10 聲望
   */
  private static executeLudditeSkill(
    player: Player,
    targetId: string | undefined,
    players: Map<string, Player>
  ): ActionResult {
    if (!targetId) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '請選擇攻擊目標',
      };
    }

    const target = players.get(targetId);
    if (!target) {
      return {
        success: false,
        action: { type: ActionType.SKILL, playerId: player.id, timestamp: Date.now() },
        message: '目標不存在',
      };
    }

    // 計算雙倍傷害
    const damage = this.calculateDamage(player, target, COMBAT.QUERY_DAMAGE * 2);

    // 造成傷害
    const actualDamage = target.takeDamage(damage);

    // 自己也扣 10 聲望
    player.spendReputation(10);

    const action: SkillAction = {
      type: ActionType.SKILL,
      playerId: player.id,
      targetId,
      timestamp: Date.now(),
    };

    return {
      success: true,
      action,
      damage: actualDamage,
      message: `${player.name} 發動【怒火】！對 ${target.name} 造成 ${actualDamage} 點傷害，自己損失 10 聲望`,
      affectedPlayers: [player.id, targetId],
    };
  }

  /**
   * 處理遊戲行動
   */
  static processAction(
    action: GameAction,
    players: Map<string, Player>
  ): ActionResult {
    const player = players.get(action.playerId);
    if (!player) {
      return {
        success: false,
        action,
        message: '玩家不存在',
      };
    }

    switch (action.type) {
      case ActionType.QUERY: {
        const queryAction = action as QueryAction;
        const target = players.get(queryAction.targetId);
        if (!target) {
          return {
            success: false,
            action,
            message: '目標玩家不存在',
          };
        }
        return this.executeQuery(player, target, players);
      }

      case ActionType.REBUT:
        return this.executeRebut(player);

      case ActionType.SKILL: {
        const skillAction = action as SkillAction;
        return this.executeSkill(player, skillAction.targetId, players);
      }

      case ActionType.PASS:
        return {
          success: true,
          action,
          message: `${player.name} 選擇觀望`,
          affectedPlayers: [player.id],
        };

      default:
        return {
          success: false,
          action,
          message: '未知行動類型',
        };
    }
  }
}
