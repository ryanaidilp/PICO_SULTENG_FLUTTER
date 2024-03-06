import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/data/data.dart';

abstract class BannerRemoteDataSource {
  Future<ApiResponseModel<List<BannerModel>>> get();
}

@LazySingleton(as: BannerRemoteDataSource)
class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final _httpModule = getIt<PicoHttpModule>();

  @override
  Future<ApiResponseModel<List<BannerModel>>> get() async {
    final response = await _httpModule.get(ApiEndpoint.banner());

    final result = ApiResponseModel<List<BannerModel>>.fromJson(
      response,
      (json) {
        if (json is! List) {
          return [];
        }

        return json.map((e) => BannerModel.fromJson(e as JSON)).toList();
      },
    );

    return result;
  }
}
