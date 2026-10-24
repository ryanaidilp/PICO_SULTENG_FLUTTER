import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/fold_text.dart';

/// The provinces for the picker: filtered by [query] (accent and case
/// insensitive on the name), Sulawesi Tengah first, the rest by name.
List<AreaSummary> orderProvinces(List<AreaSummary> all, {String query = ''}) {
  final q = foldText(query.trim());
  final rows = [
    for (final s in all)
      if (s.area is ProvinceArea && (q.isEmpty || foldText(s.name).contains(q)))
        s,
  ]..sort((a, b) => foldText(a.name).compareTo(foldText(b.name)));
  final i = rows.indexWhere(
    (s) => s.area == const AreaRef.province(kSultengProvinceId),
  );
  if (i > 0) rows.insert(0, rows.removeAt(i));
  return rows;
}

/// Labels of the age groups of C03 (`0_14`, `55_plus`), in age order.
const kAgeGroupOrder = ['0_14', '15_19', '20_24', '25_49', '50_54', '55_plus'];
