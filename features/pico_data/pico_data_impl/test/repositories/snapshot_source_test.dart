import 'dart:io';

import 'package:dependencies/network.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

import '../api/fake_adapter.dart';
import '../api/routed_adapter.dart';

final nationalOk = fixture('national_latest.json');

void main() {
  late Directory dir;
  late SnapshotStore store;
  late DateTime clock;
  late RoutedAdapter adapter;

  SnapshotSource source() => SnapshotSource(
    PicoApiClient.create(
      baseUrl: 'https://pico.test',
      userAgent: 't',
      adapter: adapter,
      retryDelay: Duration.zero,
    ),
    store,
    now: () => clock,
  );

  Future<List<Either<PicoFailure, DataSnapshot<CaseDay>>>> run(
    SnapshotSource s, {
    bool force = false,
  }) => s
      .watch(
        PicoEndpoints.nationalLatest,
        ttl: PicoTtl.latest,
        forceRefresh: force,
      )
      .toList();

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pico_source_');
    store = SnapshotStore(Directory('${dir.path}/pico_cache/v1'));
    clock = DateTime(2024, 1, 15, 8);
    adapter = RoutedAdapter({'/national/latest': FakeReply(200, nationalOk)});
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('C05 stream rule', () {
    test(
      'no copy: fetches, emits one network snapshot, saves it, closes',
      () async {
        final events = await run(source());
        expect(events.length, 1);
        final s = events.single.right;
        expect(s.source, DataSource.network);
        expect(s.isStale, isFalse);
        expect(s.fetchedAt, clock);
        expect(s.data.cumulative.positive, 6812127);
        expect(adapter.calls, ['/national/latest']);
        expect(await store.read('/national/latest'), isNotNull);
      },
    );

    test(
      'step 1: a fresh copy is emitted first and no request is made',
      () async {
        await run(source());
        adapter.calls.clear();
        clock = clock.add(const Duration(hours: 1));
        final events = await run(source());
        expect(events.length, 1);
        expect(events.single.right.source, DataSource.cache);
        expect(events.single.right.isStale, isFalse);
        expect(adapter.calls, isEmpty);
      },
    );

    test('step 2: a stale copy is emitted (stale), then refreshed from the network', () async {
      await run(source());
      clock = clock.add(const Duration(days: 8));
      final events = await run(source());
      expect(events.length, 2);
      expect(events[0].right.source, DataSource.cache);
      expect(events[0].right.isStale, isTrue);
      expect(events[1].right.source, DataSource.network);
      expect(events[1].right.fetchedAt, clock);
    });

    test('forceRefresh fetches even when fresh', () async {
      await run(source());
      adapter.calls.clear();
      final events = await run(source(), force: true);
      expect(events.length, 2);
      expect(events.last.right.source, DataSource.network);
      expect(adapter.calls.length, 1);
    });

    test('step 3: a failed fetch with a copy emits the copy again as stale, no Left', () async {
      await run(source());
      adapter.routes['/national/latest'] = const FakeReply(500, 'boom');
      clock = clock.add(const Duration(days: 8));
      final events = await run(source());
      expect(events.length, 2);
      expect(events.every((e) => e.isRight), isTrue);
      expect(events.last.right.source, DataSource.cache);
      expect(events.last.right.isStale, isTrue);
      expect(events.last.right.fetchedAt, DateTime(2024, 1, 15, 8));
    });

    test('step 4: a failed fetch without a copy emits one Left', () async {
      adapter.routes['/national/latest'] = const FakeReply(500, 'boom');
      final events = await run(source());
      expect(events.length, 1);
      expect(events.single.left.kind, PicoFailureKind.server);
    });

    test('step 4: offline without a copy is a network Left', () async {
      adapter.routes['/national/latest'] = DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'offline',
      );
      expect((await run(source())).single.left.kind, PicoFailureKind.network);
    });

    test('step 5: the stream closes after the last event', () async {
      final done = source()
          .watch(PicoEndpoints.nationalLatest, ttl: PicoTtl.latest)
          .isEmpty;
      expect(await done, isFalse);
    });

    test(
      'a body that parses badly is not saved and counts as a failure',
      () async {
        adapter.routes['/national/latest'] = const FakeReply(
          200,
          '{"status":"success","data":{"date":"x"}}',
        );
        final events = await run(source());
        expect(events.single.left.kind, PicoFailureKind.server);
        expect(await store.read('/national/latest'), isNull);
      },
    );

    test(
      'a saved copy that no longer parses is deleted and refetched',
      () async {
        await store.write(
          '/national/latest',
          '{"status":"success","data":{"nope":1}}',
          clock,
        );
        final events = await run(source());
        expect(events.length, 1);
        expect(events.single.right.source, DataSource.network);
      },
    );
  });

  group('store safety', () {
    test('a write killed halfway leaves only a .tmp and the next read is a clean miss', () async {
      final target = '${store.directory.path}/_national_latest.json';
      store.directory.createSync(recursive: true);
      File('$target.tmp').writeAsStringSync('{"v":1,"body":"hal');
      expect(await store.read('/national/latest'), isNull);
      final events = await run(source());
      expect(events.single.right.source, DataSource.network);
    });

    test('a corrupt saved file is a miss and the file is gone', () async {
      await store.write('/national/latest', 'x', clock);
      final f = store.directory.listSync().whereType<File>().single
        ..writeAsStringSync('not json');
      expect(await store.read('/national/latest'), isNull);
      expect(f.existsSync(), isFalse);
    });
  });

  test('two watchers of one key cause one client call', () async {
    adapter.delay = const Duration(milliseconds: 40);
    final s = source();
    final a = s
        .watch(PicoEndpoints.nationalLatest, ttl: PicoTtl.latest)
        .toList();
    final b = s
        .watch(PicoEndpoints.nationalLatest, ttl: PicoTtl.latest)
        .toList();
    final both = await Future.wait([a, b]);
    expect(both[0].single.right.data.cumulative.positive, 6812127);
    expect(both[1].single.right.data.cumulative.positive, 6812127);
    expect(adapter.calls.length, 1);
  });
}
