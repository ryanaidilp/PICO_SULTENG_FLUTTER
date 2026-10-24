import 'dart:async';

import 'package:dependencies/state.dart';
import 'package:layanan/src/presentation/bloc/hospitals_event.dart';
import 'package:layanan/src/presentation/bloc/hospitals_state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Loads the hospitals and their regency names. Each source is a stream by the
/// C05 rule; the page needs both, so the last event of each is combined.
class HospitalsBloc extends Bloc<HospitalsEvent, HospitalsState> {
  /// Creates the bloc.
  new(this._directory) : super(const HospitalsState()) {
    on<HospitalsStarted>((e, emit) => _watch());
    on<HospitalsRefreshed>((e, emit) => _watch(force: true, done: e.done));
    on<_Arrived>((e, emit) => emit(_merge(e.result)));
  }

  final DirectoryRepository _directory;
  List<StreamSubscription<Object?>> _subs = [];

  void _watch({bool force = false, Completer<void>? done}) {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    Either<PicoFailure, DataSnapshot<List<Hospital>>>? hospitals;
    Either<PicoFailure, DataSnapshot<List<Regency>>>? regencies;
    var open = 2;
    void push() {
      final h = hospitals;
      final r = regencies;
      if (h == null || r == null) return;
      add(_Arrived(_combine(h, r)));
    }

    void finished() {
      if (--open == 0 && done != null && !done.isCompleted) done.complete();
    }

    _subs = [
      _directory.watchHospitals(forceRefresh: force).listen((v) {
        hospitals = v;
        push();
      }, onDone: finished),
      _directory.watchRegencies(forceRefresh: force).listen((v) {
        regencies = v;
        push();
      }, onDone: finished),
    ];
  }

  Either<PicoFailure, DataSnapshot<HospitalsData>> _combine(
    Either<PicoFailure, DataSnapshot<List<Hospital>>> h,
    Either<PicoFailure, DataSnapshot<List<Regency>>> r,
  ) => h.fold(Left.new, (hs) {
    // Names are a nicety: without them a group header falls back to the code.
    final names = r.rightOrNull?.data ?? const <Regency>[];
    return Right(
      DataSnapshot(
        data: (hospitals: hs.data, regencies: names),
        fetchedAt: hs.fetchedAt,
        source: hs.source,
        isStale: hs.isStale || r.isLeft,
      ),
    );
  });

  HospitalsState _merge(Either<PicoFailure, DataSnapshot<HospitalsData>> r) =>
      r.fold(
        (f) => state.snapshot != null
            ? state
            : HospitalsState(failure: f, loading: false),
        (s) => HospitalsState(snapshot: s, loading: false),
      );

  @override
  Future<void> close() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    return super.close();
  }
}

final class _Arrived extends HospitalsEvent {
  const new(this.result);

  final Either<PicoFailure, DataSnapshot<HospitalsData>> result;
}
