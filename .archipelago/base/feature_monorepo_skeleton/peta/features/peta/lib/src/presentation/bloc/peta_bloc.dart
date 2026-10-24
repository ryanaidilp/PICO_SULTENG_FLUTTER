import 'package:dependencies/state.dart';

import 'package:peta/src/presentation/bloc/peta_event.dart';
import 'package:peta/src/presentation/bloc/peta_state.dart';

/// Bloc for the Peta feature.
class PetaBloc() extends Bloc<PetaEvent, PetaState> {
  this : super(const PetaState.initial()) {
    on<PetaEvent>(_onEvent);
  }

  Future<void> _onEvent(PetaEvent event, Emitter<PetaState> emit) async {
    await switch (event) {
      PetaStarted() || PetaLoadRequested() => _onLoad(emit),
      PetaRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<PetaState> emit) async {
    emit(const PetaState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const PetaState.loaded());
    } catch (e) {
      emit(PetaState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<PetaState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
