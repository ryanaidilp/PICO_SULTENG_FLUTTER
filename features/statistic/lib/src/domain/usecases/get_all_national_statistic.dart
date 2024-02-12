import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';
import 'package:statistic/statistic.dart';

@LazySingleton()
class GetAllNationalStatistic
    implements UseCase<List<Statistic>, NoParams, StatisticRepository> {
  @override
  Future<Either<Failure, List<Statistic>>> call(NoParams param) =>
      repo.allNational();

  @override
  StatisticRepository get repo => getIt<StatisticRepository>();
}
