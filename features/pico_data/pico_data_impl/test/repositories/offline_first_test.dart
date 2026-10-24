import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/repositories/case_repository_impl.dart';
import 'package:pico_data_impl/src/repositories/content_repository_impl.dart';

import '../api/fake_adapter.dart';
import '../api/routed_adapter.dart';

/// Reads the real bundled seed from disk.
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = File('assets/seed/seed.json').readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// A store whose writes are slow, to prove the result is emitted first.
class _SlowStore extends SnapshotStore {
  _SlowStore(super.directory);

  bool wrote = false;

  @override
  Future<void> write(
    String key,
    String body,
    DateTime fetchedAt, {
    String? etag,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    wrote = true;
    return super.write(key, body, fetchedAt, etag: etag);
  }
}

final nationalLatest = fixture('national_latest.json');
final provinces = fixture('provinces_per_page_2.json');

void main() {
  late Directory dir;
  late SnapshotStore store;
  late DateTime clock;
  late RoutedAdapter adapter;
  late DateTime seedDate;

  PicoApiClient client() => PicoApiClient.create(
    baseUrl: 'https://pico.test',
    userAgent: 't',
    adapter: adapter,
    retryDelay: Duration.zero,
  );

  SnapshotSource source({
    SnapshotStore? s,
    bool conditional = false,
    bool withSeed = true,
  }) => SnapshotSource(
    client(),
    s ?? store,
    seed: withSeed ? AssetSeed(bundle: _FileBundle()) : const NoSeed(),
    conditional: conditional,
    now: () => clock,
  );

  Future<List<Either<PicoFailure, DataSnapshot<T>>>> run<T>(
    SnapshotSource s,
    Endpoint<T> e,
    Duration ttl, {
    bool force = false,
  }) => s.watch(e, ttl: ttl, forceRefresh: force).toList();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pico_offline_');
    store = SnapshotStore(Directory('${dir.path}/pico_cache/v1'));
    adapter = RoutedAdapter({
      '/national/latest': FakeReply(200, nationalLatest),
      '/provinces': FakeReply(200, provinces),
      '/banners': FakeReply(200, fixture('banners.json')),
    });
    final seed = await AssetSeed(bundle: _FileBundle())
        .read('/national/latest');
    seedDate = seed!.fetchedAt;
    clock = seedDate.add(const Duration(days: 1));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('seed', () {
    test(
      'first launch, empty store: the seed answers, zero requests',
      () async {
        final events = await run(
          source(),
          PicoEndpoints.nationalLatest,
          PicoTtl.latest,
        );
        expect(events, hasLength(1));
        final s = events.single.right;
        expect(s.source, DataSource.cache);
        expect(s.isStale, isFalse);
        expect(
          s.fetchedAt,
          seedDate,
          reason: 'the stamp carries the seed date',
        );
        expect(s.data.cumulative.positive, 6812127);
        expect(adapter.calls, isEmpty);
      },
    );

    test('a stale seed shows first, then refreshes; a failed refresh keeps '
        'the stale copy and never an error', () async {
      clock = seedDate.add(const Duration(days: 30));
      adapter.routes.remove('/national/latest');
      final events = await run(
        source(),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect(events, hasLength(2));
      expect(events.every((e) => e.isRight), isTrue);
      expect(events.last.right.isStale, isTrue);
      expect(events.last.right.fetchedAt, seedDate);
      expect(adapter.calls, ['/national/latest']);
    });

    test(
      'clearing the store falls back to the seed, not to a blank app',
      () async {
        final s = source();
        clock = seedDate.add(const Duration(days: 30));
        await run(s, PicoEndpoints.nationalLatest, PicoTtl.latest);
        expect((await store.read('/national/latest')), isNotNull);
        await store.clear();
        adapter.calls.clear();
        clock = seedDate.add(const Duration(days: 1));
        final events = await run(
          source(),
          PicoEndpoints.nationalLatest,
          PicoTtl.latest,
        );
        expect(events.single.right.data.cumulative.positive, 6812127);
        expect(adapter.calls, isEmpty);
      },
    );

    test('the bundled seed is small and complete', () async {
      final raw = File('assets/seed/seed.json');
      expect(raw.lengthSync(), lessThan(60 * 1024));
      final seed = AssetSeed(bundle: _FileBundle());
      for (final k in [
        '/national/latest',
        '/provinces',
        '/banners?load_all=true',
        kLatestRtKey,
        PicoEndpoints.regencySummaries.key,
      ]) {
        expect(await seed.read(k), isNotNull, reason: k);
      }
      expect(jsonDecode(raw.readAsStringSync())['dataThrough'], '2024-01-14');
    });
  });

  group('policy', () {
    test('a fresh saved copy never touches the network', () async {
      await store.write('/national/latest', nationalLatest, clock);
      final events = await run(
        source(withSeed: false),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect(events, hasLength(1));
      expect(adapter.calls, isEmpty);
    });

    test('an archive series is not re-fetched on every open', () async {
      await store.write(
        '/national?all=true',
        fixture('national_all_true_sample.json'),
        clock.subtract(const Duration(days: 60)),
      );
      final repo = CaseRepositoryImpl(source(withSeed: false));
      final events = await repo.watchSeries(const AreaRef.national()).toList();
      expect(events, hasLength(1));
      expect(events.single.right.isStale, isFalse);
      expect(adapter.calls, isEmpty);
    });

    test('the result is emitted before the save finishes', () async {
      final slow = _SlowStore(Directory('${dir.path}/slow'));
      final s = source(s: slow, withSeed: false);
      final it = StreamIterator(
        s.watch(PicoEndpoints.nationalLatest, ttl: PicoTtl.latest),
      );
      expect(await it.moveNext(), isTrue);
      expect(it.current.right.source, DataSource.network);
      expect(slow.wrote, isFalse, reason: 'emitted while the write is pending');
      expect(await it.moveNext(), isFalse);
      expect(slow.wrote, isTrue, reason: 'the stream closes after the save');
    });

    test('a body over 100 KB is decoded and mapped in an isolate', () async {
      final row =
          (jsonDecode(fixture('national_all_true_sample.json'))
                  as Map<String, dynamic>)['data'][0]
              as Map<String, dynamic>;
      final rows = [
        for (var i = 0; i < 1500; i++)
          {...row, 'date': DateTime(2020, 3, 2 + i).toIso8601String()},
      ];
      final body = jsonEncode({'status': 'success', 'data': rows});
      expect(body.length, greaterThan(kIsolateDecodeThreshold));
      final result = await client().parse(PicoEndpoints.nationalSeries, body);
      expect(result.right.days, hasLength(1500));
      expect(result.right.days.first.date, DateTime(2020, 3, 2));
      expect(result.right.days.every((d) => d.rt == null), isTrue);
    });

    test('a bad big body is a failure, not an exception', () async {
      final body = '{"status":"success","data":[${'1,' * 80000}1]}';
      final result = await client().parse(PicoEndpoints.nationalSeries, body);
      expect(result.isLeft, isTrue);
      expect(result.left.kind, PicoFailureKind.server);
    });
  });

  group('conditional requests (flag on since API 2.11.0)', () {
    test('off: a stale copy is fetched with no If-None-Match', () async {
      await store.write(
        '/national/latest',
        'old',
        clock.subtract(const Duration(days: 30)),
        etag: 'W/"a"',
      );
      await run(
        source(withSeed: false),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect(adapter.headers.single.containsKey('If-None-Match'), isFalse);
    });

    test('on: 304 keeps the copy and only moves its date', () async {
      final old = clock.subtract(const Duration(days: 30));
      await store.write('/national/latest', nationalLatest, old, etag: 'W/"a"');
      adapter.routes['/national/latest'] = const FakeReply(304, '');
      final events = await run(
        source(withSeed: false, conditional: true),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect(adapter.headers.single['If-None-Match'], 'W/"a"');
      expect(events, hasLength(2));
      expect(events.first.right.isStale, isTrue);
      expect(events.last.right.fetchedAt, clock);
      expect(events.last.right.data.cumulative.positive, 6812127);
      final saved = (await store.read('/national/latest'))!;
      expect(saved.body, nationalLatest);
      expect(saved.etag, 'W/"a"');
      expect(saved.fetchedAt.isAtSameMomentAs(clock), isTrue);
    });

    test('on: a 200 stores the new ETag', () async {
      adapter.routes['/national/latest'] = FakeReply(
        200,
        nationalLatest,
        etag: 'W/"b"',
      );
      await run(
        source(withSeed: false, conditional: true),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect((await store.read('/national/latest'))!.etag, 'W/"b"');
    });

    test('a stale copy with no ETag never sends If-None-Match', () async {
      await store.write(
        '/national/latest',
        nationalLatest,
        clock.subtract(const Duration(days: 30)),
      );
      await run(
        source(withSeed: false),
        PicoEndpoints.nationalLatest,
        PicoTtl.latest,
      );
      expect(adapter.headers.single.containsKey('If-None-Match'), isFalse);
    });

    test('the flag is on since API 2.11.0', () {
      expect(kConditionalRequests, isTrue);
    });
  });

  group('Beranda request counts (empty, warm and stale stores)', () {
    // What Beranda reads: national latest, province rows, the Rt reading and
    // the banners. Never a series.
    Future<void> beranda(SnapshotSource s) async {
      final cases = CaseRepositoryImpl(s);
      final content = ContentRepositoryImpl(s);
      for (final w in [
        cases.watchNationalLatest(),
        cases.watchProvinceSummaries(),
        cases.watchNationalLatestRt(),
        content.watchBanners(),
      ]) {
        final events = await w.toList();
        expect(events.every((e) => e.isRight), isTrue);
        expect(events, isNotEmpty);
      }
    }

    test('cold start, empty store, seed present: 0 requests', () async {
      await beranda(source());
      expect(adapter.calls, isEmpty);
    });

    test('warm start, fresh copies: 0 requests', () async {
      clock = seedDate.add(const Duration(days: 20));
      await beranda(source()); // stale seed: refreshes and saves
      adapter.calls.clear();
      clock = clock.add(const Duration(days: 1));
      await beranda(source());
      expect(adapter.calls, isEmpty);
    });

    test(
      'stale copies: background refresh of latest-style endpoints only',
      () async {
        clock = seedDate.add(const Duration(days: 20));
        await beranda(source());
        expect(adapter.calls.toSet(), {
          '/national/latest',
          '/provinces',
          '/banners',
        });
        expect(adapter.calls, hasLength(3));
        expect(
          adapter.calls.any(
            (c) => c.startsWith('/national') && c != '/national/latest',
          ),
          isFalse,
          reason: 'no full series on Beranda',
        );
      },
    );

    test(
      'the Rt reading comes from the seed with its own date, no request',
      () async {
        final r = await CaseRepositoryImpl(source())
            .watchNationalLatestRt()
            .toList();
        final rt = r.single.right.data!;
        expect(rt.date, DateTime(2023, 7, 9));
        expect(rt.rt.value, 0.12);
        expect(adapter.calls, isEmpty);
      },
    );

    test(
      'opening Statistik loads the series once and refreshes the Rt value',
      () async {
        adapter.routes['/national'] = FakeReply(
          200,
          fixture('national_all_true_sample.json'),
        );
        final repo = CaseRepositoryImpl(source());
        await repo.watchSeries(const AreaRef.national()).toList();
        expect(adapter.calls, ['/national']);
        // The derived value is saved behind the emission.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // The sample has no Rt: the derived value is now "none", never zero.
        final rt = (await repo.watchNationalLatestRt().toList()).single.right;
        expect(rt.data, isNull);
      },
    );

    test('13 kabupaten latest rows come from the seed: 0 requests', () async {
      final events = await CaseRepositoryImpl(source())
          .watchRegencySummaries()
          .toList();
      expect(events, hasLength(1));
      expect(events.single.right.source, DataSource.cache);
      expect(events.single.right.data, hasLength(13));
      expect(events.single.right.fetchedAt, seedDate);
      expect(adapter.calls, isEmpty);
    });
  });

  test('latest Rt codec: null is not zero', () {
    expect(decodeLatestRt(encodeLatestRt(null)), isNull);
    final rt = (
      date: DateTime(2023, 7, 9),
      rt: const Rt(value: .12, lower: .08, upper: .15),
    );
    expect(decodeLatestRt(encodeLatestRt(rt))!.rt.value, .12);
  });
}
