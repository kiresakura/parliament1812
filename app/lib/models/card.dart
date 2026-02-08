import 'package:freezed_annotation/freezed_annotation.dart';
// Removed constants import

part 'card.freezed.dart';
part 'card.g.dart';

enum CardType {
  @JsonValue('attack')
  attack,
  
  @JsonValue('defense')
  defense,
  
  @JsonValue('control')
  control,
  
  @JsonValue('buff')
  buff,
  
  @JsonValue('intel')
  intel,
  
  @JsonValue('healing')
  healing,
  
  @JsonValue('social')
  social,
  
  @JsonValue('special')
  special,
}

@freezed
class GameCard with _$GameCard {
  const factory GameCard({
    required String id,
    required String name,
    required String description,
    required CardType type,
    required CardRarity rarity,
    required CardTargetType targetType,
    required int influenceCost,
    @Default(0) int goldCost,
    required int baseValue,
    String? roleId,  // 角色專屬卡才有
    @Default([]) List<CardEffect> effects,
    @Default({}) Map<String, dynamic> metadata,
  }) = _GameCard;

  factory GameCard.fromJson(Map<String, Object?> json) => _$GameCardFromJson(json);
}

@freezed
class CardEffect with _$CardEffect {
  const factory CardEffect({
    required CardEffectType type,
    required int value,
    String? condition,
    String? target,
    @Default({}) Map<String, dynamic> params,
  }) = _CardEffect;

  factory CardEffect.fromJson(Map<String, Object?> json) => _$CardEffectFromJson(json);
}

enum CardRarity {
  @JsonValue('N')
  normal,
  
  @JsonValue('R')
  rare,
  
  @JsonValue('SR')
  epic,
  
  @JsonValue('SSR')
  legendary,
}

enum CardTargetType {
  @JsonValue('none')
  none,          // 無目標
  
  @JsonValue('self')
  self,          // 自己
  
  @JsonValue('single')
  single,        // 單一目標
  
  @JsonValue('multiple')
  multiple,      // 多個目標
  
  @JsonValue('all')
  all,          // 所有人
  
  @JsonValue('faction')
  faction,      // 同陣營
}

enum CardEffectType {
  damage,           // 造成傷害
  heal,            // 治療
  buff,            // 增益
  debuff,          // 減益  
  control,         // 控制
  draw,            // 抽牌
  discard,         // 棄牌
  resource,        // 資源變化
  special,         // 特殊效果
}

extension CardRarityExtension on CardRarity {
  String get displayName {
    switch (this) {
      case CardRarity.normal:
        return '普通';
      case CardRarity.rare:
        return '稀有';
      case CardRarity.epic:
        return '史詩';
      case CardRarity.legendary:
        return '傳說';
    }
  }

  String get symbol {
    switch (this) {
      case CardRarity.normal:
        return 'N';
      case CardRarity.rare:
        return 'R';
      case CardRarity.epic:
        return 'SR';
      case CardRarity.legendary:
        return 'SSR';
    }
  }
}

