/**
 * Bill Model
 * 議案資料模型
 */

import { BillData, BillOption, BILLS, Faction } from '../config/constants';

export class Bill {
  readonly id: string;
  readonly name: string;
  readonly description: string;
  readonly options: BillOption[];

  constructor(data: BillData) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.options = data.options;
  }

  static getById(id: string): Bill | null {
    const data = BILLS[id];
    if (!data) return null;
    return new Bill(data);
  }

  static getAll(): Bill[] {
    return Object.values(BILLS).map(data => new Bill(data));
  }

  static getRandom(): Bill {
    const bills = Object.values(BILLS);
    const randomIndex = Math.floor(Math.random() * bills.length);
    return new Bill(bills[randomIndex]);
  }

  getOption(optionId: string): BillOption | null {
    return this.options.find(opt => opt.id === optionId) || null;
  }

  getOptionsByFaction(faction: Faction): BillOption[] {
    return this.options.filter(opt => opt.benefitFaction === faction);
  }

  toJSON(): BillData {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      options: this.options,
    };
  }
}
