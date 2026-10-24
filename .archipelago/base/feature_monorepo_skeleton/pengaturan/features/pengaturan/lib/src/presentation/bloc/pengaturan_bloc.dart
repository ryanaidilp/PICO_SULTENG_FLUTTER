import 'package:dependencies/state.dart';

import 'package:pengaturan/src/presentation/bloc/pengaturan_event.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_state.dart';

/// Bloc for the Pengaturan feature.
class PengaturanBloc() extends Bloc<PengaturanEvent, PengaturanState> {
  this : super(const PengaturanState.initial()) {
    on<PengaturanEvent>(_onEvent);
  }

  Future<void> _onEvent(
    PengaturanEvent event,
    Emitter<PengaturanState> emit,
  ) async {
    await switch (event) {
      PengaturanStarted() || PengaturanLoadRequested() => _onLoad(emit),
      PengaturanRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<PengaturanState> emit) async {
    emit(const PengaturanState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const PengaturanState.loaded());
    } catch (e) {
      emit(PengaturanState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<PengaturanState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
