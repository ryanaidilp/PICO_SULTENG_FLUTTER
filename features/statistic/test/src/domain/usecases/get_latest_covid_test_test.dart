import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';
import 'package:statistic/src/domain/failures/covid_test_failure.dart';
import 'package:statistic/src/domain/repositories/covid_test_repository.dart';
import 'package:statistic/src/domain/usecases/get_latest_covid_test.dart';
import 'package:statistic/statistic.dart';

import '../../../fixtures/fixtures.dart';

class MockCovidTestRepository extends Mock implements CovidTestRepository {}

void main() {
  late final List<CovidTest> data;
  late final CovidTestRepository mockRepository;
  late final GetLatestCovidTest usecase;
  setUpAll(
    () {
      final json = Fixture.jsonFromFixture(StatisticFixture.covidTest);
      final result = ApiResponseModel<List<CovidTestModel>>.fromJson(
        json,
        (json) {
          if (json is! List) {
            return [];
          }

          return json.map((e) => CovidTestModel.fromJson(e as JSON)).toList();
        },
      );

      data = result.data.map((e) => e.toEntity()).toList();
      mockRepository = MockCovidTestRepository();
      registerTestLazySingleton<CovidTestRepository>(mockRepository);
      usecase = GetLatestCovidTest();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'GetLatestCovidTest',
    () {
      test(
        'should return list of covid test when success',
        () async {
          // arrange
          when(
            () => mockRepository.latest(),
          ).thenAnswer((_) async => Right(data));

          // act
          final result = await usecase.call(NoParams());

          // assert
          expect(result, Right<Failure, List<CovidTest>>(data));
          verify(
            () => mockRepository.latest(),
          ).called(1);
        },
      );

      test(
        'should return covid test failure when failed',
        () async {
          // arrange
          when(
            () => mockRepository.latest(),
          ).thenAnswer(
            (_) async => const Left(
              CovidTestFailure(message: 'There is something wrong!'),
            ),
          );

          // act
          final result = await usecase.call(NoParams());

          // assert
          expect(
            result,
            const Left<Failure, List<CovidTest>>(
              CovidTestFailure(message: 'There is something wrong!'),
            ),
          );
          verify(
            () => mockRepository.latest(),
          ).called(1);
        },
      );
    },
  );
}
