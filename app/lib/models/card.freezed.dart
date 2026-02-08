// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameCard _$GameCardFromJson(Map<String, dynamic> json) {
  return _GameCard.fromJson(json);
}

/// @nodoc
mixin _$GameCard {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  CardType get type => throw _privateConstructorUsedError;
  CardRarity get rarity => throw _privateConstructorUsedError;
  CardTargetType get targetType => throw _privateConstructorUsedError;
  int get influenceCost => throw _privateConstructorUsedError;
  int get goldCost => throw _privateConstructorUsedError;
  int get baseValue => throw _privateConstructorUsedError;
  String? get roleId => throw _privateConstructorUsedError; // 角色專屬卡才有
  List<CardEffect> get effects => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this GameCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameCardCopyWith<GameCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCardCopyWith<$Res> {
  factory $GameCardCopyWith(GameCard value, $Res Function(GameCard) then) =
      _$GameCardCopyWithImpl<$Res, GameCard>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    CardType type,
    CardRarity rarity,
    CardTargetType targetType,
    int influenceCost,
    int goldCost,
    int baseValue,
    String? roleId,
    List<CardEffect> effects,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class _$GameCardCopyWithImpl<$Res, $Val extends GameCard>
    implements $GameCardCopyWith<$Res> {
  _$GameCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? rarity = null,
    Object? targetType = null,
    Object? influenceCost = null,
    Object? goldCost = null,
    Object? baseValue = null,
    Object? roleId = freezed,
    Object? effects = null,
    Object? metadata = null,
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
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as CardType,
            rarity: null == rarity
                ? _value.rarity
                : rarity // ignore: cast_nullable_to_non_nullable
                      as CardRarity,
            targetType: null == targetType
                ? _value.targetType
                : targetType // ignore: cast_nullable_to_non_nullable
                      as CardTargetType,
            influenceCost: null == influenceCost
                ? _value.influenceCost
                : influenceCost // ignore: cast_nullable_to_non_nullable
                      as int,
            goldCost: null == goldCost
                ? _value.goldCost
                : goldCost // ignore: cast_nullable_to_non_nullable
                      as int,
            baseValue: null == baseValue
                ? _value.baseValue
                : baseValue // ignore: cast_nullable_to_non_nullable
                      as int,
            roleId: freezed == roleId
                ? _value.roleId
                : roleId // ignore: cast_nullable_to_non_nullable
                      as String?,
            effects: null == effects
                ? _value.effects
                : effects // ignore: cast_nullable_to_non_nullable
                      as List<CardEffect>,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameCardImplCopyWith<$Res>
    implements $GameCardCopyWith<$Res> {
  factory _$$GameCardImplCopyWith(
    _$GameCardImpl value,
    $Res Function(_$GameCardImpl) then,
  ) = __$$GameCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    CardType type,
    CardRarity rarity,
    CardTargetType targetType,
    int influenceCost,
    int goldCost,
    int baseValue,
    String? roleId,
    List<CardEffect> effects,
    Map<String, dynamic> metadata,
  });
}

/// @nodoc
class __$$GameCardImplCopyWithImpl<$Res>
    extends _$GameCardCopyWithImpl<$Res, _$GameCardImpl>
    implements _$$GameCardImplCopyWith<$Res> {
  __$$GameCardImplCopyWithImpl(
    _$GameCardImpl _value,
    $Res Function(_$GameCardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? rarity = null,
    Object? targetType = null,
    Object? influenceCost = null,
    Object? goldCost = null,
    Object? baseValue = null,
    Object? roleId = freezed,
    Object? effects = null,
    Object? metadata = null,
  }) {
    return _then(
      _$GameCardImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as CardType,
        rarity: null == rarity
            ? _value.rarity
            : rarity // ignore: cast_nullable_to_non_nullable
                  as CardRarity,
        targetType: null == targetType
            ? _value.targetType
            : targetType // ignore: cast_nullable_to_non_nullable
                  as CardTargetType,
        influenceCost: null == influenceCost
            ? _value.influenceCost
            : influenceCost // ignore: cast_nullable_to_non_nullable
                  as int,
        goldCost: null == goldCost
            ? _value.goldCost
            : goldCost // ignore: cast_nullable_to_non_nullable
                  as int,
        baseValue: null == baseValue
            ? _value.baseValue
            : baseValue // ignore: cast_nullable_to_non_nullable
                  as int,
        roleId: freezed == roleId
            ? _value.roleId
            : roleId // ignore: cast_nullable_to_non_nullable
                  as String?,
        effects: null == effects
            ? _value._effects
            : effects // ignore: cast_nullable_to_non_nullable
                  as List<CardEffect>,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameCardImpl implements _GameCard {
  const _$GameCardImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.targetType,
    required this.influenceCost,
    this.goldCost = 0,
    required this.baseValue,
    this.roleId,
    final List<CardEffect> effects = const [],
    final Map<String, dynamic> metadata = const {},
  }) : _effects = effects,
       _metadata = metadata;

  factory _$GameCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameCardImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final CardType type;
  @override
  final CardRarity rarity;
  @override
  final CardTargetType targetType;
  @override
  final int influenceCost;
  @override
  @JsonKey()
  final int goldCost;
  @override
  final int baseValue;
  @override
  final String? roleId;
  // 角色專屬卡才有
  final List<CardEffect> _effects;
  // 角色專屬卡才有
  @override
  @JsonKey()
  List<CardEffect> get effects {
    if (_effects is EqualUnmodifiableListView) return _effects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_effects);
  }

  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'GameCard(id: $id, name: $name, description: $description, type: $type, rarity: $rarity, targetType: $targetType, influenceCost: $influenceCost, goldCost: $goldCost, baseValue: $baseValue, roleId: $roleId, effects: $effects, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.rarity, rarity) || other.rarity == rarity) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.influenceCost, influenceCost) ||
                other.influenceCost == influenceCost) &&
            (identical(other.goldCost, goldCost) ||
                other.goldCost == goldCost) &&
            (identical(other.baseValue, baseValue) ||
                other.baseValue == baseValue) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            const DeepCollectionEquality().equals(other._effects, _effects) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    type,
    rarity,
    targetType,
    influenceCost,
    goldCost,
    baseValue,
    roleId,
    const DeepCollectionEquality().hash(_effects),
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameCardImplCopyWith<_$GameCardImpl> get copyWith =>
      __$$GameCardImplCopyWithImpl<_$GameCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameCardImplToJson(this);
  }
}

