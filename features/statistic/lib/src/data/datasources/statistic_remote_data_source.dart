import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';

abstract class StatisticRemoteDataSource {
  Future<ApiResponseModel<StatisticModel>> latest();
  Future<ApiResponseModel<StatisticModel>> latestNational();
  Future<ApiResponseModel<List<StatisticModel>>> all();
  Future<ApiResponseModel<List<StatisticModel>>> allNational();
}

@LazySingleton(as: StatisticRemoteDataSource)
class StatisticRemoteDataSourceImpl implements StatisticRemoteDataSource {
  final _httpModule = getIt<PicoHttpModule>();

  @override
  Future<ApiResponseModel<StatisticModel>> latest() async {
    final response = await _httpModule.get(ApiEndpoint.latestProvince());

    final result = ApiResponseModel<StatisticModel>.fromJson(
      response,
      (json) => StatisticModel.fromJson(json! as JSON),
    );

    return result;
  }

  @override
  Future<ApiResponseModel<StatisticModel>> latestNational() async {
    final response = await _httpModule.get(ApiEndpoint.latest());

    final result = ApiResponseModel<StatisticModel>.fromJson(
      response,
      (json) => StatisticModel.fromJson(json! as JSON),
    );

    return result;
  }

  @override
  Future<ApiResponseModel<List<StatisticModel>>> all() async {
    final response = await _httpModule.get(ApiEndpoint.historyProvince());

    final result = ApiResponseModel<List<StatisticModel>>.fromJson(
      response,
      (json) {
        if (json is! List) {
          return [];
        }

        final data = json.map((e) => StatisticModel.fromJson(e as JSON));

        return data.toList();
      },
    );

    return result;
  }

  @override
  Future<ApiResponseModel<List<StatisticModel>>> allNational() async {
    final response = await _httpModule.get(ApiEndpoint.history());

    final result = ApiResponseModel<List<StatisticModel>>.fromJson(
      response,
      (json) {
        if (json is! List) {
          return [];
        }

        final data = json.map((e) => StatisticModel.fromJson(e as JSON));

        return data.toList();
      },
    );

    return result;
  }
}
