import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/statistic.dart';

abstract class StatisticRepository {
  Future<Either<Failure, Statistic>> latest();
  Future<Either<Failure, Statistic>> latestNational();
}
