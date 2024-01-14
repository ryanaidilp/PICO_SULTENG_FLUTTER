import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/datasources/statistic_remote_data_source.dart';
import 'package:statistic/src/data/models/statistic_model.dart';

import '../../../fixtures/fixtures.dart';

class MockPicoHttpModule extends Mock implements PicoHttpModule {}

void main() {
  late final PicoHttpModule mockHttpModule;
  late final StatisticRemoteDataSource dataSource;

  setUpAll(
    () {
      mockHttpModule = MockPicoHttpModule();
      registerTestLazySingleton<PicoHttpModule>(mockHttpModule);
      dataSource = StatisticRemoteDataSourceImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'StatisticRemoteDataSource',
    () {
      group(
        'latest()',
        () {
          late ApiResponseModel<StatisticModel> data;
          late JSON response;
          setUp(
            () {
              response =
                  Fixture.jsonFromFixture(StatisticFixture.latestStatistic);
              data = ApiResponseModel<StatisticModel>.fromJson(
                response,
                (json) => StatisticModel.fromJson(json! as JSON),
              );
            },
          );

          test(
            'should return latest data of covid-19 when success',
            () async {
              // arrange
              when(
                () => mockHttpModule.get(ApiEndpoint.latestProvince()),
              ).thenAnswer((_) async => response);

              // act
              final result = await dataSource.latest();

              // assert
              expect(result, data);
              verify(
                () => mockHttpModule.get(ApiEndpoint.latestProvince()),
              ).called(1);
            },
          );
        },
      );

      group(
        'latestNational()',
        () {
          late ApiResponseModel<StatisticModel> data;
          late JSON response;
          setUp(
            () {
              response = Fixture.jsonFromFixture(
                StatisticFixture.latestNationalStatistic,
              );
              data = ApiResponseModel<StatisticModel>.fromJson(
                response,
                (json) => StatisticModel.fromJson(json! as JSON),
              );
            },
          );

          test(
            'should return latest national data of covid-19 when success',
            () async {
              // arrange
              when(
                () => mockHttpModule.get(ApiEndpoint.latest()),
              ).thenAnswer((_) async => response);

              // act
              final result = await dataSource.latestNational();

              // assert
              expect(result, data);
              verify(
                () => mockHttpModule.get(ApiEndpoint.latest()),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
