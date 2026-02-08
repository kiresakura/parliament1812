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
  CharacterType get character => throw _privateConstructorUsedError;
  String get faction => throw _privateConstructorUsedError;
  PlayerResources get resources => throw _privateConstructorUsedError;
  bool get isReady => throw _privateConstructorUsedError;
  bool get isHost => throw _privateConstructorUsedError;
  bool get isAlive => throw _privateConstructorUsedError; // false = 政治死亡
  List<String> get handCards => throw _privateConstructorUsedError; // 手牌 ID 列表
  List<String> get negativeTraits => throw _privateConstructorUsedError; // 負面特質
  Map<String, dynamic> get status => throw _privateConstructorUsedError;

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
    CharacterType character,
    String faction,
    PlayerResources resources,
    bool isReady,
    bool isHost,
    bool isAlive,
    List<String> handCards,
    List<String> negativeTraits,
    Map<String, dynamic> status,
  });

  $PlayerResourcesCopyWith<$Res> get resources;
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
    Object? character = null,
    Object? faction = null,
    Object? resources = null,
    Object? isReady = null,
    Object? isHost = null,
    Object? isAlive = null,
    Object? handCards = null,
    Object? negativeTraits = null,
    Object? status = null,
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
            character: null == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                      as CharacterType,
            faction: null == faction
                ? _value.faction
                : faction // ignore: cast_nullable_to_non_nullable
                      as String,
            resources: null == resources
                ? _value.resources
                : resources // ignore: cast_nullable_to_non_nullable
                      as PlayerResources,
            isReady: null == isReady
                ? _value.isReady
                : isReady // ignore: cast_nullable_to_non_nullable
                      as bool,
            isHost: null == isHost
                ? _value.isHost
                : isHost // ignore: cast_nullable_to_non_nullable
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
          )
          as $Val,
    );
  }

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerResourcesCopyWith<$Res> get resources {
    return $PlayerResourcesCopyWith<$Res>(_value.resources, (value) {
      return _then(_value.copyWith(resources: value) as $Val);
    });
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
    CharacterType character,
    String faction,
    PlayerResources resources,
    bool isReady,
    bool isHost,
    bool isAlive,
    List<String> handCards,
    List<String> negativeTraits,
    Map<String, dynamic> status,
  });

  @override
  $PlayerResourcesCopyWith<$Res> get resources;
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
    Object? character = null,
    Object? faction = null,
    Object? resources = null,
    Object? isReady = null,
    Object? isHost = null,
    Object? isAlive = null,
    Object? handCards = null,
    Object? negativeTraits = null,
    Object? status = null,
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
        character: null == character
            ? _value.character
            : character // ignore: cast_nullable_to_non_nullable
                  as CharacterType,
        faction: null == faction
            ? _value.faction
            : faction // ignore: cast_nullable_to_non_nullable
                  as String,
        resources: null == resources
            ? _value.resources
            : resources // ignore: cast_nullable_to_non_nullable
                  as PlayerResources,
        isReady: null == isReady
            ? _value.isReady
            : isReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        isHost: null == isHost
            ? _value.isHost
            : isHost // ignore: cast_nullable_to_non_nullable
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
    required this.character,
    required this.faction,
    required this.resources,
    required this.isReady,
    required this.isHost,
    required this.isAlive,
    final List<String> handCards = const [],
    final List<String> negativeTraits = const [],
    final Map<String, dynamic> status = const {},
  }) : _handCards = handCards,
       _negativeTraits = negativeTraits,
       _status = status;

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final CharacterType character;
  @override
  final String faction;
  @override
  final PlayerResources resources;
  @override
  final bool isReady;
  @override
  final bool isHost;
  @override
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

  @override
  String toString() {
    return 'Player(id: $id, name: $name, character: $character, faction: $faction, resources: $resources, isReady: $isReady, isHost: $isHost, isAlive: $isAlive, handCards: $handCards, negativeTraits: $negativeTraits, status: $status)';
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
            (identical(other.faction, faction) || other.faction == faction) &&
            (identical(other.resources, resources) ||
                other.resources == resources) &&
            (identical(other.isReady, isReady) || other.isReady == isReady) &&
            (identical(other.isHost, isHost) || other.isHost == isHost) &&
            (identical(other.isAlive, isAlive) || other.isAlive == isAlive) &&
            const DeepCollectionEquality().equals(
              other._handCards,
              _handCards,
            ) &&
            const DeepCollectionEquality().equals(
              other._negativeTraits,
              _negativeTraits,
            ) &&
            const DeepCollectionEquality().equals(other._status, _status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    character,
    faction,
    resources,
    isReady,
    isHost,
    isAlive,
    const DeepCollectionEquality().hash(_handCards),
    const DeepCollectionEquality().hash(_negativeTraits),
    const DeepCollectionEquality().hash(_status),
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
    required final CharacterType character,
    required final String faction,
    required final PlayerResources resources,
    required final bool isReady,
    required final bool isHost,
    required final bool isAlive,
    final List<String> handCards,
    final List<String> negativeTraits,
    final Map<String, dynamic> status,
  }) = _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  CharacterType get character;
  @override
  String get faction;
  @override
  PlayerResources get resources;
  @override
  bool get isReady;
  @override
  bool get isHost;
  @override
  bool get isAlive; // false = 政治死亡
  @override
  List<String> get handCards; // 手牌 ID 列表
  @override
  List<String> get negativeTraits; // 負面特質
  @override
  Map<String, dynamic> get status;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerResources _$PlayerResourcesFromJson(Map<String, dynamic> json) {
  return _PlayerResources.fromJson(json);
}

