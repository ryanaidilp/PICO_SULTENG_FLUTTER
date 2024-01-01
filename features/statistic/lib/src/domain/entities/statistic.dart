import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/case.dart';
import 'package:statistic/src/domain/entities/recap.dart';

class Statistic extends Equatable {
  Statistic({
    this.day = 0,
    DateTime? updatedAt,
    Case? cumulative,
    Case? newCases,
    Recap? recap,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        cumulative = cumulative ?? const Case(),
        newCases = newCases ?? const Case(),
        recap = recap ?? const Recap();
  final int day;
  final DateTime updatedAt;
  final Case cumulative;
  final Case newCases;
  final Recap recap;
  @override
  List<Object> get props => [day, updatedAt, cumulative, newCases];
}
