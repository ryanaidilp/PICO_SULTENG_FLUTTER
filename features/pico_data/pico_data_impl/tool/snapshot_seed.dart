// Builds the bundled first-launch seed from the live API (C05, ADR-0109):
//   dart run tool/snapshot_seed.dart [baseUrl] [out]
// Defaults: https://pico-api.banuacoder.com/api/v1 and assets/seed/seed.json.
//
// Repeatable: run it again and commit the file when the archive changes. The
// seed holds only small "latest" resources (about 40 KB): the latest national
// row, the 34 provinces (latest each), the banners, the latest national Rt and
// the latest row of the 13 kabupaten (one `include_latest_case` call). No
// series.
import 'dart:convert';
import 'dart:io';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/api/dates.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/ttl.dart' show kLatestRtKey;

Future<String> get(HttpClient c, String base, String path) async {
  final req = await c.getUrl(Uri.parse('$base$path'));
  req.headers.set('Accept', 'application/json');
  req.headers.set('User-Agent', 'PICO-Sulteng-seed-tool');
  final res = await req.close();
  if (res.statusCode != 200) {
    throw StateError('GET $path -> ${res.statusCode}');
  }
  return utf8.decodeStream(res);
}

Object? dataOf(String body) =>
    (jsonDecode(body) as Map<String, dynamic>)['data'];

Future<void> main(List<String> args) async {
  final base = args.isNotEmpty
      ? args[0]
      : 'https://pico-api.banuacoder.com/api/v1';
  final out = args.length > 1 ? args[1] : 'assets/seed/seed.json';
  final c = HttpClient();
  final entries = <String, String>{};

  final latestPath = PicoEndpoints.nationalLatest.key;
  entries[latestPath] = await get(c, base, latestPath);
  final latest = PicoEndpoints.nationalLatest.map(dataOf(entries[latestPath]!));

  entries[PicoEndpoints.provinces.key] = await get(
    c,
    base,
    PicoEndpoints.provinces.key,
  );
  entries[PicoEndpoints.banners.key] = await get(
    c,
    base,
    PicoEndpoints.banners.key,
  );

  final series = PicoEndpoints.nationalSeries.map(
    dataOf(await get(c, base, PicoEndpoints.nationalSeries.key)),
  );
  entries[kLatestRtKey] = encodeLatestRt(latestRtOf(series));

  // API 2.11.0: the 13 latest rows in one call.
  final regKey = PicoEndpoints.regencySummaries.key;
  entries[regKey] = await get(c, base, regKey);

  final seed = {
    'version': 1,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'dataThrough': formatApiDate(latest.date),
    'entries': entries,
  };
  File(out)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(seed));
  stdout.writeln(
    'wrote $out: ${File(out).lengthSync()} bytes, ${entries.length} entries, '
    'data through ${seed['dataThrough']}',
  );
  c.close();
}
