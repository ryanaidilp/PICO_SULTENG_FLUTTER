import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/datasources/covid_test_remote_data_source.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';
import 'package:statistic/src/data/repositories/covid_test_repository_impl.dart';
import 'package:statistic/src/domain/exception/covid_test_exception.dart';
import 'package:statistic/src/domain/failures/covid_test_failure.dart';
import 'package:statistic/src/domain/repositories/covid_test_repository.dart';
import 'package:statistic/statistic.dart';

import '../../../fixtures/fixtures.dart';

class MockCovidTestRemoteDataSource extends Mock
    implements CovidTestRemoteDataSource {}

void main() {
  late final CovidTestRemoteDataSource mockRemoteDataSource;
  late CovidTestRepository repository;

  setUpAll(
    () {
      mockRemoteDataSource = MockCovidTestRemoteDataSource();
      registerTestLazySingleton<CovidTestRemoteDataSource>(
        mockRemoteDataSource,
      );
      repository = CovidTestRepositoryImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'CovidTestRepositoryImpl',
    () {
      group(
        'latest()',
        () {
          late ApiResponseModel<List<CovidTestModel>> response;
          late ApiResponseModel<List<CovidTestModel>> failedResponse;
          late List<CovidTest> data;

          setUp(
            () {
              final json = Fixture.jsonFromFixture(StatisticFixture.covidTest);
              response = ApiResponseModel<List<CovidTestModel>>.fromJson(
                json,
                (json) {
                  if (json is! List) {
                    return [];
                  }

                  return json
                      .map((e) => CovidTestModel.fromJson(e as JSON))
                      .toList();
                },
              );
              data = response.data.map((e) => e.toEntity()).toList();
              final failedJson = Fixture.jsonFromFixture(
                StatisticFixture.failed,
              );
              failedResponse = ApiResponseModel<List<CovidTestModel>>.fromJson(
                failedJson,
                (json) {
                  if (json == null || json is! List) {
                    return [];
                  }

                  return json
                      .map((e) => CovidTestModel.fromJson(e as JSON))
                      .toList();
                },
              );
            },
          );

          test(
            'should return list of covid test when success',
            () async {
              // arrange
              when(
                () => mockRemoteDataSource.latest(),
              ).thenAnswer((_) async => response);

              // act
              final result = await repository.latest();

              // assert
              expect(
                result,
                isA<Right<Failure, List<CovidTest>>>().having(
                  (item) => item.value,
                  'data',
                  data,
                ),
              );
              verify(
                () => mockRemoteDataSource.latest(),
              ).called(1);
            },
          );

          test(
            'should return failure when response not success',
            () async {
              /// arrange
              const errorMessage = 'There is something wrong!';
              when(
                () => mockRemoteDataSource.latest(),
              ).thenAnswer((_) async => failedResponse);

              /// act
              final result = await repository.latest();

              /// assert
              expect(
                result,
                const Left<Failure, List<CovidTest>>(
                  CovidTestFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.latest(),
              ).called(1);
            },
          );

          test(
            'should return failure when exception occured',
            () async {
              /// arrange
              const errorMessage = 'There is something wrong!';
              when(
                () => mockRemoteDataSource.latest(),
              ).thenThrow(
                const CovidTestException(
                  message: errorMessage,
                ),
              );

              /// act
              final result = await repository.latest();

              /// assert
              expect(
                result,
                const Left<Failure, List<CovidTest>>(
                  CovidTestFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.latest(),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
