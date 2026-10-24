import 'dart:async';

import 'package:dependencies/state.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_state.dart';

/// Loads the vaccination coverage of a scope, and the locations on demand.
/// Each source is a stream by the C05 rule.
class VaksinBloc extends Bloc<VaksinEvent, VaksinState> {
  /// Creates the bloc.
  new(this._stats, this._directory) : super(const VaksinState()) {
    on<VaksinStarted>((e, emit) => _watchSeries(state.scope));
    on<VaksinScopeChanged>((e, emit) {
      if (e.scope == state.scope) return;
      emit(
        state.copyWith(
          scope: e.scope,
          series: const VaksinSection<VaccinationSeries>.loading(),
        ),
      );
      _watchSeries(e.scope);
    });
    on<VaksinSegmentChanged>((e, emit) {
      emit(state.copyWith(segment: e.segment));
      if (e.segment == VaksinSegment.locations && _locSubs.isEmpty) {
        _watchLocations();
      }
    });
    on<VaksinRefreshed>((e, emit) {
      if (state.segment == VaksinSegment.coverage) {
        _watchSeries(state.scope, force: true, done: e.done);
      } else {
        _watchLocations(force: true, done: e.done);
      }
    });
    on<_SeriesArrived>((e, emit) {
      if (e.scope != state.scope) return;
      emit(state.copyWith(series: _section(e.result, state.series)));
    });
    on<_LocationsArrived>(
      (e, emit) =>
          emit(state.copyWith(locations: _section(e.result, state.locations))),
    );
  }

  final StatsRepository _stats;
  final DirectoryRepository _directory;
  StreamSubscription<Object?>? _seriesSub;
  List<StreamSubscription<Object?>> _locSubs = [];

  void _watchSeries(
    VaccinationScope scope, {
    bool force = false,
    Completer<void>? done,
  }) {
    unawaited(_seriesSub?.cancel());
    _seriesSub = _stats
        .watchVaccination(scope, forceRefresh: force)
        .listen(
          (r) => add(_SeriesArrived(scope, r)),
          onDone: () => _complete(done),
        );
  }

  void _watchLocations({bool force = false, Completer<void>? done}) {
    for (final s in _locSubs) {
      unawaited(s.cancel());
    }
    // Locations and their regency names arrive as two streams; the page needs
    // both, so the last event of each is combined.
    Either<PicoFailure, DataSnapshot<List<VaccineLocation>>>? locs;
    Either<PicoFailure, DataSnapshot<List<Regency>>>? regs;
    var open = 2;
    void push() {
      final l = locs;
      final r = regs;
      if (l == null || r == null) return;
      add(_LocationsArrived(_combine(l, r)));
    }

    void finished() {
      if (--open == 0) _complete(done);
    }

    final a = _directory.watchVaccineLocations(forceRefresh: force).listen((v) {
      locs = v;
      push();
    }, onDone: finished);
    final b = _directory.watchRegencies(forceRefresh: force).listen((v) {
      regs = v;
      push();
    }, onDone: finished);
    _locSubs = [a, b];
  }

  Either<PicoFailure, DataSnapshot<LocationsData>> _combine(
    Either<PicoFailure, DataSnapshot<List<VaccineLocation>>> l,
    Either<PicoFailure, DataSnapshot<List<Regency>>> r,
  ) => l.fold(Left.new, (ls) {
    // Names are a nicety: without them the group header falls back to the code.
    final names = r.rightOrNull?.data ?? const <Regency>[];
    return Right(
      DataSnapshot(
        data: (locations: ls.data, regencies: names),
        fetchedAt: ls.fetchedAt,
        source: ls.source,
        isStale: ls.isStale || (r.isLeft),
      ),
    );
  });

  void _complete(Completer<void>? done) {
    if (done != null && !done.isCompleted) done.complete();
  }

  VaksinSection<T> _section<T>(
    Either<PicoFailure, DataSnapshot<T>> r,
    VaksinSection<T> previous,
  ) => r.fold(
    (f) => previous.snapshot != null
        ? previous
        : VaksinSection<T>(failure: f, loading: false),
    (s) => VaksinSection<T>(snapshot: s, loading: false),
  );

  @override
  Future<void> close() async {
    await _seriesSub?.cancel();
    for (final s in _locSubs) {
      await s.cancel();
    }
    return super.close();
  }
}

final class _SeriesArrived extends VaksinEvent {
  const new(this.scope, this.result);

  final VaccinationScope scope;
  final Either<PicoFailure, DataSnapshot<VaccinationSeries>> result;
}

final class _LocationsArrived extends VaksinEvent {
  const new(this.result);

  final Either<PicoFailure, DataSnapshot<LocationsData>> result;
}
