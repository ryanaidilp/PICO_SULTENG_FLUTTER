import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/usecases/get_latest_covid_test.dart';
import 'package:statistic/statistic.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetLatestCovidTest extends Mock implements GetLatestCovidTest {}

void main() {
  late GetLatestCovidTest mockUseCase;
  late List<CovidTest> data;
  late int total;

  setUpAll(
    () {
      final json = Fixture.jsonFromFixture(StatisticFixture.covidTest);
      final result = ApiResponseModel<List<CovidTestModel>>.fromJson(
        json,
        (json) => (json! as List)
            .map((e) => CovidTestModel.fromJson(e as JSON))
            .toList(),
      );
      total = result.data.fold(
        0,
        (previousValue, element) => previousValue + element.total,
      );
      data = result.data.map((e) => e.toEntity()).toList();
      mockUseCase = MockGetLatestCovidTest();
      registerTestLazySingleton<GetLatestCovidTest>(mockUseCase);
    },
  );

  tearDownAll(unregisterTestInjection);

  const errorMessage = 'There is something wrong!';

  group(
    'LatestCovidTestBloc',
    () {
      blocTest<LatestCovidTestBloc, LatestCovidTestState>(
        'should emit nothing when initialize',
        build: LatestCovidTestBloc.new,
        expect: () => <LatestCovidTestState>[],
      );

      blocTest<LatestCovidTestBloc, LatestCovidTestState>(
        'should emit [Loading,Loaded] states when success',
        build: LatestCovidTestBloc.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => Right(data),
        ),
        act: (bloc) => bloc.add(LatestCovidTestEvent.load()),
        expect: () => <LatestCovidTestState>[
          LatestCovidTestState.loading(),
          LatestCovidTestState.loaded(data: data, total: total),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );

      blocTest<LatestCovidTestBloc, LatestCovidTestState>(
        'should emit [Loading,Empty] states when success and data empty',
        build: LatestCovidTestBloc.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => const Right([]),
        ),
        act: (bloc) => bloc.add(LatestCovidTestEvent.load()),
        expect: () => <LatestCovidTestState>[
          LatestCovidTestState.loading(),
          LatestCovidTestState.empty(),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );

      blocTest<LatestCovidTestBloc, LatestCovidTestState>(
        'should emit [Loading,Failed] states when failed',
        build: LatestCovidTestBloc.new,
        setUp: () => when(() => mockUseCase.call(NoParams())).thenAnswer(
          (_) async => const Left(StatisticFailure(message: errorMessage)),
        ),
        act: (bloc) => bloc.add(LatestCovidTestEvent.load()),
        expect: () => <LatestCovidTestState>[
          LatestCovidTestState.loading(),
          LatestCovidTestState.failed(
            failure: const StatisticFailure(message: errorMessage),
          ),
        ],
        verify: (_) => verify(() => mockUseCase.call(NoParams())),
      );
    },
  );
}
