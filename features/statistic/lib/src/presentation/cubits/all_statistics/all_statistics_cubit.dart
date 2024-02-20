import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_all_statistic.dart';
import 'package:statistic/statistic.dart';

part 'all_statistics_state.dart';
part 'all_statistics_cubit.freezed.dart';

class AllStatisticsCubit extends Cubit<AllStatisticsState> {
  AllStatisticsCubit() : super(AllStatisticsState.initial());

  final _usecase = getIt<GetAllStatistic>();

  Future<void> fetch() async {
    emit(AllStatisticsState.loading());
    final result = await _usecase.call(NoParams());
    result.fold(
      (l) => emit(AllStatisticsState.failed(failure: l)),
      (r) => emit(
        AllStatisticsState.loaded(data: r),
      ),
    );
  }
}
