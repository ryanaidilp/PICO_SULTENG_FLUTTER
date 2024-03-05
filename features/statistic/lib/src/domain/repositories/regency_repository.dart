import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/domain.dart';

abstract interface class RegencyRepository {
  Future<Either<Failure, List<Regency>>> getRegenciesByProvinceCode({
    required int provinceCode,
  });
}
