import 'package:test/test.dart';
import 'package:identifiers/identifiers.dart';

void main() {
  test('builders produce the C07 paths', () {
    expect(PicoRoutes.beranda, '/beranda');
    expect(PicoRoutes.statistik(), '/statistik');
    expect(
      PicoRoutes.statistik(
        level: 'province',
        id: '72',
        metric: 'positive',
        from: DateTime(2021, 7, 5),
        to: DateTime(2021, 7, 16),
        daily: true,
      ),
      '/statistik?level=province&id=72&metric=positive&from=2021-07-05&to=2021-07-16&daily=true',
    );
    expect(PicoRoutes.provinsi('72'), '/statistik/provinsi/72');
    expect(PicoRoutes.kabupatenDetail(7271), '/statistik/kabupaten/7271');
    expect(
      PicoRoutes.rt(area: 'province:72'),
      '/statistik/rt?area=province:72',
    );
    expect(
      PicoRoutes.peta(metric: 'active', date: DateTime(2024, 1, 14)),
      '/peta?metric=active&date=2024-01-14',
    );
    expect(
      PicoRoutes.rumahSakitDetail('7271025'),
      '/layanan/rumah-sakit/7271025',
    );
    expect(
      PicoRoutes.infografisDetail(146, page: 1),
      '/info/infografis/146?page=1',
    );
    expect(PicoRoutes.tips('cuci-tangan'), '/info/tips/cuci-tangan');
  });

  test('dates in paths are plain YYYY-MM-DD, never datetimes', () {
    expect(PicoRoutes.formatDate(DateTime(2021, 7, 5, 23, 59)), '2021-07-05');
  });

  test('patterns are unique lowercase slugs', () {
    expect(PicoRoutes.patterns.toSet().length, PicoRoutes.patterns.length);
    for (final p in PicoRoutes.patterns) {
      expect(p, matches(RegExp(r'^/[a-z0-9\-/:]+$')), reason: p);
    }
  });
}
