import 'package:pico_data_api/pico_data_api.dart';

/// Cumulative value of [metric] on the latest day of [s].
int cumulativeOf(AreaSummary s, CaseMetric metric) =>
    s.latest.cumulative.of(metric);

/// Daily change of [metric] on the latest day of [s].
int dailyOf(AreaSummary s, CaseMetric metric) => s.latest.daily.of(metric);

/// How the list is ordered.
enum RegencySort {
  /// By the chosen cumulative value, high to low.
  value,

  /// By name.
  name,
}

/// One row of the list: a regency and its summary, if it loaded.
typedef RegencyRowData = ({Regency regency, AreaSummary? summary});

/// Rows in order. [names] is the full list of 13; a regency with no summary
/// (not loaded or failed) keeps its place at the end, never a 0.
List<RegencyRowData> orderRegencies(
  List<Regency> names,
  List<AreaSummary> summaries, {
  required CaseMetric metric,
  required RegencySort sort,
}) {
  final byCode = {
    for (final s in summaries)
      if (s.area is RegencyArea) (s.area as RegencyArea).code: s,
  };
  final rows = [for (final r in names) (regency: r, summary: byCode[r.code])];
  int byName(RegencyRowData a, RegencyRowData b) =>
      a.regency.name.toLowerCase().compareTo(b.regency.name.toLowerCase());
  rows.sort((a, b) {
    final sa = a.summary;
    final sb = b.summary;
    if (sa == null || sb == null) {
      if (sa == null && sb == null) return byName(a, b);
      return sa == null ? 1 : -1;
    }
    if (sort == RegencySort.name) return byName(a, b);
    final c = cumulativeOf(sb, metric).compareTo(cumulativeOf(sa, metric));
    return c != 0 ? c : byName(a, b);
  });
  return rows;
}
