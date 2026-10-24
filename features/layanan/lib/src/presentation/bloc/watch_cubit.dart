import 'dart:async';

import 'package:dependencies/equality.dart';
import 'package:dependencies/state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// One data source as a state: loading, data with freshness facts, or a
/// failure with no saved copy.
final class WatchState<T> extends Equatable {
  const new({this.snapshot, this.failure, this.loading = true});

  final DataSnapshot<T>? snapshot;
  final PicoFailure? failure;
  final bool loading;

  T? get data => snapshot?.data;

  @override
  List<Object?> get props => [snapshot, failure, loading];
}

/// Follows one repository stream by the C05 rule. Created lazily by the shell,
/// so a source nobody opens is never requested.
class WatchCubit<T> extends Cubit<WatchState<T>> {
  new(this._source) : super(WatchState<T>()) {
    _listen(force: false);
  }

  final Watch<T> Function({bool forceRefresh}) _source;
  StreamSubscription<Object?>? _sub;

  void _listen({required bool force, Completer<void>? done}) {
    unawaited(_sub?.cancel());
    _sub = _source(forceRefresh: force).listen(
      (r) {
        if (isClosed) return;
        r.fold(
          // A failure never hides a saved copy that is already shown.
          (f) => emit(
            state.snapshot != null
                ? state
                : WatchState<T>(failure: f, loading: false),
          ),
          (s) => emit(WatchState<T>(snapshot: s, loading: false)),
        );
      },
      onDone: () {
        if (done != null && !done.isCompleted) done.complete();
      },
    );
  }

  /// Pull to refresh.
  Future<void> refresh() {
    final done = Completer<void>();
    _listen(force: true, done: done);
    return done.future;
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    return super.close();
  }
}
