import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/covid_test.dart';
import 'package:statistic/src/domain/usecases/get_latest_covid_test.dart';

part 'latest_covid_test_event.dart';
part 'latest_covid_test_state.dart';
part 'latest_covid_test_bloc.freezed.dart';

class LatestCovidTestBloc
    extends Bloc<LatestCovidTestEvent, LatestCovidTestState> {
  LatestCovidTestBloc() : super(LatestCovidTestState.initial()) {
    on<LatestCovidTestEvent>(
      (event, emit) async {
        if (event is _LoadLatestCovidTestEvent) {
          emit(LatestCovidTestState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (l) => emit(
              LatestCovidTestState.failed(
                failure: l,
              ),
            ),
            (r) => r.isEmpty
                ? emit(LatestCovidTestState.empty())
                : emit(
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
                  ),
          );
        }
      },
    );
  }

  final _usecase = getIt<GetLatestCovidTest>();
}
