import 'package:dependencies/state.dart';

import 'package:layanan/src/presentation/bloc/layanan_event.dart';
import 'package:layanan/src/presentation/bloc/layanan_state.dart';

/// Bloc for the Layanan feature.
class LayananBloc() extends Bloc<LayananEvent, LayananState> {
  this : super(const LayananState.initial()) {
    on<LayananEvent>(_onEvent);
  }

  Future<void> _onEvent(LayananEvent event, Emitter<LayananState> emit) async {
    await switch (event) {
      LayananStarted() || LayananLoadRequested() => _onLoad(emit),
      LayananRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<LayananState> emit) async {
    emit(const LayananState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const LayananState.loaded());
    } catch (e) {
      emit(LayananState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<LayananState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
