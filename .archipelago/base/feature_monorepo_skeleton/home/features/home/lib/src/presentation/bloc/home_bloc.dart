import 'package:dependencies/state.dart';

import 'package:home/src/presentation/bloc/home_event.dart';
import 'package:home/src/presentation/bloc/home_state.dart';

/// Bloc for the Home feature.
class HomeBloc() extends Bloc<HomeEvent, HomeState> {
  this : super(const HomeState.initial()) {
    on<HomeEvent>(_onEvent);
  }

  Future<void> _onEvent(HomeEvent event, Emitter<HomeState> emit) async {
    await switch (event) {
      HomeStarted() || HomeLoadRequested() => _onLoad(emit),
      HomeRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<HomeState> emit) async {
    emit(const HomeState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const HomeState.loaded());
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<HomeState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
