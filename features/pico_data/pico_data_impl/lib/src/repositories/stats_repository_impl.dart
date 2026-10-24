import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// [StatsRepository] over the snapshot source (C05). TTL 24 h.
@LazySingleton(as: StatsRepository)
class StatsRepositoryImpl implements StatsRepository {
  /// Creates the repository.
  StatsRepositoryImpl(this._source);

  final SnapshotSource _source;

  @override
  Watch<List<TestType>> watchTestTypes({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.testTypes,
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<TestTotal>> watchLatestTests({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.latestTests,
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<GenderSnapshot> watchLatestGender({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.latestGender,
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<VaccinationSeries> watchVaccination(
    VaccinationScope scope, {
    bool forceRefresh = false,
  }) => _source.watch(
    PicoEndpoints.vaccination(scope),
    ttl: PicoTtl.data,
    forceRefresh: forceRefresh,
  );
}
