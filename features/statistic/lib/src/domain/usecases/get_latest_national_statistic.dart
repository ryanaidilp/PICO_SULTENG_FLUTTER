import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';
import 'package:statistic/statistic.dart';

@LazySingleton()
class GetLatestNationalStatistic
    implements UseCase<Statistic, NoParams, StatisticRepository> {
  @override
  Future<Either<Failure, Statistic>> call(NoParams param) =>
      repo.latestNational();

  @override
  StatisticRepository get repo => getIt<StatisticRepository>();
}
