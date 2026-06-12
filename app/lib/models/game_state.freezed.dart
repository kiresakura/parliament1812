// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  Room get room => throw _privateConstructorUsedError;
  String? get currentPlayerId => throw _privateConstructorUsedError;
  List<GameCard> get hand => throw _privateConstructorUsedError;
  GamePhase get phase => throw _privateConstructorUsedError;
  int get round => throw _privateConstructorUsedError;
  int get remainingSeconds => throw _privateConstructorUsedError;
  List<ChatMessage> get chatMessages => throw _privateConstructorUsedError;
  List<GameEvent> get gameEvents => throw _privateConstructorUsedError;
  Map<String, VoteChoice> get votes => throw _privateConstructorUsedError;
  String? get currentSpeakerId => throw _privateConstructorUsedError;
  String? get currentBill => throw _privateConstructorUsedError;
  GameResult? get result => throw _privateConstructorUsedError;

  /// 回合制：當前行動玩家 ID
  String? get currentTurnPlayerId => throw _privateConstructorUsedError;

  /// 回合制：當前行動玩家名稱
  String? get currentTurnPlayerName => throw _privateConstructorUsedError;

  /// 回合制：剩餘行動點數
  int get actionPointsRemaining => throw _privateConstructorUsedError;

  /// 回合制：回合順序
  List<String> get turnOrder => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    Room room,
    String? currentPlayerId,
    List<GameCard> hand,
    GamePhase phase,
    int round,
    int remainingSeconds,
    List<ChatMessage> chatMessages,
    List<GameEvent> gameEvents,
    Map<String, VoteChoice> votes,
    String? currentSpeakerId,
    String? currentBill,
    GameResult? result,
    String? currentTurnPlayerId,
    String? currentTurnPlayerName,
    int actionPointsRemaining,
    List<String> turnOrder,
  });

  $RoomCopyWith<$Res> get room;
  $GameResultCopyWith<$Res>? get result;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = null,
    Object? currentPlayerId = freezed,
    Object? hand = null,
    Object? phase = null,
    Object? round = null,
    Object? remainingSeconds = null,
    Object? chatMessages = null,
    Object? gameEvents = null,
    Object? votes = null,
    Object? currentSpeakerId = freezed,
    Object? currentBill = freezed,
    Object? result = freezed,
    Object? currentTurnPlayerId = freezed,
    Object? currentTurnPlayerName = freezed,
    Object? actionPointsRemaining = null,
    Object? turnOrder = null,
  }) {
    return _then(
      _value.copyWith(
            room: null == room
                ? _value.room
                : room // ignore: cast_nullable_to_non_nullable
                      as Room,
            currentPlayerId: freezed == currentPlayerId
                ? _value.currentPlayerId
                : currentPlayerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            hand: null == hand
                ? _value.hand
                : hand // ignore: cast_nullable_to_non_nullable
                      as List<GameCard>,
            phase: null == phase
                ? _value.phase
                : phase // ignore: cast_nullable_to_non_nullable
                      as GamePhase,
            round: null == round
                ? _value.round
                : round // ignore: cast_nullable_to_non_nullable
                      as int,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            chatMessages: null == chatMessages
                ? _value.chatMessages
                : chatMessages // ignore: cast_nullable_to_non_nullable
                      as List<ChatMessage>,
            gameEvents: null == gameEvents
                ? _value.gameEvents
                : gameEvents // ignore: cast_nullable_to_non_nullable
                      as List<GameEvent>,
            votes: null == votes
                ? _value.votes
                : votes // ignore: cast_nullable_to_non_nullable
                      as Map<String, VoteChoice>,
            currentSpeakerId: freezed == currentSpeakerId
                ? _value.currentSpeakerId
                : currentSpeakerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentBill: freezed == currentBill
                ? _value.currentBill
                : currentBill // ignore: cast_nullable_to_non_nullable
                      as String?,
            result: freezed == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as GameResult?,
            currentTurnPlayerId: freezed == currentTurnPlayerId
                ? _value.currentTurnPlayerId
                : currentTurnPlayerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentTurnPlayerName: freezed == currentTurnPlayerName
                ? _value.currentTurnPlayerName
                : currentTurnPlayerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            actionPointsRemaining: null == actionPointsRemaining
                ? _value.actionPointsRemaining
                : actionPointsRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
            turnOrder: null == turnOrder
                ? _value.turnOrder
                : turnOrder // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RoomCopyWith<$Res> get room {
    return $RoomCopyWith<$Res>(_value.room, (value) {
      return _then(_value.copyWith(room: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameResultCopyWith<$Res>? get result {
    if (_value.result == null) {
      return null;
    }

    return $GameResultCopyWith<$Res>(_value.result!, (value) {
      return _then(_value.copyWith(result: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Room room,
    String? currentPlayerId,
    List<GameCard> hand,
    GamePhase phase,
    int round,
    int remainingSeconds,
    List<ChatMessage> chatMessages,
    List<GameEvent> gameEvents,
    Map<String, VoteChoice> votes,
    String? currentSpeakerId,
    String? currentBill,
    GameResult? result,
    String? currentTurnPlayerId,
    String? currentTurnPlayerName,
    int actionPointsRemaining,
    List<String> turnOrder,
  });

  @override
  $RoomCopyWith<$Res> get room;
  @override
  $GameResultCopyWith<$Res>? get result;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = null,
    Object? currentPlayerId = freezed,
    Object? hand = null,
    Object? phase = null,
    Object? round = null,
    Object? remainingSeconds = null,
    Object? chatMessages = null,
    Object? gameEvents = null,
    Object? votes = null,
    Object? currentSpeakerId = freezed,
    Object? currentBill = freezed,
    Object? result = freezed,
    Object? currentTurnPlayerId = freezed,
    Object? currentTurnPlayerName = freezed,
    Object? actionPointsRemaining = null,
    Object? turnOrder = null,
  }) {
    return _then(
      _$GameStateImpl(
        room: null == room
            ? _value.room
            : room // ignore: cast_nullable_to_non_nullable
                  as Room,
        currentPlayerId: freezed == currentPlayerId
            ? _value.currentPlayerId
            : currentPlayerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        hand: null == hand
            ? _value._hand
            : hand // ignore: cast_nullable_to_non_nullable
                  as List<GameCard>,
        phase: null == phase
            ? _value.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as GamePhase,
        round: null == round
            ? _value.round
            : round // ignore: cast_nullable_to_non_nullable
                  as int,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        chatMessages: null == chatMessages
            ? _value._chatMessages
            : chatMessages // ignore: cast_nullable_to_non_nullable
                  as List<ChatMessage>,
        gameEvents: null == gameEvents
            ? _value._gameEvents
            : gameEvents // ignore: cast_nullable_to_non_nullable
                  as List<GameEvent>,
        votes: null == votes
            ? _value._votes
            : votes // ignore: cast_nullable_to_non_nullable
                  as Map<String, VoteChoice>,
        currentSpeakerId: freezed == currentSpeakerId
            ? _value.currentSpeakerId
            : currentSpeakerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentBill: freezed == currentBill
            ? _value.currentBill
            : currentBill // ignore: cast_nullable_to_non_nullable
                  as String?,
        result: freezed == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as GameResult?,
        currentTurnPlayerId: freezed == currentTurnPlayerId
            ? _value.currentTurnPlayerId
            : currentTurnPlayerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentTurnPlayerName: freezed == currentTurnPlayerName
            ? _value.currentTurnPlayerName
            : currentTurnPlayerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        actionPointsRemaining: null == actionPointsRemaining
            ? _value.actionPointsRemaining
            : actionPointsRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
        turnOrder: null == turnOrder
            ? _value._turnOrder
            : turnOrder // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateImpl implements _GameState {
  const _$GameStateImpl({
    required this.room,
    required this.currentPlayerId,
    required final List<GameCard> hand,
    required this.phase,
    required this.round,
    required this.remainingSeconds,
    final List<ChatMessage> chatMessages = const [],
    final List<GameEvent> gameEvents = const [],
    final Map<String, VoteChoice> votes = const {},
    this.currentSpeakerId,
    this.currentBill,
    this.result,
    this.currentTurnPlayerId,
    this.currentTurnPlayerName,
    this.actionPointsRemaining = 3,
    final List<String> turnOrder = const [],
  }) : _hand = hand,
       _chatMessages = chatMessages,
       _gameEvents = gameEvents,
       _votes = votes,
       _turnOrder = turnOrder;

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  @override
  final Room room;
  @override
  final String? currentPlayerId;
  final List<GameCard> _hand;
  @override
  List<GameCard> get hand {
    if (_hand is EqualUnmodifiableListView) return _hand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hand);
  }

  @override
  final GamePhase phase;
  @override
  final int round;
  @override
  final int remainingSeconds;
  final List<ChatMessage> _chatMessages;
  @override
  @JsonKey()
  List<ChatMessage> get chatMessages {
    if (_chatMessages is EqualUnmodifiableListView) return _chatMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chatMessages);
  }

  final List<GameEvent> _gameEvents;
  @override
  @JsonKey()
  List<GameEvent> get gameEvents {
    if (_gameEvents is EqualUnmodifiableListView) return _gameEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gameEvents);
  }

  final Map<String, VoteChoice> _votes;
  @override
  @JsonKey()
  Map<String, VoteChoice> get votes {
    if (_votes is EqualUnmodifiableMapView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_votes);
  }

  @override
  final String? currentSpeakerId;
  @override
  final String? currentBill;
  @override
  final GameResult? result;

  /// 回合制：當前行動玩家 ID
  @override
  final String? currentTurnPlayerId;

  /// 回合制：當前行動玩家名稱
  @override
  final String? currentTurnPlayerName;

  /// 回合制：剩餘行動點數
  @override
  @JsonKey()
  final int actionPointsRemaining;

  /// 回合制：回合順序
  final List<String> _turnOrder;

  /// 回合制：回合順序
  @override
  @JsonKey()
  List<String> get turnOrder {
    if (_turnOrder is EqualUnmodifiableListView) return _turnOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_turnOrder);
  }

  @override
  String toString() {
    return 'GameState(room: $room, currentPlayerId: $currentPlayerId, hand: $hand, phase: $phase, round: $round, remainingSeconds: $remainingSeconds, chatMessages: $chatMessages, gameEvents: $gameEvents, votes: $votes, currentSpeakerId: $currentSpeakerId, currentBill: $currentBill, result: $result, currentTurnPlayerId: $currentTurnPlayerId, currentTurnPlayerName: $currentTurnPlayerName, actionPointsRemaining: $actionPointsRemaining, turnOrder: $turnOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.currentPlayerId, currentPlayerId) ||
                other.currentPlayerId == currentPlayerId) &&
            const DeepCollectionEquality().equals(other._hand, _hand) &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            const DeepCollectionEquality().equals(
              other._chatMessages,
              _chatMessages,
            ) &&
            const DeepCollectionEquality().equals(
              other._gameEvents,
              _gameEvents,
            ) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            (identical(other.currentSpeakerId, currentSpeakerId) ||
                other.currentSpeakerId == currentSpeakerId) &&
            (identical(other.currentBill, currentBill) ||
                other.currentBill == currentBill) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.currentTurnPlayerId, currentTurnPlayerId) ||
                other.currentTurnPlayerId == currentTurnPlayerId) &&
            (identical(other.currentTurnPlayerName, currentTurnPlayerName) ||
                other.currentTurnPlayerName == currentTurnPlayerName) &&
            (identical(other.actionPointsRemaining, actionPointsRemaining) ||
                other.actionPointsRemaining == actionPointsRemaining) &&
            const DeepCollectionEquality().equals(
              other._turnOrder,
              _turnOrder,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    room,
    currentPlayerId,
    const DeepCollectionEquality().hash(_hand),
    phase,
    round,
    remainingSeconds,
    const DeepCollectionEquality().hash(_chatMessages),
    const DeepCollectionEquality().hash(_gameEvents),
    const DeepCollectionEquality().hash(_votes),
    currentSpeakerId,
    currentBill,
    result,
    currentTurnPlayerId,
    currentTurnPlayerName,
    actionPointsRemaining,
    const DeepCollectionEquality().hash(_turnOrder),
  );

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(this);
  }
}

abstract class _GameState implements GameState {
  const factory _GameState({
    required final Room room,
    required final String? currentPlayerId,
    required final List<GameCard> hand,
    required final GamePhase phase,
    required final int round,
    required final int remainingSeconds,
    final List<ChatMessage> chatMessages,
    final List<GameEvent> gameEvents,
    final Map<String, VoteChoice> votes,
    final String? currentSpeakerId,
    final String? currentBill,
    final GameResult? result,
    final String? currentTurnPlayerId,
    final String? currentTurnPlayerName,
    final int actionPointsRemaining,
    final List<String> turnOrder,
  }) = _$GameStateImpl;

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  @override
  Room get room;
  @override
  String? get currentPlayerId;
  @override
  List<GameCard> get hand;
  @override
  GamePhase get phase;
  @override
  int get round;
  @override
  int get remainingSeconds;
  @override
  List<ChatMessage> get chatMessages;
  @override
  List<GameEvent> get gameEvents;
  @override
  Map<String, VoteChoice> get votes;
  @override
  String? get currentSpeakerId;
  @override
  String? get currentBill;
  @override
  GameResult? get result;

  /// 回合制：當前行動玩家 ID
  @override
  String? get currentTurnPlayerId;

  /// 回合制：當前行動玩家名稱
  @override
  String? get currentTurnPlayerName;

  /// 回合制：剩餘行動點數
  @override
  int get actionPointsRemaining;

  /// 回合制：回合順序
  @override
  List<String> get turnOrder;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get fromId => throw _privateConstructorUsedError;
  String get fromName => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  bool get isPrivate => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get toId => throw _privateConstructorUsedError; // 私訊目標
  ChatMessageType? get type => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
    ChatMessage value,
    $Res Function(ChatMessage) then,
  ) = _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call({
    String id,
    String fromId,
    String fromName,
    String content,
    bool isPrivate,
    DateTime timestamp,
    String? toId,
    ChatMessageType? type,
  });
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromId = null,
    Object? fromName = null,
    Object? content = null,
    Object? isPrivate = null,
    Object? timestamp = null,
    Object? toId = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fromId: null == fromId
                ? _value.fromId
                : fromId // ignore: cast_nullable_to_non_nullable
                      as String,
            fromName: null == fromName
                ? _value.fromName
                : fromName // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            isPrivate: null == isPrivate
                ? _value.isPrivate
                : isPrivate // ignore: cast_nullable_to_non_nullable
                      as bool,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            toId: freezed == toId
                ? _value.toId
                : toId // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ChatMessageType?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
    _$ChatMessageImpl value,
    $Res Function(_$ChatMessageImpl) then,
  ) = __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fromId,
    String fromName,
    String content,
    bool isPrivate,
    DateTime timestamp,
    String? toId,
    ChatMessageType? type,
  });
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
    _$ChatMessageImpl _value,
    $Res Function(_$ChatMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromId = null,
    Object? fromName = null,
    Object? content = null,
    Object? isPrivate = null,
    Object? timestamp = null,
    Object? toId = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _$ChatMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fromId: null == fromId
            ? _value.fromId
            : fromId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromName: null == fromName
            ? _value.fromName
            : fromName // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        isPrivate: null == isPrivate
            ? _value.isPrivate
            : isPrivate // ignore: cast_nullable_to_non_nullable
                  as bool,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        toId: freezed == toId
            ? _value.toId
            : toId // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ChatMessageType?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.content,
    required this.isPrivate,
    required this.timestamp,
    this.toId,
    this.type,
  });

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String fromId;
  @override
  final String fromName;
  @override
  final String content;
  @override
  final bool isPrivate;
  @override
  final DateTime timestamp;
  @override
  final String? toId;
  // 私訊目標
  @override
  final ChatMessageType? type;

  @override
  String toString() {
    return 'ChatMessage(id: $id, fromId: $fromId, fromName: $fromName, content: $content, isPrivate: $isPrivate, timestamp: $timestamp, toId: $toId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromId, fromId) || other.fromId == fromId) &&
            (identical(other.fromName, fromName) ||
                other.fromName == fromName) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.toId, toId) || other.toId == toId) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fromId,
    fromName,
    content,
    isPrivate,
    timestamp,
    toId,
    type,
  );

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(this);
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage({
    required final String id,
    required final String fromId,
    required final String fromName,
    required final String content,
    required final bool isPrivate,
    required final DateTime timestamp,
    final String? toId,
    final ChatMessageType? type,
  }) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get fromId;
  @override
  String get fromName;
  @override
  String get content;
  @override
  bool get isPrivate;
  @override
  DateTime get timestamp;
  @override
  String? get toId; // 私訊目標
  @override
  ChatMessageType? get type;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameEvent _$GameEventFromJson(Map<String, dynamic> json) {
  return _GameEvent.fromJson(json);
}

