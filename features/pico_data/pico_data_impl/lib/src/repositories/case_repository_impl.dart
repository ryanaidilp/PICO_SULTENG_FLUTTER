import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// [CaseRepository] over the snapshot source (C05).
@LazySingleton(as: CaseRepository)
class CaseRepositoryImpl implements CaseRepository {
  /// Creates the repository.
  CaseRepositoryImpl(this._source) : _summaryEndpoint = kRegencySummaryEndpoint;

  /// For tests: choose the kabupaten summary path without the const flag.
  @visibleForTesting
  CaseRepositoryImpl.withSummaryEndpoint(
    this._source, {
    required bool useSummaryEndpoint,
  }) : _summaryEndpoint = useSummaryEndpoint;

  final SnapshotSource _source;
  final bool _summaryEndpoint;

  @override
  Watch<CaseDay> watchNationalLatest({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.nationalLatest,
        ttl: PicoTtl.latest,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) {
    final watch = _source.watch(
      switch (area) {
        NationalArea() => PicoEndpoints.nationalSeries,
        ProvinceArea(:final id) => PicoEndpoints.provinceSeries(id),
        RegencyArea(:final code) => PicoEndpoints.regencySeries(code),
      },
      ttl: PicoTtl.archiveSeries,
      forceRefresh: forceRefresh,
    );
    if (area is! NationalArea) return watch;
    // The full national series also feeds the small Rt value Beranda reads.
    return watch.map((r) {
      if (r case Right(:final value) when value.source == DataSource.network) {
        unawaited(
          _source.saveDerived(
            kLatestRtKey,
            encodeLatestRt(latestRtOf(value.data)),
          ),
        );
      }
      return r;
    });
  }

  @override
  Watch<LatestRt?> watchNationalLatestRt({bool forceRefresh = false}) async* {
    // Never a request: the saved value, else the bundled seed, else nothing.
    final saved = await _source.peekRaw(kLatestRtKey);
    DataSnapshot<LatestRt?> snapshot(LatestRt? rt, DateTime at) =>
        DataSnapshot(data: rt, fetchedAt: at, source: DataSource.cache);
    if (saved == null) {
      yield Right(snapshot(null, _source.now));
      return;
    }
    try {
      yield Right(snapshot(decodeLatestRt(saved.body), saved.fetchedAt));
    } on Object {
      yield Right(snapshot(null, saved.fetchedAt));
    }
  }

  @override
  Watch<List<AreaSummary>> watchProvinceSummaries({
    bool forceRefresh = false,
  }) => _source.watch(
    PicoEndpoints.provinces,
    ttl: PicoTtl.latest,
    forceRefresh: forceRefresh,
  );

  @override
  Watch<List<AreaSummary>> watchRegencySummaries({
    bool forceRefresh = false,
  }) async* {
    if (_summaryEndpoint) {
      // One call (API 2.11.0): seed or saved copy first, then the network by
      // the stream rule. Only when it yields nothing at all (the call failed
      // and there is no copy) does the 13-series loop below run.
      var gotData = false;
      PicoFailure? failure;
      await for (final e in _source.watch(
        PicoEndpoints.regencySummaries,
        ttl: PicoTtl.archiveSeries,
        forceRefresh: forceRefresh,
      )) {
        if (e.isRight) {
          gotData = true;
          yield e;
        } else {
          failure = e.left;
        }
      }
      if (gotData) return;
      if (failure?.kind == PicoFailureKind.rateLimited) {
        yield Left(failure!);
        return;
      }
    }

    // Offline first for the fallback. 1) The 13 series saved from earlier
    // visits. Neither this nor a copy inside the archive TTL touches the
    // network; only a miss (or a pull to refresh) reaches the loop below.
    final savedNames = await _source.peek(
      PicoEndpoints.regencies,
      PicoTtl.directory,
    );
    if (savedNames != null) {
      final parts = <(String, String, DataSnapshot<CaseSeries>)>[];
      for (final r in savedNames.data) {
        final s = await _source.peek(
          PicoEndpoints.regencySeries(r.code),
          PicoTtl.archiveSeries,
        );
        if (s != null) parts.add((r.code, r.name, s));
      }
      if (parts.length == savedNames.data.length) {
        final c = _compose(parts, anyMissing: false);
        if (c != null) yield Right(c);
        if (!forceRefresh && !parts.any((p) => p.$3.isStale)) return;
      }
    }

    // Fallback (C02): the 13 series one after another, last row of each.
    final names = await _source.latest(
      PicoEndpoints.regencies,
      ttl: PicoTtl.directory,
      forceRefresh: forceRefresh,
    );
    if (names.isLeft) {
      yield Left(names.left);
      return;
    }
    final regencies = names.right.data;

    // Step 1: what is saved, at once.
    final saved = <(String, String, DataSnapshot<CaseSeries>)>[];
    for (final r in regencies) {
      final s = await _source.peek(
        PicoEndpoints.regencySeries(r.code),
        PicoTtl.archiveSeries,
      );
      if (s != null) saved.add((r.code, r.name, s));
    }
    if (saved.length == regencies.length) {
      final c = _compose(saved, anyMissing: false);
      if (c != null) yield Right(c);
      if (!forceRefresh && !saved.any((p) => p.$3.isStale)) return;
    }

    // Step 2: one request at a time, each series also fills the detail cache.
    final fresh = <(String, String, DataSnapshot<CaseSeries>)>[];
    PicoFailure? firstFailure;
    for (final r in regencies) {
      final res = await _source.latest(
        PicoEndpoints.regencySeries(r.code),
        ttl: PicoTtl.archiveSeries,
        forceRefresh: forceRefresh,
      );
      switch (res) {
        case Right(:final value):
          fresh.add((r.code, r.name, value));
        case Left(:final value):
          firstFailure ??= value;
      }
      // Rows appear as they arrive; the last answer is emitted after the loop.
      if (r != regencies.last && fresh.isNotEmpty) {
        final partial = _compose(fresh, anyMissing: true);
        if (partial != null) yield Right(partial);
      }
    }
    final c = _compose(fresh, anyMissing: fresh.length < regencies.length);
    yield c != null
        ? Right(c)
        : Left(
            firstFailure ??
                const PicoFailure(PicoFailureKind.network, message: 'No data'),
          );
  }
}

DataSnapshot<List<AreaSummary>>? _compose(
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
    refreshFailure: usable
        .map((p) => p.$3.refreshFailure)
        .firstWhere((f) => f != null, orElse: () => null),
  );
}
