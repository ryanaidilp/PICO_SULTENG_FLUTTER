import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/covid_test.dart';

abstract class CovidTestRepository {
  Future<Either<Failure, List<CovidTest>>> latest();
}
