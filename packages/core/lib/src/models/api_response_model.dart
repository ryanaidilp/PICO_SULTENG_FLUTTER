import 'package:core/src/models/error_model.dart';
import 'package:dependencies/dependencies.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiResponseModel<T> with _$ApiResponseModel<T> {
  factory ApiResponseModel({
    @JsonKey() required bool success,
    @JsonKey() required T data,
    @JsonKey() List<ErrorModel>? errors,
  }) = _ApiResponseModel;
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJson,
  ) =>
      _$ApiResponseModelFromJson(
        json,
        fromJson,
      );
}
