import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

import '../api/fake_adapter.dart';
import '../api/routed_adapter.dart';

const regs = {
  '7201': 'Banggai Kepulauan',
  '7202': 'Banggai',
  '7203': 'Morowali',
  '7204': 'Poso',
  '7205': 'Donggala',
  '7206': 'Toli-Toli',
  '7207': 'Buol',
  '7208': 'Parigi Mautong',
  '7209': 'Tojo Una-Una',
  '7210': 'Sigi',
  '7211': 'Banggai Laut',
  '7212': 'Morowali Utara',
  '7271': 'Kota Palu',
};

FakeReply listReply() => FakeReply.ok({
  'status': 'success',
  'data': [
    for (final e in regs.entries)
      {'id': int.parse(e.key), 'province_id': 72, 'name': e.value},
  ],
});

FakeReply seriesReply(String code) => FakeReply.ok({
  'status': 'success',
  'data': [
    for (final (i, d) in ['2024-01-13', '2024-01-14'].indexed)
      {
        'id': i,
        'day': i,
        'regency_id': int.parse(code),
        'positive': 1,
        'recovered': 0,
        'deceased': 0,
        'cumulative_positive': 10 + i,
        'cumulative_recovered': 5,
        'cumulative_deceased': 1,
        'rt': null,
        'rt_upper': null,
        'rt_lower': null,
        'regency': {
          'id': int.parse(code),
          'province_id': 0,
          'name': regs[code],
        },
        'date': '${d}T00:00:00+07:00',
      },
  ],
});

