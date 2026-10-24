import 'dart:convert';
import 'dart:math' as math;

/// Codes of the 13 kabupaten and kota by the names the old GeoJSON and the
/// API use (C02). Both spellings of Parigi Moutong map to 7208.
const Map<String, String> kRegencyCodeByName = {
  'Banggai Kepulauan': '7201',
  'Banggai': '7202',
  'Morowali': '7203',
  'Poso': '7204',
  'Donggala': '7205',
  'Toli-Toli': '7206',
  'Tolitoli': '7206',
  'Buol': '7207',
  'Parigi Mautong': '7208',
  'Parigi Moutong': '7208',
  'Tojo Una-Una': '7209',
  'Sigi': '7210',
  'Banggai Laut': '7211',
  'Morowali Utara': '7212',
  'Kota Palu': '7271',
};

/// The 13 codes.
const List<String> kRegencyCodes = [
  '7201',
  '7202',
  '7203',
  '7204',
  '7205',
  '7206',
  '7207',
  '7208',
  '7209',
  '7210',
  '7211',
  '7212',
  '7271',
];

/// A point as `[lon, lat]`.
typedef LonLat = List<double>;

/// Douglas-Peucker on an open or closed ring. Keeps the first and last point.
List<LonLat> simplifyRing(List<LonLat> pts, double tolerance) {
  if (pts.length <= 4) return pts;
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = keep[pts.length - 1] = true;
  final stack = <(int, int)>[(0, pts.length - 1)];
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    var maxD = 0.0;
    var idx = -1;
    for (var i = a + 1; i < b; i++) {
      final d = _perp(pts[i], pts[a], pts[b]);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx >= 0 && maxD > tolerance) {
      keep[idx] = true;
      stack
        ..add((a, idx))
        ..add((idx, b));
    }
  }
  final out = [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
  // A ring needs at least a triangle plus the closing point.
  return out.length < 4 ? pts.sublist(0, 4) : out;
}

double _perp(LonLat p, LonLat a, LonLat b) {
  final dx = b[0] - a[0];
  final dy = b[1] - a[1];
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) {
    return math.sqrt(math.pow(p[0] - a[0], 2) + math.pow(p[1] - a[1], 2));
  }
  final t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / len2;
  final tt = t.clamp(0.0, 1.0);
  final cx = a[0] + tt * dx;
  final cy = a[1] + tt * dy;
  return math.sqrt(math.pow(p[0] - cx, 2) + math.pow(p[1] - cy, 2));
}

double _round(double v, int digits) {
  final f = math.pow(10, digits);
  return (v * f).round() / f;
}

double _area(List<LonLat> r) {
  var a = 0.0;
  for (var i = 0; i < r.length - 1; i++) {
    a += r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
  }
  return a / 2;
}

