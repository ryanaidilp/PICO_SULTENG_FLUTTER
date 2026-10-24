import 'dart:async';

import 'package:dependencies/state.dart';
import 'package:infografis/src/presentation/bloc/infografis_event.dart';
import 'package:infografis/src/presentation/bloc/infografis_state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Pages of infographics, 20 per page, each page a stream by the C05 rule.
/// The last page (`hasNext` false) ends the requests.
class InfografisBloc extends Bloc<InfografisEvent, InfografisState> {
  new(this._content) : super(const InfografisState()) {
    on<InfografisStarted>((e, emit) => _load(1));
    on<InfografisRefreshed>((e, emit) {
      _pages.clear();
      emit(
        state.copyWith(
          items: const [],
          loadedPages: 0,
          hasNext: false,
          loading: true,
          clearFailure: true,
        ),
      );
      _load(1, force: true, done: e.done);
    });
    on<InfografisMoreRequested>((e, emit) {
      if (state.loading || state.loadingMore || !state.hasNext) return;
      emit(state.copyWith(loadingMore: true, clearFailure: true));
      _load(state.loadedPages + 1);
    });
    on<_PageArrived>((e, emit) {
      e.result.fold(
        (f) => emit(
          state.items.isEmpty
              ? state.copyWith(failure: f, loading: false, loadingMore: false)
              // A later page failed: keep what is shown, allow a retry.
              : state.copyWith(failure: f, loadingMore: false),
        ),
        (s) {
          _pages[e.page] = s.data;
          final ordered = _pages.keys.toList()..sort();
          emit(
            state.copyWith(
              items: [for (final p in ordered) ..._pages[p]!.items],
              loadedPages: ordered.last,
              hasNext: _pages[ordered.last]!.hasNext,
              loading: false,
              loadingMore: false,
              clearFailure: true,
              fetchedAt: s.fetchedAt,
              isStale: s.isStale,
            ),
          );
        },
      );
    });
  }

  final ContentRepository _content;
  final Map<int, InfographicPage> _pages = {};
  final List<StreamSubscription<Object?>> _subs = [];

  void _load(int page, {bool force = false, Completer<void>? done}) {
    _subs.add(
      _content
          .watchInfographics(page: page, forceRefresh: force)
          .listen(
            (r) => add(_PageArrived(page, r)),
            onDone: () {
              if (done != null && !done.isCompleted) done.complete();
            },
          ),
    );
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    return super.close();
  }
}

final class _PageArrived extends InfografisEvent {
  const new(this.page, this.result);

  final int page;
  final Either<PicoFailure, DataSnapshot<InfographicPage>> result;
}
