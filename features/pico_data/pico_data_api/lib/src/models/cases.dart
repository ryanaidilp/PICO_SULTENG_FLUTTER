import 'package:dependencies_core/equality.dart';
import 'package:pico_data_api/src/models/area.dart';

/// COVID-19 counts. `active` can be negative in daily values (C01).
final class CaseCounts extends Equatable {
  /// Creates counts.
  const new({
    required this.positive,
    required this.recovered,
    required this.deceased,
    required this.active,
  });

  /// All zero.
  static const zero = CaseCounts(
    positive: 0,
    recovered: 0,
    deceased: 0,
    active: 0,
  );

  /// Confirmed positive.
  final int positive;

  /// Recovered.
  final int recovered;

  /// Deceased.
  final int deceased;

  /// Active (can be negative in daily values).
  final int active;

  /// Value for one metric.
  int of(CaseMetric m) => switch (m) {
    CaseMetric.positive => positive,
    CaseMetric.recovered => recovered,
    CaseMetric.deceased => deceased,
    CaseMetric.active => active,
  };

  @override
  List<Object?> get props => [positive, recovered, deceased, active];
}

/// Case metric. Maps 1:1 to the kit's `PicoState` roles.
enum CaseMetric {
  /// Positive.
  positive,

  /// Recovered.
  recovered,

  /// Deceased.
  deceased,

  /// Active.
  active,
}

/// Effective reproduction number with its interval. A day with no computed
/// value has a null `Rt`, never 0 (C01).
final class Rt extends Equatable {
  /// Creates an Rt.
  const new({required this.value, required this.lower, required this.upper});

  /// Point estimate.
  final double value;

  /// Lower bound.
  final double lower;

  /// Upper bound.
  final double upper;

  @override
  List<Object?> get props => [value, lower, upper];
}

/// ODP/PDP monitoring, cumulative. Null means no data (C01).
final class Monitoring extends Equatable {
  /// Creates monitoring numbers.
  const new({
    this.odpActive,
    this.odpFinished,
    this.pdpActive,
    this.pdpFinished,
  });

  /// ODP under monitoring.
  final int? odpActive;

  /// ODP finished.
  final int? odpFinished;

  /// PDP under care.
  final int? pdpActive;

  /// PDP finished.
  final int? pdpFinished;

  /// True when at least one field has a value above zero.
  bool get hasData => [
    odpActive,
    odpFinished,
    pdpActive,
    pdpFinished,
  ].any((v) => v != null && v > 0);

  @override
  List<Object?> get props => [odpActive, odpFinished, pdpActive, pdpFinished];
}

/// One calendar day of one area. Keyed by [date], never by the API `day`.
final class CaseDay extends Equatable {
  /// Creates a day. [date] is reduced to a calendar date.
  new({
    required DateTime date,
    required this.daily,
    required this.cumulative,
    this.rt,
    this.monitoring,
  }) : date = dateOnly(date);

  /// Local calendar date at 00:00.
  final DateTime date;

  /// New cases that day.
  final CaseCounts daily;

  /// Totals up to that day.
  final CaseCounts cumulative;

  /// Reproduction number, null when not computed.
  final Rt? rt;

  /// ODP/PDP, null when absent.
  final Monitoring? monitoring;

  @override
  List<Object?> get props => [date, daily, cumulative, rt, monitoring];
}

/// A time series of one area: ascending by date with one entry per date.
final class CaseSeries extends Equatable {
  const new _({required this.area, required this.areaName, required this.days});

  /// Builds a series from rows in any order. Sorts by date and keeps the last
  /// row seen for a repeated date (the API sends duplicates, C01).
  factory fromDays({
    required AreaRef area,
    required String areaName,
    required Iterable<CaseDay> days,
  }) {
    final byDate = <DateTime, CaseDay>{for (final d in days) d.date: d};
    final sorted = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return CaseSeries._(
      area: area,
      areaName: areaName,
      days: List.unmodifiable(sorted),
    );
  }

  /// Area of the series.
  final AreaRef area;

  /// Display name from the API.
  final String areaName;

  /// Ascending by date, no duplicate dates.
  final List<CaseDay> days;

  /// The most recent day, or null when empty.
  CaseDay? get latest => days.isEmpty ? null : days.last;

  /// The day for [date], or null. Lookup is by calendar date.
  CaseDay? on(DateTime date) {
    final d = dateOnly(date);
    for (final day in days) {
      if (day.date == d) return day;
    }
    return null;
  }

  /// Days inside [range], still ascending.
  List<CaseDay> inRange(DateRange range) =>
      days.where((d) => range.contains(d.date)).toList();

  /// The day with the highest [metric] (daily or cumulative), or null.
  CaseDay? peak(CaseMetric metric, {bool daily = true}) {
    CaseDay? best;
    for (final d in days) {
      final v = (daily ? d.daily : d.cumulative).of(metric);
      if (best == null ||
          v > (daily ? best.daily : best.cumulative).of(metric)) {
        best = d;
      }
    }
    return best;
  }

  @override
  List<Object?> get props => [area, areaName, days];
}

/// The latest day of one area, for lists.
final class AreaSummary extends Equatable {
  /// Creates a summary.
  const new({required this.area, required this.name, required this.latest});

  /// Area.
  final AreaRef area;

  /// Display name.
  final String name;

  /// Latest day.
  final CaseDay latest;

  @override
  List<Object?> get props => [area, name, latest];
}
