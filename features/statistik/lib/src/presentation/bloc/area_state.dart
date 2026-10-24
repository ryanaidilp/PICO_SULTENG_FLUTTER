import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/area_view.dart';

/// State of the area page.
final class AreaState extends Equatable {
  /// Creates a state.
  const AreaState({
    this.query = const AreaQuery(),
    this.compare = false,
    this.snapshot,
    this.failure,
    this.view,
    this.loading = true,
  });

  /// The current query (also the URL).
  final AreaQuery query;

  /// "Bandingkan": overlay the four metrics (cumulative only).
  final bool compare;

  /// The series with its freshness facts.
  final DataSnapshot<CaseSeries>? snapshot;

  /// Set when the series failed and there is no saved copy.
  final PicoFailure? failure;

  /// Derived from [snapshot] and [query], no request involved.
  final AreaView? view;

  /// True until the first answer for the current area.
  final bool loading;

  /// Copy with replaced fields. [clearSnapshot] drops series and view.
  AreaState copyWith({
    AreaQuery? query,
    bool? compare,
    DataSnapshot<CaseSeries>? snapshot,
    PicoFailure? failure,
    AreaView? view,
    bool? loading,
    bool clearData = false,
  }) => AreaState(
    query: query ?? this.query,
    compare: compare ?? this.compare,
    snapshot: clearData ? null : snapshot ?? this.snapshot,
    failure: clearData ? failure : failure ?? this.failure,
    view: clearData ? null : view ?? this.view,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [query, compare, snapshot, failure, view, loading];
}
