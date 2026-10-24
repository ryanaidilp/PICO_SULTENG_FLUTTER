import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/domain/hospital_math.dart';
import 'package:pico_data_api/pico_data_api.dart';

import '../support.dart';

void main() {
  test('foldText drops accents and case', () {
    expect(foldText('Pétra ÀÉÎ'), 'petra aei');
  });

  test('search is accent and case insensitive on name or kabupaten', () {
    expect(matchesHospital(sindhu, 'Kota Palu', 'sindhu'), isTrue);
    expect(matchesHospital(sindhu, 'Kota Palu', 'SINDHU trisno'), isTrue);
    expect(matchesHospital(sindhu, 'Kota Palu', 'kota palu'), isTrue);
    expect(matchesHospital(accented, 'Banggai', 'petra'), isTrue);
    expect(matchesHospital(accented, 'Banggai', 'pétra'), isTrue);
    expect(matchesHospital(sindhu, 'Kota Palu', 'tolitoli'), isFalse);
    expect(matchesHospital(sindhu, 'Kota Palu', '  '), isTrue);
  });

  test('groups follow the regency order and drop empty groups', () {
    final g = groupHospitals(all, regencies);
    expect(
      [for (final x in g) x.name],
      ['Banggai Kepulauan', 'Tolitoli', 'Kota Palu'],
    );
    expect(groupHospitals(all, regencies, query: 'sindhu').single.items, [
      sindhu,
    ]);
    expect(groupHospitals(all, regencies, query: 'zzz'), isEmpty);
  });

  test('an unknown regency code is a last group named by its code', () {
    final g = groupHospitals(all, const [Regency(code: '7271', name: 'Palu')]);
    expect(g.last.name, anyOf('7201', '7208'));
    expect(g.first.name, 'Palu');
  });

  test('bed totals sum, and no beds is zero', () {
    expect(bedTotals(sindhu), (available: 21, total: 28));
    expect(bedTotals(noCoords), (available: 0, total: 0));
  });

  test('map link: geo on Android, Apple Maps on iOS, null without coords', () {
    expect(
      mapUri(sindhu, platform: TargetPlatform.android).toString(),
      startsWith('geo:-0.8959781,119.8874783?q='),
    );
    expect(
      mapUri(sindhu, platform: TargetPlatform.iOS)!.host,
      'maps.apple.com',
    );
    expect(mapUri(noCoords, platform: TargetPlatform.android), isNull);
    expect(mapUri(sindhu, platform: TargetPlatform.windows), isNull);
  });

  test('a (0, 0) or out of range point is not valid', () {
    expect(hasValidLocation(const LatLng(0, 0)), isFalse);
    expect(hasValidLocation(const LatLng(91, 10)), isFalse);
    expect(hasValidLocation(const LatLng(-0.9, 119.8)), isTrue);
    expect(hasValidLocation(null), isFalse);
  });
}
