import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// [DirectoryRepository] over the snapshot source (C05). TTL 6 h.
@LazySingleton(as: DirectoryRepository)
class DirectoryRepositoryImpl implements DirectoryRepository {
  /// Creates the repository.
  DirectoryRepositoryImpl(this._source);

  final SnapshotSource _source;

  @override
  Watch<List<Regency>> watchRegencies({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.regencies,
        ttl: PicoTtl.directory,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<Hospital>> watchHospitals({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.hospitals,
        ttl: PicoTtl.directory,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<TaskForceGroup>> watchTaskForces({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.taskForces,
        ttl: PicoTtl.directory,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<VaccineLocation>> watchVaccineLocations({
    bool forceRefresh = false,
  }) => _source.watch(
    PicoEndpoints.vaccineLocations,
    ttl: PicoTtl.directory,
    forceRefresh: forceRefresh,
  );
}
