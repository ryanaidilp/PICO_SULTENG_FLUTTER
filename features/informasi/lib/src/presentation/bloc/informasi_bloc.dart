import 'package:dependencies/state.dart';
import 'package:informasi/src/domain/tip_source.dart';
import 'package:informasi/src/presentation/bloc/informasi_event.dart';
import 'package:informasi/src/presentation/bloc/informasi_state.dart';

/// Loads the bundled articles once.
class InformasiBloc extends Bloc<InformasiEvent, InformasiState> {
  new(this._source) : super(const InformasiState()) {
    on<TipsStarted>((e, emit) async {
      emit(InformasiState(tips: await loadTips(_source)));
    });
  }

  final TipSource _source;
}
