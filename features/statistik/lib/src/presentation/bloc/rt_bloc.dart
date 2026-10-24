import 'dart:async';

import 'package:dependencies/equality.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:pico_data_api/pico_data_api.dart';
import 'package:statistik/src/domain/rt_view.dart';

/// Events of the Rt bloc.
abstract class RtEvent {
  const RtEvent();
}

/// A page opened for [area].
final class RtOpened extends RtEvent {
  const RtOpened(this.area);

  final AreaRef area;
}

/// The user chose another area.
final class RtAreaChanged extends RtEvent {
  const RtAreaChanged(this.area);

  final AreaRef area;
}

/// The user chose a range. No request.
final class RtRangeChanged extends RtEvent {
  const RtRangeChanged(this.range);

  final DateTimeRange? range;
}

/// Pull to refresh or retry.
final class RtRefreshed extends RtEvent {
  const RtRefreshed({this.done});

  final Completer<void>? done;
}

/// State of the Rt page.
final class RtState extends Equatable {
  const RtState({
    this.area = const AreaRef.national(),
    this.range,
    this.snapshot,
    this.failure,
    this.view,
    this.loading = true,
  });

  final AreaRef area;

  /// Chosen range, null for all data.
  final DateTimeRange? range;
  final DataSnapshot<CaseSeries>? snapshot;
  final PicoFailure? failure;
  final RtView? view;
  final bool loading;

  @override
  List<Object?> get props => [area, range, snapshot, failure, view, loading];
}

/// Loads the series of the chosen area and derives the Rt view. A range change
/// only recomputes the view; the repository is asked again only for another
/// area or a refresh.
class RtBloc extends Bloc<RtEvent, RtState> {
  RtBloc(this._cases) : super(const RtState()) {
    on<RtOpened>((e, emit) {
      if (e.area == _loaded && state.snapshot != null) return;
      _switch(e.area, emit);
    });
    on<RtAreaChanged>((e, emit) {
      if (e.area == _loaded) return;
      _switch(e.area, emit);
    });
    on<RtRangeChanged>((e, emit) {
      final snap = state.snapshot;
      emit(
        RtState(
          area: state.area,
          range: e.range,
          snapshot: snap,
          view: snap == null
              ? null
              : buildRtView(snap.data, from: e.range?.start, to: e.range?.end),
          loading: false,
        ),
      );
    });
    on<RtRefreshed>((e, emit) => _watch(state.area, force: true, done: e.done));
    on<_Arrived>((e, emit) {
      if (e.area != _loaded) return;
      e.result.fold(
        (f) => emit(
          RtState(
            area: state.area,
            range: state.range,
            failure: f,
            loading: false,
          ),
        ),
        (s) => emit(
          RtState(
            area: state.area,
            range: state.range,
            snapshot: s,
            view: buildRtView(
              s.data,
              from: state.range?.start,
              to: state.range?.end,
            ),
            loading: false,
          ),
        ),
      );
    });
  }

  final CaseRepository _cases;
  StreamSubscription<Object?>? _sub;
  AreaRef? _loaded;

  void _switch(AreaRef area, Emitter<RtState> emit) {
    emit(RtState(area: area));
    _watch(area);
  }

  void _watch(AreaRef area, {bool force = false, Completer<void>? done}) {
    unawaited(_sub?.cancel());
    _loaded = area;
    _sub = _cases
        .watchSeries(area, forceRefresh: force)
        .listen(
          (r) => add(_Arrived(area, r)),
          onDone: () {
            if (done != null && !done.isCompleted) done.complete();
          },
        );
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    return super.close();
  }
}

final class _Arrived extends RtEvent {
  const _Arrived(this.area, this.result);

  final AreaRef area;
  final Either<PicoFailure, DataSnapshot<CaseSeries>> result;
}
