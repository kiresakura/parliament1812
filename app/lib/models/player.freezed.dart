// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  CharacterType? get character =>
      throw _privateConstructorUsedError; // 可為空，因為初始時未選角
  int get reputation => throw _privateConstructorUsedError; // 聲望（直接從後端）
  int get gold => throw _privateConstructorUsedError; // 金幣（直接從後端）
  bool get isReady => throw _privateConstructorUsedError;
  bool get isHost => throw _privateConstructorUsedError;
  bool get isSpectator => throw _privateConstructorUsedError; // 觀戰者標記
  bool get isAlive => throw _privateConstructorUsedError; // false = 政治死亡
  List<String> get handCards => throw _privateConstructorUsedError; // 手牌 ID 列表
  List<String> get negativeTraits => throw _privateConstructorUsedError; // 負面特質
  Map<String, dynamic> get status =>
      throw _privateConstructorUsedError; // 狀態效果（沉默、封印等）
  // 同盟相關
  List<String> get allianceIds =>
      throw _privateConstructorUsedError; // 同盟 ID 列表
  bool get hasPendingAlliance => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call({
    String id,
    String name,
    CharacterType? character,
    int reputation,
    int gold,
    bool isReady,
    bool isHost,
    bool isSpectator,
    bool isAlive,
    List<String> handCards,
    List<String> negativeTraits,
    Map<String, dynamic> status,
    List<String> allianceIds,
    bool hasPendingAlliance,
  });
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? character = freezed,
    Object? reputation = null,
    Object? gold = null,
    Object? isReady = null,
    Object? isHost = null,
    Object? isSpectator = null,
    Object? isAlive = null,
    Object? handCards = null,
    Object? negativeTraits = null,
    Object? status = null,
    Object? allianceIds = null,
    Object? hasPendingAlliance = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            character: freezed == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                      as CharacterType?,
            reputation: null == reputation
                ? _value.reputation
                : reputation // ignore: cast_nullable_to_non_nullable
                      as int,
            gold: null == gold
                ? _value.gold
                : gold // ignore: cast_nullable_to_non_nullable
                      as int,
            isReady: null == isReady
                ? _value.isReady
                : isReady // ignore: cast_nullable_to_non_nullable
                      as bool,
            isHost: null == isHost
                ? _value.isHost
                : isHost // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSpectator: null == isSpectator
                ? _value.isSpectator
                : isSpectator // ignore: cast_nullable_to_non_nullable
                      as bool,
            isAlive: null == isAlive
                ? _value.isAlive
                : isAlive // ignore: cast_nullable_to_non_nullable
                      as bool,
            handCards: null == handCards
                ? _value.handCards
                : handCards // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            negativeTraits: null == negativeTraits
                ? _value.negativeTraits
                : negativeTraits // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            allianceIds: null == allianceIds
                ? _value.allianceIds
                : allianceIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            hasPendingAlliance: null == hasPendingAlliance
                ? _value.hasPendingAlliance
                : hasPendingAlliance // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
    _$PlayerImpl value,
    $Res Function(_$PlayerImpl) then,
  ) = __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    CharacterType? character,
    int reputation,
    int gold,
    bool isReady,
    bool isHost,
    bool isSpectator,
    bool isAlive,
    List<String> handCards,
    List<String> negativeTraits,
    Map<String, dynamic> status,
    List<String> allianceIds,
    bool hasPendingAlliance,
  });
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
    _$PlayerImpl _value,
    $Res Function(_$PlayerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? character = freezed,
    Object? reputation = null,
    Object? gold = null,
    Object? isReady = null,
    Object? isHost = null,
    Object? isSpectator = null,
    Object? isAlive = null,
    Object? handCards = null,
    Object? negativeTraits = null,
    Object? status = null,
    Object? allianceIds = null,
    Object? hasPendingAlliance = null,
  }) {
    return _then(
      _$PlayerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        character: freezed == character
            ? _value.character
            : character // ignore: cast_nullable_to_non_nullable
                  as CharacterType?,
        reputation: null == reputation
            ? _value.reputation
            : reputation // ignore: cast_nullable_to_non_nullable
                  as int,
        gold: null == gold
            ? _value.gold
            : gold // ignore: cast_nullable_to_non_nullable
                  as int,
        isReady: null == isReady
            ? _value.isReady
            : isReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        isHost: null == isHost
            ? _value.isHost
            : isHost // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSpectator: null == isSpectator
            ? _value.isSpectator
            : isSpectator // ignore: cast_nullable_to_non_nullable
                  as bool,
        isAlive: null == isAlive
            ? _value.isAlive
            : isAlive // ignore: cast_nullable_to_non_nullable
                  as bool,
        handCards: null == handCards
            ? _value._handCards
            : handCards // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        negativeTraits: null == negativeTraits
            ? _value._negativeTraits
            : negativeTraits // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value._status
            : status // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        allianceIds: null == allianceIds
            ? _value._allianceIds
            : allianceIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        hasPendingAlliance: null == hasPendingAlliance
            ? _value.hasPendingAlliance
            : hasPendingAlliance // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl implements _Player {
  const _$PlayerImpl({
    required this.id,
    required this.name,
    this.character,
    required this.reputation,
    required this.gold,
    required this.isReady,
    required this.isHost,
    this.isSpectator = false,
    this.isAlive = true,
    final List<String> handCards = const [],
    final List<String> negativeTraits = const [],
    final Map<String, dynamic> status = const {},
    final List<String> allianceIds = const [],
    this.hasPendingAlliance = false,
  }) : _handCards = handCards,
       _negativeTraits = negativeTraits,
       _status = status,
       _allianceIds = allianceIds;

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final CharacterType? character;
  // 可為空，因為初始時未選角
  @override
  final int reputation;
  // 聲望（直接從後端）
  @override
  final int gold;
  // 金幣（直接從後端）
  @override
  final bool isReady;
  @override
  final bool isHost;
  @override
  @JsonKey()
  final bool isSpectator;
  // 觀戰者標記
  @override
  @JsonKey()
  final bool isAlive;
  // false = 政治死亡
  final List<String> _handCards;
  // false = 政治死亡
  @override
  @JsonKey()
  List<String> get handCards {
    if (_handCards is EqualUnmodifiableListView) return _handCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_handCards);
  }

  // 手牌 ID 列表
  final List<String> _negativeTraits;
  // 手牌 ID 列表
  @override
  @JsonKey()
  List<String> get negativeTraits {
    if (_negativeTraits is EqualUnmodifiableListView) return _negativeTraits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_negativeTraits);
  }

  // 負面特質
  final Map<String, dynamic> _status;
  // 負面特質
  @override
  @JsonKey()
  Map<String, dynamic> get status {
    if (_status is EqualUnmodifiableMapView) return _status;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_status);
  }

  // 狀態效果（沉默、封印等）
  // 同盟相關
  final List<String> _allianceIds;
  // 狀態效果（沉默、封印等）
  // 同盟相關
  @override
  @JsonKey()
  List<String> get allianceIds {
    if (_allianceIds is EqualUnmodifiableListView) return _allianceIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allianceIds);
  }

  // 同盟 ID 列表
  @override
  @JsonKey()
  final bool hasPendingAlliance;

  @override
  String toString() {
    return 'Player(id: $id, name: $name, character: $character, reputation: $reputation, gold: $gold, isReady: $isReady, isHost: $isHost, isSpectator: $isSpectator, isAlive: $isAlive, handCards: $handCards, negativeTraits: $negativeTraits, status: $status, allianceIds: $allianceIds, hasPendingAlliance: $hasPendingAlliance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.reputation, reputation) ||
                other.reputation == reputation) &&
            (identical(other.gold, gold) || other.gold == gold) &&
            (identical(other.isReady, isReady) || other.isReady == isReady) &&
            (identical(other.isHost, isHost) || other.isHost == isHost) &&
            (identical(other.isSpectator, isSpectator) ||
                other.isSpectator == isSpectator) &&
            (identical(other.isAlive, isAlive) || other.isAlive == isAlive) &&
            const DeepCollectionEquality().equals(
              other._handCards,
              _handCards,
            ) &&
            const DeepCollectionEquality().equals(
              other._negativeTraits,
              _negativeTraits,
            ) &&
            const DeepCollectionEquality().equals(other._status, _status) &&
            const DeepCollectionEquality().equals(
              other._allianceIds,
              _allianceIds,
            ) &&
            (identical(other.hasPendingAlliance, hasPendingAlliance) ||
                other.hasPendingAlliance == hasPendingAlliance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    character,
    reputation,
    gold,
    isReady,
    isHost,
    isSpectator,
    isAlive,
    const DeepCollectionEquality().hash(_handCards),
    const DeepCollectionEquality().hash(_negativeTraits),
    const DeepCollectionEquality().hash(_status),
    const DeepCollectionEquality().hash(_allianceIds),
    hasPendingAlliance,
  );

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(this);
  }
}

abstract class _Player implements Player {
  const factory _Player({
    required final String id,
    required final String name,
    final CharacterType? character,
    required final int reputation,
    required final int gold,
    required final bool isReady,
    required final bool isHost,
    final bool isSpectator,
    final bool isAlive,
    final List<String> handCards,
    final List<String> negativeTraits,
    final Map<String, dynamic> status,
    final List<String> allianceIds,
    final bool hasPendingAlliance,
  }) = _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  CharacterType? get character; // 可為空，因為初始時未選角
  @override
  int get reputation; // 聲望（直接從後端）
  @override
  int get gold; // 金幣（直接從後端）
  @override
  bool get isReady;
  @override
  bool get isHost;
  @override
  bool get isSpectator; // 觀戰者標記
  @override
  bool get isAlive; // false = 政治死亡
  @override
  List<String> get handCards; // 手牌 ID 列表
  @override
  List<String> get negativeTraits; // 負面特質
  @override
  Map<String, dynamic> get status; // 狀態效果（沉默、封印等）
  // 同盟相關
  @override
  List<String> get allianceIds; // 同盟 ID 列表
  @override
  bool get hasPendingAlliance;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
