import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/statistic.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';

@LazySingleton()
class GetLatestStatistic
    implements UseCase<Statistic, NoParams, StatisticRepository> {
  @override
  Future<Either<Failure, Statistic>> call(NoParams param) => repo.latest();

  @override
  StatisticRepository get repo => getIt<StatisticRepository>();
}
