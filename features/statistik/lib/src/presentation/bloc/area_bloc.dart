import 'dart:async';

import 'package:dependencies/state.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/area_view.dart';
import 'package:statistik/src/presentation/bloc/area_event.dart';
import 'package:statistik/src/presentation/bloc/area_state.dart';

/// Loads the series of the chosen area and derives the view. The series comes
/// from the repository by the C05 stream rule. A change of metric, daily or
/// range only recomputes the view: the repository is asked again only when the
/// area changes or the user refreshes.
class AreaBloc extends Bloc<AreaEvent, AreaState> {
  /// Creates the bloc over [cases].
  AreaBloc(this._cases) : super(const AreaState()) {
    on<AreaOpened>(_onOpened);
    on<AreaQueryChanged>(_onQuery);
    on<AreaCompareToggled>(
      (e, emit) => emit(state.copyWith(compare: !state.compare)),
    );
    on<AreaRefreshed>(_onRefresh);
    on<_SeriesArrived>(_onSeries);
  }

  final CaseRepository _cases;
  StreamSubscription<Either<PicoFailure, DataSnapshot<CaseSeries>>>? _sub;
  AreaRef? _loadedArea;

  void _watch(AreaRef area, {bool force = false, Completer<void>? done}) {
    unawaited(_sub?.cancel());
    _loadedArea = area;
    _sub = _cases
        .watchSeries(area, forceRefresh: force)
        .listen(
          (r) => add(_SeriesArrived(area, r)),
          onDone: () {
            if (done != null && !done.isCompleted) done.complete();
          },
        );
  }

  void _onOpened(AreaOpened e, Emitter<AreaState> emit) {
    if (e.query == state.query && _loadedArea == e.query.area) return;
    _applyQuery(e.query, emit);
  }

  void _onQuery(AreaQueryChanged e, Emitter<AreaState> emit) =>
      _applyQuery(e.query, emit);

  void _applyQuery(AreaQuery q, Emitter<AreaState> emit) {
    if (q.area != _loadedArea) {
      emit(state.copyWith(query: q, clearData: true, loading: true));
      _watch(q.area);
      return;
    }
    final snap = state.snapshot;
    emit(
      state.copyWith(
        query: q,
        view: snap == null ? null : buildAreaView(snap.data, q),
      ),
    );
  }

  void _onSeries(_SeriesArrived e, Emitter<AreaState> emit) {
    if (e.area != _loadedArea) return;
    e.result.fold(
      (f) => emit(state.copyWith(failure: f, loading: false, clearData: true)),
      (snap) => emit(
        AreaState(
          query: state.query,
          compare: state.compare,
          snapshot: snap,
          view: buildAreaView(snap.data, state.query),
          loading: false,
        ),
      ),
    );
  }

  void _onRefresh(AreaRefreshed e, Emitter<AreaState> emit) =>
      _watch(state.query.area, force: true, done: e.done);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

final class _SeriesArrived extends AreaEvent {
  const _SeriesArrived(this.area, this.result);

  final AreaRef area;
  final Either<PicoFailure, DataSnapshot<CaseSeries>> result;
}
