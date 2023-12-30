import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/entities/banner.dart';

abstract class BannerRepository {
  Future<Either<Failure, List<Banner>>> get();
}
