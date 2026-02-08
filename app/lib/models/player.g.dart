// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  character: $enumDecodeNullable(_$CharacterTypeEnumMap, json['character']),
  reputation: (json['reputation'] as num).toInt(),
  gold: (json['gold'] as num).toInt(),
  isReady: json['isReady'] as bool,
  isHost: json['isHost'] as bool,
  isSpectator: json['isSpectator'] as bool? ?? false,
  isAlive: json['isAlive'] as bool? ?? true,
  handCards:
      (json['handCards'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  negativeTraits:
      (json['negativeTraits'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status: json['status'] as Map<String, dynamic>? ?? const {},
  allianceIds:
      (json['allianceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  hasPendingAlliance: json['hasPendingAlliance'] as bool? ?? false,
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': _$CharacterTypeEnumMap[instance.character],
      'reputation': instance.reputation,
      'gold': instance.gold,
      'isReady': instance.isReady,
      'isHost': instance.isHost,
      'isSpectator': instance.isSpectator,
      'isAlive': instance.isAlive,
      'handCards': instance.handCards,
      'negativeTraits': instance.negativeTraits,
      'status': instance.status,
      'allianceIds': instance.allianceIds,
      'hasPendingAlliance': instance.hasPendingAlliance,
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
