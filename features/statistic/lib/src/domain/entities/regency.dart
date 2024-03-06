import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/case.dart';
import 'package:statistic/src/domain/entities/recap.dart';

class Regency extends Equatable {
  Regency({
    this.id = 0,
    this.day = 0,
    this.name = 'Regency',
    DateTime? date,
    Case? newCase,
    Case? cumulative,
    Recap? recap,
  })  : date = date ?? DateTime.now(),
        newCase = newCase ?? const Case(),
        cumulative = cumulative ?? const Case(),
        recap = recap ?? const Recap();

  final int id;
  final int day;
  final String name;
  final DateTime date;
  final Case newCase;
  final Case cumulative;
  final Recap recap;

  @override
  List<Object> get props {
    return [
      id,
      day,
      name,
      date,
      newCase,
      cumulative,
      recap,
    ];
  }
}
