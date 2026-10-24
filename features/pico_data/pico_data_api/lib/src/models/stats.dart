import 'package:dependencies_core/equality.dart';
import 'package:pico_data_api/src/models/area.dart';

/// A test method (pcr, rdt, tcm, rdt_ab, rdt_ag). Text is Indonesian only.
final class TestType extends Equatable {
  /// Creates a test type.
  const new({
    required this.key,
    required this.name,
    required this.sample,
    required this.duration,
    required this.isRecommended,
  });

  /// Stable key, for example `pcr`.
  final String key;

  /// Full name.
  final String name;

  /// Sample taken.
  final String sample;

  /// Time to result.
  final String duration;

  /// Whether health authorities recommend it.
  final bool isRecommended;

  @override
  List<Object?> get props => [key, name, sample, duration, isRecommended];
}

/// Latest cumulative test totals of one type. Has no date on purpose (C03).
final class TestTotal extends Equatable {
  /// Creates totals.
  const new({
    required this.typeKey,
    required this.sourceDay,
    required this.process,
    required this.invalid,
    required this.positive,
    required this.negative,
  });

  /// Type key.
  final String typeKey;

  /// API `day` sequence number (ordering only, not a date).
  final int sourceDay;

  /// In process.
  final int process;

  /// Invalid.
  final int invalid;

  /// Positive.
  final int positive;

  /// Negative.
  final int negative;

  @override
  List<Object?> get props => [
    typeKey,
    sourceDay,
    process,
    invalid,
    positive,
    negative,
  ];
}

/// Counts of one sex with the API's own age groups (`0_14`, ..., `55_plus`).
final class GenderCounts extends Equatable {
  /// Creates counts.
  const new({required this.total, required this.ageGroups});

  /// All ages.
  final int total;

  /// Age group key to count, in API order.
  final Map<String, int> ageGroups;

  @override
  List<Object?> get props => [total, ageGroups];
}

/// Positive and PDP split by sex.
final class GenderGroup extends Equatable {
  /// Creates a group.
  const new({required this.male, required this.female});

  /// Male.
  final GenderCounts male;

  /// Female.
  final GenderCounts female;

  @override
  List<Object?> get props => [male, female];
}

/// Latest gender snapshot. Has no date (C03).
final class GenderSnapshot extends Equatable {
  /// Creates a snapshot.
  const new({
    required this.sourceDay,
    required this.positive,
    required this.pdp,
  });

  /// API `day` sequence number.
  final int sourceDay;

  /// Positive cases.
  final GenderGroup positive;

  /// PDP.
  final GenderGroup pdp;

  @override
  List<Object?> get props => [sourceDay, positive, pdp];
}

/// Where vaccination is counted.
enum VaccinationScope {
  /// Indonesia.
  national,

  /// Central Sulawesi.
  sulteng,
}

/// Priority group of the vaccination programme.
enum VaccineGroup {
  /// Elderly.
  elderly,

  /// Health workers.
  healthWorker,

  /// General public.
  publik,

  /// Public officers.
  publicOfficer,

  /// Teenagers.
  teenager,
}

/// Dose 1 and dose 2 numbers.
final class DoseStats extends Equatable {
  /// Creates dose stats.
  const new({
    required this.dailyDose1,
    required this.dailyDose2,
    required this.cumulativeDose1,
    required this.cumulativeDose2,
    required this.coverageDose1,
    required this.coverageDose2,
  });

  /// Doses given that day, first dose.
  final int dailyDose1;

  /// Doses given that day, second dose.
  final int dailyDose2;

  /// Total first doses.
  final int cumulativeDose1;

  /// Total second doses.
  final int cumulativeDose2;

  /// Percent of target, can pass 100.
  final double coverageDose1;

  /// Percent of target, can pass 100.
  final double coverageDose2;

  @override
  List<Object?> get props => [
    dailyDose1,
    dailyDose2,
    cumulativeDose1,
    cumulativeDose2,
    coverageDose1,
    coverageDose2,
  ];
}

/// Dose stats of one priority group with its target.
final class GroupStats extends Equatable {
  /// Creates group stats.
  const new({required this.target, required this.doses});

  /// People targeted.
  final int target;

  /// Doses.
  final DoseStats doses;

  @override
  List<Object?> get props => [target, doses];
}

/// One day of vaccination. Keyed by [date].
final class VaccinationDay extends Equatable {
  /// Creates a day. [date] is reduced to a calendar date.
  new({
    required DateTime date,
    required this.target,
    required this.total,
    required this.groups,
  }) : date = dateOnly(date);

  /// Calendar date.
  final DateTime date;

  /// People targeted.
  final int target;

  /// All groups together.
  final DoseStats total;

  /// Per priority group.
  final Map<VaccineGroup, GroupStats> groups;

  @override
  List<Object?> get props => [date, target, total, groups];
}

/// Vaccination over time, ascending by date, one entry per date.
final class VaccinationSeries extends Equatable {
  const new _(this.scope, this.days);

  /// Sorts by date and keeps the last row for a repeated date.
  factory fromDays(VaccinationScope scope, Iterable<VaccinationDay> days) {
    final byDate = <DateTime, VaccinationDay>{for (final d in days) d.date: d};
    final sorted = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return VaccinationSeries._(scope, List.unmodifiable(sorted));
  }

  /// Scope.
  final VaccinationScope scope;

  /// Ascending, no duplicate dates.
  final List<VaccinationDay> days;

  /// Latest day or null.
  VaccinationDay? get latest => days.isEmpty ? null : days.last;

  @override
  List<Object?> get props => [scope, days];
}
