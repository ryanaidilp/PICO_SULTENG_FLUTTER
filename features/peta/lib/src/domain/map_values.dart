import 'package:pico_data_api/pico_data_api.dart';

/// What the map shows for one kabupaten: a value (null for "not available",
/// for example an Rt that was not computed), and the day it belongs to.
class MapValue {
  const MapValue({
    required this.code,
    required this.name,
    this.value,
    required this.date,
  });

  final String code;
  final String name;

  /// The figure, or null when there is none. Never replaced by 0.
  final num? value;

  /// The data day.
  final DateTime date;
}

/// The Rt readings plus the four case types.
enum PetaMetric { positive, recovered, deceased, active, rt }

/// The value of [metric] on [day]: the cumulative figure, or the Rt estimate.
num? valueOf(CaseDay day, PetaMetric metric) => switch (metric) {
  PetaMetric.positive => day.cumulative.positive,
  PetaMetric.recovered => day.cumulative.recovered,
  PetaMetric.deceased => day.cumulative.deceased,
  PetaMetric.active => day.cumulative.active,
  PetaMetric.rt => day.rt?.value,
};

/// The step 0..5 of every value: 6 bins with (as near as possible) the same
/// number of regions. Equal values share a step. Null values have no step.
Map<String, int> markSteps(List<MapValue> values) {
  final ranked = [
    for (final v in values)
      if (v.value != null) v,
  ]..sort((a, b) => a.value!.compareTo(b.value!));
  final n = ranked.length;
  final out = <String, int>{};
  num? last;
  var lastStep = 0;
  for (var i = 0; i < n; i++) {
    final v = ranked[i];
    final step = v.value == last ? lastStep : (i * 6 ~/ n).clamp(0, 5);
    out[v.code] = step;
    last = v.value;
    lastStep = step;
  }
  return out;
}

/// The value range of each of the 6 steps, or null for an empty step.
List<({num min, num max})?> stepRanges(
  List<MapValue> values,
  Map<String, int> steps,
) {
  final out = List<({num min, num max})?>.filled(6, null);
  for (final v in values) {
    final s = steps[v.code];
    if (s == null || v.value == null) continue;
    final cur = out[s];
    out[s] = cur == null
        ? (min: v.value!, max: v.value!)
        : (
            min: v.value! < cur.min ? v.value! : cur.min,
            max: v.value! > cur.max ? v.value! : cur.max,
          );
  }
  return out;
}

/// Order of the list and of the semantics nodes: by value high to low, regions
/// with no value last, ties by name.
List<MapValue> listOrder(List<MapValue> values) {
  final l = [...values];
  l.sort((a, b) {
    if (a.value == null || b.value == null) {
      if (a.value == null && b.value == null) return a.name.compareTo(b.name);
      return a.value == null ? 1 : -1;
    }
    final c = b.value!.compareTo(a.value!);
    return c != 0 ? c : a.name.compareTo(b.name);
  });
  return l;
}
