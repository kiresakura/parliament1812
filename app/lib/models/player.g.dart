// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  character: $enumDecode(_$CharacterTypeEnumMap, json['character']),
  faction: json['faction'] as String,
  resources: PlayerResources.fromJson(
    json['resources'] as Map<String, dynamic>,
  ),
  isReady: json['isReady'] as bool,
  isHost: json['isHost'] as bool,
  isAlive: json['isAlive'] as bool,
  handCards:
      (json['handCards'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  negativeTraits:
      (json['negativeTraits'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status: json['status'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': _$CharacterTypeEnumMap[instance.character]!,
      'faction': instance.faction,
      'resources': instance.resources,
      'isReady': instance.isReady,
      'isHost': instance.isHost,
      'isAlive': instance.isAlive,
      'handCards': instance.handCards,
      'negativeTraits': instance.negativeTraits,
      'status': instance.status,
    };

const _$CharacterTypeEnumMap = {
  CharacterType.thomasWorker: 'thomas_worker',
  CharacterType.richardFactory: 'richard_factory',
  CharacterType.georgeLuddite: 'george_luddite',
  CharacterType.robertReformer: 'robert_reformer',
  CharacterType.edwardJournalist: 'edward_journalist',
  CharacterType.williamMp: 'william_mp',
  CharacterType.georgeKing: 'george_king',
};

_$PlayerResourcesImpl _$$PlayerResourcesImplFromJson(
  Map<String, dynamic> json,
) => _$PlayerResourcesImpl(
  reputation: (json['reputation'] as num?)?.toInt() ?? 50,
  influence: (json['influence'] as num?)?.toInt() ?? 10,
  gold: (json['gold'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$$PlayerResourcesImplToJson(
  _$PlayerResourcesImpl instance,
) => <String, dynamic>{
  'reputation': instance.reputation,
  'influence': instance.influence,
  'gold': instance.gold,
};
