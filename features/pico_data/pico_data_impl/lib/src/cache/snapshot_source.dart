import 'dart:async';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoint.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';

/// Reads an [Endpoint] through the snapshot store with the C05 stream rule:
///
/// 1. a cached copy is emitted first (`source: cache`, `isStale` by TTL),
/// 2. a missing or stale copy, or `forceRefresh`, is fetched and emitted
///    (`source: network`),
/// 3. a failed fetch with a copy emits that copy again with `isStale: true`,
/// 4. a failed fetch without a copy emits one `Left`,
/// 5. the stream then closes.
///
/// Watchers of the same key share one request (in-flight dedupe). A body is
/// written to the store only after it parsed.
class SnapshotSource {
  /// Creates the source. [now] is the clock, replaced in tests.
  SnapshotSource(this._client, this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PicoApiClient _client;
  final SnapshotStore _store;
  final DateTime Function() _now;
  final Map<String, Future<Object>> _inflight = {};

  /// The store, for the local data admin.
  SnapshotStore get store => _store;

  /// The saved copy of [endpoint], or null on a miss or a copy that no longer
  /// parses (it is deleted).
  Future<DataSnapshot<T>?> peek<T>(Endpoint<T> endpoint, Duration ttl) async {
    final saved = await _store.read(endpoint.key);
    if (saved == null) return null;
    final parsed = await _client.parse(endpoint, saved.body);
    if (parsed.isLeft) {
      await _store.remove(endpoint.key);
      return null;
    }
    return DataSnapshot(
      data: parsed.right,
      fetchedAt: saved.fetchedAt,
      source: DataSource.cache,
      isStale: saved.isStale(ttl, _now()),
    );
  }

  Future<Either<PicoFailure, (T, DateTime)>> _fetch<T>(Endpoint<T> endpoint) {
    final key = endpoint.key;
    final future = _inflight.putIfAbsent(key, () async {
      try {
        final body = await _client.getBody(
          endpoint.path,
          query: endpoint.query,
        );
        if (body.isLeft) return Left<PicoFailure, (T, DateTime)>(body.left);
        final parsed = await _client.parse(endpoint, body.right);
        if (parsed.isLeft) return Left<PicoFailure, (T, DateTime)>(parsed.left);
        final at = _now();
        try {
          await _store.write(key, body.right, at);
        } on Object {
          // A failed save must not hide fresh data.
        }
        return Right<PicoFailure, (T, DateTime)>((parsed.right, at));
      } finally {
        unawaited(Future<void>.microtask(() => _inflight.remove(key)));
      }
    });
    return future as Future<Either<PicoFailure, (T, DateTime)>>;
  }

  /// Streams [endpoint] by the C05 rule.
  Watch<T> watch<T>(
    Endpoint<T> endpoint, {
    required Duration ttl,
    bool forceRefresh = false,
  }) async* {
    final cached = await peek(endpoint, ttl);
    if (cached != null) yield Right(cached);
    if (cached != null && !cached.isStale && !forceRefresh) return;

    final fetched = await _fetch(endpoint);
    switch (fetched) {
      case Right(:final value):
        yield Right(
          DataSnapshot(
            data: value.$1,
            fetchedAt: value.$2,
            source: DataSource.network,
          ),
        );
      case Left(:final value):
        if (cached != null) {
          yield Right(
            DataSnapshot(
              data: cached.data,
              fetchedAt: cached.fetchedAt,
              source: DataSource.cache,
              isStale: true,
            ),
          );
        } else {
          yield Left(value);
        }
    }
  }

  /// The last event of [watch]: the freshest result.
  Future<Either<PicoFailure, DataSnapshot<T>>> latest<T>(
    Endpoint<T> endpoint, {
    required Duration ttl,
    bool forceRefresh = false,
  }) => watch(endpoint, ttl: ttl, forceRefresh: forceRefresh).last;
}
