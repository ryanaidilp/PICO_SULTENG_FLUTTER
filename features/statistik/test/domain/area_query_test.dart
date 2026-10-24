import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/area_view.dart';

import '../support.dart';

AreaQuery parse(String url) {
  final u = Uri.parse(url);
  return AreaQuery.fromParams(u.queryParameters);
}

void main() {
  group('URL round trip', () {
    const urls = [
      '/statistik',
      '/statistik?level=national',
      '/statistik?level=province&id=71',
      '/statistik?metric=active&from=2021-07-15&to=2021-07-16&daily=false',
      '/statistik?level=national&metric=active&from=2021-07-15&to=2021-07-16&daily=false',
      '/statistik?level=regency&id=7271&metric=deceased',
      '/statistik?metric=recovered&from=2023-01-01',
      '/statistik?daily=false',
    ];
    for (final u in urls) {
      test('print(parse($u)) is the same URL', () {
        expect(parse(u).path, u);
      });
    }

    test('parse(print(q)) is the same query', () {
      final q = AreaQuery(
        area: const AreaRef.province('72'),
        metric: CaseMetric.active,
        daily: false,
        from: DateTime(2021, 7, 15),
        to: DateTime(2021, 7, 16),
      );
      expect(parse(q.path), q);
    });

    test('defaults are never printed: Sulawesi Tengah leads, Indonesia is explicit', () {
      expect(const AreaQuery().path, '/statistik');
      expect(const AreaQuery().area, const AreaRef.province('72'));
      expect(nationalQuery.path, '/statistik?level=national');
    });

    test('invalid values fall back to defaults and never throw', () {
      final q = parse(
        '/statistik?level=galaxy&id=zz&metric=pizza&from=2021-02-31&to=hari&daily=maybe',
      );
      expect(q, const AreaQuery());
      expect(
        parse('/statistik?level=province').area,
        const AreaRef.province('72'),
      );
      expect(
        parse('/statistik?level=regency&id=72').area,
        const AreaRef.province('72'),
      );
    });
  });

  group('buildAreaView', () {
    final series = sultengSeries();

    test('range 2021-07-15 to 2021-07-15: the positif daily is 308', () {
      final v = buildAreaView(
        series,
        AreaQuery(from: DateTime(2021, 7, 15), to: DateTime(2021, 7, 15)),
      )!;
      expect(v.days.length, 1);
      expect(v.last.daily.positive, 308);
      expect(v.totals.positive, 308);
      expect(v.peak.date, DateTime(2021, 7, 15));
    });

    test(
      'a range before the first day or after the last is clamped, never empty',
      () {
        final before = buildAreaView(
          series,
          AreaQuery(from: DateTime(2019), to: DateTime(2019, 6)),
        )!;
        expect(before.days, isNotEmpty);
        expect(before.range.start, DateTime(2020, 3, 2));
        final after = buildAreaView(
          series,
          AreaQuery(from: DateTime(2030), to: DateTime(2031)),
        )!;
        expect(after.days, isNotEmpty);
        expect(after.range.end, DateTime(2024, 1, 14));
      },
    );

    test('a reversed range is swapped', () {
      final v = buildAreaView(
        series,
        AreaQuery(from: DateTime(2021, 7, 20), to: DateTime(2021, 7, 10)),
      )!;
      expect(v.range.start, DateTime(2021, 7, 10));
      expect(v.range.end, DateTime(2021, 7, 20));
    });

    test('the open range follows the whole data', () {
      final v = buildAreaView(series, nationalQuery)!;
      expect(v.range.start, DateTime(2020, 3, 2));
      expect(v.range.end, DateTime(2024, 1, 14));
      expect(v.days.length, 1414);
    });

    test('an empty series has no view', () {
      expect(
        buildAreaView(
          CaseSeries.fromDays(
            area: const AreaRef.national(),
            areaName: 'x',
            days: const [],
          ),
          nationalQuery,
        ),
        isNull,
      );
    });
  });
}
