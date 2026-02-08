// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Room _$RoomFromJson(Map<String, dynamic> json) {
  return _Room.fromJson(json);
}

/// @nodoc
mixin _$Room {
  String get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get hostId => throw _privateConstructorUsedError;
  RoomStatus get status => throw _privateConstructorUsedError;
  GamePhase get phase => throw _privateConstructorUsedError;
  List<Player> get players => throw _privateConstructorUsedError;
  RoomSettings get settings => throw _privateConstructorUsedError;
  int get round => throw _privateConstructorUsedError;
  int get remainingSeconds => throw _privateConstructorUsedError;
  String get currentBill => throw _privateConstructorUsedError; // 當前議案內容
  Map<String, dynamic> get gameState =>
      throw _privateConstructorUsedError; // 遊戲狀態資料
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomCopyWith<Room> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomCopyWith<$Res> {
  factory $RoomCopyWith(Room value, $Res Function(Room) then) =
      _$RoomCopyWithImpl<$Res, Room>;
  @useResult
  $Res call({
    String id,
    String code,
    String name,
    String hostId,
    RoomStatus status,
    GamePhase phase,
    List<Player> players,
    RoomSettings settings,
    int round,
    int remainingSeconds,
    String currentBill,
    Map<String, dynamic> gameState,
    DateTime createdAt,
    DateTime? startedAt,
  });

  $RoomSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class _$RoomCopyWithImpl<$Res, $Val extends Room>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? hostId = null,
    Object? status = null,
    Object? phase = null,
    Object? players = null,
    Object? settings = null,
    Object? round = null,
    Object? remainingSeconds = null,
    Object? currentBill = null,
    Object? gameState = null,
    Object? createdAt = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            hostId: null == hostId
                ? _value.hostId
                : hostId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as RoomStatus,
            phase: null == phase
                ? _value.phase
                : phase // ignore: cast_nullable_to_non_nullable
                      as GamePhase,
            players: null == players
                ? _value.players
                : players // ignore: cast_nullable_to_non_nullable
                      as List<Player>,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as RoomSettings,
            round: null == round
                ? _value.round
                : round // ignore: cast_nullable_to_non_nullable
                      as int,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            currentBill: null == currentBill
                ? _value.currentBill
                : currentBill // ignore: cast_nullable_to_non_nullable
                      as String,
            gameState: null == gameState
                ? _value.gameState
                : gameState // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RoomSettingsCopyWith<$Res> get settings {
    return $RoomSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomImplCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$$RoomImplCopyWith(
    _$RoomImpl value,
    $Res Function(_$RoomImpl) then,
  ) = __$$RoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String code,
    String name,
    String hostId,
    RoomStatus status,
    GamePhase phase,
    List<Player> players,
    RoomSettings settings,
    int round,
    int remainingSeconds,
    String currentBill,
    Map<String, dynamic> gameState,
    DateTime createdAt,
    DateTime? startedAt,
  });

  @override
  $RoomSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class __$$RoomImplCopyWithImpl<$Res>
    extends _$RoomCopyWithImpl<$Res, _$RoomImpl>
    implements _$$RoomImplCopyWith<$Res> {
  __$$RoomImplCopyWithImpl(_$RoomImpl _value, $Res Function(_$RoomImpl) _then)
    : super(_value, _then);

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? hostId = null,
    Object? status = null,
    Object? phase = null,
    Object? players = null,
    Object? settings = null,
    Object? round = null,
    Object? remainingSeconds = null,
    Object? currentBill = null,
    Object? gameState = null,
    Object? createdAt = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _$RoomImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        hostId: null == hostId
            ? _value.hostId
            : hostId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as RoomStatus,
        phase: null == phase
            ? _value.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as GamePhase,
        players: null == players
            ? _value._players
            : players // ignore: cast_nullable_to_non_nullable
                  as List<Player>,
        settings: null == settings
            ? _value.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as RoomSettings,
        round: null == round
            ? _value.round
            : round // ignore: cast_nullable_to_non_nullable
                  as int,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        currentBill: null == currentBill
            ? _value.currentBill
            : currentBill // ignore: cast_nullable_to_non_nullable
                  as String,
        gameState: null == gameState
            ? _value._gameState
            : gameState // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomImpl implements _Room {
  const _$RoomImpl({
    required this.id,
    required this.code,
    required this.name,
    required this.hostId,
    required this.status,
    required this.phase,
    required final List<Player> players,
    required this.settings,
    this.round = 1,
    this.remainingSeconds = 0,
    this.currentBill = '',
    final Map<String, dynamic> gameState = const {},
    required this.createdAt,
    this.startedAt,
  }) : _players = players,
       _gameState = gameState;

  factory _$RoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomImplFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String hostId;
  @override
  final RoomStatus status;
  @override
  final GamePhase phase;
  final List<Player> _players;
  @override
  List<Player> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  @override
  final RoomSettings settings;
  @override
  @JsonKey()
  final int round;
  @override
  @JsonKey()
  final int remainingSeconds;
  @override
  @JsonKey()
  final String currentBill;
  // 當前議案內容
  final Map<String, dynamic> _gameState;
  // 當前議案內容
  @override
  @JsonKey()
  Map<String, dynamic> get gameState {
    if (_gameState is EqualUnmodifiableMapView) return _gameState;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_gameState);
  }

  // 遊戲狀態資料
  @override
  final DateTime createdAt;
  @override
  final DateTime? startedAt;

  @override
  String toString() {
    return 'Room(id: $id, code: $code, name: $name, hostId: $hostId, status: $status, phase: $phase, players: $players, settings: $settings, round: $round, remainingSeconds: $remainingSeconds, currentBill: $currentBill, gameState: $gameState, createdAt: $createdAt, startedAt: $startedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.phase, phase) || other.phase == phase) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.currentBill, currentBill) ||
                other.currentBill == currentBill) &&
            const DeepCollectionEquality().equals(
              other._gameState,
              _gameState,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    code,
    name,
    hostId,
    status,
    phase,
    const DeepCollectionEquality().hash(_players),
    settings,
    round,
    remainingSeconds,
    currentBill,
    const DeepCollectionEquality().hash(_gameState),
    createdAt,
    startedAt,
  );

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      __$$RoomImplCopyWithImpl<_$RoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomImplToJson(this);
  }
}

