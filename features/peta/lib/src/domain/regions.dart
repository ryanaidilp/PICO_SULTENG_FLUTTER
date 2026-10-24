import 'dart:convert';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:peta/src/domain/geo_normalize.dart';

/// One kabupaten or kota: its code, name, outline and label point, in
/// longitude and latitude.
class Region {
  const Region({
    required this.code,
    required this.name,
    required this.polygons,
    required this.labelPoint,
  });

  /// BPS code, for example `7271`.
  final String code;

  /// Name as the GeoJSON spells it.
  final String name;

  /// Polygons, each a list of rings (outer first); points are `[lon, lat]`.
  final List<List<List<LonLat>>> polygons;

  /// A point inside the largest ring.
  final LonLat labelPoint;
}

/// Parses the normalised `sulteng.json`. Pure and isolate-safe.
List<Region> parseRegions(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final out = <Region>[];
  for (final f
      in (root['features'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final props = f['properties'] as Map<String, dynamic>;
    final lp = (props['labelPoint'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    final polys = <List<List<LonLat>>>[];
    for (final poly
        in (f['geometry'] as Map<String, dynamic>)['coordinates']
            as List<dynamic>) {
      polys.add([
        for (final ring in poly as List<dynamic>)
          [
            for (final p in ring as List<dynamic>)
              [
                ((p as List<dynamic>)[0] as num).toDouble(),
                (p[1] as num).toDouble(),
              ],
          ],
      ]);
    }
    out.add(
      Region(
        code: props['code'] as String,
        name: props['name'] as String,
        polygons: polys,
        labelPoint: lp,
      ),
    );
  }
  return out;
}

/// Parses in an isolate (the file is about 60 KB, parsed once per session).
Future<List<Region>> parseRegionsInIsolate(String source) =>
    compute(parseRegions, source);

/// Equirectangular projection fitted to a box: x is longitude scaled by the
/// cosine of the mean latitude, y is flipped latitude.
class MapProjection {
  MapProjection(List<Region> regions) {
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final r in regions) {
      for (final poly in r.polygons) {
        for (final p in poly.first) {
          minX = p[0] < minX ? p[0] : minX;
          maxX = p[0] > maxX ? p[0] : maxX;
          minY = p[1] < minY ? p[1] : minY;
          maxY = p[1] > maxY ? p[1] : maxY;
        }
      }
    }
    _minLon = minX;
    _maxLat = maxY;
    // Near the equator; the cosine only matters a little.
    _k = 0.99996;
    width = (maxX - minX) * _k;
    height = maxY - minY;
  }

  late final double _minLon;
  late final double _maxLat;
  late final double _k;

  /// Width of the map in projected units.
  late final double width;

  /// Height of the map in projected units.
  late final double height;

  /// Aspect ratio (width over height).
  double get aspect => width / height;

  /// [lon], [lat] to a point in a box of [size] with no padding.
  Offset project(double lon, double lat, Size size) => Offset(
    (lon - _minLon) * _k / width * size.width,
    (_maxLat - lat) / height * size.height,
  );

  /// The bounds of [r] in a box of [size].
  Rect boundsOf(Region r, Size size) {
    Rect? b;
    for (final poly in r.polygons) {
      for (final p in poly.first) {
        final o = project(p[0], p[1], size);
        b = b == null
            ? Rect.fromPoints(o, o)
            : b.expandToInclude(Rect.fromPoints(o, o));
      }
    }
    return b!;
  }
}

/// Whether the projected point [at] is inside a region.
bool regionContains(Region r, MapProjection pr, Size size, Offset at) {
  for (final poly in r.polygons) {
    final outer = [for (final p in poly.first) pr.project(p[0], p[1], size)];
    var inside = false;
    for (var i = 0, j = outer.length - 1; i < outer.length; j = i++) {
      final a = outer[i];
      final b = outer[j];
      if ((a.dy > at.dy) != (b.dy > at.dy) &&
          at.dx < (b.dx - a.dx) * (at.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    if (inside) return true;
  }
  return false;
}
