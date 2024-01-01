import 'package:dependencies/dependencies.dart';

class CovidTest extends Equatable {
  CovidTest({
    this.day = 0,
    DateTime? updatedAt,
    this.name = '',
    this.sample = '',
    this.duration = '',
    this.positive = 0,
    this.negative = 0,
    this.process = 0,
    this.invalid = 0,
    this.total = 0,
  }) : updatedAt = updatedAt ?? DateTime.now();
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