/// @nodoc
mixin _$GameEvent {
  String get id => throw _privateConstructorUsedError;
  GameEventType get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  String? get playerId => throw _privateConstructorUsedError;
  String? get playerName => throw _privateConstructorUsedError;

  /// Serializes this GameEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameEventCopyWith<GameEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameEventCopyWith<$Res> {
  factory $GameEventCopyWith(GameEvent value, $Res Function(GameEvent) then) =
      _$GameEventCopyWithImpl<$Res, GameEvent>;
  @useResult
  $Res call({
    String id,
    GameEventType type,
    String description,
    DateTime timestamp,
    Map<String, dynamic> data,
    String? playerId,
    String? playerName,
  });
}

/// @nodoc
class _$GameEventCopyWithImpl<$Res, $Val extends GameEvent>
    implements $GameEventCopyWith<$Res> {
  _$GameEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? description = null,
    Object? timestamp = null,
    Object? data = null,
    Object? playerId = freezed,
    Object? playerName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as GameEventType,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            playerId: freezed == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            playerName: freezed == playerName
                ? _value.playerName
                : playerName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameEventImplCopyWith<$Res>
    implements $GameEventCopyWith<$Res> {
  factory _$$GameEventImplCopyWith(
    _$GameEventImpl value,
    $Res Function(_$GameEventImpl) then,
  ) = __$$GameEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    GameEventType type,
    String description,
    DateTime timestamp,
    Map<String, dynamic> data,
    String? playerId,
    String? playerName,
  });
}

