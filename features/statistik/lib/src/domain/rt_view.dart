import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';

/// Parses `national`, `province:72`, `regency:7271`. Anything else is the
/// national area (never throws).
AreaRef parseRtArea(String? s) {
  if (s == null) return const AreaRef.national();
  final m = RegExp(r'^(province|regency):(\d+)$').firstMatch(s);
  if (m == null) return const AreaRef.national();
  final id = m.group(2)!;
  if (m.group(1) == 'province' && id.length == 2) return AreaRef.province(id);
  if (m.group(1) == 'regency' && id.length == 4) return AreaRef.regency(id);
  return const AreaRef.national();
}

/// The `area=` value of [a].
String rtAreaParam(AreaRef a) => switch (a) {
  NationalArea() => 'national',
  ProvinceArea(:final id) => 'province:$id',
  RegencyArea(:final code) => 'regency:$code',
};

/// The newest computed Rt in range and the day it belongs to.
typedef RtReading = ({DateTime date, Rt rt});

/// What the Rt page shows for one series and one range. Derived with no
/// request. A day with no Rt stays null: it is never drawn or counted as 0.
final class RtView extends Equatable {
  const RtView({
    required this.range,
    required this.points,
    required this.latest,
    required this.lastDataDay,
    required this.nullDays,
    required this.computedDays,
    required this.daysAboveOne,
  });

  /// Effective range, clamped to the data.
  final DateRange range;

  /// One point per date in range; null Rt for days without an estimate.
  final List<(DateTime, Rt?)> points;

  /// The newest computed Rt in range, or null when every day is null.
  final RtReading? latest;

  /// The last data day in range (may be later than [latest]).
  final DateTime lastDataDay;

  /// Days in range with no Rt.
  final int nullDays;

  /// Days in range with an Rt.
  final int computedDays;

  /// Computed days whose Rt value is above 1.
  final int daysAboveOne;

  /// Whether the newest data day has no Rt of its own.
  bool get latestIsOlderThanData =>
      latest != null && latest!.date.isBefore(lastDataDay);

  @override
  List<Object?> get props => [
    range,
    points,
    latest,
    lastDataDay,
    nullDays,
    computedDays,
    daysAboveOne,
  ];
}

/// Builds the view of [series] for [from]..[to] (null = open ends), clamped to
/// the data and swapped if reversed. Null for an empty series.
RtView? buildRtView(CaseSeries series, {DateTime? from, DateTime? to}) {
  final all = series.days;
  if (all.isEmpty) return null;
  final first = all.first.date;
  final last = all.last.date;
  DateTime clamp(DateTime d) =>
      d.isBefore(first) ? first : (d.isAfter(last) ? last : d);
  var start = clamp(from ?? first);
  var end = clamp(to ?? last);
  if (start.isAfter(end)) (start, end) = (end, start);
  final range = DateRange(start, end);
  final days = series.inRange(range);
  RtReading? latest;
  var nulls = 0;
  var above = 0;
  for (final d in days) {
    final rt = d.rt;
    if (rt == null) {
      nulls++;
    } else {
      latest = (date: d.date, rt: rt);
      if (rt.value > 1) above++;
    }
  }
  return RtView(
    range: range,
    points: [for (final d in days) (d.date, d.rt)],
    latest: latest,
    lastDataDay: days.last.date,
    nullDays: nulls,
    computedDays: days.length - nulls,
    daysAboveOne: above,
  );
}

/// The AreaLevel of [a], for the level control.
AreaLevel levelOf(AreaRef a) => switch (a) {
  NationalArea() => AreaLevel.national,
  ProvinceArea() => AreaLevel.province,
  RegencyArea() => AreaLevel.regency,
};
