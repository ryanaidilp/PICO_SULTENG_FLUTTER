import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/data/datasources/banner_remote_data_source.dart';
import 'package:home/src/data/models/banner_model.dart';
import 'package:home/src/domain/entities/banner.dart';
import 'package:home/src/domain/failures/banner_failure.dart';
import 'package:home/src/domain/repositories/banner_repository.dart';

@LazySingleton(as: BannerRepository)
class BannerRepositoryImpl implements BannerRepository {
  final _httpDataSource = getIt<BannerRemoteDataSource>();

  @override
  Future<Either<Failure, List<Banner>>> get() async {
    try {
      final result = await _httpDataSource.get();

      if (!result.success) {
        return Left(
          BannerFailure(
            message: result.errors?.first.message ?? 'Error',
          ),
        );
      }

      return Right(result.data.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(BannerFailure(message: e.toString()));
    }
  }
}
