import 'package:dependencies/dependencies.dart';

class CovidTest extends Equatable {
  const CovidTest({
    required this.day,
    required this.updatedAt,
    required this.name,
    required this.sample,
    required this.duration,
    required this.positive,
    required this.negative,
    required this.process,
    required this.invalid,
    required this.total,
  });
  final int day;
  final DateTime updatedAt;
  final String name;
  final String sample;
  final String duration;
  final int positive;
  final int negative;
  final int process;
  final int invalid;
  final int total;
  @override
  List<Object> get props {
    return [
      day,
      updatedAt,
      name,
      sample,
      duration,
      positive,
      negative,
      process,
      invalid,
      total,
    ];
  }
}
