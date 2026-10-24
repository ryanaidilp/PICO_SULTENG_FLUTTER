import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/api/content_api.dart'
    show
        bannersFrom,
        donationsFrom,
        infographicsFrom,
        partnersFrom,
        telemedicinesFrom;
import 'package:pico_data_impl/src/api/endpoint.dart';
import 'package:pico_data_impl/src/api/facilities_api.dart'
    show hospitalsFrom, taskForcesFrom, vaccineLocationsFrom;
import 'package:pico_data_impl/src/api/stats_api.dart'
    show genderFrom, latestTestsFrom, testTypesFrom, vaccinationFrom;

List<dynamic> _list(Object? d) => d! as List<dynamic>;
Map<String, dynamic> _map(Object? d) => d! as Map<String, dynamic>;

/// Switch for `GET /regencies?load_all=true&include_latest_case=true` (PR #91
/// in the API repo). It is merged but not deployed, so it stays off and the
/// repository fetches the 13 series one by one (C02 fallback). Flip it once the
/// deploy is live.
const bool kRegencySummaryEndpoint = false;

/// Every request the app makes, as [Endpoint]s. Only `all=true` and
/// `load_all=true` are sent: no sort, no datetimes, no date parameters.
abstract final class PicoEndpoints {
  /// `GET /national/latest`.
  static final nationalLatest = Endpoint<CaseDay>(
    '/national/latest',
    (d) => caseDayFromNested(_map(d)),
  );

  /// `GET /national?all=true`.
  static final nationalSeries = Endpoint<CaseSeries>(
    '/national',
    (d) => seriesFromNested(
      _list(d),
      area: const AreaRef.national(),
      fallbackName: 'Indonesia',
    ),
    query: {'all': true},
  );

  /// `GET /provinces`.
  static final provinces = Endpoint<List<AreaSummary>>(
    '/provinces',
    (d) => provinceSummaries(_list(d)),
  );

  /// `GET /provinces/{id}/cases?all=true`.
  static Endpoint<CaseSeries> provinceSeries(String id) => Endpoint(
    '/provinces/$id/cases',
    (d) => seriesFromNested(
      _list(d),
      area: AreaRef.province(id),
      fallbackName: id,
    ),
    query: {'all': true},
  );

  /// `GET /regencies?load_all=true`.
  static final regencies = Endpoint<List<Regency>>(
    '/regencies',
    (d) => regencyList(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /regencies?load_all=true&include_latest_case=true` (not deployed).
  static final regencySummaries = Endpoint<List<AreaSummary>>(
    '/regencies',
    (d) => regencySummariesFromLatest(_list(d)),
    query: {'load_all': true, 'include_latest_case': true},
  );

  /// `GET /regencies/{code}/cases`.
  static Endpoint<CaseSeries> regencySeries(String code) => Endpoint(
    '/regencies/$code/cases',
    (d) => seriesFromRegency(_list(d), code: code),
  );

  /// `GET /hospitals?load_all=true`.
  static final hospitals = Endpoint<List<Hospital>>(
    '/hospitals',
    (d) => hospitalsFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /task-forces?load_all=true`.
  static final taskForces = Endpoint<List<TaskForceGroup>>(
    '/task-forces',
    (d) => taskForcesFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /vaccination/locations?load_all=true`.
  static final vaccineLocations = Endpoint<List<VaccineLocation>>(
    '/vaccination/locations',
    (d) => vaccineLocationsFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /stats/test-types`.
  static final testTypes = Endpoint<List<TestType>>(
    '/stats/test-types',
    (d) => testTypesFrom(_list(d)),
  );

  /// `GET /stats/tests`.
  static final latestTests = Endpoint<List<TestTotal>>(
    '/stats/tests',
    (d) => latestTestsFrom(_list(d)),
  );

  /// `GET /stats/gender/latest`.
  static final latestGender = Endpoint<GenderSnapshot>(
    '/stats/gender/latest',
    (d) => genderFrom(_map(d)),
  );

  /// `GET /vaccination/national|province?load_all=true`.
  static Endpoint<VaccinationSeries> vaccination(VaccinationScope scope) =>
      Endpoint(
        scope == VaccinationScope.national
            ? '/vaccination/national'
            : '/vaccination/province',
        (d) => vaccinationFrom(scope, _list(d)),
        query: {'load_all': true},
      );

  /// `GET /banners?load_all=true`.
  static final banners = Endpoint<List<Banner>>(
    '/banners',
    (d) => bannersFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /infographics?page=N&per_page=20`.
  static Endpoint<InfographicPage> infographics(int page) => Endpoint(
    '/infographics',
    (d) => infographicsFrom(_map(d), page),
    query: {'page': page, 'per_page': 20},
    unwrapPage: false,
  );

  /// `GET /donations?load_all=true`.
  static final donations = Endpoint<List<Donation>>(
    '/donations',
    (d) => donationsFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /telemedicines?load_all=true`.
  static final telemedicines = Endpoint<List<Telemedicine>>(
    '/telemedicines',
    (d) => telemedicinesFrom(_list(d)),
    query: {'load_all': true},
  );

  /// `GET /partners?load_all=true`.
  static final partners = Endpoint<List<Partner>>(
    '/partners',
    (d) => partnersFrom(_list(d)),
    query: {'load_all': true},
  );
}

/// Maps `/regencies?include_latest_case=true` rows: each row has the nested
/// `latest_case`, like `/provinces`.
List<AreaSummary> regencySummariesFromLatest(List<dynamic> rows) => [
  for (final r in rows.cast<Map<String, dynamic>>())
    if (r['latest_case'] is Map<String, dynamic>)
      AreaSummary(
        area: AreaRef.regency('${r['id']}'),
        name: r['name'] as String,
        latest: caseDayFromNested(r['latest_case'] as Map<String, dynamic>),
      ),
];
