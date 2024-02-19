import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/usecases/get_latest_national_statistic.dart';
import 'package:statistic/statistic.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetLatestNationalStatistic extends Mock
    implements GetLatestNationalStatistic {}

void main() {
  late GetLatestNationalStatistic mockUseCase;
  late Statistic data;

  setUpAll(
    () {
      final json = Fixture.jsonFromFixture(
        StatisticFixture.latestNationalStatistic,
      );
      final result = ApiResponseModel<StatisticModel>.fromJson(
        json,
        (json) => StatisticModel.fromJson(json! as JSON),
      );

      data = result.data.toEntity();
      mockUseCase = MockGetLatestNationalStatistic();
      registerTestLazySingleton<GetLatestNationalStatistic>(mockUseCase);
    },
  );

  tearDownAll(unregisterTestInjection);

  const errorMessage = 'There is something wrong!';

  group(
    'LatestNationalStatisticCubit',
    () {
      blocTest<LatestNationalStatisticCubit, LatestNationalStatisticState>(
        'should emit nothing when initialize',
        build: LatestNationalStatisticCubit.new,
        expect: () => <LatestNationalStatisticState>[],
      );

      blocTest<LatestNationalStatisticCubit, LatestNationalStatisticState>(
        'should emit [Loading,Loaded] states when success',
        build: LatestNationalStatisticCubit.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => Right(data),
        ),
        act: (cubit) => cubit.fetch(),
        expect: () => <LatestNationalStatisticState>[
          LatestNationalStatisticState.loading(),
          LatestNationalStatisticState.loaded(data: data),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );

      blocTest<LatestNationalStatisticCubit, LatestNationalStatisticState>(
        'should emit [Loading,Failed] states when failed',
        build: LatestNationalStatisticCubit.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => const Left(StatisticFailure(message: errorMessage)),
        ),
        act: (cubit) => cubit.fetch(),
        expect: () => <LatestNationalStatisticState>[
          LatestNationalStatisticState.loading(),
          LatestNationalStatisticState.failed(
            failure: const StatisticFailure(message: errorMessage),
          ),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );
    },
  );
}
