/// Fakes of every port, for feature tests.
///
/// Each fake serves one fixed value (or one failure) as a network snapshot.
/// Set the `...Result` fields to change what a method returns.
library;

import 'dart:async';

import 'package:pico_data_api/pico_data_api.dart';

/// Wraps [value] as a fresh network snapshot.
Either<PicoFailure, DataSnapshot<T>> fakeSnapshot<T>(
  T value, {
  DateTime? fetchedAt,
  DataSource source = DataSource.network,
  bool isStale = false,
}) => Right(
  DataSnapshot(
    data: value,
    fetchedAt: fetchedAt ?? DateTime(2024, 1, 15),
    source: source,
    isStale: isStale,
  ),
);

/// A one-shot failure for fakes.
Either<PicoFailure, DataSnapshot<T>> fakeFailure<T>([
  PicoFailureKind kind = PicoFailureKind.network,
]) => Left(PicoFailure(kind, message: 'fake ${kind.name}'));

Watch<T> _once<T>(Either<PicoFailure, DataSnapshot<T>> r) => Stream.value(r);

/// Fake [CaseRepository]. Defaults to empty data.
class FakeCaseRepository implements CaseRepository {
  /// Creates the fake.
  new({
    Either<PicoFailure, DataSnapshot<CaseDay>>? nationalLatest,
    this.series = const {},
    Either<PicoFailure, DataSnapshot<List<AreaSummary>>>? provinces,
    Either<PicoFailure, DataSnapshot<List<AreaSummary>>>? regencies,
  }) : nationalLatestResult = nationalLatest ?? fakeFailure(),
       provincesResult = provinces ?? fakeSnapshot(const []),
       regenciesResult = regencies ?? fakeSnapshot(const []);

  /// Result of [watchNationalLatest].
  Either<PicoFailure, DataSnapshot<CaseDay>> nationalLatestResult;

  /// Series per area. A missing area answers `notFound`.
  Map<AreaRef, CaseSeries> series;

  /// Result of [watchProvinceSummaries].
  Either<PicoFailure, DataSnapshot<List<AreaSummary>>> provincesResult;

  /// Result of [watchRegencySummaries].
  Either<PicoFailure, DataSnapshot<List<AreaSummary>>> regenciesResult;

  /// Number of calls with `forceRefresh: true`.
  int forcedRefreshes = 0;

  @override
  Watch<CaseDay> watchNationalLatest({bool forceRefresh = false}) {
    if (forceRefresh) forcedRefreshes++;
    return _once(nationalLatestResult);
  }

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) {
    if (forceRefresh) forcedRefreshes++;
    final s = series[area];
    return _once(
      s == null ? fakeFailure(PicoFailureKind.notFound) : fakeSnapshot(s),
    );
  }

  @override
  Watch<List<AreaSummary>> watchProvinceSummaries({bool forceRefresh = false}) {
    if (forceRefresh) forcedRefreshes++;
    return _once(provincesResult);
  }

  @override
  Watch<List<AreaSummary>> watchRegencySummaries({bool forceRefresh = false}) {
    if (forceRefresh) forcedRefreshes++;
    return _once(regenciesResult);
  }
}

/// Fake [StatsRepository].
class FakeStatsRepository implements StatsRepository {
  /// Result of [watchTestTypes].
  Either<PicoFailure, DataSnapshot<List<TestType>>> testTypes = fakeSnapshot(
    const <TestType>[],
  );

  /// Result of [watchLatestTests].
  Either<PicoFailure, DataSnapshot<List<TestTotal>>> latestTests = fakeSnapshot(
    const <TestTotal>[],
  );

  /// Result of [watchLatestGender].
  Either<PicoFailure, DataSnapshot<GenderSnapshot>> latestGender =
      fakeFailure();

  /// Vaccination per scope. A missing scope answers a network failure.
  Map<VaccinationScope, VaccinationSeries> vaccination = {};

  @override
  Watch<List<TestType>> watchTestTypes({bool forceRefresh = false}) =>
      _once(testTypes);

  @override
  Watch<List<TestTotal>> watchLatestTests({bool forceRefresh = false}) =>
      _once(latestTests);

