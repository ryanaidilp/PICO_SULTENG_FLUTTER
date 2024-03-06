import 'package:core/core.dart';
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

  double get reactivePercentage => NumberHelper.calculatePercentage(
        value: positive,
        total: total,
      );
  double get nonReactivePercentage => NumberHelper.calculatePercentage(
        value: negative,
        total: total,
      );
  double get inProcessPercentage => NumberHelper.calculatePercentage(
        value: process,
        total: total,
      );
  double get invalidPercentage => NumberHelper.calculatePercentage(
        value: invalid,
        total: total,
      );
  String get nameAbbreviation {
    final buffer = StringBuffer();
    final texts = name.split(' ');
    final title = texts.map((e) => e.substring(0, 1)).toList();
    buffer.writeAll(title);
    return buffer.toString();
  }

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
