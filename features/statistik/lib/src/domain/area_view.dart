import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';

/// What the page shows for one series and one query, derived without any
/// network call: changing metric, daily or range only recomputes this.
final class AreaView extends Equatable {
  /// Creates a view.
  const AreaView({
    required this.range,
    required this.days,
    required this.last,
    required this.totals,
    required this.peak,
  });

  /// The effective range, clamped to the data.
  final DateRange range;

  /// Days inside [range], ascending, one per date.
  final List<CaseDay> days;

  /// The last day in range: the tiles read it.
  final CaseDay last;

  /// Sum of the daily values over [range] ("Total dalam rentang").
  final CaseCounts totals;

  /// The day with the highest daily value of the chosen metric in [range].
  final CaseDay peak;

  @override
  List<Object?> get props => [range, days, last, totals, peak];
}

/// Builds the view of [series] for [query], or null for an empty series.
///
/// The requested range is clamped to the first and last day of the data, and
/// swapped if reversed, so input can never produce an empty range.
AreaView? buildAreaView(CaseSeries series, AreaQuery query) {
  final all = series.days;
  if (all.isEmpty) return null;
  final first = all.first.date;
  final last = all.last.date;
  DateTime clamp(DateTime d) =>
      d.isBefore(first) ? first : (d.isAfter(last) ? last : d);
  var start = clamp(query.from ?? first);
  var end = clamp(query.to ?? last);
  if (start.isAfter(end)) (start, end) = (end, start);
  final range = DateRange(start, end);
  final days = series.inRange(range);
  var pos = 0;
  var rec = 0;
  var dec = 0;
  var act = 0;
  CaseDay peak = days.first;
  for (final d in days) {
    pos += d.daily.positive;
    rec += d.daily.recovered;
    dec += d.daily.deceased;
    act += d.daily.active;
    if (d.daily.of(query.metric) > peak.daily.of(query.metric)) peak = d;
  }
  return AreaView(
    range: range,
    days: days,
    last: days.last,
    totals: CaseCounts(
      positive: pos,
      recovered: rec,
      deceased: dec,
      active: act,
    ),
    peak: peak,
  );
}
