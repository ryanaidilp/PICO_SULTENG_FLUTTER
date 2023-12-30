// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ApiResponseModel<T> _$ApiResponseModelFromJson<T>(
    Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  return _ApiResponseModel<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$ApiResponseModel<T> {
  @JsonKey()
  bool get success => throw _privateConstructorUsedError;
  @JsonKey()
  T get data => throw _privateConstructorUsedError;
  @JsonKey()
  List<ErrorModel>? get errors => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiResponseModelCopyWith<T, ApiResponseModel<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiResponseModelCopyWith<T, $Res> {
  factory $ApiResponseModelCopyWith(
          ApiResponseModel<T> value, $Res Function(ApiResponseModel<T>) then) =
      _$ApiResponseModelCopyWithImpl<T, $Res, ApiResponseModel<T>>;
  @useResult
  $Res call(
      {@JsonKey() bool success,
      @JsonKey() T data,
      @JsonKey() List<ErrorModel>? errors});
}

/// @nodoc
class _$ApiResponseModelCopyWithImpl<T, $Res, $Val extends ApiResponseModel<T>>
    implements $ApiResponseModelCopyWith<T, $Res> {
  _$ApiResponseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = freezed,
    Object? errors = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T,
      errors: freezed == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<ErrorModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiResponseModelImplCopyWith<T, $Res>
    implements $ApiResponseModelCopyWith<T, $Res> {
  factory _$$ApiResponseModelImplCopyWith(_$ApiResponseModelImpl<T> value,
          $Res Function(_$ApiResponseModelImpl<T>) then) =
      __$$ApiResponseModelImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey() bool success,
      @JsonKey() T data,
      @JsonKey() List<ErrorModel>? errors});
}

/// @nodoc
class __$$ApiResponseModelImplCopyWithImpl<T, $Res>
    extends _$ApiResponseModelCopyWithImpl<T, $Res, _$ApiResponseModelImpl<T>>
    implements _$$ApiResponseModelImplCopyWith<T, $Res> {
  __$$ApiResponseModelImplCopyWithImpl(_$ApiResponseModelImpl<T> _value,
      $Res Function(_$ApiResponseModelImpl<T>) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = freezed,
    Object? errors = freezed,
  }) {
    return _then(_$ApiResponseModelImpl<T>(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T,
      errors: freezed == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<ErrorModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$ApiResponseModelImpl<T> implements _ApiResponseModel<T> {
  _$ApiResponseModelImpl(
      {@JsonKey() required this.success,
      @JsonKey() required this.data,
      @JsonKey() final List<ErrorModel>? errors})
      : _errors = errors;

  factory _$ApiResponseModelImpl.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$$ApiResponseModelImplFromJson(json, fromJsonT);

  @override
  @JsonKey()
  final bool success;
  @override
  @JsonKey()
  final T data;
  final List<ErrorModel>? _errors;
  @override
  @JsonKey()
  List<ErrorModel>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ApiResponseModel<$T>(success: $success, data: $data, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiResponseModelImpl<T> &&
            (identical(other.success, success) || other.success == success) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      const DeepCollectionEquality().hash(data),
      const DeepCollectionEquality().hash(_errors));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiResponseModelImplCopyWith<T, _$ApiResponseModelImpl<T>> get copyWith =>
      __$$ApiResponseModelImplCopyWithImpl<T, _$ApiResponseModelImpl<T>>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$ApiResponseModelImplToJson<T>(this, toJsonT);
  }
}

abstract class _ApiResponseModel<T> implements ApiResponseModel<T> {
  factory _ApiResponseModel(
      {@JsonKey() required final bool success,
      @JsonKey() required final T data,
      @JsonKey() final List<ErrorModel>? errors}) = _$ApiResponseModelImpl<T>;

  factory _ApiResponseModel.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =
      _$ApiResponseModelImpl<T>.fromJson;

  @override
  @JsonKey()
  bool get success;
  @override
  @JsonKey()
  T get data;
  @override
  @JsonKey()
  List<ErrorModel>? get errors;
  @override
  @JsonKey(ignore: true)
  _$$ApiResponseModelImplCopyWith<T, _$ApiResponseModelImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
