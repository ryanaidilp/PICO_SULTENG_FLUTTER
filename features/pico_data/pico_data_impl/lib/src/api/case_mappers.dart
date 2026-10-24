import 'dart:convert';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/dates.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
int? _intOrNull(Object? v) => (v as num?)?.toInt();
double? _dbl(Object? v) => (v as num?)?.toDouble();

CaseCounts _counts(Map<String, dynamic> m) => CaseCounts(
  positive: _int(m['positive']),
  recovered: _int(m['recovered']),
  deceased: _int(m['deceased']),
  active: _int(m['active']),
);

/// A missing or null value is a null Rt, never 0 (C01).
Rt? _rt(num? value, num? lower, num? upper) {
  if (value == null) return null;
  return Rt(
    value: value.toDouble(),
    lower: (lower ?? value).toDouble(),
    upper: (upper ?? value).toDouble(),
  );
}

Monitoring? _monitoring(Object? odp, Object? pdp) {
  if (odp is! Map<String, dynamic> && pdp is! Map<String, dynamic>) return null;
  final o = odp is Map<String, dynamic> ? odp : const <String, dynamic>{};
  final p = pdp is Map<String, dynamic> ? pdp : const <String, dynamic>{};
  return Monitoring(
    odpActive: _intOrNull(o['active']),
    odpFinished: _intOrNull(o['finished']),
    pdpActive: _intOrNull(p['active']),
    pdpFinished: _intOrNull(p['finished']),
  );
}

/// Maps the nested case shape (national and province rows). The date is the
/// calendar date, the API `day` is ignored.
CaseDay caseDayFromNested(Map<String, dynamic> j) {
  final cumulative = j['cumulative'] as Map<String, dynamic>;
  final rr =
      (j['statistics'] as Map<String, dynamic>?)?['reproduction_rate']
          as Map<String, dynamic>?;
  return CaseDay(
    date: parseApiDate(j['date'] as String),
    daily: _counts(j['daily'] as Map<String, dynamic>),
    cumulative: _counts(cumulative),
    rt: _rt(
      rr?['value'] as num?,
      rr?['lower_bound'] as num?,
      rr?['upper_bound'] as num?,
    ),
    monitoring: _monitoring(cumulative['odp'], cumulative['pdp']),
  );
}

/// Maps a national or province list into a series keyed by date. The province
/// list arrives descending: [CaseSeries.fromDays] sorts it ascending.
CaseSeries seriesFromNested(
  List<dynamic> rows, {
  required AreaRef area,
  required String fallbackName,
}) {
  final maps = rows.cast<Map<String, dynamic>>();
  final province = maps.isEmpty
      ? null
      : maps.first['province'] as Map<String, dynamic>?;
  return CaseSeries.fromDays(
    area: area,
    areaName: province?['name'] as String? ?? fallbackName,
    days: maps.map(caseDayFromNested),
  );
}

/// Maps `/provinces` rows to summaries. Provinces without a latest case are
/// skipped.
List<AreaSummary> provinceSummaries(List<dynamic> rows) => [
  for (final r in rows.cast<Map<String, dynamic>>())
    if (r['latest_case'] is Map<String, dynamic>)
      AreaSummary(
        area: AreaRef.province('${r['id']}'),
        name: r['name'] as String,
        latest: caseDayFromNested(r['latest_case'] as Map<String, dynamic>),
      ),
];

/// Maps the flat regency rows (C02) into a series keyed by date.
///
/// There is no `active` field: cumulative active is
/// `positive - recovered - deceased`, and daily active is the difference from
/// the previous day (the first day equals its cumulative active).
CaseSeries seriesFromRegency(List<dynamic> rows, {required String code}) {
  final maps = rows.cast<Map<String, dynamic>>();
  final byDate = <DateTime, Map<String, dynamic>>{
    for (final m in maps) parseApiDate(m['date'] as String): m,
  };
  final dates = byDate.keys.toList()..sort();
  final days = <CaseDay>[];
  var prevActive = 0;
  for (final date in dates) {
    final m = byDate[date]!;
    final cumPositive = _int(m['cumulative_positive']);
    final cumRecovered = _int(m['cumulative_recovered']);
    final cumDeceased = _int(m['cumulative_deceased']);
    final cumActive = cumPositive - cumRecovered - cumDeceased;
    days.add(
      CaseDay(
        date: date,
        daily: CaseCounts(
          positive: _int(m['positive']),
          recovered: _int(m['recovered']),
          deceased: _int(m['deceased']),
          active: cumActive - prevActive,
        ),
        cumulative: CaseCounts(
          positive: cumPositive,
          recovered: cumRecovered,
          deceased: cumDeceased,
          active: cumActive,
        ),
        rt: _rt(_dbl(m['rt']), _dbl(m['rt_lower']), _dbl(m['rt_upper'])),
        monitoring: _monitoring(
          {
            'active': m['cumulative_person_under_observation'],
            'finished': m['cumulative_finished_person_under_observation'],
          },
          {
            'active': m['cumulative_person_under_supervision'],
            'finished': m['cumulative_finished_person_under_supervision'],
          },
        ),
      ),
    );
    prevActive = cumActive;
  }
  final name = maps.isEmpty
      ? code
      : (maps.first['regency'] as Map<String, dynamic>?)?['name'] as String? ??
            code;
  return CaseSeries.fromDays(
    area: AreaRef.regency(code),
    areaName: name,
    days: days,
  );
}

/// Regency list rows.
List<Regency> regencyList(List<dynamic> rows) => [
  for (final r in rows.cast<Map<String, dynamic>>())
    Regency(code: '${r['id']}', name: r['name'] as String),
];

/// The newest day of [s] that has an Rt, never a zero stand-in.
LatestRt? latestRtOf(CaseSeries s) {
  for (final d in s.days.reversed) {
    final rt = d.rt;
    if (rt != null) return (date: d.date, rt: rt);
  }
  return null;
}

/// The small stored form of a [LatestRt]: `{date, value, lower, upper}`, or
/// `{}` when there is none.
String encodeLatestRt(LatestRt? r) => r == null
    ? '{}'
    : jsonEncode({
        'date': formatApiDate(r.date),
        'value': r.rt.value,
        'lower': r.rt.lower,
        'upper': r.rt.upper,
      });

/// Reverse of [encodeLatestRt].
LatestRt? decodeLatestRt(String text) {
  final j = jsonDecode(text) as Map<String, dynamic>;
  if (j['date'] == null || j['value'] == null) return null;
  return (
    date: parseApiDate(j['date'] as String),
    rt: Rt(
      value: (j['value'] as num).toDouble(),
      lower: (j['lower'] as num).toDouble(),
      upper: (j['upper'] as num).toDouble(),
    ),
  );
}
