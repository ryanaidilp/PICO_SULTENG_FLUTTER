import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/domain.dart';

abstract class BannerRepository {
  Future<Either<Failure, List<Banner>>> get();
}
