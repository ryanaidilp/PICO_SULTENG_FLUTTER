import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:peta/src/domain/geo_normalize.dart';
import 'package:peta/src/domain/map_values.dart';
import 'package:peta/src/domain/regions.dart';

String asset() => File('assets/geojson/sulteng.json').readAsStringSync();

/// The 13 names as the API spells them (C02), including both spellings.
const apiNames = {
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

void main() {
  group('normalised asset', () {
    test('is at most 60 KB and has all 13 codes, each with a label point', () {
      expect(
        File('assets/geojson/sulteng.json').lengthSync(),
        lessThanOrEqualTo(60 * 1024),
      );
      final regions = parseRegions(asset());
      expect(regions.map((r) => r.code).toList(), kRegencyCodes);
      for (final r in regions) {
        expect(r.polygons, isNotEmpty);
        expect(r.labelPoint, hasLength(2));
      }
    });

    test('every API regency name maps to exactly one polygon', () {
      final byCode = {for (final r in parseRegions(asset())) r.code: r};
      for (final e in apiNames.entries) {
        expect(kRegencyCodeByName[e.value], e.key, reason: e.value);
        expect(byCode[e.key], isNotNull, reason: e.value);
      }
      expect(byCode, hasLength(13));
    });

    test('Kota Palu stays visible: its outline keeps 20 or more points', () {
      final palu = parseRegions(asset()).firstWhere((r) => r.code == '7271');
      expect(palu.polygons.first.first.length, greaterThanOrEqualTo(20));
    });

    test('the label point of each region lies inside one of its rings', () {
      for (final r in parseRegions(asset())) {
        final inside = r.polygons.any(
          (poly) => ringContains(poly.first, r.labelPoint[0], r.labelPoint[1]),
        );
        expect(inside, isTrue, reason: r.name);
      }
    });
  });

  group('normalizeSulteng', () {
    test('rebuilds the asset from the old file when it is at hand', () {
      final old = File('/tmp/sulteng_old.json');
      if (!old.existsSync()) return;
      final r = normalizeSulteng(old.readAsStringSync());
      expect(r.bytes, lessThanOrEqualTo(60 * 1024));
      expect(r.json, asset());
    });

    test('rejects an unknown region and a missing region', () {
      final bad = jsonEncode({
        'features': [
          {
            'properties': {'name': 'Atlantis'},
            'geometry': {'type': 'Polygon', 'coordinates': <dynamic>[]},
          },
        ],
      });
      expect(() => normalizeSulteng(bad), throwsFormatException);
    });

    test('Douglas-Peucker keeps the ends and drops collinear points', () {
      final ring = <LonLat>[
        [0, 0],
        [1, 0.0001],
        [2, 0],
        [3, 0],
        [3, 3],
        [0, 3],
        [0, 0],
      ];
      final s = simplifyRing(ring, 0.01);
      expect(s.first, ring.first);
      expect(s.last, ring.last);
      expect(s.length, lessThan(ring.length));
    });
  });

  group('hit test', () {
    const size = Size(400, 400);
    test('a tap at the label point of each region selects that region', () {
      final regions = parseRegions(asset());
      final pr = MapProjection(regions);
      for (final r in regions) {
        final at = pr.project(r.labelPoint[0], r.labelPoint[1], size);
        final hits = [
          for (final x in regions)
            if (regionContains(x, pr, size, at)) x.code,
        ];
        expect(hits, contains(r.code), reason: r.name);
      }
    });
  });

  group('mark steps', () {
    MapValue v(String code, num? value) => MapValue(
      code: code,
      name: code,
      value: value,
      date: DateTime(2024, 1, 14),
    );

    test('6 equal-count bins over 13 values; equal values share a step', () {
      final values = [for (var i = 0; i < 13; i++) v('c$i', i * 100)];
      final steps = markSteps(values);
      final counts = List.filled(6, 0);
      for (final s in steps.values) {
        counts[s]++;
      }
      expect(counts.reduce((a, b) => a + b), 13);
      expect(counts.every((c) => c >= 2 && c <= 3), isTrue, reason: '$counts');
      expect(steps['c0'], 0);
      expect(steps['c12'], 5);
      final ties = markSteps([v('a', 5), v('b', 5), v('c', 5)]);
      expect(ties.values.toSet(), hasLength(1));
    });

    test('a null value has no step and no range; order puts it last', () {
      final values = [v('a', 3), v('b', null), v('c', 9)];
      final steps = markSteps(values);
      expect(steps.containsKey('b'), isFalse);
      expect(listOrder(values).map((e) => e.code), ['c', 'a', 'b']);
      final ranges = stepRanges(values, steps);
      expect(ranges.whereType<Object>().length, 2);
    });
  });
}
