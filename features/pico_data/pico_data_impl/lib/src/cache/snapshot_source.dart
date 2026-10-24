import 'dart:async';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoint.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';
import 'package:pico_data_impl/src/cache/seed_source.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// Reads an [Endpoint] through the snapshot store with the C05 stream rule:
///
/// 1. a cached copy is emitted first (`source: cache`, `isStale` by TTL),
/// 2. a missing or stale copy, or `forceRefresh`, is fetched and emitted
///    (`source: network`),
/// 3. a failed fetch with a copy emits that copy again with `isStale: true`,
/// 4. a failed fetch without a copy emits one `Left`,
/// 5. the stream then closes.
///
/// Offline first: a copy that is not stale never touches the network. A missing
/// store copy falls back to the bundled seed (so a first launch, or a cleared
/// store, still shows data). The result is emitted before it is written to disk.
///
/// With [kConditionalRequests] on, a stale copy that has an `ETag` is asked
/// with `If-None-Match`; a 304 keeps the copy and only moves its date.
///
/// Watchers of the same key share one request (in-flight dedupe). A body is
/// written to the store only after it parsed.
class SnapshotSource {
  /// Creates the source. [now] is the clock, replaced in tests.
  SnapshotSource(
    this._client,
    this._store, {
    SeedSource seed = const NoSeed(),
    bool conditional = kConditionalRequests,
    DateTime Function()? now,
  }) : _seed = seed,
       _conditional = conditional,
       _now = now ?? DateTime.now;

  final PicoApiClient _client;
  final SnapshotStore _store;
  final SeedSource _seed;
  final bool _conditional;
  final DateTime Function() _now;
  final Map<String, Future<Object>> _inflight = {};

  /// The store, for the local data admin.
  SnapshotStore get store => _store;

  /// The saved copy of [endpoint], or null on a miss or a copy that no longer
  /// parses (it is deleted). A store miss falls back to the seed.
  Future<DataSnapshot<T>?> peek<T>(Endpoint<T> endpoint, Duration ttl) async =>
      (await _peek(endpoint, ttl))?.$1;

  Future<(DataSnapshot<T>, String?)?> _peek<T>(
    Endpoint<T> endpoint,
    Duration ttl,
  ) async {
    final saved = await peekRaw(endpoint.key);
    if (saved == null) return null;
    final parsed = await _client.parse(endpoint, saved.body);
    if (parsed.isLeft) {
      await _store.remove(endpoint.key);
      return null;
    }
    return (
      DataSnapshot(
        data: parsed.right,
        fetchedAt: saved.fetchedAt,
        source: DataSource.cache,
        isStale: saved.isStale(ttl, _now()),
      ),
      saved.etag,
    );
  }

  /// The saved text for [key], else the seed's, else null. Used for derived
  /// keys too (a small local value that is never requested).
  Future<StoredSnapshot?> peekRaw(String key) async =>
      await _store.read(key) ?? await _seed.read(key);

  /// Saves a small derived value under [key] (best effort).
  Future<void> saveDerived(String key, String body) async {
    try {
      await _store.write(key, body, _now());
    } on Object {
      // A derived value is only a shortcut.
    }
  }

  /// Now, for derived values.
  DateTime get now => _now();

  Future<Either<PicoFailure, _Fetched<T>>> _fetch<T>(
    Endpoint<T> endpoint, {
    DataSnapshot<T>? cached,
    String? etag,
  }) {
    final key = endpoint.key;
    final future = _inflight.putIfAbsent(key, () async {
      try {
        final ask = _conditional && cached != null && etag != null;
        final body = await _client.fetchBody(
          endpoint.path,
          query: endpoint.query,
          ifNoneMatch: ask ? etag : null,
        );
        if (body.isLeft) return Left<PicoFailure, _Fetched<T>>(body.left);
        final fetched = body.right;
        final at = _now();
        if (fetched.notModified && cached != null) {
          // 304: the copy is current. Only its date moves.
          return Right<PicoFailure, _Fetched<T>>(
            _Fetched(cached.data, at, _swallow(_store.touch(key, at))),
          );
        }
        final parsed = await _client.parse(endpoint, fetched.body);
        if (parsed.isLeft) {
          return Left<PicoFailure, _Fetched<T>>(parsed.left);
        }
        // The caller emits first; the write finishes behind it.
        return Right<PicoFailure, _Fetched<T>>(
          _Fetched(
            parsed.right,
            at,
            _swallow(_store.write(key, fetched.body, at, etag: fetched.etag)),
          ),
        );
      } finally {
        unawaited(Future<void>.microtask(() => _inflight.remove(key)));
      }
    });
    return future as Future<Either<PicoFailure, _Fetched<T>>>;
  }

  /// A failed save must not hide fresh data.
  Future<void> _swallow(Future<void> f) async {
    try {
      await f;
    } on Object {
      // Ignored on purpose.
    }
  }

  /// Streams [endpoint] by the C05 rule.
  Watch<T> watch<T>(
    Endpoint<T> endpoint, {
    required Duration ttl,
    bool forceRefresh = false,
  }) async* {
    final peeked = await _peek(endpoint, ttl);
    final cached = peeked?.$1;
    if (cached != null) yield Right(cached);
    if (cached != null && !cached.isStale && !forceRefresh) return;

    final fetched = await _fetch(endpoint, cached: cached, etag: peeked?.$2);
    switch (fetched) {
      case Right(:final value):
        yield Right(
          DataSnapshot(
            data: value.data,
            fetchedAt: value.at,
            source: DataSource.network,
          ),
        );
        await value.saved;
      case Left(:final value):
        if (cached != null) {
          yield Right(
            DataSnapshot(
              data: cached.data,
              fetchedAt: cached.fetchedAt,
              source: DataSource.cache,
              isStale: true,
              refreshFailure: value.kind,
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

final class _Fetched<T> {
  const _Fetched(this.data, this.at, this.saved);

  final T data;
  final DateTime at;
  final Future<void> saved;
}
