import 'package:dependencies/dependencies.dart';

class ReproductionNumber extends Equatable {
  const ReproductionNumber({
    this.value,
    this.upperBound,
    this.lowerBound,
  });
  final double? value;
  final double? upperBound;
  final double? lowerBound;

  @override
  List<Object?> get props => [value, upperBound, lowerBound];
}
