import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/dates.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
double _dbl(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Test method rows (C03).
List<TestType> testTypesFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>()) _testType(j),
];

TestType _testType(Map<String, dynamic> j) => TestType(
  key: j['key'] as String,
  name: j['name'] as String,
  sample: cleanString(j['sample']) ?? '',
  duration: cleanString(j['duration']) ?? '',
  isRecommended: j['is_recommended'] == true,
);

/// The row with the highest `day` per type. `date_from` is a report-period
/// start, not a daily date, so no date is kept (C03).
List<TestTotal> latestTestsFrom(List<dynamic> rows) {
  final best = <String, Map<String, dynamic>>{};
  for (final j in rows.cast<Map<String, dynamic>>()) {
    final key = (j['test_type'] as Map<String, dynamic>)['key'] as String;
    final cur = best[key];
    if (cur == null || _int(j['day']) > _int(cur['day'])) best[key] = j;
  }
  return [
    for (final e in best.entries)
      TestTotal(
        typeKey: e.key,
        sourceDay: _int(e.value['day']),
        process: _int(e.value['process']),
        invalid: _int(e.value['invalid']),
        positive: _int(e.value['positive']),
        negative: _int(e.value['negative']),
      ),
  ];
}

GenderCounts _gender(Map<String, dynamic> j) => GenderCounts(
  total: _int(j['total']),
  ageGroups: {
    for (final e
        in (j['age_groups'] as Map<String, dynamic>? ?? const {}).entries)
      e.key: _int(e.value),
  },
);

GenderGroup _group(Map<String, dynamic> j) => GenderGroup(
  male: _gender(j['male'] as Map<String, dynamic>),
  female: _gender(j['female'] as Map<String, dynamic>),
);

/// `/stats/gender/latest` (C03). It has no date.
GenderSnapshot genderFrom(Map<String, dynamic> j) => GenderSnapshot(
  sourceDay: _int(j['day']),
  positive: _group(j['positive'] as Map<String, dynamic>),
  pdp: _group(j['pdp'] as Map<String, dynamic>),
);

DoseStats _doses(Map<String, dynamic> j) {
  final daily = j['daily'] as Map<String, dynamic>? ?? const {};
  final cum = j['cumulative'] as Map<String, dynamic>? ?? const {};
  final cov = j['coverage'] as Map<String, dynamic>? ?? const {};
  return DoseStats(
    dailyDose1: _int(daily['dose_1']),
    dailyDose2: _int(daily['dose_2']),
    cumulativeDose1: _int(cum['dose_1']),
    cumulativeDose2: _int(cum['dose_2']),
    coverageDose1: _dbl(cov['dose_1']),
    coverageDose2: _dbl(cov['dose_2']),
  );
}

const _groupKeys = {
  'elderly': VaccineGroup.elderly,
  'health_worker': VaccineGroup.healthWorker,
  'public': VaccineGroup.publik,
  'public_officer': VaccineGroup.publicOfficer,
  'teenager': VaccineGroup.teenager,
};

/// Vaccination rows keyed by calendar date. A Sulteng scope keeps only
/// province 72 rows.
VaccinationSeries vaccinationFrom(VaccinationScope scope, List<dynamic> rows) {
  final days = <VaccinationDay>[];
  for (final j in rows.cast<Map<String, dynamic>>()) {
    if (scope == VaccinationScope.sulteng &&
        j['province_id'] != null &&
        '${j['province_id']}' != '72') {
      continue;
    }
    final groups = j['groups'] as Map<String, dynamic>? ?? const {};
    days.add(
      VaccinationDay(
        date: parseApiDate(j['date'] as String),
        target: _int(j['target']),
        total: _doses(j['total'] as Map<String, dynamic>),
        groups: {
          for (final e in _groupKeys.entries)
            if (groups[e.key] is Map<String, dynamic>)
              e.value: GroupStats(
                target: _int((groups[e.key] as Map<String, dynamic>)['target']),
                doses: _doses(groups[e.key] as Map<String, dynamic>),
              ),
        },
      ),
    );
  }
  return VaccinationSeries.fromDays(scope, days);
}

/// Statistics endpoints of C03.
class StatsApi {
  /// Creates the API over [client].
  new(this._client);

  final PicoApiClient _client;

  /// `GET /stats/test-types`.
  Future<Either<PicoFailure, List<TestType>>> testTypes() => _client.getMapped(
    '/stats/test-types',
    (d) => testTypesFrom(d! as List<dynamic>),
  );

  /// `GET /stats/tests`, reduced to the latest row per type.
  Future<Either<PicoFailure, List<TestTotal>>> latestTests() => _client
      .getMapped('/stats/tests', (d) => latestTestsFrom(d! as List<dynamic>));

  /// `GET /stats/gender/latest`.
  Future<Either<PicoFailure, GenderSnapshot>> latestGender() =>
      _client.getMapped(
        '/stats/gender/latest',
        (d) => genderFrom(d! as Map<String, dynamic>),
      );

  /// `GET /vaccination/national|province?load_all=true`.
  Future<Either<PicoFailure, VaccinationSeries>> vaccination(
    VaccinationScope scope,
  ) => _client.getMapped(
    scope == VaccinationScope.national
        ? '/vaccination/national'
        : '/vaccination/province',
    (d) => vaccinationFrom(scope, d! as List<dynamic>),
    query: {'load_all': true},
  );
}
