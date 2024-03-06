import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_latest_national_statistic.dart';
import 'package:statistic/statistic.dart';

part 'latest_national_statistic_state.dart';
part 'latest_national_statistic_cubit.freezed.dart';

class LatestNationalStatisticCubit extends Cubit<LatestNationalStatisticState> {
  LatestNationalStatisticCubit()
      : super(
          LatestNationalStatisticState.initial(),
        );

  final _usecase = getIt<GetLatestNationalStatistic>();

  Future<void> fetch() async {
    emit(LatestNationalStatisticState.loading());
    final result = await _usecase.call(NoParams());
    result.fold(
      (l) => emit(LatestNationalStatisticState.failed(failure: l)),
      (r) => emit(LatestNationalStatisticState.loaded(data: r)),
    );
  }
}
