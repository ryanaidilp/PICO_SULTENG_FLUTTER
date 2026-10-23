import 'dart:convert';

import 'package:dependencies/network.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

import 'fake_adapter.dart';

PicoApiClient client(FakeAdapter a) => PicoApiClient.create(
  baseUrl: 'https://pico.test/api/v1',
  userAgent: 'PICO-Sulteng/test (test)',
  adapter: a,
  retryDelay: Duration.zero,
);

void main() {
  group('case fixtures', () {
    test(
      'national latest: 2024-01-14, cumulative positive 6,812,127, Rt null',
      () async {
        final api = CaseApi(
          client(FakeAdapter([fixtureReply('national_latest.json')])),
        );
        final day = (await api.nationalLatest()).right;
        expect(day.date, DateTime(2024, 1, 14));
        expect(day.cumulative.positive, 6812127);
        expect(day.cumulative.active, 8245);
        expect(day.rt, isNull);
        expect(day.monitoring, isNull);
      },
    );

    test('national all: keyed by date, ascending', () async {
      final api = CaseApi(
        client(FakeAdapter([fixtureReply('national_all_true_sample.json')])),
      );
      final s = (await api.nationalSeries()).right;
      expect(s.area, const AreaRef.national());
      expect(s.latest!.date, DateTime(2024, 1, 14));
      expect(s.days.map((d) => d.date).toSet().length, s.days.length);
    });

    test('Sulteng 2021-07-15: 308 daily, Rt 2.088 (2.194, 1.985), time part dropped', () async {
      final a = FakeAdapter([
        fixtureReply(
          'provinces_72_cases_start_date_2021-07-15_end_date_2021-07-16.json',
        ),
      ]);
      final s = (await CaseApi(client(a)).provinceSeries('72')).right;
      final d = s.on(DateTime(2021, 7, 15))!;
      expect(d.daily.positive, 308);
      expect(d.rt, const Rt(value: 2.088, lower: 1.985, upper: 2.194));
      expect(s.areaName, 'Sulawesi Tengah');
      expect(d.monitoring!.odpActive, 124);
    });

    test('province list that arrives descending is ascending with no duplicate date', () async {
      final a = FakeAdapter([
        fixtureReply('provinces_72_cases_all_true_sample.json'),
      ]);
      final s = (await CaseApi(client(a)).provinceSeries('72')).right;
      expect(s.days.length, 2);
      expect(s.days.first.date.isBefore(s.days.last.date), isTrue);
    });

    test('provinces: summaries for the 34 with latest day', () async {
      final a = FakeAdapter([fixtureReply('provinces_per_page_2.json')]);
      final list = (await CaseApi(client(a)).provinces()).right;
      expect(list.length, 34);
      expect(list.first.area, const AreaRef.province('11'));
      expect(list.first.name, 'Aceh');
      expect(list.first.latest.date, DateTime(2024, 1, 14));
    });

    test(
      'Kota Palu: active is derived, daily active is the day difference',
      () async {
        final a = FakeAdapter([
          fixtureReply('regencies_7271_cases_sample.json'),
        ]);
        final s = (await CaseApi(client(a)).regencySeries('7271')).right;
        expect(s.areaName, 'Kota Palu');
        for (final d in s.days) {
          expect(
            d.cumulative.active,
            d.cumulative.positive -
                d.cumulative.recovered -
                d.cumulative.deceased,
          );
        }
        expect(
          s.days.last.daily.active,
          s.days.last.cumulative.active - s.days.first.cumulative.active,
        );
        expect(s.days.first.rt!.value, 1.858);
      },
    );

    test('regency list gives code and name', () async {
      final a = FakeAdapter([fixtureReply('regencies_per_page_2.json')]);
      final list = (await CaseApi(client(a)).regencies()).right;
      expect(list.first.code, isNotEmpty);
      expect(list.first.name, isNotEmpty);
    });
  });

  group('requests', () {
    test('send only all=true and plain paths: no sort, no datetimes', () async {
      final a = FakeAdapter([fixtureReply('national_all_true_sample.json')]);
      await CaseApi(client(a)).nationalSeries();
      final r = a.requests.single;
      expect(r.queryParameters, {'all': true});
      expect(r.uri.toString(), isNot(contains('sort')));
      expect(r.headers['User-Agent'], 'PICO-Sulteng/test (test)');
      expect(r.connectTimeout, const Duration(seconds: 10));
      expect(r.receiveTimeout, const Duration(seconds: 30));
    });

    test('date helpers are plain YYYY-MM-DD', () {
      expect(parseApiDate('2021-07-15T16:53:00+07:00'), DateTime(2021, 7, 15));
      expect(formatApiDate(DateTime(2021, 7, 5, 23, 59)), '2021-07-05');
      expect(cleanString('NULL'), isNull);
      expect(cleanString('  '), isNull);
      expect(cleanString(' a '), 'a');
    });
  });

  group('failures', () {
    Future<Either<PicoFailure, Object?>> get(
      List<Object> replies, {
      FakeAdapter? out,
    }) {
      final a = out ?? FakeAdapter(replies);
      return client(a).getData('/x');
    }

    test('404 is notFound', () async {
      expect(
        (await get([const FakeReply(404, '{"status":"error","error":"x"}')]))
            .left
            .kind,
        PicoFailureKind.notFound,
      );
    });

    test('400 is badRequest', () async {
      expect(
        (await get([const FakeReply(400, '{}')])).left.kind,
        PicoFailureKind.badRequest,
      );
    });

    test('429 then 200 retries once and succeeds', () async {
      final a = FakeAdapter([
        const FakeReply(429, '{}'),
        FakeReply.ok({
          'status': 'success',
          'data': [1],
        }),
      ]);
      expect((await get([], out: a)).right, [1]);
      expect(a.requests.length, 2);
    });

    test('429 twice is rateLimited after one retry', () async {
      final a = FakeAdapter([const FakeReply(429, '{}')]);
      expect((await get([], out: a)).left.kind, PicoFailureKind.rateLimited);
      expect(a.requests.length, 2);
    });

    test('500 is server', () async {
      expect(
        (await get([const FakeReply(500, 'boom')])).left.kind,
        PicoFailureKind.server,
      );
    });

    test('timeout is network', () async {
      final e = DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: RequestOptions(),
      );
      expect((await get([e])).left.kind, PicoFailureKind.network);
    });

    test('a non-JSON body is server', () async {
      expect(
        (await get([const FakeReply(200, '<html>')])).left.kind,
        PicoFailureKind.server,
      );
    });

    test('status error in a 200 body is server', () async {
      expect(
        (await get([const FakeReply(200, '{"status":"error","error":"bad"}')]))
            .left
            .kind,
        PicoFailureKind.server,
      );
    });

    test('malformed rows become a server failure, not an exception', () async {
      final a = FakeAdapter([
        FakeReply.ok({
          'status': 'success',
          'data': [
            {'date': 'x'},
          ],
        }),
      ]);
      expect(
        (await CaseApi(client(a)).nationalSeries()).left.kind,
        PicoFailureKind.server,
      );
    });
  });

  test(
    'a body over 100 KB is decoded in an isolate and still parses',
    () async {
      final big = {
        'status': 'success',
        'data': List.generate(4000, (i) => {'i': i, 'pad': 'x' * 40}),
      };
      expect(jsonEncode(big).length, greaterThan(kIsolateDecodeThreshold));
      final r = await client(FakeAdapter([FakeReply.ok(big)])).getData('/big');
      expect((r.right! as List).length, 4000);
    },
  );
}
