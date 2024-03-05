import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/regency_model.dart';

abstract interface class RegencyRemoteDataSource {
  Future<ApiResponseModel<List<RegencyModel>>> fetchRegenciesByProvinceCode({
    required int provinceCode,
  });
}

@LazySingleton(as: RegencyRemoteDataSource)
class RegencyRemoteDataSourceImpl implements RegencyRemoteDataSource {
  final _httpModule = getIt<PicoHttpModule>();

  @override
  Future<ApiResponseModel<List<RegencyModel>>> fetchRegenciesByProvinceCode({
    required int provinceCode,
  }) async {
    final response = await _httpModule.get(
      ApiEndpoint.regenciesStatisticsByProvince(
        provinceCode: '$provinceCode',
      ),
    );

    final result = ApiResponseModel<List<RegencyModel>>.fromJson(
      response,
      (json) {
        if (json is! List) {
          return [];
        }

        return json.map((e) => RegencyModel.fromJson(e as JSON)).toList();
      },
    );

    return result;
  }
}