void main() {
  late Directory dir;
  late RoutedAdapter adapter;
  late SnapshotSource src;
  var clock = DateTime(2024, 1, 15, 8);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pico_reg_');
    clock = DateTime(2024, 1, 15, 8);
    adapter = RoutedAdapter({
      '/regencies': listReply(),
      for (final c in regs.keys) '/regencies/$c/cases': seriesReply(c),
    });
    src = SnapshotSource(
      PicoApiClient.create(
        baseUrl: 'https://pico.test',
        userAgent: 't',
        adapter: adapter,
        retryDelay: Duration.zero,
      ),
      SnapshotStore(Directory('${dir.path}/c')),
      now: () => clock,
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the flag is on since API 2.11.0 (live 2026-10-24)', () {
    expect(kRegencySummaryEndpoint, isTrue);
  });

  test('fallback makes 13 series calls in sequence and returns 13 summaries sorted by name', () async {
    final repo = CaseRepositoryImpl(src, useSummaryEndpoint: false);
    final events = await repo.watchRegencySummaries().toList();
    // Rows arrive one by one: 1, 2, ... 12 partial results, then all 13.
    expect(
      [for (final e in events) e.right.data.length],
      [for (var i = 1; i <= 13; i++) i],
    );
    expect(events.take(12).every((e) => e.right.isStale), isTrue);
    final s = events.last.right;
    expect(s.isStale, isFalse);
    expect(s.data.length, 13);
    final names = s.data.map((e) => e.name).toList();
    expect(
      names,
      [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );
    expect(names.first, 'Banggai');
    expect(s.data.first.latest.date, DateTime(2024, 1, 14));
    expect(s.data.first.area, const AreaRef.regency('7202'));
    expect(s.source, DataSource.network);
    final seriesCalls = adapter.calls
        .where((p) => p.endsWith('/cases'))
        .toList();
    expect(seriesCalls, [for (final c in regs.keys) '/regencies/$c/cases']);
    expect(adapter.calls.first, '/regencies');
  });

  test(
    'each series also fills the cache for the kabupaten detail page',
    () async {
      await CaseRepositoryImpl(
        src,
        useSummaryEndpoint: false,
      ).watchRegencySummaries().toList();
      adapter.calls.clear();
      final detail = await CaseRepositoryImpl(
        src,
        useSummaryEndpoint: false,
      ).watchSeries(const AreaRef.regency('7271')).toList();
      expect(detail.single.right.source, DataSource.cache);
      expect(adapter.calls, isEmpty);
    },
  );

  test(
    'second open: cached summaries come first, no calls while fresh',
    () async {
      await CaseRepositoryImpl(
        src,
        useSummaryEndpoint: false,
      ).watchRegencySummaries().toList();
      adapter.calls.clear();
      final events = await CaseRepositoryImpl(
        src,
        useSummaryEndpoint: false,
      ).watchRegencySummaries().toList();
      expect(events.length, 1);
      expect(events.single.right.source, DataSource.cache);
      expect(adapter.calls, isEmpty);
    },
  );

  test(
    'one series failing keeps the others and marks the result stale',
    () async {
      adapter.routes['/regencies/7204/cases'] = const FakeReply(500, 'x');
      final events = await CaseRepositoryImpl(
        src,
        useSummaryEndpoint: false,
      ).watchRegencySummaries().toList();
      final s = events.last.right;
      expect(s.data.length, 12);
      expect(s.isStale, isTrue);
      expect(
        s.data.any((r) => r.area == const AreaRef.regency('7204')),
        isFalse,
      );
    },
  );

  test('regency list failing with no copy is one Left', () async {
    adapter.routes['/regencies'] = const FakeReply(500, 'x');
    final events = await CaseRepositoryImpl(
      src,
      useSummaryEndpoint: false,
    ).watchRegencySummaries().toList();
    expect(events.single.left.kind, PicoFailureKind.server);
  });

  test(
    'the directory repository lists the 13 regencies with one light request',
    () async {
      final events = await DirectoryRepositoryImpl(src)
          .watchRegencies()
          .toList();
      expect(events.single.right.data.length, 13);
      expect(
        events.single.right.data.first,
        const Regency(code: '7201', name: 'Banggai Kepulauan'),
      );
      expect(adapter.calls, ['/regencies']);
    },
  );

  group('one call: GET /regencies?include_latest_case=true&load_all=true', () {
    const summaryPath = '/regencies';
    FakeReply live() => FakeReply(
      200,
      fixture('regencies_include_latest_case.json'),
      etag: 'W/"abc"',
    );

    test('maps the live flat latest_case rows: 13 rows by name, null Rt stays null', () async {
      adapter.routes['$summaryPath#latest'] = live();
      final events = await CaseRepositoryImpl(src)
          .watchRegencySummaries()
          .toList();
      expect(adapter.calls, [summaryPath], reason: 'one request, no series');
      final s = events.single.right;
      expect(s.data, hasLength(13));
      final names = s.data.map((e) => e.name).toList();
      expect(
        names,
        [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      );
      final banggai = s.data.firstWhere((e) => e.name == 'Banggai');
      expect(banggai.area, const AreaRef.regency('7202'));
      expect(banggai.latest.date, DateTime(2024, 1, 14));
      expect(banggai.latest.cumulative.positive, 8335);
      expect(banggai.latest.daily.active, 0 - 22 - 0);
      expect(banggai.latest.rt, isNull, reason: 'null Rt is never 0');
    });

    test('a row without latest_case is skipped, not zero', () {
      final r = regencySummariesFromLatest([
        {'id': 7201, 'name': 'A', 'latest_case': null},
      ]);
      expect(r, isEmpty);
    });

    test(
      'the single call fails with nothing saved: the 13-series loop runs',
      () async {
        adapter.routes['$summaryPath#latest'] = const FakeReply(
          500,
          '{"status":"error"}',
        );
        final events = await CaseRepositoryImpl(src)
            .watchRegencySummaries()
            .toList();
        expect(events.last.right.data, hasLength(13));
        expect(adapter.calls.first, summaryPath);
        expect(adapter.calls.where((p) => p.endsWith('/cases')), hasLength(13));
      },
    );

    test('the call is rate limited: no 13-request storm', () async {
      adapter.routes['$summaryPath#latest'] = const FakeReply(
        429,
        '{"status":"error"}',
      );
      final events = await CaseRepositoryImpl(src)
          .watchRegencySummaries()
          .toList();
      expect(events.single.isLeft, isTrue);
      expect(adapter.calls.where((p) => p.endsWith('/cases')), isEmpty);
    });

    test('a saved copy inside the archive TTL: 0 requests', () async {
      adapter.routes['$summaryPath#latest'] = live();
      final repo = CaseRepositoryImpl(src);
      await repo.watchRegencySummaries().toList();
      adapter.calls.clear();
      clock = clock.add(const Duration(days: 1));
      final events = await repo.watchRegencySummaries().toList();
      expect(events.single.right.source, DataSource.cache);
      expect(adapter.calls, isEmpty);
    });
  });

  test('the include_latest_case mapper reads the flat shape of API 2.11.0', () {
    final rows =
        (jsonDecode(fixture('regencies_include_latest_case.json'))
                as Map<String, dynamic>)['data']
            as List<dynamic>;
    final summaries = regencySummariesFromLatest(rows);
    expect(summaries, hasLength(13));
    expect(
      PicoEndpoints.regencySummaries.key,
      '/regencies?include_latest_case=true&load_all=true',
    );
  });
}
