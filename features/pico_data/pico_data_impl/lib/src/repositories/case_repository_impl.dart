import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// [CaseRepository] over the snapshot source (C05).
@LazySingleton(as: CaseRepository)
class CaseRepositoryImpl implements CaseRepository {
  /// Creates the repository.
  CaseRepositoryImpl(this._source);

  final SnapshotSource _source;

  @override
  Watch<CaseDay> watchNationalLatest({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.nationalLatest,
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) =>
      _source.watch(
        switch (area) {
          NationalArea() => PicoEndpoints.nationalSeries,
          ProvinceArea(:final id) => PicoEndpoints.provinceSeries(id),
          RegencyArea(:final code) => PicoEndpoints.regencySeries(code),
        },
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<AreaSummary>> watchProvinceSummaries({
    bool forceRefresh = false,
  }) => _source.watch(
    PicoEndpoints.provinces,
    ttl: PicoTtl.data,
    forceRefresh: forceRefresh,
  );

  @override
  Watch<List<AreaSummary>> watchRegencySummaries({
    bool forceRefresh = false,
  }) async* {
    if (kRegencySummaryEndpoint) {
      yield* _source.watch(
        PicoEndpoints.regencySummaries,
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );
      return;
    }
    // Fallback (C02): the 13 series one after another, last row of each.
    final names = await _source.latest(
      PicoEndpoints.regencies,
      ttl: PicoTtl.data,
      forceRefresh: forceRefresh,
    );
    if (names.isLeft) {
      yield Left(names.left);
      return;
    }
    final regencies = names.right.data;

    DataSnapshot<List<AreaSummary>>? compose(
      List<(String, String, DataSnapshot<CaseSeries>)> parts, {
      required bool anyMissing,
    }) {
      final usable = [
        for (final p in parts)
          if (p.$3.data.latest != null) p,
      ];
      if (usable.isEmpty) return null;
      final summaries = [
        for (final (code, name, snap) in usable)
          AreaSummary(
            area: AreaRef.regency(code),
            name: name,
            latest: snap.data.latest!,
          ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final oldest = usable
          .map((p) => p.$3.fetchedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return DataSnapshot(
        data: summaries,
        fetchedAt: oldest,
        source: usable.any((p) => p.$3.source == DataSource.network)
            ? DataSource.network
            : DataSource.cache,
        isStale: anyMissing || usable.any((p) => p.$3.isStale),
      );
    }

    // Step 1: what is saved, at once.
    final saved = <(String, String, DataSnapshot<CaseSeries>)>[];
    for (final r in regencies) {
      final s = await _source.peek(
        PicoEndpoints.regencySeries(r.code),
        PicoTtl.data,
      );
      if (s != null) saved.add((r.code, r.name, s));
    }
    if (saved.length == regencies.length) {
      final c = compose(saved, anyMissing: false);
      if (c != null) yield Right(c);
      if (!forceRefresh && !saved.any((p) => p.$3.isStale)) return;
    }

    // Step 2: one request at a time, each series also fills the detail cache.
    final fresh = <(String, String, DataSnapshot<CaseSeries>)>[];
    PicoFailure? firstFailure;
    for (final r in regencies) {
      final res = await _source.latest(
        PicoEndpoints.regencySeries(r.code),
        ttl: PicoTtl.data,
        forceRefresh: forceRefresh,
      );
      switch (res) {
        case Right(:final value):
          fresh.add((r.code, r.name, value));
        case Left(:final value):
          firstFailure ??= value;
      }
    }
    final c = compose(fresh, anyMissing: fresh.length < regencies.length);
    yield c != null
        ? Right(c)
        : Left(
            firstFailure ??
                const PicoFailure(PicoFailureKind.network, message: 'No data'),
          );
  }
}
