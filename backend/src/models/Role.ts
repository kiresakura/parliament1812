/**
 * Role Model
 * 角色資料模型
 */

import { Faction, RoleData, ROLES } from '../config/constants';

export class Role {
  readonly id: string;
  readonly name: string;
  readonly nameEn: string;
  readonly faction: Faction;
  readonly initialReputation: number;
  readonly skillName: string;
  readonly skillDescription: string;
  readonly rhetoric: number;
  readonly intel: number;

  constructor(data: RoleData) {
    this.id = data.id;
    this.name = data.name;
    this.nameEn = data.nameEn;
    this.faction = data.faction;
    this.initialReputation = data.initialReputation;
    this.skillName = data.skillName;
    this.skillDescription = data.skillDescription;
    this.rhetoric = data.rhetoric;
    this.intel = data.intel;
  }

  static getById(id: string): Role | null {
    const data = ROLES[id];
    if (!data) return null;
    return new Role(data);
  }

  static getAll(): Role[] {
    return Object.values(ROLES).map(data => new Role(data));
  }

  static getByFaction(faction: Faction): Role[] {
    return Object.values(ROLES)
      .filter(data => data.faction === faction)
      .map(data => new Role(data));
  }

  toJSON(): RoleData {
    return {
      id: this.id,
      name: this.name,
      nameEn: this.nameEn,
      faction: this.faction,
      initialReputation: this.initialReputation,
      skillName: this.skillName,
      skillDescription: this.skillDescription,
      rhetoric: this.rhetoric,
      intel: this.intel,
    };
  }
}
