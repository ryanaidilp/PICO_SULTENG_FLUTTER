import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/percentage.dart';
import 'package:statistic/src/domain/entities/reproduction_number.dart';

class Recap extends Equatable {
  const Recap({
    required this.percentage,
    this.reproductionNumber,
  });
  final Percentage percentage;
  final ReproductionNumber? reproductionNumber;
  @override
  List<Object?> get props => [percentage, reproductionNumber];
}