/// @nodoc
mixin _$PlayerResources {
  int get reputation => throw _privateConstructorUsedError; // 聲望 ❤️
  int get influence => throw _privateConstructorUsedError; // 影響力 🌟
  int get gold => throw _privateConstructorUsedError;

  /// Serializes this PlayerResources to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerResources
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerResourcesCopyWith<PlayerResources> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerResourcesCopyWith<$Res> {
  factory $PlayerResourcesCopyWith(
    PlayerResources value,
    $Res Function(PlayerResources) then,
  ) = _$PlayerResourcesCopyWithImpl<$Res, PlayerResources>;
  @useResult
  $Res call({int reputation, int influence, int gold});
}

/// @nodoc
class _$PlayerResourcesCopyWithImpl<$Res, $Val extends PlayerResources>
    implements $PlayerResourcesCopyWith<$Res> {
  _$PlayerResourcesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerResources
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reputation = null,
    Object? influence = null,
    Object? gold = null,
  }) {
    return _then(
      _value.copyWith(
            reputation: null == reputation
                ? _value.reputation
                : reputation // ignore: cast_nullable_to_non_nullable
                      as int,
            influence: null == influence
                ? _value.influence
                : influence // ignore: cast_nullable_to_non_nullable
                      as int,
            gold: null == gold
                ? _value.gold
                : gold // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerResourcesImplCopyWith<$Res>
    implements $PlayerResourcesCopyWith<$Res> {
  factory _$$PlayerResourcesImplCopyWith(
    _$PlayerResourcesImpl value,
    $Res Function(_$PlayerResourcesImpl) then,
  ) = __$$PlayerResourcesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int reputation, int influence, int gold});
}

/// @nodoc
class __$$PlayerResourcesImplCopyWithImpl<$Res>
    extends _$PlayerResourcesCopyWithImpl<$Res, _$PlayerResourcesImpl>
    implements _$$PlayerResourcesImplCopyWith<$Res> {
  __$$PlayerResourcesImplCopyWithImpl(
    _$PlayerResourcesImpl _value,
    $Res Function(_$PlayerResourcesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerResources
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reputation = null,
    Object? influence = null,
    Object? gold = null,
  }) {
    return _then(
      _$PlayerResourcesImpl(
        reputation: null == reputation
            ? _value.reputation
            : reputation // ignore: cast_nullable_to_non_nullable
                  as int,
        influence: null == influence
            ? _value.influence
            : influence // ignore: cast_nullable_to_non_nullable
                  as int,
        gold: null == gold
            ? _value.gold
            : gold // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerResourcesImpl implements _PlayerResources {
  const _$PlayerResourcesImpl({
    this.reputation = 50,
    this.influence = 10,
    this.gold = 30,
  });

  factory _$PlayerResourcesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerResourcesImplFromJson(json);

  @override
  @JsonKey()
  final int reputation;
  // 聲望 ❤️
  @override
  @JsonKey()
  final int influence;
  // 影響力 🌟
  @override
  @JsonKey()
  final int gold;

  @override
  String toString() {
    return 'PlayerResources(reputation: $reputation, influence: $influence, gold: $gold)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerResourcesImpl &&
            (identical(other.reputation, reputation) ||
                other.reputation == reputation) &&
            (identical(other.influence, influence) ||
                other.influence == influence) &&
            (identical(other.gold, gold) || other.gold == gold));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reputation, influence, gold);

  /// Create a copy of PlayerResources
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerResourcesImplCopyWith<_$PlayerResourcesImpl> get copyWith =>
      __$$PlayerResourcesImplCopyWithImpl<_$PlayerResourcesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerResourcesImplToJson(this);
  }
}

abstract class _PlayerResources implements PlayerResources {
  const factory _PlayerResources({
    final int reputation,
    final int influence,
    final int gold,
  }) = _$PlayerResourcesImpl;

  factory _PlayerResources.fromJson(Map<String, dynamic> json) =
      _$PlayerResourcesImpl.fromJson;

  @override
  int get reputation; // 聲望 ❤️
  @override
  int get influence; // 影響力 🌟
  @override
  int get gold;

  /// Create a copy of PlayerResources
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerResourcesImplCopyWith<_$PlayerResourcesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