/// Point-in-ring (ray casting), [lon], [lat].
bool ringContains(List<LonLat> r, double lon, double lat) {
  var inside = false;
  for (var i = 0, j = r.length - 1; i < r.length; j = i++) {
    final xi = r[i][0];
    final yi = r[i][1];
    final xj = r[j][0];
    final yj = r[j][1];
    if ((yi > lat) != (yj > lat) &&
        lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// A point inside the largest ring: the centroid when it is inside, else the
/// inside point of a coarse grid farthest from the edges.
LonLat labelPointOf(List<LonLat> ring) {
  final a = _area(ring);
  var cx = 0.0;
  var cy = 0.0;
  for (var i = 0; i < ring.length - 1; i++) {
    final f = ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1];
    cx += (ring[i][0] + ring[i + 1][0]) * f;
    cy += (ring[i][1] + ring[i + 1][1]) * f;
  }
  if (a != 0) {
    cx /= 6 * a;
    cy /= 6 * a;
    if (ringContains(ring, cx, cy)) return [_round(cx, 4), _round(cy, 4)];
  }
  var minX = double.infinity;
  var maxX = -double.infinity;
  var minY = double.infinity;
  var maxY = -double.infinity;
  for (final p in ring) {
    minX = math.min(minX, p[0]);
    maxX = math.max(maxX, p[0]);
    minY = math.min(minY, p[1]);
    maxY = math.max(maxY, p[1]);
  }
  LonLat best = ring.first;
  var bestD = -1.0;
  for (var i = 1; i < 30; i++) {
    for (var j = 1; j < 30; j++) {
      final x = minX + (maxX - minX) * i / 30;
      final y = minY + (maxY - minY) * j / 30;
      if (!ringContains(ring, x, y)) continue;
      var d = double.infinity;
      for (var k = 0; k < ring.length - 1; k++) {
        d = math.min(d, _perp([x, y], ring[k], ring[k + 1]));
      }
      if (d > bestD) {
        bestD = d;
        best = [x, y];
      }
    }
  }
  return [_round(best[0], 4), _round(best[1], 4)];
}

List<List<List<LonLat>>> _polygons(Map<String, dynamic> geometry) {
  List<LonLat> ring(dynamic r) => [
    for (final p in r as List<dynamic>)
      [((p as List<dynamic>)[0] as num).toDouble(), (p[1] as num).toDouble()],
  ];
  final type = geometry['type'] as String;
  final c = geometry['coordinates'] as List<dynamic>;
  if (type == 'Polygon') {
    return [
      [for (final r in c) ring(r)],
    ];
  }
  return [
    for (final poly in c) [for (final r in poly as List<dynamic>) ring(r)],
  ];
}

/// Result of [normalizeSulteng].
class NormalizedGeo {
  const NormalizedGeo(this.json, this.tolerance, this.bytes);

  /// The normalised GeoJSON text.
  final String json;

  /// The Douglas-Peucker tolerance used, in degrees.
  final double tolerance;

  /// Size of [json] in bytes.
  final int bytes;
}

/// Normalises the old `sulteng.json`: adds `properties.code` from [kRegencyCodeByName],
/// simplifies with the smallest tolerance that gives at most [maxBytes], rounds
/// coordinates to 4 decimals and adds `properties.labelPoint` (`[lon, lat]`).
/// Throws [FormatException] when a feature has an unknown name or the 13 codes
/// are not all present.
NormalizedGeo normalizeSulteng(String source, {int maxBytes = 60 * 1024}) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final features = (root['features'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final codes = <String>{};
  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>;
    final name = (props['name'] ?? props['id']) as String;
    final code = kRegencyCodeByName[name] ?? kRegencyCodeByName[props['id']];
    if (code == null) throw FormatException('Unknown region "$name"');
    codes.add(code);
  }
  if (codes.length != 13 || !codes.containsAll(kRegencyCodes)) {
    throw FormatException(
      'Expected the 13 codes, got ${codes.toList()..sort()}',
    );
  }

  String build(double tol) {
    final out = <Map<String, dynamic>>[];
    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>;
      final name = (props['name'] ?? props['id']) as String;
      final code = kRegencyCodeByName[name] ?? kRegencyCodeByName[props['id']]!;
      final polys = <List<List<LonLat>>>[];
      List<LonLat>? largest;
      var largestArea = 0.0;
      for (final poly in _polygons(f['geometry'] as Map<String, dynamic>)) {
        final rings = <List<LonLat>>[];
        for (final r in poly) {
          final s = simplifyRing(
            r,
            tol,
          ).map((p) => [_round(p[0], 4), _round(p[1], 4)]).toList();
          if (s.length >= 4) rings.add(s);
        }
        if (rings.isEmpty) continue;
        polys.add(rings);
        final a = _area(rings.first).abs();
        if (a > largestArea) {
          largestArea = a;
          largest = rings.first;
        }
      }
      out.add({
        'type': 'Feature',
        'properties': {
          'code': code,
          'name': name == 'Parigi Mautong' ? 'Parigi Moutong' : name,
          'labelPoint': labelPointOf(largest!),
        },
        'geometry': {'type': 'MultiPolygon', 'coordinates': polys},
      });
    }
    out.sort(
      (a, b) => ((a['properties'] as Map)['code'] as String).compareTo(
        (b['properties'] as Map)['code'] as String,
      ),
    );
    return jsonEncode({'type': 'FeatureCollection', 'features': out});
  }

  // The smallest tolerance (most detail) that fits the size budget.
  var lo = 0.0;
  var hi = 0.05;
  var best = build(hi);
  var bestTol = hi;
  for (var i = 0; i < 14; i++) {
    final mid = (lo + hi) / 2;
    final s = build(mid);
    if (utf8.encode(s).length <= maxBytes) {
      best = s;
      bestTol = mid;
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return NormalizedGeo(best, bestTol, utf8.encode(best).length);
}