/// @nodoc
class __$$GameEventImplCopyWithImpl<$Res>
    extends _$GameEventCopyWithImpl<$Res, _$GameEventImpl>
    implements _$$GameEventImplCopyWith<$Res> {
  __$$GameEventImplCopyWithImpl(
    _$GameEventImpl _value,
    $Res Function(_$GameEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? description = null,
    Object? timestamp = null,
    Object? data = null,
    Object? playerId = freezed,
    Object? playerName = freezed,
  }) {
    return _then(
      _$GameEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as GameEventType,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        playerId: freezed == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        playerName: freezed == playerName
            ? _value.playerName
            : playerName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameEventImpl implements _GameEvent {
  const _$GameEventImpl({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    final Map<String, dynamic> data = const {},
    this.playerId,
    this.playerName,
  }) : _data = data;

  factory _$GameEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameEventImplFromJson(json);

  @override
  final String id;
  @override
  final GameEventType type;
  @override
  final String description;
  @override
  final DateTime timestamp;
  final Map<String, dynamic> _data;
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  final String? playerId;
  @override
  final String? playerName;

  @override
  String toString() {
    return 'GameEvent(id: $id, type: $type, description: $description, timestamp: $timestamp, data: $data, playerId: $playerId, playerName: $playerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    description,
    timestamp,
    const DeepCollectionEquality().hash(_data),
    playerId,
    playerName,
  );

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameEventImplCopyWith<_$GameEventImpl> get copyWith =>
      __$$GameEventImplCopyWithImpl<_$GameEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameEventImplToJson(this);
  }
}

abstract class _GameEvent implements GameEvent {
  const factory _GameEvent({
    required final String id,
    required final GameEventType type,
    required final String description,
    required final DateTime timestamp,
    final Map<String, dynamic> data,
    final String? playerId,
    final String? playerName,
  }) = _$GameEventImpl;

  factory _GameEvent.fromJson(Map<String, dynamic> json) =
      _$GameEventImpl.fromJson;

  @override
  String get id;
  @override
  GameEventType get type;
  @override
  String get description;
  @override
  DateTime get timestamp;
  @override
  Map<String, dynamic> get data;
  @override
  String? get playerId;
  @override
  String? get playerName;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameEventImplCopyWith<_$GameEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameResult _$GameResultFromJson(Map<String, dynamic> json) {
  return _GameResult.fromJson(json);
}

/// @nodoc
mixin _$GameResult {
  String get winnerFaction => throw _privateConstructorUsedError;
  Map<String, double> get votes => throw _privateConstructorUsedError;
  List<PlayerRanking> get rankings => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;

  /// Serializes this GameResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameResultCopyWith<GameResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameResultCopyWith<$Res> {
  factory $GameResultCopyWith(
    GameResult value,
    $Res Function(GameResult) then,
  ) = _$GameResultCopyWithImpl<$Res, GameResult>;
  @useResult
  $Res call({
    String winnerFaction,
    Map<String, double> votes,
    List<PlayerRanking> rankings,
    DateTime? endTime,
  });
}

/// @nodoc
class _$GameResultCopyWithImpl<$Res, $Val extends GameResult>
    implements $GameResultCopyWith<$Res> {
  _$GameResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? winnerFaction = null,
    Object? votes = null,
    Object? rankings = null,
    Object? endTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            winnerFaction: null == winnerFaction
                ? _value.winnerFaction
                : winnerFaction // ignore: cast_nullable_to_non_nullable
                      as String,
            votes: null == votes
                ? _value.votes
                : votes // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
            rankings: null == rankings
                ? _value.rankings
                : rankings // ignore: cast_nullable_to_non_nullable
                      as List<PlayerRanking>,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameResultImplCopyWith<$Res>
    implements $GameResultCopyWith<$Res> {
  factory _$$GameResultImplCopyWith(
    _$GameResultImpl value,
    $Res Function(_$GameResultImpl) then,
  ) = __$$GameResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String winnerFaction,
    Map<String, double> votes,
    List<PlayerRanking> rankings,
    DateTime? endTime,
  });
}

/// @nodoc
class __$$GameResultImplCopyWithImpl<$Res>
    extends _$GameResultCopyWithImpl<$Res, _$GameResultImpl>
    implements _$$GameResultImplCopyWith<$Res> {
  __$$GameResultImplCopyWithImpl(
    _$GameResultImpl _value,
    $Res Function(_$GameResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? winnerFaction = null,
    Object? votes = null,
    Object? rankings = null,
    Object? endTime = freezed,
  }) {
    return _then(
      _$GameResultImpl(
        winnerFaction: null == winnerFaction
            ? _value.winnerFaction
            : winnerFaction // ignore: cast_nullable_to_non_nullable
                  as String,
        votes: null == votes
            ? _value._votes
            : votes // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
        rankings: null == rankings
            ? _value._rankings
            : rankings // ignore: cast_nullable_to_non_nullable
                  as List<PlayerRanking>,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameResultImpl implements _GameResult {
  const _$GameResultImpl({
    required this.winnerFaction,
    required final Map<String, double> votes,
    required final List<PlayerRanking> rankings,
    this.endTime,
  }) : _votes = votes,
       _rankings = rankings;

  factory _$GameResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameResultImplFromJson(json);

  @override
  final String winnerFaction;
  final Map<String, double> _votes;
  @override
  Map<String, double> get votes {
    if (_votes is EqualUnmodifiableMapView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_votes);
  }

  final List<PlayerRanking> _rankings;
  @override
  List<PlayerRanking> get rankings {
    if (_rankings is EqualUnmodifiableListView) return _rankings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rankings);
  }

  @override
  final DateTime? endTime;

  @override
  String toString() {
    return 'GameResult(winnerFaction: $winnerFaction, votes: $votes, rankings: $rankings, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameResultImpl &&
            (identical(other.winnerFaction, winnerFaction) ||
                other.winnerFaction == winnerFaction) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            const DeepCollectionEquality().equals(other._rankings, _rankings) &&
            (identical(other.endTime, endTime) || other.endTime == endTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    winnerFaction,
    const DeepCollectionEquality().hash(_votes),
    const DeepCollectionEquality().hash(_rankings),
    endTime,
  );

  /// Create a copy of GameResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameResultImplCopyWith<_$GameResultImpl> get copyWith =>
      __$$GameResultImplCopyWithImpl<_$GameResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameResultImplToJson(this);
  }
}

abstract class _GameResult implements GameResult {
  const factory _GameResult({
    required final String winnerFaction,
    required final Map<String, double> votes,
    required final List<PlayerRanking> rankings,
    final DateTime? endTime,
  }) = _$GameResultImpl;

  factory _GameResult.fromJson(Map<String, dynamic> json) =
      _$GameResultImpl.fromJson;

  @override
  String get winnerFaction;
  @override
  Map<String, double> get votes;
  @override
  List<PlayerRanking> get rankings;
  @override
  DateTime? get endTime;

  /// Create a copy of GameResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameResultImplCopyWith<_$GameResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerRanking _$PlayerRankingFromJson(Map<String, dynamic> json) {
  return _PlayerRanking.fromJson(json);
}

/// @nodoc
mixin _$PlayerRanking {
  String get playerId => throw _privateConstructorUsedError;
  String get playerName => throw _privateConstructorUsedError;
  CharacterType get character => throw _privateConstructorUsedError;
  int get finalReputation => throw _privateConstructorUsedError;
  int get rank => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;

  /// Serializes this PlayerRanking to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerRanking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerRankingCopyWith<PlayerRanking> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerRankingCopyWith<$Res> {
  factory $PlayerRankingCopyWith(
    PlayerRanking value,
    $Res Function(PlayerRanking) then,
  ) = _$PlayerRankingCopyWithImpl<$Res, PlayerRanking>;
  @useResult
  $Res call({
    String playerId,
    String playerName,
    CharacterType character,
    int finalReputation,
    int rank,
    int score,
  });
}

/// @nodoc
class _$PlayerRankingCopyWithImpl<$Res, $Val extends PlayerRanking>
    implements $PlayerRankingCopyWith<$Res> {
  _$PlayerRankingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerRanking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? character = null,
    Object? finalReputation = null,
    Object? rank = null,
    Object? score = null,
  }) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
            playerName: null == playerName
                ? _value.playerName
                : playerName // ignore: cast_nullable_to_non_nullable
                      as String,
            character: null == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                      as CharacterType,
            finalReputation: null == finalReputation
                ? _value.finalReputation
                : finalReputation // ignore: cast_nullable_to_non_nullable
                      as int,
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerRankingImplCopyWith<$Res>
    implements $PlayerRankingCopyWith<$Res> {
  factory _$$PlayerRankingImplCopyWith(
    _$PlayerRankingImpl value,
    $Res Function(_$PlayerRankingImpl) then,
  ) = __$$PlayerRankingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String playerId,
    String playerName,
    CharacterType character,
    int finalReputation,
    int rank,
    int score,
  });
}

/// @nodoc
class __$$PlayerRankingImplCopyWithImpl<$Res>
    extends _$PlayerRankingCopyWithImpl<$Res, _$PlayerRankingImpl>
    implements _$$PlayerRankingImplCopyWith<$Res> {
  __$$PlayerRankingImplCopyWithImpl(
    _$PlayerRankingImpl _value,
    $Res Function(_$PlayerRankingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerRanking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? character = null,
    Object? finalReputation = null,
    Object? rank = null,
    Object? score = null,
  }) {
    return _then(
      _$PlayerRankingImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        playerName: null == playerName
            ? _value.playerName
            : playerName // ignore: cast_nullable_to_non_nullable
                  as String,
        character: null == character
            ? _value.character
            : character // ignore: cast_nullable_to_non_nullable
                  as CharacterType,
        finalReputation: null == finalReputation
            ? _value.finalReputation
            : finalReputation // ignore: cast_nullable_to_non_nullable
                  as int,
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerRankingImpl implements _PlayerRanking {
  const _$PlayerRankingImpl({
    required this.playerId,
    required this.playerName,
    required this.character,
    required this.finalReputation,
    required this.rank,
    required this.score,
  });

  factory _$PlayerRankingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerRankingImplFromJson(json);

  @override
  final String playerId;
  @override
  final String playerName;
  @override
  final CharacterType character;
  @override
  final int finalReputation;
  @override
  final int rank;
  @override
  final int score;

  @override
  String toString() {
    return 'PlayerRanking(playerId: $playerId, playerName: $playerName, character: $character, finalReputation: $finalReputation, rank: $rank, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerRankingImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.finalReputation, finalReputation) ||
                other.finalReputation == finalReputation) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    playerId,
    playerName,
    character,
    finalReputation,
    rank,
    score,
  );

  /// Create a copy of PlayerRanking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerRankingImplCopyWith<_$PlayerRankingImpl> get copyWith =>
      __$$PlayerRankingImplCopyWithImpl<_$PlayerRankingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerRankingImplToJson(this);
  }
}

abstract class _PlayerRanking implements PlayerRanking {
  const factory _PlayerRanking({
    required final String playerId,
    required final String playerName,
    required final CharacterType character,
    required final int finalReputation,
    required final int rank,
    required final int score,
  }) = _$PlayerRankingImpl;

  factory _PlayerRanking.fromJson(Map<String, dynamic> json) =
      _$PlayerRankingImpl.fromJson;

  @override
  String get playerId;
  @override
  String get playerName;
  @override
  CharacterType get character;
  @override
  int get finalReputation;
  @override
  int get rank;
  @override
  int get score;

  /// Create a copy of PlayerRanking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerRankingImplCopyWith<_$PlayerRankingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
