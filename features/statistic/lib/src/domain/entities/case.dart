import 'package:dependencies/dependencies.dart';

class Case extends Equatable {
  const Case({
    this.positive = 0,
    this.recovered = 0,
    this.deceased = 0,
    this.underTreatment = 0,
    this.totalObserved = 0,
    this.finishedObservation = 0,
    this.underObservation = 0,
    this.totalSupervised = 0,
    this.finishedSupervision = 0,
    this.underSupervision = 0,
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
