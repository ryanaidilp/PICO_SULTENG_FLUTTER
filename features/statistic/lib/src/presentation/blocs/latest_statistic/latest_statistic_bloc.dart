import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/statistic.dart';
import 'package:statistic/src/domain/usecases/get_latest_statistic.dart';

part 'latest_statistic_event.dart';
part 'latest_statistic_state.dart';
part 'latest_statistic_bloc.freezed.dart';

class LatestStatisticBloc
    extends Bloc<LatestStatisticEvent, LatestStatisticState> {
  LatestStatisticBloc() : super(LatestStatisticState.initial()) {
    on<LatestStatisticEvent>(
      (event, emit) async {
        if (event is _LoadLatestStatisticEvent) {
          emit(LatestStatisticState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (l) => emit(
              LatestStatisticState.failed(failure: l),
            ),
            (r) => emit(
              LatestStatisticState.loaded(data: r),
            ),
          );
        } 
      },
    );
  }

  final _usecase = getIt<GetLatestStatistic>();

}