abstract class _Room implements Room {
  const factory _Room({
    required final String id,
    required final String code,
    required final String name,
    required final String hostId,
    required final RoomStatus status,
    required final GamePhase phase,
    required final List<Player> players,
    required final RoomSettings settings,
    final int round,
    final int remainingSeconds,
    final String currentBill,
    final Map<String, dynamic> gameState,
    required final DateTime createdAt,
    final DateTime? startedAt,
  }) = _$RoomImpl;

  factory _Room.fromJson(Map<String, dynamic> json) = _$RoomImpl.fromJson;

  @override
  String get id;
  @override
  String get code;
  @override
  String get name;
  @override
  String get hostId;
  @override
  RoomStatus get status;
  @override
  GamePhase get phase;
  @override
  List<Player> get players;
  @override
  RoomSettings get settings;
  @override
  int get round;
  @override
  int get remainingSeconds;
  @override
  String get currentBill; // 當前議案內容
  @override
  Map<String, dynamic> get gameState; // 遊戲狀態資料
  @override
  DateTime get createdAt;
  @override
  DateTime? get startedAt;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoomSettings _$RoomSettingsFromJson(Map<String, dynamic> json) {
  return _RoomSettings.fromJson(json);
}

/// @nodoc
mixin _$RoomSettings {
  int get maxPlayers => throw _privateConstructorUsedError;
  int get minPlayers => throw _privateConstructorUsedError;
  bool get allowSpectators => throw _privateConstructorUsedError;
  bool get isPrivate => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  int get preparationDuration => throw _privateConstructorUsedError;
  int get conspiracyDuration => throw _privateConstructorUsedError;
  int get debateDuration => throw _privateConstructorUsedError;
  int get eventDuration => throw _privateConstructorUsedError;
  int get finalSpeechDuration => throw _privateConstructorUsedError;
  int get votingDuration => throw _privateConstructorUsedError;

  /// Serializes this RoomSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomSettingsCopyWith<RoomSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomSettingsCopyWith<$Res> {
  factory $RoomSettingsCopyWith(
    RoomSettings value,
    $Res Function(RoomSettings) then,
  ) = _$RoomSettingsCopyWithImpl<$Res, RoomSettings>;
  @useResult
  $Res call({
    int maxPlayers,
    int minPlayers,
    bool allowSpectators,
    bool isPrivate,
    String password,
    int preparationDuration,
    int conspiracyDuration,
    int debateDuration,
    int eventDuration,
    int finalSpeechDuration,
    int votingDuration,
  });
}

/// @nodoc
class _$RoomSettingsCopyWithImpl<$Res, $Val extends RoomSettings>
    implements $RoomSettingsCopyWith<$Res> {
  _$RoomSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxPlayers = null,
    Object? minPlayers = null,
    Object? allowSpectators = null,
    Object? isPrivate = null,
    Object? password = null,
    Object? preparationDuration = null,
    Object? conspiracyDuration = null,
    Object? debateDuration = null,
    Object? eventDuration = null,
    Object? finalSpeechDuration = null,
    Object? votingDuration = null,
  }) {
    return _then(
      _value.copyWith(
            maxPlayers: null == maxPlayers
                ? _value.maxPlayers
                : maxPlayers // ignore: cast_nullable_to_non_nullable
                      as int,
            minPlayers: null == minPlayers
                ? _value.minPlayers
                : minPlayers // ignore: cast_nullable_to_non_nullable
                      as int,
            allowSpectators: null == allowSpectators
                ? _value.allowSpectators
                : allowSpectators // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPrivate: null == isPrivate
                ? _value.isPrivate
                : isPrivate // ignore: cast_nullable_to_non_nullable
                      as bool,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            preparationDuration: null == preparationDuration
                ? _value.preparationDuration
                : preparationDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            conspiracyDuration: null == conspiracyDuration
                ? _value.conspiracyDuration
                : conspiracyDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            debateDuration: null == debateDuration
                ? _value.debateDuration
                : debateDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            eventDuration: null == eventDuration
                ? _value.eventDuration
                : eventDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            finalSpeechDuration: null == finalSpeechDuration
                ? _value.finalSpeechDuration
                : finalSpeechDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            votingDuration: null == votingDuration
                ? _value.votingDuration
                : votingDuration // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoomSettingsImplCopyWith<$Res>
    implements $RoomSettingsCopyWith<$Res> {
  factory _$$RoomSettingsImplCopyWith(
    _$RoomSettingsImpl value,
    $Res Function(_$RoomSettingsImpl) then,
  ) = __$$RoomSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int maxPlayers,
    int minPlayers,
    bool allowSpectators,
    bool isPrivate,
    String password,
    int preparationDuration,
    int conspiracyDuration,
    int debateDuration,
    int eventDuration,
    int finalSpeechDuration,
    int votingDuration,
  });
}

/// @nodoc
class __$$RoomSettingsImplCopyWithImpl<$Res>
    extends _$RoomSettingsCopyWithImpl<$Res, _$RoomSettingsImpl>
    implements _$$RoomSettingsImplCopyWith<$Res> {
  __$$RoomSettingsImplCopyWithImpl(
    _$RoomSettingsImpl _value,
    $Res Function(_$RoomSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoomSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxPlayers = null,
    Object? minPlayers = null,
    Object? allowSpectators = null,
    Object? isPrivate = null,
    Object? password = null,
    Object? preparationDuration = null,
    Object? conspiracyDuration = null,
    Object? debateDuration = null,
    Object? eventDuration = null,
    Object? finalSpeechDuration = null,
    Object? votingDuration = null,
  }) {
    return _then(
      _$RoomSettingsImpl(
        maxPlayers: null == maxPlayers
            ? _value.maxPlayers
            : maxPlayers // ignore: cast_nullable_to_non_nullable
                  as int,
        minPlayers: null == minPlayers
            ? _value.minPlayers
            : minPlayers // ignore: cast_nullable_to_non_nullable
                  as int,
        allowSpectators: null == allowSpectators
            ? _value.allowSpectators
            : allowSpectators // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPrivate: null == isPrivate
            ? _value.isPrivate
            : isPrivate // ignore: cast_nullable_to_non_nullable
                  as bool,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        preparationDuration: null == preparationDuration
            ? _value.preparationDuration
            : preparationDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        conspiracyDuration: null == conspiracyDuration
            ? _value.conspiracyDuration
            : conspiracyDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        debateDuration: null == debateDuration
            ? _value.debateDuration
            : debateDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        eventDuration: null == eventDuration
            ? _value.eventDuration
            : eventDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        finalSpeechDuration: null == finalSpeechDuration
            ? _value.finalSpeechDuration
            : finalSpeechDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        votingDuration: null == votingDuration
            ? _value.votingDuration
            : votingDuration // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomSettingsImpl implements _RoomSettings {
  const _$RoomSettingsImpl({
    this.maxPlayers = 7,
    this.minPlayers = 3,
    this.allowSpectators = true,
    this.isPrivate = false,
    this.password = '',
    this.preparationDuration = 60,
    this.conspiracyDuration = 180,
    this.debateDuration = 360,
    this.eventDuration = 60,
    this.finalSpeechDuration = 120,
    this.votingDuration = 60,
  });

  factory _$RoomSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomSettingsImplFromJson(json);

  @override
  @JsonKey()
  final int maxPlayers;
  @override
  @JsonKey()
  final int minPlayers;
  @override
  @JsonKey()
  final bool allowSpectators;
  @override
  @JsonKey()
  final bool isPrivate;
  @override
  @JsonKey()
  final String password;
  @override
  @JsonKey()
  final int preparationDuration;
  @override
  @JsonKey()
  final int conspiracyDuration;
  @override
  @JsonKey()
  final int debateDuration;
  @override
  @JsonKey()
  final int eventDuration;
  @override
  @JsonKey()
  final int finalSpeechDuration;
  @override
  @JsonKey()
  final int votingDuration;

  @override
  String toString() {
    return 'RoomSettings(maxPlayers: $maxPlayers, minPlayers: $minPlayers, allowSpectators: $allowSpectators, isPrivate: $isPrivate, password: $password, preparationDuration: $preparationDuration, conspiracyDuration: $conspiracyDuration, debateDuration: $debateDuration, eventDuration: $eventDuration, finalSpeechDuration: $finalSpeechDuration, votingDuration: $votingDuration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomSettingsImpl &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.minPlayers, minPlayers) ||
                other.minPlayers == minPlayers) &&
            (identical(other.allowSpectators, allowSpectators) ||
                other.allowSpectators == allowSpectators) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.preparationDuration, preparationDuration) ||
                other.preparationDuration == preparationDuration) &&
            (identical(other.conspiracyDuration, conspiracyDuration) ||
                other.conspiracyDuration == conspiracyDuration) &&
            (identical(other.debateDuration, debateDuration) ||
                other.debateDuration == debateDuration) &&
            (identical(other.eventDuration, eventDuration) ||
                other.eventDuration == eventDuration) &&
            (identical(other.finalSpeechDuration, finalSpeechDuration) ||
                other.finalSpeechDuration == finalSpeechDuration) &&
            (identical(other.votingDuration, votingDuration) ||
                other.votingDuration == votingDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    maxPlayers,
    minPlayers,
    allowSpectators,
    isPrivate,
    password,
    preparationDuration,
    conspiracyDuration,
    debateDuration,
    eventDuration,
    finalSpeechDuration,
    votingDuration,
  );

  /// Create a copy of RoomSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomSettingsImplCopyWith<_$RoomSettingsImpl> get copyWith =>
      __$$RoomSettingsImplCopyWithImpl<_$RoomSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomSettingsImplToJson(this);
  }
}

abstract class _RoomSettings implements RoomSettings {
  const factory _RoomSettings({
    final int maxPlayers,
    final int minPlayers,
    final bool allowSpectators,
    final bool isPrivate,
    final String password,
    final int preparationDuration,
    final int conspiracyDuration,
    final int debateDuration,
    final int eventDuration,
    final int finalSpeechDuration,
    final int votingDuration,
  }) = _$RoomSettingsImpl;

  factory _RoomSettings.fromJson(Map<String, dynamic> json) =
      _$RoomSettingsImpl.fromJson;

  @override
  int get maxPlayers;
  @override
  int get minPlayers;
  @override
  bool get allowSpectators;
  @override
  bool get isPrivate;
  @override
  String get password;
  @override
  int get preparationDuration;
  @override
  int get conspiracyDuration;
  @override
  int get debateDuration;
  @override
  int get eventDuration;
  @override
  int get finalSpeechDuration;
  @override
  int get votingDuration;

  /// Create a copy of RoomSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomSettingsImplCopyWith<_$RoomSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