abstract class _GameCard implements GameCard {
  const factory _GameCard({
    required final String id,
    required final String name,
    required final String description,
    required final CardType type,
    required final CardRarity rarity,
    required final CardTargetType targetType,
    required final int influenceCost,
    final int goldCost,
    required final int baseValue,
    final String? roleId,
    final List<CardEffect> effects,
    final Map<String, dynamic> metadata,
  }) = _$GameCardImpl;

  factory _GameCard.fromJson(Map<String, dynamic> json) =
      _$GameCardImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  CardType get type;
  @override
  CardRarity get rarity;
  @override
  CardTargetType get targetType;
  @override
  int get influenceCost;
  @override
  int get goldCost;
  @override
  int get baseValue;
  @override
  String? get roleId; // 角色專屬卡才有
  @override
  List<CardEffect> get effects;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameCardImplCopyWith<_$GameCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CardEffect _$CardEffectFromJson(Map<String, dynamic> json) {
  return _CardEffect.fromJson(json);
}

/// @nodoc
mixin _$CardEffect {
  CardEffectType get type => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  String? get condition => throw _privateConstructorUsedError;
  String? get target => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;

  /// Serializes this CardEffect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardEffectCopyWith<CardEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardEffectCopyWith<$Res> {
  factory $CardEffectCopyWith(
    CardEffect value,
    $Res Function(CardEffect) then,
  ) = _$CardEffectCopyWithImpl<$Res, CardEffect>;
  @useResult
  $Res call({
    CardEffectType type,
    int value,
    String? condition,
    String? target,
    Map<String, dynamic> params,
  });
}

/// @nodoc
class _$CardEffectCopyWithImpl<$Res, $Val extends CardEffect>
    implements $CardEffectCopyWith<$Res> {
  _$CardEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? value = null,
    Object? condition = freezed,
    Object? target = freezed,
    Object? params = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as CardEffectType,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            condition: freezed == condition
                ? _value.condition
                : condition // ignore: cast_nullable_to_non_nullable
                      as String?,
            target: freezed == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as String?,
            params: null == params
                ? _value.params
                : params // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CardEffectImplCopyWith<$Res>
    implements $CardEffectCopyWith<$Res> {
  factory _$$CardEffectImplCopyWith(
    _$CardEffectImpl value,
    $Res Function(_$CardEffectImpl) then,
  ) = __$$CardEffectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CardEffectType type,
    int value,
    String? condition,
    String? target,
    Map<String, dynamic> params,
  });
}

/// @nodoc
class __$$CardEffectImplCopyWithImpl<$Res>
    extends _$CardEffectCopyWithImpl<$Res, _$CardEffectImpl>
    implements _$$CardEffectImplCopyWith<$Res> {
  __$$CardEffectImplCopyWithImpl(
    _$CardEffectImpl _value,
    $Res Function(_$CardEffectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CardEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? value = null,
    Object? condition = freezed,
    Object? target = freezed,
    Object? params = null,
  }) {
    return _then(
      _$CardEffectImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as CardEffectType,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        condition: freezed == condition
            ? _value.condition
            : condition // ignore: cast_nullable_to_non_nullable
                  as String?,
        target: freezed == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as String?,
        params: null == params
            ? _value._params
            : params // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CardEffectImpl implements _CardEffect {
  const _$CardEffectImpl({
    required this.type,
    required this.value,
    this.condition,
    this.target,
    final Map<String, dynamic> params = const {},
  }) : _params = params;

  factory _$CardEffectImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardEffectImplFromJson(json);

  @override
  final CardEffectType type;
  @override
  final int value;
  @override
  final String? condition;
  @override
  final String? target;
  final Map<String, dynamic> _params;
  @override
  @JsonKey()
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  String toString() {
    return 'CardEffect(type: $type, value: $value, condition: $condition, target: $target, params: $params)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardEffectImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.target, target) || other.target == target) &&
            const DeepCollectionEquality().equals(other._params, _params));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    value,
    condition,
    target,
    const DeepCollectionEquality().hash(_params),
  );

  /// Create a copy of CardEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardEffectImplCopyWith<_$CardEffectImpl> get copyWith =>
      __$$CardEffectImplCopyWithImpl<_$CardEffectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardEffectImplToJson(this);
  }
}

abstract class _CardEffect implements CardEffect {
  const factory _CardEffect({
    required final CardEffectType type,
    required final int value,
    final String? condition,
    final String? target,
    final Map<String, dynamic> params,
  }) = _$CardEffectImpl;

  factory _CardEffect.fromJson(Map<String, dynamic> json) =
      _$CardEffectImpl.fromJson;

  @override
  CardEffectType get type;
  @override
  int get value;
  @override
  String? get condition;
  @override
  String? get target;
  @override
  Map<String, dynamic> get params;

  /// Create a copy of CardEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardEffectImplCopyWith<_$CardEffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