// 卡牌資料庫
class CardDatabase {
  static final Map<String, GameCard> _cards = {
    // ============== 通用對策卡 (20張) ==============
    
    // 攻擊類 (5張)
    'A01': const GameCard(
      id: 'A01',
      name: '質詢',
      description: '指定目標聲望 -10',
      type: CardType.attack,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 10,
      effects: [
        CardEffect(type: CardEffectType.damage, value: 10),
      ],
    ),
    
    'A02': const GameCard(
      id: 'A02',
      name: '公開指控',
      description: '指定目標聲望 -15，若目標本回合說過謊則 -25',
      type: CardType.attack,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 15,
      effects: [
        CardEffect(
          type: CardEffectType.damage, 
          value: 15,
          condition: 'conditional_extra_damage',
          params: {'extra_value': 10, 'condition': 'target_lied_this_turn'},
        ),
      ],
    ),
    
    'A03': const GameCard(
      id: 'A03',
      name: '連環質詢',
      description: '對 2 名目標各造成聲望 -8',
      type: CardType.attack,
      rarity: CardRarity.rare,
      targetType: CardTargetType.multiple,
      influenceCost: 4,
      baseValue: 16,
      effects: [
        CardEffect(type: CardEffectType.damage, value: 8, target: 'multiple_2'),
      ],
    ),
    
    'A04': const GameCard(
      id: 'A04',
      name: '致命一擊',
      description: '指定目標聲望 -30，但你也損失 -10 聲望',
      type: CardType.attack,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 5,
      baseValue: 20,
      effects: [
        CardEffect(type: CardEffectType.damage, value: 30),
        CardEffect(type: CardEffectType.damage, value: 10, target: 'self'),
      ],
    ),
    
    'A05': const GameCard(
      id: 'A05',
      name: '政治暗殺',
      description: '若目標聲望 ≤30，直接使其政治死亡',
      type: CardType.attack,
      rarity: CardRarity.legendary,
      targetType: CardTargetType.single,
      influenceCost: 8,
      baseValue: 999,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1,
          condition: 'target_reputation_le_30',
          params: {'effect': 'political_death'},
        ),
      ],
    ),

    // 防禦類 (4張)
    'D01': const GameCard(
      id: 'D01',
      name: '反駁',
      description: '抵銷對你的 1 次攻擊',
      type: CardType.defense,
      rarity: CardRarity.normal,
      targetType: CardTargetType.none,
      influenceCost: 1,
      baseValue: 1,
      effects: [
        CardEffect(type: CardEffectType.special, value: 1, params: {'effect': 'counter_attack'}),
      ],
    ),
    
    'D02': const GameCard(
      id: 'D02',
      name: '強力反駁',
      description: '抵銷攻擊並反彈 5 點傷害給攻擊者',
      type: CardType.defense,
      rarity: CardRarity.rare,
      targetType: CardTargetType.none,
      influenceCost: 2,
      baseValue: 5,
      effects: [
        CardEffect(type: CardEffectType.special, value: 1, params: {'effect': 'counter_attack'}),
        CardEffect(type: CardEffectType.damage, value: 5, target: 'attacker'),
      ],
    ),
    
    'D03': const GameCard(
      id: 'D03',
      name: '鐵壁',
      description: '本回合免疫所有攻擊（在回合開始時使用）',
      type: CardType.defense,
      rarity: CardRarity.epic,
      targetType: CardTargetType.self,
      influenceCost: 3,
      baseValue: 999,
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 1, 
          params: {'effect': 'immunity', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'D04': const GameCard(
      id: 'D04',
      name: '替罪羊',
      description: '將對你的攻擊轉移給另一名玩家',
      type: CardType.defense,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'redirect_attack'},
        ),
      ],
    ),

    // 控制類 (3張)
    'C01': const GameCard(
      id: 'C01',
      name: '沉默',
      description: '目標本回合無法發言（但可打卡）',
      type: CardType.control,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'silence', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'C02': const GameCard(
      id: 'C02',
      name: '封印',
      description: '目標本回合無法使用卡牌（但可發言）',
      type: CardType.control,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 4,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'seal', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'C03': const GameCard(
      id: 'C03',
      name: '脅迫',
      description: '強制目標下次投票必須與你相同',
      type: CardType.control,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 5,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'force_vote_copy', 'duration': 'next_vote'},
        ),
      ],
    ),

    // 增益類 (3張)
    'B01': const GameCard(
      id: 'B01',
      name: '鼓舞',
      description: '指定盟友下次攻擊傷害 +10',
      type: CardType.buff,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 10,
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 10, 
          params: {'effect': 'attack_boost', 'duration': 'next_attack'},
        ),
      ],
    ),
    
    'B02': const GameCard(
      id: 'B02',
      name: '援護',
      description: '指定盟友下次受到傷害 -10',
      type: CardType.buff,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 10,
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 10, 
          params: {'effect': 'defense_boost', 'duration': 'next_damage'},
        ),
      ],
    ),
    
    'B03': const GameCard(
      id: 'B03',
      name: '號召',
      description: '所有盟友本回合攻擊傷害 +5',
      type: CardType.buff,
      rarity: CardRarity.rare,
      targetType: CardTargetType.faction,
      influenceCost: 3,
      baseValue: 5,
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 5, 
          target: 'faction',
          params: {'effect': 'attack_boost', 'duration': 'this_turn'},
        ),
      ],
    ),

    // 情報類 (3張)
    'I01': const GameCard(
      id: 'I01',
      name: '調查',
      description: '查看目標的 1 張隨機手牌',
      type: CardType.intel,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'peek_hand', 'count': 1},
        ),
      ],
    ),
    
    'I02': const GameCard(
      id: 'I02',
      name: '揭露陣營',
      description: '公開揭露目標的陣營歸屬',
      type: CardType.intel,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'reveal_faction'},
        ),
      ],
    ),
    
    'I03': const GameCard(
      id: 'I03',
      name: '揭露任務',
      description: '查看目標的秘密任務（不公開）',
      type: CardType.intel,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 5,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'peek_mission'},
        ),
      ],
    ),

    // 社交類 (2張)
    'S01': const GameCard(
      id: 'S01',
      name: '結盟',
      description: '與目標建立同盟（需對方同意）',
      type: CardType.social,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 5,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'propose_alliance'},
        ),
      ],
    ),
    
    'S02': const GameCard(
      id: 'S02',
      name: '背叛',
      description: '解除同盟，對前盟友造成聲望 -20',
      type: CardType.social,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 20,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'break_alliance'},
        ),
        CardEffect(type: CardEffectType.damage, value: 20),
      ],
    ),

    // 治療類 (2張)
    'H01': const GameCard(
      id: 'H01',
      name: '療傷',
      description: '恢復自己 10 聲望',
      type: CardType.healing,
      rarity: CardRarity.normal,
      targetType: CardTargetType.self,
      influenceCost: 2,
      baseValue: 10,
      effects: [
        CardEffect(type: CardEffectType.heal, value: 10),
      ],
    ),
    
    'H02': const GameCard(
      id: 'H02',
      name: '背書',
      description: '恢復目標 20 聲望（可復活政治死亡者）',
      type: CardType.healing,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 4,
      baseValue: 20,
      effects: [
        CardEffect(type: CardEffectType.heal, value: 20),
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'revive'},
        ),
      ],
    ),

    // 特殊類 (2張)
    'X01': const GameCard(
      id: 'X01',
      name: '賄賂',
      description: '從目標手中隨機抽取 1 張卡',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 0,
      goldCost: 20,
      baseValue: 1,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'steal_card', 'count': 1},
        ),
      ],
    ),
    
    'X02': const GameCard(
      id: 'X02',
      name: '奇蹟逆轉',
      description: '使你的聲望和目標交換',
      type: CardType.special,
      rarity: CardRarity.legendary,
      targetType: CardTargetType.single,
      influenceCost: 10,
      baseValue: 999,
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'swap_reputation'},
        ),
      ],
    ),

    // ============== 角色專屬卡 (21張) ==============

    // 工人湯瑪斯 (3張)
    'T01': const GameCard(
      id: 'T01',
      name: '工人之怒',
      description: '對資方陣營角色造成聲望 -25（對非資方僅 -10）',
      type: CardType.attack,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 4,
      baseValue: 25,
      roleId: 'thomas_worker',
      effects: [
        CardEffect(
          type: CardEffectType.damage, 
          value: 25,
          condition: 'target_faction_capital',
          params: {'default_value': 10},
        ),
      ],
    ),
    
    'T02': const GameCard(
      id: 'T02',
      name: '團結一心',
      description: '所有勞工派盟友本回合獲得：攻擊 +5、防禦 +5',
      type: CardType.buff,
      rarity: CardRarity.rare,
      targetType: CardTargetType.faction,
      influenceCost: 3,
      baseValue: 5,
      roleId: 'thomas_worker',
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 5, 
          target: 'faction_labor',
          params: {'effect': 'attack_defense_boost', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'T03': const GameCard(
      id: 'T03',
      name: '苦情牌',
      description: '犧牲 15 聲望，獲得 +6🌟 影響力',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.self,
      influenceCost: 1,
      baseValue: 6,
      roleId: 'thomas_worker',
      effects: [
        CardEffect(type: CardEffectType.damage, value: 15, target: 'self'),
        CardEffect(type: CardEffectType.resource, value: 6, params: {'type': 'influence'}),
      ],
    ),

    // 工廠主理查 (3張)
    'R01': const GameCard(
      id: 'R01',
      name: '金錢攻勢',
      description: '指定目標本回合無法發言且無法打卡',
      type: CardType.control,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 0,
      goldCost: 40,
      baseValue: 1,
      roleId: 'richard_factory',
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'silence_and_seal', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'R02': const GameCard(
      id: 'R02',
      name: '經濟威脅',
      description: '造成「你的金幣數 ÷ 10」點聲望傷害（最高 -15）',
      type: CardType.attack,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 15,
      roleId: 'richard_factory',
      effects: [
        CardEffect(
          type: CardEffectType.damage, 
          value: 1,
          params: {'calculation': 'gold_divided_by_10', 'max': 15},
        ),
      ],
    ),
    
    'R03': const GameCard(
      id: 'R03',
      name: '產業聯盟',
      description: '所有資方陣營角色（包括你）回復 8 聲望',
      type: CardType.healing,
      rarity: CardRarity.normal,
      targetType: CardTargetType.faction,
      influenceCost: 2,
      baseValue: 8,
      roleId: 'richard_factory',
      effects: [
        CardEffect(
          type: CardEffectType.heal, 
          value: 8, 
          target: 'faction_capital',
        ),
      ],
    ),

    // 盧德派喬治 (3張)  
    'G01': const GameCard(
      id: 'G01',
      name: '暴力抗議',
      description: '對目標造成聲望 -30，但你自己也損失 -15 聲望',
      type: CardType.attack,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 5,
      baseValue: 30,
      roleId: 'george_luddite',
      effects: [
        CardEffect(type: CardEffectType.damage, value: 30),
        CardEffect(type: CardEffectType.damage, value: 15, target: 'self'),
      ],
    ),
    
    'G02': const GameCard(
      id: 'G02',
      name: '煽動群眾',
      description: '本回合所有攻擊卡傷害 +10（包括你和盟友）',
      type: CardType.buff,
      rarity: CardRarity.rare,
      targetType: CardTargetType.all,
      influenceCost: 4,
      baseValue: 10,
      roleId: 'george_luddite',
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 10, 
          target: 'all',
          params: {'effect': 'global_attack_boost', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'G03': const GameCard(
      id: 'G03',
      name: '破壞機器',
      description: '隨機抽取工廠主理查的 1 張手牌並銷毀',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 1,
      roleId: 'george_luddite',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'destroy_card', 'target_role': 'richard_factory'},
        ),
      ],
    ),

    // 改革者羅伯特 (3張)
    'B01_CHAR': const GameCard(
      id: 'B01_CHAR',
      name: '和平倡議',
      description: '本回合所有攻擊卡傷害減半（全場效果）',
      type: CardType.special,
      rarity: CardRarity.epic,
      targetType: CardTargetType.all,
      influenceCost: 4,
      baseValue: 1,
      roleId: 'robert_reformer',
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          target: 'all',
          params: {'effect': 'halve_attack_damage', 'duration': 'this_turn'},
        ),
      ],
    ),
    
    'B02_CHAR': const GameCard(
      id: 'B02_CHAR',
      name: '跨派結盟',
      description: '與任意陣營的角色結盟，雙方獲得 +10 防禦（而非 +5）',
      type: CardType.social,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 10,
      roleId: 'robert_reformer',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'enhanced_alliance', 'defense_bonus': 10},
        ),
      ],
    ),
    
    'B03_CHAR': const GameCard(
      id: 'B03_CHAR',
      name: '折衷方案',
      description: '本輪投票增加一個「D. 擱置議案」選項',
      type: CardType.control,
      rarity: CardRarity.normal,
      targetType: CardTargetType.none,
      influenceCost: 3,
      baseValue: 1,
      roleId: 'robert_reformer',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'add_vote_option', 'option': 'postpone'},
        ),
      ],
    ),

    // 記者愛德華 (3張)
    'E01': const GameCard(
      id: 'E01',
      name: '獨家報導',
      description: '公開揭露目標的秘密任務給所有人看',
      type: CardType.intel,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 1,
      roleId: 'edward_journalist',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'reveal_mission_public'},
        ),
      ],
    ),
    
    'E02': const GameCard(
      id: 'E02',
      name: '深入調查',
      description: '查看目標的全部手牌（不公開）',
      type: CardType.intel,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 2,
      baseValue: 1,
      roleId: 'edward_journalist',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'peek_full_hand'},
        ),
      ],
    ),
    
    'E03': const GameCard(
      id: 'E03',
      name: '輿論風暴',
      description: '若你本回合已使用過情報類卡牌，傷害 -25；否則 -10',
      type: CardType.attack,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 4,
      baseValue: 25,
      roleId: 'edward_journalist',
      effects: [
        CardEffect(
          type: CardEffectType.damage, 
          value: 25,
          condition: 'used_intel_card_this_turn',
          params: {'default_value': 10},
        ),
      ],
    ),

    // 議員威廉 (3張)
    'W01': const GameCard(
      id: 'W01',
      name: '政治交易',
      description: '與目標交換 1 張手牌（雙方各選 1 張給對方）',
      type: CardType.special,
      rarity: CardRarity.epic,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 1,
      roleId: 'william_mp',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'exchange_cards'},
        ),
      ],
    ),
    
    'W02': const GameCard(
      id: 'W02',
      name: '人脈網絡',
      description: '查看任意 2 名玩家的陣營',
      type: CardType.intel,
      rarity: CardRarity.rare,
      targetType: CardTargetType.multiple,
      influenceCost: 2,
      baseValue: 1,
      roleId: 'william_mp',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 2, 
          params: {'effect': 'peek_faction', 'count': 2},
        ),
      ],
    ),
    
    'W03': const GameCard(
      id: 'W03',
      name: '議長權威',
      description: '改變發言順序，指定下一位發言者',
      type: CardType.control,
      rarity: CardRarity.normal,
      targetType: CardTargetType.single,
      influenceCost: 4,
      baseValue: 1,
      roleId: 'william_mp',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'change_speaker_order'},
        ),
      ],
    ),

    // 喬治三世 (3張)
    'K01': const GameCard(
      id: 'K01',
      name: '王權宣言',
      description: '取消本輪投票，直接宣布一個選項獲勝（每局限用 1 次）',
      type: CardType.special,
      rarity: CardRarity.legendary,
      targetType: CardTargetType.none,
      influenceCost: 6,
      baseValue: 999,
      roleId: 'george_king',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'royal_decree', 'usage_limit': 1},
        ),
      ],
    ),
    
    'K02': const GameCard(
      id: 'K02',
      name: '皇家裁決',
      description: '立即結束辯論階段，進入投票（跳過剩餘發言）',
      type: CardType.control,
      rarity: CardRarity.epic,
      targetType: CardTargetType.none,
      influenceCost: 4,
      baseValue: 1,
      roleId: 'george_king',
      effects: [
        CardEffect(
          type: CardEffectType.special, 
          value: 1, 
          params: {'effect': 'force_phase_change', 'to_phase': 'voting'},
        ),
      ],
    ),
    
    'K03': const GameCard(
      id: 'K03',
      name: '龍恩浩蕩',
      description: '指定一名玩家，其本回合免疫所有傷害',
      type: CardType.defense,
      rarity: CardRarity.rare,
      targetType: CardTargetType.single,
      influenceCost: 3,
      baseValue: 999,
      roleId: 'george_king',
      effects: [
        CardEffect(
          type: CardEffectType.buff, 
          value: 1, 
          params: {'effect': 'immunity', 'duration': 'this_turn'},
        ),
      ],
    ),

    // ============== 負面特質卡 (11張) ==============
    // 這些卡牌是被動效果，不會在手牌中，但在資料庫中定義效果

    'NT01': const GameCard(
      id: 'NT01',
      name: '文盲',
      description: '使用情報類卡牌時，效果減半',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.none,
      influenceCost: 0,
      baseValue: 0,
      roleId: 'thomas_worker',
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'intel_cards_halved', 'passive': true},
        ),
      ],
    ),
    
    'NT02': const GameCard(
      id: 'NT02',
      name: '眾矢之的',
      description: '受到的所有傷害 +5',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.none,
      influenceCost: 0,
      baseValue: 0,
      roleId: 'richard_factory',
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 5, 
          params: {'effect': 'increased_damage_taken', 'passive': true},
        ),
      ],
    ),
    
    'NT03': const GameCard(
      id: 'NT03',
      name: '貪婪',
      description: '金幣低於 20 時，無法使用任何專屬卡',
      type: CardType.special,
      rarity: CardRarity.normal,
      targetType: CardTargetType.none,
      influenceCost: 0,
      baseValue: 0,
      roleId: 'richard_factory',
      effects: [
        CardEffect(
          type: CardEffectType.debuff, 
          value: 1, 
          params: {'effect': 'conditional_card_block', 'condition': 'gold_lt_20', 'passive': true},
        ),
      ],
    ),

    // 更多負面特質...（為了篇幅考量，這裡簡化）
  };

  // 取得所有卡牌
  static Map<String, GameCard> getAllCards() => Map.unmodifiable(_cards);

  // 根據 ID 取得卡牌
  static GameCard? getCard(String id) => _cards[id];

  // 取得通用卡池
  static List<GameCard> getUniversalCards() {
    return _cards.values
        .where((card) => card.roleId == null && !card.id.startsWith('NT'))
        .toList();
  }

  // 取得角色專屬卡
  static List<GameCard> getCharacterCards(String roleId) {
    return _cards.values
        .where((card) => card.roleId == roleId)
        .toList();
  }

  // 取得負面特質卡
  static List<GameCard> getNegativeTraitCards(String roleId) {
    return _cards.values
        .where((card) => card.id.startsWith('NT') && card.roleId == roleId)
        .toList();
  }

  // 根據稀有度篩選卡牌
  static List<GameCard> getCardsByRarity(CardRarity rarity) {
    return _cards.values
        .where((card) => card.rarity == rarity)
        .toList();
  }

  // 根據類型篩選卡牌
  static List<GameCard> getCardsByType(CardType type) {
    return _cards.values
        .where((card) => card.type == type)
        .toList();
  }
}