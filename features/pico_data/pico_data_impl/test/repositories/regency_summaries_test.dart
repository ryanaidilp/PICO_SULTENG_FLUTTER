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

  test('the flag stays off until PR #91 is deployed', () {
    expect(kRegencySummaryEndpoint, isFalse);
  });

  test('fallback makes 13 series calls in sequence and returns 13 summaries sorted by name', () async {
    final repo = CaseRepositoryImpl(src);
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
      await CaseRepositoryImpl(src).watchRegencySummaries().toList();
      adapter.calls.clear();
      final detail = await CaseRepositoryImpl(src)
          .watchSeries(const AreaRef.regency('7271'))
          .toList();
      expect(detail.single.right.source, DataSource.cache);
      expect(adapter.calls, isEmpty);
    },
  );

  test(
    'second open: cached summaries come first, no calls while fresh',
    () async {
      await CaseRepositoryImpl(src).watchRegencySummaries().toList();
      adapter.calls.clear();
      final events = await CaseRepositoryImpl(src)
          .watchRegencySummaries()
          .toList();
      expect(events.length, 1);
      expect(events.single.right.source, DataSource.cache);
      expect(adapter.calls, isEmpty);
    },
  );

  test(
    'one series failing keeps the others and marks the result stale',
    () async {
      adapter.routes['/regencies/7204/cases'] = const FakeReply(500, 'x');
      final events = await CaseRepositoryImpl(src)
          .watchRegencySummaries()
          .toList();
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
    final events = await CaseRepositoryImpl(src)
        .watchRegencySummaries()
        .toList();
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

  test('the include_latest_case mapper is ready for the deploy', () {
    final rows =
        jsonDecode(fixture('provinces_per_page_2.json'))['data']
            as List<dynamic>;
    final summaries = regencySummariesFromLatest([
      {
        'id': 7271,
        'name': 'Kota Palu',
        'latest_case': (rows.first as Map)['latest_case'],
      },
    ]);
    expect(summaries.single.area, const AreaRef.regency('7271'));
    expect(
      PicoEndpoints.regencySummaries.key,
      '/regencies?include_latest_case=true&load_all=true',
    );
  });
}
