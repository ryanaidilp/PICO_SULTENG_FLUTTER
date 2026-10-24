import 'package:dependencies/state.dart';

import 'package:infografis/src/presentation/bloc/infografis_event.dart';
import 'package:infografis/src/presentation/bloc/infografis_state.dart';

/// Bloc for the Infografis feature.
class InfografisBloc() extends Bloc<InfografisEvent, InfografisState> {
  this : super(const InfografisState.initial()) {
    on<InfografisEvent>(_onEvent);
  }

  Future<void> _onEvent(
    InfografisEvent event,
    Emitter<InfografisState> emit,
  ) async {
    await switch (event) {
      InfografisStarted() || InfografisLoadRequested() => _onLoad(emit),
      InfografisRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<InfografisState> emit) async {
    emit(const InfografisState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const InfografisState.loaded());
    } catch (e) {
      emit(InfografisState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<InfografisState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
