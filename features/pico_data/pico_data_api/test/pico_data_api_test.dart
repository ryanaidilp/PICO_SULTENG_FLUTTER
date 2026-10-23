import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:test/test.dart';

CaseDay day(String iso, {int positive = 1, Rt? rt, Monitoring? monitoring}) =>
    CaseDay(
      date: DateTime.parse(iso),
      daily: CaseCounts(
        positive: positive,
        recovered: 0,
        deceased: 0,
        active: positive,
      ),
      cumulative: CaseCounts(
        positive: positive,
        recovered: 0,
        deceased: 0,
        active: positive,
      ),
      rt: rt,
      monitoring: monitoring,
    );

void main() {
  group('CaseSeries is keyed by date', () {
    test('sorts a descending list ascending with no duplicate date', () {
      final s = CaseSeries.fromDays(
        area: const AreaRef.province('72'),
        areaName: 'Sulawesi Tengah',
        days: [
          day('2021-07-16', positive: 5),
          day('2021-07-15T16:53:00', positive: 3),
          day('2021-07-15', positive: 308),
        ],
      );
      expect(s.days.map((d) => d.date), [
        DateTime(2021, 7, 15),
        DateTime(2021, 7, 16),
      ]);
      expect(s.on(DateTime(2021, 7, 15))!.daily.positive, 308);
      expect(s.latest!.date, DateTime(2021, 7, 16));
    });

    test('a date with a time part is reduced to the calendar date', () {
      final d = CaseDay(
        date: DateTime(2021, 7, 15, 16, 53),
        daily: CaseCounts.zero,
        cumulative: CaseCounts.zero,
      );
      expect(d.date, DateTime(2021, 7, 15));
    });

    test('inRange is inclusive and peak finds the highest day', () {
      final s = CaseSeries.fromDays(
        area: const AreaRef.national(),
        areaName: 'Indonesia',
        days: [
          day('2021-01-01', positive: 2),
          day('2021-01-02', positive: 9),
          day('2021-01-03', positive: 4),
        ],
      );
      final r = DateRange(DateTime(2021, 1, 2), DateTime(2021, 1, 3));
      expect(s.inRange(r).length, 2);
      expect(s.peak(CaseMetric.positive)!.date, DateTime(2021, 1, 2));
    });
  });

  test('Rt and monitoring stay null when absent, never 0', () {
    final d = day('2021-01-01');
    expect(d.rt, isNull);
    expect(d.monitoring, isNull);
    expect(const Monitoring(odpActive: 0).hasData, isFalse);
    expect(const Monitoring(odpActive: 4).hasData, isTrue);
  });

  test('AreaRef compares by value', () {
    expect(const AreaRef.province('72'), const AreaRef.province('72'));
    expect(const AreaRef.regency('7271'), isNot(const AreaRef.province('72')));
  });

  test('fakes follow the port signatures and serve data', () async {
    final fake = FakeCaseRepository(
      series: {
        const AreaRef.national(): CaseSeries.fromDays(
          area: const AreaRef.national(),
          areaName: 'Indonesia',
          days: [day('2024-01-14')],
        ),
      },
    );
    final ok = await fake.watchSeries(const AreaRef.national()).first;
    expect(ok.isRight, isTrue);
    final missing = await fake.watchSeries(const AreaRef.regency('1')).first;
    expect(missing.leftOrNull!.kind, PicoFailureKind.notFound);
    await fake.watchNationalLatest(forceRefresh: true).first;
    expect(fake.forcedRefreshes, 1);

    final settings = FakeSettingsRepository();
    final changes = settings.themeModeChanges.first;
    await settings.setThemeMode(PicoThemeMode.dark);
    expect(await changes, PicoThemeMode.dark);
  });
}
