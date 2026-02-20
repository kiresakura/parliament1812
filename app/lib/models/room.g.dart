// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomImpl _$$RoomImplFromJson(Map<String, dynamic> json) => _$RoomImpl(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  hostId: json['hostId'] as String,
  status: $enumDecode(_$RoomStatusEnumMap, json['status']),
  phase: $enumDecode(_$GamePhaseEnumMap, json['phase']),
  players: (json['players'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  settings: RoomSettings.fromJson(json['settings'] as Map<String, dynamic>),
  round: (json['round'] as num?)?.toInt() ?? 1,
  remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
  currentBill: json['currentBill'] as String? ?? '',
  gameState: json['gameState'] as Map<String, dynamic>? ?? const {},
  spectators:
      (json['spectators'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
);

Map<String, dynamic> _$$RoomImplToJson(_$RoomImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'hostId': instance.hostId,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'phase': _$GamePhaseEnumMap[instance.phase]!,
      'players': instance.players,
      'settings': instance.settings,
      'round': instance.round,
      'remainingSeconds': instance.remainingSeconds,
      'currentBill': instance.currentBill,
      'gameState': instance.gameState,
      'spectators': instance.spectators,
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
    };

const _$RoomStatusEnumMap = {
  RoomStatus.waiting: 'waiting',
  RoomStatus.ready: 'ready',
  RoomStatus.playing: 'playing',
  RoomStatus.finished: 'finished',
  RoomStatus.cancelled: 'cancelled',
};

const _$GamePhaseEnumMap = {
  GamePhase.waiting: 'waiting',
  GamePhase.preparation: 'preparation',
  GamePhase.playerTurn: 'player_turn',
  GamePhase.conspiracy: 'conspiracy',
  GamePhase.debate: 'debate',
  GamePhase.event: 'event',
  GamePhase.finalSpeech: 'final_speech',
  GamePhase.voting: 'voting',
  GamePhase.result: 'result',
};

_$RoomSettingsImpl _$$RoomSettingsImplFromJson(Map<String, dynamic> json) =>
    _$RoomSettingsImpl(
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? 2,
      allowSpectators: json['allowSpectators'] as bool? ?? true,
      maxSpectators: (json['maxSpectators'] as num?)?.toInt() ?? 10,
      isPrivate: json['isPrivate'] as bool? ?? false,
      password: json['password'] as String? ?? '',
      preparationDuration: (json['preparationDuration'] as num?)?.toInt() ?? 60,
      conspiracyDuration: (json['conspiracyDuration'] as num?)?.toInt() ?? 180,
      debateDuration: (json['debateDuration'] as num?)?.toInt() ?? 360,
      eventDuration: (json['eventDuration'] as num?)?.toInt() ?? 60,
      finalSpeechDuration:
          (json['finalSpeechDuration'] as num?)?.toInt() ?? 120,
      votingDuration: (json['votingDuration'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$$RoomSettingsImplToJson(_$RoomSettingsImpl instance) =>
    <String, dynamic>{
      'maxPlayers': instance.maxPlayers,
      'minPlayers': instance.minPlayers,
      'allowSpectators': instance.allowSpectators,
      'maxSpectators': instance.maxSpectators,
      'isPrivate': instance.isPrivate,
      'password': instance.password,
      'preparationDuration': instance.preparationDuration,
      'conspiracyDuration': instance.conspiracyDuration,
      'debateDuration': instance.debateDuration,
      'eventDuration': instance.eventDuration,
      'finalSpeechDuration': instance.finalSpeechDuration,
      'votingDuration': instance.votingDuration,
    };
