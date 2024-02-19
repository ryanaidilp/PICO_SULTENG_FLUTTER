import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/usecases/get_latest_covid_test.dart';
import 'package:statistic/statistic.dart';

part 'latest_covid_test_state.dart';
part 'latest_covid_test_cubit.freezed.dart';

class LatestCovidTestCubit extends Cubit<LatestCovidTestState> {
  LatestCovidTestCubit() : super(LatestCovidTestState.initial());

  final _usecase = getIt<GetLatestCovidTest>();

  Future<void> fetch() async {
    emit(LatestCovidTestState.loading());
    final result = await _usecase.call(NoParams());
    result.fold(
      (l) => emit(LatestCovidTestState.failed(failure: l)),
      (r) {
        if (r.isEmpty) {
          emit(LatestCovidTestState.empty());
        } else {
          emit(
            LatestCovidTestState.loaded(
              data: r,
              total: r.fold(
                0,
                (
                  previousValue,
                  element,
                ) =>
                    previousValue + element.total,
              ),
            ),
          );
        }
      },
    );
  }
}
