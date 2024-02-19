import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_all_statistic.dart';
import 'package:statistic/statistic.dart';

part 'all_statistics_event.dart';
part 'all_statistics_state.dart';
part 'all_statistics_bloc.freezed.dart';

class AllStatisticsBloc extends Bloc<AllStatisticsEvent, AllStatisticsState> {
  AllStatisticsBloc() : super(AllStatisticsState.initial()) {
    on<AllStatisticsEvent>(
      (event, emit) async {
        if (event is _AllStatisticsFetched) {
          emit(AllStatisticsState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (l) => emit(AllStatisticsState.failed(failure: l)),
            (r) => emit(AllStatisticsState.loaded(data: r)),
          );
        }
      },
    );
  }

  final _usecase = getIt<GetAllStatistic>();
}
