import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';

abstract class CovidTestRemoteDataSource {
  Future<ApiResponseModel<List<CovidTestModel>>> latest();
}

@LazySingleton(as: CovidTestRemoteDataSource)
class CovidTestRemoteDataSourceImpl implements CovidTestRemoteDataSource {
  final _httpModule = getIt<PicoHttpModule>();
  @override
  Future<ApiResponseModel<List<CovidTestModel>>> latest() async {
    final response = await _httpModule.get(ApiEndpoint.testLatest());

    final result = ApiResponseModel<List<CovidTestModel>>.fromJson(
      response,
      (json) {
        if (json is! List) {
          return [];
        }

        return json.map((e) => CovidTestModel.fromJson(e as JSON)).toList();
      },
    );

    return result;
  }
}
