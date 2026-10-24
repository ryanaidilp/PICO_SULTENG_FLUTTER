import 'package:pico_data_api/pico_data_api.dart';

/// Display order of the priority groups.
const List<VaccineGroup> kGroupOrder = [
  VaccineGroup.elderly,
  VaccineGroup.healthWorker,
  VaccineGroup.publik,
  VaccineGroup.publicOfficer,
  VaccineGroup.teenager,
];

/// A coverage above 100 percent is real data (health workers 100,36%): it is
/// shown as is, with a note.
bool exceedsTarget(double percent) => percent > 100;

/// A group with no target has nothing to measure coverage against.
bool hasTarget(GroupStats g) => g.target > 0;

/// Locations grouped by regency code, in the order of [regencies], then any
/// unknown code last. Empty groups are dropped.
List<({String code, String name, List<VaccineLocation> items})> groupLocations(
  List<VaccineLocation> locations,
  List<Regency> regencies,
) {
  final names = {for (final r in regencies) r.code: r.name};
  final order = [
    ...regencies.map((r) => r.code),
    ...locations.map((l) => l.regencyCode).where((c) => !names.containsKey(c)),
  ];
  final seen = <String>{};
  return [
    for (final code in order)
      if (seen.add(code))
        (
          code: code,
          name: names[code] ?? code,
          items: [
            for (final l in locations)
              if (l.regencyCode == code) l,
          ],
        ),
  ].where((g) => g.items.isNotEmpty).toList();
}
