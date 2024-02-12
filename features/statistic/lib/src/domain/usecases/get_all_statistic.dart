import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/entities.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';

@LazySingleton()
class GetAllStatistic
    implements UseCase<List<Statistic>, NoParams, StatisticRepository> {
  @override
  Future<Either<Failure, List<Statistic>>> call(NoParams param) => repo.all();

  @override
  StatisticRepository get repo => getIt<StatisticRepository>();
}
