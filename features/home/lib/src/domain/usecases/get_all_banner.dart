import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/entities/banner.dart';
import 'package:home/src/domain/repositories/banner_repository.dart';

@LazySingleton()
class GetAllBanner
    implements UseCase<List<Banner>, NoParams, BannerRepository> {
  @override
  Future<Either<Failure, List<Banner>>> call(NoParams param) => repo.get();

  @override
  BannerRepository get repo => getIt<BannerRepository>();
}
