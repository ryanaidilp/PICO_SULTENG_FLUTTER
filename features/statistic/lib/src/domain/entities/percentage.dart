

import 'package:dependencies/dependencies.dart';

class Percentage extends Equatable {
  const Percentage({
    required this.underTreatment,
    required this.deceased,
    required this.recovered,
  });
  final double underTreatment;
  final double deceased;
  final double recovered;
  @override
  List<Object> get props => [underTreatment, deceased, recovered];
}
