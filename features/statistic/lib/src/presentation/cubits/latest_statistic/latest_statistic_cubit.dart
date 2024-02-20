import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_latest_statistic.dart';
import 'package:statistic/statistic.dart';

part 'latest_statistic_state.dart';
part 'latest_statistic_cubit.freezed.dart';

class LatestStatisticCubit extends Cubit<LatestStatisticState> {
  LatestStatisticCubit() : super(LatestStatisticState.initial());

  final _usecase = getIt<GetLatestStatistic>();

  Future<void> fetch() async {
    emit(LatestStatisticState.loading());
    final result = await _usecase.call(NoParams());
    result.fold(
      (l) => emit(LatestStatisticState.failed(failure: l)),
      (r) => emit(LatestStatisticState.loaded(data: r)),
    );
  }
}
