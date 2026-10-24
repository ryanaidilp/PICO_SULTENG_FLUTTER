import 'package:dependencies/state.dart';

import 'package:statistik/src/presentation/bloc/statistik_event.dart';
import 'package:statistik/src/presentation/bloc/statistik_state.dart';

/// Bloc for the Statistik feature.
class StatistikBloc() extends Bloc<StatistikEvent, StatistikState> {
  this : super(const StatistikState.initial()) {
    on<StatistikEvent>(_onEvent);
  }

  Future<void> _onEvent(
    StatistikEvent event,
    Emitter<StatistikState> emit,
  ) async {
    await switch (event) {
      StatistikStarted() || StatistikLoadRequested() => _onLoad(emit),
      StatistikRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<StatistikState> emit) async {
    emit(const StatistikState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const StatistikState.loaded());
    } catch (e) {
      emit(StatistikState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<StatistikState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
