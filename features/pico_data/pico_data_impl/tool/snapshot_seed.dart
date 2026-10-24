// Builds the bundled first-launch seed from the live API (C05, ADR-0109):
//   dart run tool/snapshot_seed.dart [baseUrl] [out]
// Defaults: https://pico-api.banuacoder.com/api/v1 and assets/seed/seed.json.
//
// Repeatable: run it again and commit the file when the archive changes. The
// seed holds only small "latest" resources (about 40 KB): the latest national
// row, the 34 provinces (latest each), the banners, the latest national Rt and
// the latest row of the 13 kabupaten. No series.
import 'dart:convert';
import 'dart:io';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/api/dates.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/ttl.dart'
    show kLatestRtKey, kRegencySummariesKey;

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

Map<String, int> counts(CaseCounts c) => {
  'positive': c.positive,
  'recovered': c.recovered,
  'deceased': c.deceased,
  'active': c.active,
};

/// The nested API shape of one day, the one `regencySummariesFromLatest` reads.
Map<String, Object?> nested(CaseDay d) => {
  'date': formatApiDate(d.date),
  'daily': counts(d.daily),
  'cumulative': {
    ...counts(d.cumulative),
    if (d.monitoring != null) ...{
      'odp': {
        'active': d.monitoring!.odpActive,
        'finished': d.monitoring!.odpFinished,
      },
      'pdp': {
        'active': d.monitoring!.pdpActive,
        'finished': d.monitoring!.pdpFinished,
      },
    },
  },
  if (d.rt != null)
    'statistics': {
      'reproduction_rate': {
        'value': d.rt!.value,
        'lower_bound': d.rt!.lower,
        'upper_bound': d.rt!.upper,
      },
    },
};

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

  final names = PicoEndpoints.regencies.map(
    dataOf(await get(c, base, PicoEndpoints.regencies.key)),
  );
  final rows = <Map<String, Object?>>[];
  for (final r in names) {
    final s = PicoEndpoints.regencySeries(
      r.code,
    ).map(dataOf(await get(c, base, PicoEndpoints.regencySeries(r.code).key)));
    final day = s.latest;
    if (day == null) continue;
    rows.add({'id': r.code, 'name': r.name, 'latest_case': nested(day)});
  }
  entries[kRegencySummariesKey] = jsonEncode(rows);

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
