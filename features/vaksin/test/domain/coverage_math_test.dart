import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:vaksin/src/domain/coverage_math.dart';

import '../support.dart';

void main() {
  test('coverage above 100 percent is flagged, 100 itself is not', () {
    expect(exceedsTarget(100.36), isTrue);
    expect(exceedsTarget(100), isFalse);
    expect(exceedsTarget(93.43), isFalse);
  });

  test('a group with target 0 has no target', () {
    final day = sultengDay(DateTime(2021, 5, 4));
    expect(hasTarget(day.groups.values.last), isFalse);
    expect(hasTarget(day.groups.values.first), isTrue);
  });

  test('locations group by regency in list order, unknown codes last, empty groups dropped', () {
    final g = groupLocations([
      mapolda,
      withQuota,
      const VaccineLocation(
        name: 'X',
        address: '',
        regencyCode: '9999',
        firstDose: false,
        secondDose: false,
      ),
    ], regencies);
    expect(g.map((e) => e.name), ['Banggai', 'Kota Palu', '9999']);
    expect(g[1].items.single.name, 'Gerai Vaksinasi Presisi Mapolda');
  });
}
