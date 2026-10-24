// Normalises the old sulteng.json for the Peta feature (spec S39):
//   dart run tool/normalize_geojson.dart <old sulteng.json> assets/geojson/sulteng.json
import 'dart:io';

import 'package:peta/src/domain/geo_normalize.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: normalize_geojson.dart <in> <out>');
    exit(64);
  }
  final r = normalizeSulteng(File(args[0]).readAsStringSync());
  File(args[1]).writeAsStringSync(r.json);
  stdout.writeln(
    'wrote ${args[1]}: ${r.bytes} bytes, tolerance ${r.tolerance.toStringAsFixed(5)}',
  );
}
