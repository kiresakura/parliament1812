// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameCardImpl _$$GameCardImplFromJson(Map<String, dynamic> json) =>
    _$GameCardImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CardTypeEnumMap, json['type']),
      rarity: $enumDecode(_$CardRarityEnumMap, json['rarity']),
      targetType: $enumDecode(_$CardTargetTypeEnumMap, json['targetType']),
      influenceCost: (json['influenceCost'] as num).toInt(),
      goldCost: (json['goldCost'] as num?)?.toInt() ?? 0,
      baseValue: (json['baseValue'] as num).toInt(),
      roleId: json['roleId'] as String?,
      effects:
          (json['effects'] as List<dynamic>?)
              ?.map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$GameCardImplToJson(_$GameCardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$CardTypeEnumMap[instance.type]!,
      'rarity': _$CardRarityEnumMap[instance.rarity]!,
      'targetType': _$CardTargetTypeEnumMap[instance.targetType]!,
      'influenceCost': instance.influenceCost,
      'goldCost': instance.goldCost,
      'baseValue': instance.baseValue,
      'roleId': instance.roleId,
      'effects': instance.effects,
      'metadata': instance.metadata,
    };

const _$CardTypeEnumMap = {
  CardType.attack: 'attack',
  CardType.defense: 'defense',
  CardType.control: 'control',
  CardType.buff: 'buff',
  CardType.intel: 'intel',
  CardType.healing: 'healing',
  CardType.social: 'social',
  CardType.special: 'special',
};

const _$CardRarityEnumMap = {
  CardRarity.normal: 'N',
  CardRarity.rare: 'R',
  CardRarity.epic: 'SR',
  CardRarity.legendary: 'SSR',
};

const _$CardTargetTypeEnumMap = {
  CardTargetType.none: 'none',
  CardTargetType.self: 'self',
  CardTargetType.single: 'single',
  CardTargetType.multiple: 'multiple',
  CardTargetType.all: 'all',
  CardTargetType.faction: 'faction',
};

_$CardEffectImpl _$$CardEffectImplFromJson(Map<String, dynamic> json) =>
    _$CardEffectImpl(
      type: $enumDecode(_$CardEffectTypeEnumMap, json['type']),
      value: (json['value'] as num).toInt(),
      condition: json['condition'] as String?,
      target: json['target'] as String?,
      params: json['params'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$CardEffectImplToJson(_$CardEffectImpl instance) =>
    <String, dynamic>{
      'type': _$CardEffectTypeEnumMap[instance.type]!,
      'value': instance.value,
      'condition': instance.condition,
      'target': instance.target,
      'params': instance.params,
    };

const _$CardEffectTypeEnumMap = {
  CardEffectType.damage: 'damage',
  CardEffectType.heal: 'heal',
  CardEffectType.buff: 'buff',
  CardEffectType.debuff: 'debuff',
  CardEffectType.control: 'control',
  CardEffectType.draw: 'draw',
  CardEffectType.discard: 'discard',
  CardEffectType.resource: 'resource',
  CardEffectType.special: 'special',
};
