import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/percentage.dart';
import 'package:statistic/src/domain/entities/reproduction_number.dart';

class Recap extends Equatable {
  const Recap({
    Percentage? percentage,
    this.reproductionNumber,
  }) : percentage = percentage ?? const Percentage();
  final Percentage percentage;
  final ReproductionNumber? reproductionNumber;
  @override
  List<Object?> get props => [percentage, reproductionNumber];
}
