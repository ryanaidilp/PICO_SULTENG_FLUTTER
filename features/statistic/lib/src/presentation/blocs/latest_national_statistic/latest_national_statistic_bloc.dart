import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_latest_national_statistic.dart';
import 'package:statistic/statistic.dart';

part 'latest_national_statistic_event.dart';
part 'latest_national_statistic_state.dart';
part 'latest_national_statistic_bloc.freezed.dart';

class LatestNationalStatisticBloc
    extends Bloc<LatestNationalStatisticEvent, LatestNationalStatisticState> {
  LatestNationalStatisticBloc()
      : super(LatestNationalStatisticState.initial()) {
    on<LatestNationalStatisticEvent>(
      (event, emit) async {
        if (event is _LoadLatestNationalStatisticEvent) {
          emit(LatestNationalStatisticState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (l) => emit(
              LatestNationalStatisticState.failed(failure: l),
            ),
            (r) => emit(
              LatestNationalStatisticState.loaded(data: r),
            ),
          );
        }
      },
    );
  }

  final _usecase = getIt<GetLatestNationalStatistic>();
}
