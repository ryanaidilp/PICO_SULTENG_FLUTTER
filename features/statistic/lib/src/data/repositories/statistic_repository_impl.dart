import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/datasources/statistic_remote_data_source.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/entities/statistic.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';

@LazySingleton(as: StatisticRepository)
class StatisticRepositoryImpl implements StatisticRepository {
  final _httpDataSource = getIt<StatisticRemoteDataSource>();

  @override
  Future<Either<Failure, Statistic>> latest() async {
    try {
      final result = await _httpDataSource.latest();

      if (!result.success) {
        return Left(
          StatisticFailure(
            message: result.errors?.first.message ?? 'Error',
          ),
        );
      }

      return Right(result.data.toEntity());
    } catch (e) {
      return Left(StatisticFailure(message: e.toString()));
    }
  }
}
