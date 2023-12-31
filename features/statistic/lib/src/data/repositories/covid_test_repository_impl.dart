import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/datasources/covid_test_remote_data_source.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';
import 'package:statistic/src/domain/entities/covid_test.dart';
import 'package:statistic/src/domain/failures/covid_test_failure.dart';
import 'package:statistic/src/domain/repositories/covid_test_repository.dart';

@LazySingleton(as: CovidTestRepository)
class CovidTestRepositoryImpl implements CovidTestRepository {
  final _httpDataSource = getIt<CovidTestRemoteDataSource>();

  @override
  Future<Either<Failure, List<CovidTest>>> latest() async {
    try {
      final result = await _httpDataSource.latest();

      if (!result.success) {
        return Left(
          CovidTestFailure(
            message: result.errors?.first.message ?? 'Error',
          ),
        );
      }

      return Right(result.data.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CovidTestFailure(message: e.toString()));
    }
  }
}
