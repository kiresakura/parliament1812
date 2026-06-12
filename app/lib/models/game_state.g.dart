// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStateImpl _$$GameStateImplFromJson(
  Map<String, dynamic> json,
) => _$GameStateImpl(
  room: Room.fromJson(json['room'] as Map<String, dynamic>),
  currentPlayerId: json['currentPlayerId'] as String?,
  hand: (json['hand'] as List<dynamic>)
      .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  phase: $enumDecode(_$GamePhaseEnumMap, json['phase']),
  round: (json['round'] as num).toInt(),
  remainingSeconds: (json['remainingSeconds'] as num).toInt(),
  chatMessages:
      (json['chatMessages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  gameEvents:
      (json['gameEvents'] as List<dynamic>?)
          ?.map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  votes:
      (json['votes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, $enumDecode(_$VoteChoiceEnumMap, e)),
      ) ??
      const {},
  currentSpeakerId: json['currentSpeakerId'] as String?,
  currentBill: json['currentBill'] as String?,
  result: json['result'] == null
      ? null
      : GameResult.fromJson(json['result'] as Map<String, dynamic>),
  currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
  currentTurnPlayerName: json['currentTurnPlayerName'] as String?,
  actionPointsRemaining: (json['actionPointsRemaining'] as num?)?.toInt() ?? 3,
  turnOrder:
      (json['turnOrder'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$GameStateImplToJson(
  _$GameStateImpl instance,
) => <String, dynamic>{
  'room': instance.room,
  'currentPlayerId': instance.currentPlayerId,
  'hand': instance.hand,
  'phase': _$GamePhaseEnumMap[instance.phase]!,
  'round': instance.round,
  'remainingSeconds': instance.remainingSeconds,
  'chatMessages': instance.chatMessages,
  'gameEvents': instance.gameEvents,
  'votes': instance.votes.map((k, e) => MapEntry(k, _$VoteChoiceEnumMap[e]!)),
  'currentSpeakerId': instance.currentSpeakerId,
  'currentBill': instance.currentBill,
  'result': instance.result,
  'currentTurnPlayerId': instance.currentTurnPlayerId,
  'currentTurnPlayerName': instance.currentTurnPlayerName,
  'actionPointsRemaining': instance.actionPointsRemaining,
  'turnOrder': instance.turnOrder,
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

const _$VoteChoiceEnumMap = {
  VoteChoice.a: 'a',
  VoteChoice.b: 'b',
  VoteChoice.c: 'c',
  VoteChoice.abstain: 'abstain',
};

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      fromId: json['fromId'] as String,
      fromName: json['fromName'] as String,
      content: json['content'] as String,
      isPrivate: json['isPrivate'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      toId: json['toId'] as String?,
      type: $enumDecodeNullable(_$ChatMessageTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromId': instance.fromId,
      'fromName': instance.fromName,
      'content': instance.content,
      'isPrivate': instance.isPrivate,
      'timestamp': instance.timestamp.toIso8601String(),
      'toId': instance.toId,
      'type': _$ChatMessageTypeEnumMap[instance.type],
    };

const _$ChatMessageTypeEnumMap = {
  ChatMessageType.normal: 'normal',
  ChatMessageType.system: 'system',
  ChatMessageType.action: 'action',
  ChatMessageType.event: 'event',
  ChatMessageType.whisper: 'whisper',
};

_$GameEventImpl _$$GameEventImplFromJson(Map<String, dynamic> json) =>
    _$GameEventImpl(
      id: json['id'] as String,
      type: $enumDecode(_$GameEventTypeEnumMap, json['type']),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>? ?? const {},
      playerId: json['playerId'] as String?,
      playerName: json['playerName'] as String?,
    );

Map<String, dynamic> _$$GameEventImplToJson(_$GameEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$GameEventTypeEnumMap[instance.type]!,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'data': instance.data,
      'playerId': instance.playerId,
      'playerName': instance.playerName,
    };

const _$GameEventTypeEnumMap = {
  GameEventType.playerJoined: 'player_joined',
  GameEventType.playerLeft: 'player_left',
  GameEventType.gameStarted: 'game_started',
  GameEventType.phaseChanged: 'phase_changed',
  GameEventType.cardUsed: 'card_used',
  GameEventType.challenge: 'challenge',
  GameEventType.counter: 'counter',
  GameEventType.reputationChanged: 'reputation_changed',
  GameEventType.goldChanged: 'gold_changed',
  GameEventType.voteCast: 'vote_cast',
  GameEventType.voteResult: 'vote_result',
  GameEventType.playerDeath: 'player_death',
  GameEventType.randomEvent: 'random_event',
};

_$GameResultImpl _$$GameResultImplFromJson(Map<String, dynamic> json) =>
    _$GameResultImpl(
      winnerFaction: json['winnerFaction'] as String,
      votes: (json['votes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      rankings: (json['rankings'] as List<dynamic>)
          .map((e) => PlayerRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
    );

Map<String, dynamic> _$$GameResultImplToJson(_$GameResultImpl instance) =>
    <String, dynamic>{
      'winnerFaction': instance.winnerFaction,
      'votes': instance.votes,
      'rankings': instance.rankings,
      'endTime': instance.endTime?.toIso8601String(),
    };

_$PlayerRankingImpl _$$PlayerRankingImplFromJson(Map<String, dynamic> json) =>
    _$PlayerRankingImpl(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      character: $enumDecode(_$CharacterTypeEnumMap, json['character']),
      finalReputation: (json['finalReputation'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      score: (json['score'] as num).toInt(),
    );

Map<String, dynamic> _$$PlayerRankingImplToJson(_$PlayerRankingImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'character': _$CharacterTypeEnumMap[instance.character]!,
      'finalReputation': instance.finalReputation,
      'rank': instance.rank,
      'score': instance.score,
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
