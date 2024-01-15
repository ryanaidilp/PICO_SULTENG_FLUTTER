import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/usecases/get_latest_statistic.dart';
import 'package:statistic/statistic.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetLatestStatistic extends Mock implements GetLatestStatistic {}

void main() {
  late GetLatestStatistic mockUseCase;
  late Statistic data;

  setUpAll(
    () {
      final json = Fixture.jsonFromFixture(
        StatisticFixture.latestStatistic,
      );
      final result = ApiResponseModel<StatisticModel>.fromJson(
        json,
        (json) => StatisticModel.fromJson(json! as JSON),
      );

      data = result.data.toEntity();
      mockUseCase = MockGetLatestStatistic();
      registerTestLazySingleton<GetLatestStatistic>(mockUseCase);
    },
  );

  tearDownAll(unregisterTestInjection);

  const errorMessage = 'There is something wrong!';

  group(
    'LatestStatisticBloc',
    () {
      blocTest<LatestStatisticBloc, LatestStatisticState>(
        'should emit nothing when initialize',
        build: LatestStatisticBloc.new,
        expect: () => <LatestStatisticState>[],
      );

      blocTest<LatestStatisticBloc, LatestStatisticState>(
        'should emit [Loading,Loaded] states when success',
        build: LatestStatisticBloc.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => Right(data),
        ),
        act: (bloc) => bloc.add(LatestStatisticEvent.load()),
        expect: () => <LatestStatisticState>[
          LatestStatisticState.loading(),
          LatestStatisticState.loaded(data: data),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );

      blocTest<LatestStatisticBloc, LatestStatisticState>(
        'should emit [Loading,Failed] states when failed',
        build: LatestStatisticBloc.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => const Left(StatisticFailure(message: errorMessage)),
        ),
        act: (bloc) => bloc.add(LatestStatisticEvent.load()),
        expect: () => <LatestStatisticState>[
          LatestStatisticState.loading(),
          LatestStatisticState.failed(
            failure: const StatisticFailure(message: errorMessage),
          ),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );
    },
  );
}
