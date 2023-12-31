import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/case.dart';
import 'package:statistic/src/domain/entities/recap.dart';

class Statistic extends Equatable {
  const Statistic({
    required this.day,
    required this.updatedAt,
    required this.cumulative,
    required this.newCases,
    required this.recap,
  });
  final int day;
  final DateTime updatedAt;
  final Case cumulative;
  final Case newCases;
  final Recap recap;
  @override
  List<Object> get props => [day, updatedAt, cumulative, newCases];
}
