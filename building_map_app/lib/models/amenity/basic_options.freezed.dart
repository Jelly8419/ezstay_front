// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basic_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BasicOptions _$BasicOptionsFromJson(Map<String, dynamic> json) {
  return _BasicOptions.fromJson(json);
}

/// @nodoc
mixin _$BasicOptions {
  bool get refrigerator => throw _privateConstructorUsedError; // 냉장고
  bool get washingMachine => throw _privateConstructorUsedError; // 세탁기
  bool get airConditioner => throw _privateConstructorUsedError; // 에어컨
  bool get sink => throw _privateConstructorUsedError; // 싱크대
  bool get bed => throw _privateConstructorUsedError; // 침대
  bool get tv => throw _privateConstructorUsedError; // TV
  bool get internet => throw _privateConstructorUsedError;

  /// Serializes this BasicOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BasicOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BasicOptionsCopyWith<BasicOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BasicOptionsCopyWith<$Res> {
  factory $BasicOptionsCopyWith(
    BasicOptions value,
    $Res Function(BasicOptions) then,
  ) = _$BasicOptionsCopyWithImpl<$Res, BasicOptions>;
  @useResult
  $Res call({
    bool refrigerator,
    bool washingMachine,
    bool airConditioner,
    bool sink,
    bool bed,
    bool tv,
    bool internet,
  });
}

/// @nodoc
class _$BasicOptionsCopyWithImpl<$Res, $Val extends BasicOptions>
    implements $BasicOptionsCopyWith<$Res> {
  _$BasicOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BasicOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refrigerator = null,
    Object? washingMachine = null,
    Object? airConditioner = null,
    Object? sink = null,
    Object? bed = null,
    Object? tv = null,
    Object? internet = null,
  }) {
    return _then(
      _value.copyWith(
            refrigerator: null == refrigerator
                ? _value.refrigerator
                : refrigerator // ignore: cast_nullable_to_non_nullable
                      as bool,
            washingMachine: null == washingMachine
                ? _value.washingMachine
                : washingMachine // ignore: cast_nullable_to_non_nullable
                      as bool,
            airConditioner: null == airConditioner
                ? _value.airConditioner
                : airConditioner // ignore: cast_nullable_to_non_nullable
                      as bool,
            sink: null == sink
                ? _value.sink
                : sink // ignore: cast_nullable_to_non_nullable
                      as bool,
            bed: null == bed
                ? _value.bed
                : bed // ignore: cast_nullable_to_non_nullable
                      as bool,
            tv: null == tv
                ? _value.tv
                : tv // ignore: cast_nullable_to_non_nullable
                      as bool,
            internet: null == internet
                ? _value.internet
                : internet // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BasicOptionsImplCopyWith<$Res>
    implements $BasicOptionsCopyWith<$Res> {
  factory _$$BasicOptionsImplCopyWith(
    _$BasicOptionsImpl value,
    $Res Function(_$BasicOptionsImpl) then,
  ) = __$$BasicOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool refrigerator,
    bool washingMachine,
    bool airConditioner,
    bool sink,
    bool bed,
    bool tv,
    bool internet,
  });
}

/// @nodoc
class __$$BasicOptionsImplCopyWithImpl<$Res>
    extends _$BasicOptionsCopyWithImpl<$Res, _$BasicOptionsImpl>
    implements _$$BasicOptionsImplCopyWith<$Res> {
  __$$BasicOptionsImplCopyWithImpl(
    _$BasicOptionsImpl _value,
    $Res Function(_$BasicOptionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BasicOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refrigerator = null,
    Object? washingMachine = null,
    Object? airConditioner = null,
    Object? sink = null,
    Object? bed = null,
    Object? tv = null,
    Object? internet = null,
  }) {
    return _then(
      _$BasicOptionsImpl(
        refrigerator: null == refrigerator
            ? _value.refrigerator
            : refrigerator // ignore: cast_nullable_to_non_nullable
                  as bool,
        washingMachine: null == washingMachine
            ? _value.washingMachine
            : washingMachine // ignore: cast_nullable_to_non_nullable
                  as bool,
        airConditioner: null == airConditioner
            ? _value.airConditioner
            : airConditioner // ignore: cast_nullable_to_non_nullable
                  as bool,
        sink: null == sink
            ? _value.sink
            : sink // ignore: cast_nullable_to_non_nullable
                  as bool,
        bed: null == bed
            ? _value.bed
            : bed // ignore: cast_nullable_to_non_nullable
                  as bool,
        tv: null == tv
            ? _value.tv
            : tv // ignore: cast_nullable_to_non_nullable
                  as bool,
        internet: null == internet
            ? _value.internet
            : internet // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BasicOptionsImpl implements _BasicOptions {
  const _$BasicOptionsImpl({
    this.refrigerator = false,
    this.washingMachine = false,
    this.airConditioner = false,
    this.sink = false,
    this.bed = false,
    this.tv = false,
    this.internet = false,
  });

  factory _$BasicOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BasicOptionsImplFromJson(json);

  @override
  @JsonKey()
  final bool refrigerator;
  // 냉장고
  @override
  @JsonKey()
  final bool washingMachine;
  // 세탁기
  @override
  @JsonKey()
  final bool airConditioner;
  // 에어컨
  @override
  @JsonKey()
  final bool sink;
  // 싱크대
  @override
  @JsonKey()
  final bool bed;
  // 침대
  @override
  @JsonKey()
  final bool tv;
  // TV
  @override
  @JsonKey()
  final bool internet;

  @override
  String toString() {
    return 'BasicOptions(refrigerator: $refrigerator, washingMachine: $washingMachine, airConditioner: $airConditioner, sink: $sink, bed: $bed, tv: $tv, internet: $internet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BasicOptionsImpl &&
            (identical(other.refrigerator, refrigerator) ||
                other.refrigerator == refrigerator) &&
            (identical(other.washingMachine, washingMachine) ||
                other.washingMachine == washingMachine) &&
            (identical(other.airConditioner, airConditioner) ||
                other.airConditioner == airConditioner) &&
            (identical(other.sink, sink) || other.sink == sink) &&
            (identical(other.bed, bed) || other.bed == bed) &&
            (identical(other.tv, tv) || other.tv == tv) &&
            (identical(other.internet, internet) ||
                other.internet == internet));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    refrigerator,
    washingMachine,
    airConditioner,
    sink,
    bed,
    tv,
    internet,
  );

  /// Create a copy of BasicOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BasicOptionsImplCopyWith<_$BasicOptionsImpl> get copyWith =>
      __$$BasicOptionsImplCopyWithImpl<_$BasicOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BasicOptionsImplToJson(this);
  }
}

abstract class _BasicOptions implements BasicOptions {
  const factory _BasicOptions({
    final bool refrigerator,
    final bool washingMachine,
    final bool airConditioner,
    final bool sink,
    final bool bed,
    final bool tv,
    final bool internet,
  }) = _$BasicOptionsImpl;

  factory _BasicOptions.fromJson(Map<String, dynamic> json) =
      _$BasicOptionsImpl.fromJson;

  @override
  bool get refrigerator; // 냉장고
  @override
  bool get washingMachine; // 세탁기
  @override
  bool get airConditioner; // 에어컨
  @override
  bool get sink; // 싱크대
  @override
  bool get bed; // 침대
  @override
  bool get tv; // TV
  @override
  bool get internet;

  /// Create a copy of BasicOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BasicOptionsImplCopyWith<_$BasicOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
