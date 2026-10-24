import 'package:dependencies/state.dart';

import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_state.dart';

/// Bloc for the Vaksin feature.
class VaksinBloc() extends Bloc<VaksinEvent, VaksinState> {
  this : super(const VaksinState.initial()) {
    on<VaksinEvent>(_onEvent);
  }

  Future<void> _onEvent(VaksinEvent event, Emitter<VaksinState> emit) async {
    await switch (event) {
      VaksinStarted() || VaksinLoadRequested() => _onLoad(emit),
      VaksinRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<VaksinState> emit) async {
    emit(const VaksinState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const VaksinState.loaded());
    } catch (e) {
      emit(VaksinState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<VaksinState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
