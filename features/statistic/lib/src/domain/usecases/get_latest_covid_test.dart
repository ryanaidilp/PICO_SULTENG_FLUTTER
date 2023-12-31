import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/covid_test.dart';
import 'package:statistic/src/domain/repositories/covid_test_repository.dart';

@LazySingleton()
class GetLatestCovidTest
    implements UseCase<List<CovidTest>, NoParams, CovidTestRepository> {
  @override
  Future<Either<Failure, List<CovidTest>>> call(NoParams param) =>
      repo.latest();

  @override
  CovidTestRepository get repo => getIt<CovidTestRepository>();
}