  @override
  Watch<GenderSnapshot> watchLatestGender({bool forceRefresh = false}) =>
      _once(latestGender);

  @override
  Watch<VaccinationSeries> watchVaccination(
    VaccinationScope scope, {
    bool forceRefresh = false,
  }) {
    final v = vaccination[scope];
    return _once(v == null ? fakeFailure() : fakeSnapshot(v));
  }
}

/// Fake [DirectoryRepository].
class FakeDirectoryRepository implements DirectoryRepository {
  /// Result of [watchHospitals].
  Either<PicoFailure, DataSnapshot<List<Hospital>>> hospitals = fakeSnapshot(
    const <Hospital>[],
  );

  /// Result of [watchTaskForces].
  Either<PicoFailure, DataSnapshot<List<TaskForceGroup>>> taskForces =
      fakeSnapshot(const <TaskForceGroup>[]);

  /// Result of [watchVaccineLocations].
  Either<PicoFailure, DataSnapshot<List<VaccineLocation>>> vaccineLocations =
      fakeSnapshot(const <VaccineLocation>[]);

  @override
  Watch<List<Hospital>> watchHospitals({bool forceRefresh = false}) =>
      _once(hospitals);

  @override
  Watch<List<TaskForceGroup>> watchTaskForces({bool forceRefresh = false}) =>
      _once(taskForces);

  @override
  Watch<List<VaccineLocation>> watchVaccineLocations({
    bool forceRefresh = false,
  }) => _once(vaccineLocations);
}

/// Fake [ContentRepository].
class FakeContentRepository implements ContentRepository {
  /// Result of [watchBanners].
  Either<PicoFailure, DataSnapshot<List<Banner>>> banners = fakeSnapshot(
    const <Banner>[],
  );

  /// Result of [watchInfographics] for every page.
  Either<PicoFailure, DataSnapshot<InfographicPage>> infographics =
      fakeSnapshot(const InfographicPage(items: [], page: 1, hasNext: false));

  /// Result of [watchDonations].
  Either<PicoFailure, DataSnapshot<List<Donation>>> donations = fakeSnapshot(
    const <Donation>[],
  );

  /// Result of [watchTelemedicines].
  Either<PicoFailure, DataSnapshot<List<Telemedicine>>> telemedicines =
      fakeSnapshot(const <Telemedicine>[]);

  /// Result of [watchPartners].
  Either<PicoFailure, DataSnapshot<List<Partner>>> partners = fakeSnapshot(
    const <Partner>[],
  );

  @override
  Watch<List<Banner>> watchBanners({bool forceRefresh = false}) =>
      _once(banners);

  @override
  Watch<InfographicPage> watchInfographics({
    required int page,
    bool forceRefresh = false,
  }) => _once(infographics);

  @override
  Watch<List<Donation>> watchDonations({bool forceRefresh = false}) =>
      _once(donations);

  @override
  Watch<List<Telemedicine>> watchTelemedicines({bool forceRefresh = false}) =>
      _once(telemedicines);

  @override
  Watch<List<Partner>> watchPartners({bool forceRefresh = false}) =>
      _once(partners);
}

/// In-memory [SettingsRepository].
class FakeSettingsRepository implements SettingsRepository {
  PicoThemeMode _mode = PicoThemeMode.system;
  bool _alerts = false;
  final _changes = StreamController<PicoThemeMode>.broadcast();

  @override
  PicoThemeMode get themeMode => _mode;

  @override
  Stream<PicoThemeMode> get themeModeChanges => _changes.stream;

  @override
  Future<void> setThemeMode(PicoThemeMode mode) async {
    _mode = mode;
    _changes.add(mode);
  }

  @override
  bool get dataUpdateAlertsWanted => _alerts;

  @override
  Future<void> setDataUpdateAlertsWanted(bool wanted) async => _alerts = wanted;
}

/// In-memory [LocalDataAdmin].
class FakeLocalDataAdmin implements LocalDataAdmin {
  /// Bytes reported by [cachedBytes].
  int bytes = 0;

  /// Times [clearAll] was called.
  int clears = 0;

  @override
  Future<int> cachedBytes() async => bytes;

  @override
  Future<void> clearAll() async {
    clears++;
    bytes = 0;
  }
}
