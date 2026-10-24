import 'dart:async';

import 'package:dependencies/equality.dart';
import 'package:dependencies/state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// The 13 regency names, their summaries as they arrive, and whether the
/// summaries stream has ended.
final class RegenciesState extends Equatable {
  const RegenciesState({
    this.names,
    this.summaries,
    this.failure,
    this.done = false,
  });

  /// The 13 names (code and name).
  final List<Regency>? names;

  /// Summaries so far (the first load fills them one by one).
  final DataSnapshot<List<AreaSummary>>? summaries;

  /// Failure of the summaries with nothing to show.
  final PicoFailure? failure;

  /// True when the summaries stream ended.
  final bool done;

  /// Nothing known yet.
  bool get loading => summaries == null && failure == null;

  RegenciesState copyWith({
    List<Regency>? names,
    DataSnapshot<List<AreaSummary>>? summaries,
    PicoFailure? failure,
    bool clearFailure = false,
    bool? done,
  }) => RegenciesState(
    names: names ?? this.names,
    summaries: summaries ?? this.summaries,
    failure: clearFailure ? null : failure ?? this.failure,
    done: done ?? this.done,
  );

  @override
  List<Object?> get props => [names, summaries, failure, done];
}

/// Follows `watchRegencies` and `watchRegencySummaries`. Created lazily by the
/// shell, so the 13 requests of the fallback start only on this page.
class RegenciesCubit extends Cubit<RegenciesState> {
  RegenciesCubit(this._cases, this._directory) : super(const RegenciesState()) {
    _directorySub = _directory.watchRegencies().listen((r) {
      if (isClosed) return;
      r.fold((_) {}, (s) => emit(state.copyWith(names: s.data)));
    });
    _load(force: false);
  }

  final CaseRepository _cases;
  final DirectoryRepository _directory;
  StreamSubscription<Object?>? _directorySub;
  StreamSubscription<Object?>? _sub;

  void _load({required bool force, Completer<void>? done}) {
    unawaited(_sub?.cancel());
    emit(state.copyWith(done: false, clearFailure: true));
    _sub = _cases
        .watchRegencySummaries(forceRefresh: force)
        .listen(
          (r) {
            if (isClosed) return;
            r.fold(
              (f) => emit(
                state.summaries != null ? state : state.copyWith(failure: f),
              ),
              (s) => emit(state.copyWith(summaries: s)),
            );
          },
          onDone: () {
            if (!isClosed) emit(state.copyWith(done: true));
            if (done != null && !done.isCompleted) done.complete();
          },
        );
  }

  /// "Coba muat lagi": asks again; what is fresh in the saved copy is not
  /// requested twice, so only the failed regencies cost a request.
  void retry() => _load(force: false);

  /// Pull to refresh: everything is requested again.
  Future<void> refresh() {
    final done = Completer<void>();
    _load(force: true, done: done);
    return done.future;
  }

  @override
  Future<void> close() {
    unawaited(_directorySub?.cancel());
    unawaited(_sub?.cancel());
    return super.close();
  }
}
