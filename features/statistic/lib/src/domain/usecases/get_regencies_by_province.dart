import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/domain.dart';

@LazySingleton()
class GetRegenciesByProvince
    extends UseCase<List<Regency>, int, RegencyRepository> {
  @override
  Future<Either<Failure, List<Regency>>> call(int param) =>
      repo.getRegenciesByProvinceCode(provinceCode: param);

  @override
  RegencyRepository get repo => getIt<RegencyRepository>();
}
