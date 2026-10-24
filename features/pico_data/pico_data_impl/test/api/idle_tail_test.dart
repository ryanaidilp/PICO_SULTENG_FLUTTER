import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';

Map<String, dynamic> row(
  String date, {
  int pos = 0,
  int rec = 0,
  int dec = 0,
  required int cumPos,
  num? rt,
  num? lower,
  num? upper,
}) => {
  'date': '${date}T16:00:00.000000Z',
  'positive': pos,
  'recovered': rec,
  'deceased': dec,
  'cumulative_positive': cumPos,
  'cumulative_recovered': 0,
  'cumulative_deceased': 0,
  'rt': rt,
  'rt_lower': lower,
  'rt_upper': upper,
  'regency': {'id': 7271, 'name': 'Kota Palu'},
};

void main() {
  final rows = [
    row('2023-12-15', pos: 4, cumPos: 100),
    row('2023-12-16', pos: 2, cumPos: 102),
    row('2023-12-17', cumPos: 102),
    row('2024-01-14', cumPos: 102),
  ];

  test(
    'a regency series ends on the last day with activity, not on the zero rows',
    () {
      final s = seriesFromRegency(rows, code: '7271');
      expect(s.latest!.date, DateTime(2023, 12, 16));
      expect(s.on(DateTime(2024, 1, 14)), isNull, reason: 'no data, not 0');
      expect(s.latest!.cumulative.positive, 102);
    },
  );

  test('a national series is trimmed the same way, so a 7 day window holds real days', () {
    Map<String, dynamic> nested(String date, int daily, int cum) => {
      'date': '${date}T16:00:00.000000Z',
      'daily': {'positive': daily, 'recovered': 0, 'deceased': 0, 'active': 0},
      'cumulative': {
        'positive': cum,
        'recovered': 0,
        'deceased': 0,
        'active': 0,
      },
    };
    final s = seriesFromNested(
      [
        nested('2024-01-14', 0, 9),
        nested('2024-01-13', 0, 9),
        nested('2024-01-12', 4, 9),
        nested('2024-01-11', 5, 5),
      ],
      area: const AreaRef.national(),
      fallbackName: 'Indonesia',
    );
    expect(s.latest!.date, DateTime(2024, 1, 12));
    expect(s.days, hasLength(2));
  });

  test('a series with no active day at all is left as it is', () {
    final s = seriesFromRegency([row('2024-01-14', cumPos: 0)], code: '7271');
    expect(s.days, hasLength(1));
  });

  test('a missing Rt bound stays null, no zero-width band', () {
    final s = seriesFromRegency([
      row('2023-12-16', pos: 2, cumPos: 2, rt: 1.2),
    ], code: '7271');
    final rt = s.latest!.rt!;
    expect(rt.value, 1.2);
    expect(rt.lower, isNull);
    expect(rt.upper, isNull);
  });
}
