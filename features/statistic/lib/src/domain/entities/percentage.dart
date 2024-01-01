import 'package:dependencies/dependencies.dart';

class Percentage extends Equatable {
  const Percentage({
    this.underTreatment = 0,
    this.deceased = 0,
    this.recovered = 0,
  });
  final double underTreatment;
  final double deceased;
  final double recovered;
  @override
  List<Object> get props => [underTreatment, deceased, recovered];
}
