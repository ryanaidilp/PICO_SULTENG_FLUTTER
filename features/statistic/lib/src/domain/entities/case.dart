import 'package:dependencies/dependencies.dart';

class Case extends Equatable {
  const Case({
    required this.positive,
    required this.recovered,
    required this.deceased,
    required this.underTreatment,
    required this.totalObserved,
    required this.finishedObservation,
    required this.underObservation,
    required this.totalSupervised,
    required this.finishedSupervision,
    required this.underSupervision,
  });
  final int positive;
  final int recovered;
  final int deceased;
  final int underTreatment;
  final int totalObserved;
  final int finishedObservation;
  final int underObservation;
  final int totalSupervised;
  final int finishedSupervision;
  final int underSupervision;
  @override
  List<Object> get props {
    return [
      positive,
      recovered,
      deceased,
      underTreatment,
      totalObserved,
      finishedObservation,
      underObservation,
      totalSupervised,
      finishedSupervision,
      underSupervision,
    ];
  }
}
