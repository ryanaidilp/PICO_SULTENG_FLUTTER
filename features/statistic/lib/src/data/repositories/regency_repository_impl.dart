import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/data.dart';
import 'package:statistic/src/domain/domain.dart';

@LazySingleton(as: RegencyRepository)
class RegencyRepositoryImpl implements RegencyRepository {
  final RegencyRemoteDataSource _httpDataSource =
      getIt<RegencyRemoteDataSource>();

  @override
  Future<Either<Failure, List<Regency>>> getRegenciesByProvinceCode({
    required int provinceCode,
  }) async {
    try {
      final result = await _httpDataSource.fetchRegenciesByProvinceCode(
        provinceCode: provinceCode,
      );

      if (!result.success) {
        return Left(
          RegencyFailure(
            message: result.errors?.first.message ?? 'Error',
          ),
        );
      }

      return Right(result.data.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(RegencyFailure(message: e.toString()));
    }
  }
}
