import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/datasources/statistic_remote_data_source.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/data/repositories/statistic_repository_impl.dart';
import 'package:statistic/src/domain/exception/statistic_exception.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';
import 'package:statistic/statistic.dart';

import '../../../fixtures/fixtures.dart';

class MockStatisticRemoteDataSource extends Mock
    implements StatisticRemoteDataSource {}

void main() {
  late final StatisticRemoteDataSource mockRemoteDataSource;
  late StatisticRepository repository;

  setUpAll(
    () {
      mockRemoteDataSource = MockStatisticRemoteDataSource();
      registerTestLazySingleton<StatisticRemoteDataSource>(
        mockRemoteDataSource,
      );
      repository = StatisticRepositoryImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'StatisticRepositoryImpl',
    () {
      const errorMessage = 'There is something wrong!';
      group(
        'latest()',
        () {
          late ApiResponseModel<StatisticModel> response;
          late Statistic data;

          setUp(
            () {
              final json = Fixture.jsonFromFixture(
                StatisticFixture.latestStatistic,
              );
              response = ApiResponseModel<StatisticModel>.fromJson(
                json,
                (json) => StatisticModel.fromJson(json! as JSON),
              );
              data = response.data.toEntity();
            },
          );

          test(
            'should return latest statistic of covid-19 when success',
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
                Right<Failure, Statistic>(data),
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

              when(
                () => mockRemoteDataSource.latest(),
              ).thenThrow(
                const StatisticException(
                  message: errorMessage,
                ),
              );

              /// act
              final result = await repository.latest();

              /// assert
              expect(
                result,
                const Left<Failure, Statistic>(
                  StatisticFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.latest(),
              ).called(1);
            },
          );
        },
      );

      group(
        'latestNational()',
        () {
          late ApiResponseModel<StatisticModel> response;
          late Statistic data;

          setUp(
            () {
              final json = Fixture.jsonFromFixture(
                StatisticFixture.latestNationalStatistic,
              );
              response = ApiResponseModel<StatisticModel>.fromJson(
                json,
                (json) => StatisticModel.fromJson(json! as JSON),
              );
              data = response.data.toEntity();
            },
          );

          test(
            'should return latest national statistic of covid-19 when success',
            () async {
              // arrange
              when(
                () => mockRemoteDataSource.latestNational(),
              ).thenAnswer((_) async => response);

              // act
              final result = await repository.latestNational();

              // assert
              expect(
                result,
                Right<Failure, Statistic>(data),
              );
              verify(
                () => mockRemoteDataSource.latestNational(),
              ).called(1);
            },
          );

          test(
            'should return failure when exception occured',
            () async {
              /// arrange

              when(
                () => mockRemoteDataSource.latestNational(),
              ).thenThrow(
                const StatisticException(
                  message: errorMessage,
                ),
              );

              /// act
              final result = await repository.latestNational();

              /// assert
              expect(
                result,
                const Left<Failure, Statistic>(
                  StatisticFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.latestNational(),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
