// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_amenity_freezed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RoomAmenityFreezed _$RoomAmenityFreezedFromJson(Map<String, dynamic> json) {
  return _RoomAmenityFreezed.fromJson(json);
}

/// @nodoc
mixin _$RoomAmenityFreezed {
  int get roomId => throw _privateConstructorUsedError;
  BasicOptions get basicOptions => throw _privateConstructorUsedError;
  AdditionalOptions get additionalOptions => throw _privateConstructorUsedError;
  ConvenienceOptions get convenienceOptions =>
      throw _privateConstructorUsedError;
  bool get petsAllowed => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this RoomAmenityFreezed to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomAmenityFreezedCopyWith<RoomAmenityFreezed> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomAmenityFreezedCopyWith<$Res> {
  factory $RoomAmenityFreezedCopyWith(
    RoomAmenityFreezed value,
    $Res Function(RoomAmenityFreezed) then,
  ) = _$RoomAmenityFreezedCopyWithImpl<$Res, RoomAmenityFreezed>;
  @useResult
  $Res call({
    int roomId,
    BasicOptions basicOptions,
    AdditionalOptions additionalOptions,
    ConvenienceOptions convenienceOptions,
    bool petsAllowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  $BasicOptionsCopyWith<$Res> get basicOptions;
  $AdditionalOptionsCopyWith<$Res> get additionalOptions;
  $ConvenienceOptionsCopyWith<$Res> get convenienceOptions;
}

/// @nodoc
class _$RoomAmenityFreezedCopyWithImpl<$Res, $Val extends RoomAmenityFreezed>
    implements $RoomAmenityFreezedCopyWith<$Res> {
  _$RoomAmenityFreezedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? basicOptions = null,
    Object? additionalOptions = null,
    Object? convenienceOptions = null,
    Object? petsAllowed = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            roomId: null == roomId
                ? _value.roomId
                : roomId // ignore: cast_nullable_to_non_nullable
                      as int,
            basicOptions: null == basicOptions
                ? _value.basicOptions
                : basicOptions // ignore: cast_nullable_to_non_nullable
                      as BasicOptions,
            additionalOptions: null == additionalOptions
                ? _value.additionalOptions
                : additionalOptions // ignore: cast_nullable_to_non_nullable
                      as AdditionalOptions,
            convenienceOptions: null == convenienceOptions
                ? _value.convenienceOptions
                : convenienceOptions // ignore: cast_nullable_to_non_nullable
                      as ConvenienceOptions,
            petsAllowed: null == petsAllowed
                ? _value.petsAllowed
                : petsAllowed // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BasicOptionsCopyWith<$Res> get basicOptions {
    return $BasicOptionsCopyWith<$Res>(_value.basicOptions, (value) {
      return _then(_value.copyWith(basicOptions: value) as $Val);
    });
  }

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AdditionalOptionsCopyWith<$Res> get additionalOptions {
    return $AdditionalOptionsCopyWith<$Res>(_value.additionalOptions, (value) {
      return _then(_value.copyWith(additionalOptions: value) as $Val);
    });
  }

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConvenienceOptionsCopyWith<$Res> get convenienceOptions {
    return $ConvenienceOptionsCopyWith<$Res>(_value.convenienceOptions, (
      value,
    ) {
      return _then(_value.copyWith(convenienceOptions: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomAmenityFreezedImplCopyWith<$Res>
    implements $RoomAmenityFreezedCopyWith<$Res> {
  factory _$$RoomAmenityFreezedImplCopyWith(
    _$RoomAmenityFreezedImpl value,
    $Res Function(_$RoomAmenityFreezedImpl) then,
  ) = __$$RoomAmenityFreezedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int roomId,
    BasicOptions basicOptions,
    AdditionalOptions additionalOptions,
    ConvenienceOptions convenienceOptions,
    bool petsAllowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  $BasicOptionsCopyWith<$Res> get basicOptions;
  @override
  $AdditionalOptionsCopyWith<$Res> get additionalOptions;
  @override
  $ConvenienceOptionsCopyWith<$Res> get convenienceOptions;
}

/// @nodoc
class __$$RoomAmenityFreezedImplCopyWithImpl<$Res>
    extends _$RoomAmenityFreezedCopyWithImpl<$Res, _$RoomAmenityFreezedImpl>
    implements _$$RoomAmenityFreezedImplCopyWith<$Res> {
  __$$RoomAmenityFreezedImplCopyWithImpl(
    _$RoomAmenityFreezedImpl _value,
    $Res Function(_$RoomAmenityFreezedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? basicOptions = null,
    Object? additionalOptions = null,
    Object? convenienceOptions = null,
    Object? petsAllowed = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$RoomAmenityFreezedImpl(
        roomId: null == roomId
            ? _value.roomId
            : roomId // ignore: cast_nullable_to_non_nullable
                  as int,
        basicOptions: null == basicOptions
            ? _value.basicOptions
            : basicOptions // ignore: cast_nullable_to_non_nullable
                  as BasicOptions,
        additionalOptions: null == additionalOptions
            ? _value.additionalOptions
            : additionalOptions // ignore: cast_nullable_to_non_nullable
                  as AdditionalOptions,
        convenienceOptions: null == convenienceOptions
            ? _value.convenienceOptions
            : convenienceOptions // ignore: cast_nullable_to_non_nullable
                  as ConvenienceOptions,
        petsAllowed: null == petsAllowed
            ? _value.petsAllowed
            : petsAllowed // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomAmenityFreezedImpl extends _RoomAmenityFreezed {
  const _$RoomAmenityFreezedImpl({
    required this.roomId,
    required this.basicOptions,
    required this.additionalOptions,
    required this.convenienceOptions,
    this.petsAllowed = false,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$RoomAmenityFreezedImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomAmenityFreezedImplFromJson(json);

  @override
  final int roomId;
  @override
  final BasicOptions basicOptions;
  @override
  final AdditionalOptions additionalOptions;
  @override
  final ConvenienceOptions convenienceOptions;
  @override
  @JsonKey()
  final bool petsAllowed;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'RoomAmenityFreezed(roomId: $roomId, basicOptions: $basicOptions, additionalOptions: $additionalOptions, convenienceOptions: $convenienceOptions, petsAllowed: $petsAllowed, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomAmenityFreezedImpl &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.basicOptions, basicOptions) ||
                other.basicOptions == basicOptions) &&
            (identical(other.additionalOptions, additionalOptions) ||
                other.additionalOptions == additionalOptions) &&
            (identical(other.convenienceOptions, convenienceOptions) ||
                other.convenienceOptions == convenienceOptions) &&
            (identical(other.petsAllowed, petsAllowed) ||
                other.petsAllowed == petsAllowed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    roomId,
    basicOptions,
    additionalOptions,
    convenienceOptions,
    petsAllowed,
    createdAt,
    updatedAt,
  );

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomAmenityFreezedImplCopyWith<_$RoomAmenityFreezedImpl> get copyWith =>
      __$$RoomAmenityFreezedImplCopyWithImpl<_$RoomAmenityFreezedImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomAmenityFreezedImplToJson(this);
  }
}

abstract class _RoomAmenityFreezed extends RoomAmenityFreezed {
  const factory _RoomAmenityFreezed({
    required final int roomId,
    required final BasicOptions basicOptions,
    required final AdditionalOptions additionalOptions,
    required final ConvenienceOptions convenienceOptions,
    final bool petsAllowed,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$RoomAmenityFreezedImpl;
  const _RoomAmenityFreezed._() : super._();

  factory _RoomAmenityFreezed.fromJson(Map<String, dynamic> json) =
      _$RoomAmenityFreezedImpl.fromJson;

  @override
  int get roomId;
  @override
  BasicOptions get basicOptions;
  @override
  AdditionalOptions get additionalOptions;
  @override
  ConvenienceOptions get convenienceOptions;
  @override
  bool get petsAllowed;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of RoomAmenityFreezed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomAmenityFreezedImplCopyWith<_$RoomAmenityFreezedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
