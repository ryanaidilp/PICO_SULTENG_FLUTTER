import 'package:dependencies/state.dart';

import 'package:informasi/src/presentation/bloc/informasi_event.dart';
import 'package:informasi/src/presentation/bloc/informasi_state.dart';

/// Bloc for the Informasi feature.
class InformasiBloc() extends Bloc<InformasiEvent, InformasiState> {
  this : super(const InformasiState.initial()) {
    on<InformasiEvent>(_onEvent);
  }

  Future<void> _onEvent(
    InformasiEvent event,
    Emitter<InformasiState> emit,
  ) async {
    await switch (event) {
      InformasiStarted() || InformasiLoadRequested() => _onLoad(emit),
      InformasiRefreshed() => _onRefresh(emit),
    };
  }

  Future<void> _onLoad(Emitter<InformasiState> emit) async {
    emit(const InformasiState.loading());
    try {
      // TODO(user): Call use case to load data. For a network request,
      // pass an `HttpCancelToken` (network_sdk_api) that `close()` cancels,
      // so closing the Bloc aborts the request. See the network_sdk docs,
      // "Cancelling requests".
      emit(const InformasiState.loaded());
    } catch (e) {
      emit(InformasiState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(Emitter<InformasiState> emit) async {
    // TODO(user): Implement refresh logic.
    await _onLoad(emit);
  }
}
