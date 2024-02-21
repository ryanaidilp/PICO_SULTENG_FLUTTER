import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/domain.dart';

@LazySingleton()
class GetAllBanner
    implements UseCase<List<Banner>, NoParams, BannerRepository> {
  @override
  Future<Either<Failure, List<Banner>>> call(NoParams param) => repo.get();

  @override
  BannerRepository get repo => getIt<BannerRepository>();
}
