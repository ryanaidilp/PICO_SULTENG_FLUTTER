import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:peta/src/domain/map_values.dart';
import 'package:peta/src/domain/regions.dart';

/// State of the map page.
final class PetaState extends Equatable {
  const PetaState({
    this.regions,
    this.snapshot,
    this.failure,
    this.metric = PetaMetric.positive,
    this.date,
    this.pastDays,
    this.dateLoading = false,
    this.list = false,
    this.selected,
    this.done = false,
  });

  /// Outlines, null until parsed.
  final List<Region>? regions;

  /// The latest day of each kabupaten (grows as the first load arrives).
  final DataSnapshot<List<AreaSummary>>? snapshot;

  /// A failure with nothing to show.
  final PicoFailure? failure;

  /// The chosen metric.
  final PetaMetric metric;

  /// The chosen day, or null for the latest.
  final DateTime? date;

  /// For a chosen day: the [CaseDay] of each code on that date, null where the
  /// series had no such day or did not load.
  final Map<String, CaseDay?>? pastDays;

  /// True while the series of a chosen day load.
  final bool dateLoading;

  /// List instead of map.
  final bool list;

  /// The kabupaten whose sheet is open.
  final String? selected;

  /// The summaries stream has ended.
  final bool done;

  bool get loading => regions == null || (snapshot == null && failure == null);

  /// The values of every kabupaten for [metric] and [date].
  List<MapValue> get values {
    final rs = regions;
    if (rs == null) return const [];
    final summaries = {
      for (final s in snapshot?.data ?? const <AreaSummary>[])
        if (s.area is RegencyArea) (s.area as RegencyArea).code: s,
    };
    return [
      for (final r in rs)
        if (_day(r.code, summaries) case final CaseDay d)
          MapValue(
            code: r.code,
            name: summaries[r.code]?.name ?? r.name,
            value: valueOf(d, metric),
            date: d.date,
          ),
    ];
  }

  CaseDay? _day(String code, Map<String, AreaSummary> summaries) {
    final past = pastDays;
    if (date != null && past != null) return past[code];
    return summaries[code]?.latest;
  }

  PetaState copyWith({
    List<Region>? regions,
    DataSnapshot<List<AreaSummary>>? snapshot,
    PicoFailure? failure,
    bool clearFailure = false,
    PetaMetric? metric,
    DateTime? date,
    bool clearDate = false,
    Map<String, CaseDay?>? pastDays,
    bool clearPast = false,
    bool? dateLoading,
    bool? list,
    String? selected,
    bool clearSelected = false,
    bool? done,
  }) => PetaState(
    regions: regions ?? this.regions,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : failure ?? this.failure,
    metric: metric ?? this.metric,
    date: clearDate ? null : date ?? this.date,
    pastDays: clearPast ? null : pastDays ?? this.pastDays,
    dateLoading: dateLoading ?? this.dateLoading,
    list: list ?? this.list,
    selected: clearSelected ? null : selected ?? this.selected,
    done: done ?? this.done,
  );

  @override
  List<Object?> get props => [
    regions,
    snapshot,
    failure,
    metric,
    date,
    pastDays,
    dateLoading,
    list,
    selected,
    done,
  ];
}
