import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';

abstract class StatisticRemoteDataSource {
  Future<ApiResponseModel<StatisticModel>> latest();
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
}
