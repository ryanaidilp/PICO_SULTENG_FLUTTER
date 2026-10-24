import 'package:flutter/foundation.dart';
import 'package:pico_data_api/pico_data_api.dart';

const _from = 'àáâãäåāăąèéêëēĕėęěìíîïĩīĭįòóôõöōŏőùúûüũūŭůűųñńçćčśšźžżýÿ';
const _to =
    'aaaaaaaaaeeeeeeeeeiiiiiiiioooooooouuuuuuuuuunnccc'
    'sszzzyy';

/// Lowercase [s] and drop common Latin accents, so "Sindhú" matches "sindhu".
String foldText(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = _from.indexOf(c);
    b.write(i >= 0 && i < _to.length ? _to[i] : c);
  }
  return b.toString();
}

/// Whether [h] matches [query] on name or regency name (accent and case
/// insensitive). An empty query matches everything.
bool matchesHospital(Hospital h, String regencyName, String query) {
  final q = foldText(query.trim());
  if (q.isEmpty) return true;
  return foldText(h.name).contains(q) || foldText(regencyName).contains(q);
}

/// Hospitals filtered by [query] and grouped by regency, in the order of
/// [regencies], then any unknown code last (shown by its code).
List<({String code, String name, List<Hospital> items})> groupHospitals(
  List<Hospital> hospitals,
  List<Regency> regencies, {
  String query = '',
}) {
  final names = {for (final r in regencies) r.code: r.name};
  final order = [
    ...regencies.map((r) => r.code),
    ...hospitals.map((h) => h.regencyCode).where((c) => !names.containsKey(c)),
  ];
  final seen = <String>{};
  return [
    for (final code in order)
      if (seen.add(code))
        (
          code: code,
          name: names[code] ?? code,
          items: [
            for (final h in hospitals)
              if (h.regencyCode == code &&
                  matchesHospital(h, names[code] ?? code, query))
                h,
          ],
        ),
  ].where((g) => g.items.isNotEmpty).toList();
}

/// Sum of free and all beds. The API sends no bed rows for some hospitals.
({int available, int total}) bedTotals(Hospital h) => (
  available: h.beds.fold(0, (a, b) => a + b.available),
  total: h.beds.fold(0, (a, b) => a + b.total),
);

/// Whether [p] can be shown on a map: in range and not the (0, 0) placeholder.
bool hasValidLocation(LatLng? p) =>
    p != null &&
    p.latitude.abs() <= 90 &&
    p.longitude.abs() <= 180 &&
    !(p.latitude == 0 && p.longitude == 0);

/// Map link for [h]: a `geo:` URI on Android, an Apple Maps URL on iOS.
/// Null without valid coordinates or on other platforms.
Uri? mapUri(Hospital h, {TargetPlatform? platform}) {
  final p = h.location;
  if (!hasValidLocation(p)) return null;
  final at = '${p!.latitude},${p.longitude}';
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android => Uri.parse(
      'geo:$at?q=$at(${Uri.encodeComponent(h.name)})',
    ),
    TargetPlatform.iOS => Uri.parse(
      'https://maps.apple.com/?ll=$at&q=${Uri.encodeComponent(h.name)}',
    ),
    _ => null,
  };
}
