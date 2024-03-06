import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/datasources/covid_test_remote_data_source.dart';
import 'package:statistic/src/data/models/covid_test_model.dart';

import '../../../fixtures/fixtures.dart';

class MockPicoHttpModule extends Mock implements PicoHttpModule {}

void main() {
  late final PicoHttpModule mockHttpModule;
  late final CovidTestRemoteDataSource dataSource;

  setUpAll(
    () {
      mockHttpModule = MockPicoHttpModule();
      registerTestLazySingleton<PicoHttpModule>(mockHttpModule);
      dataSource = CovidTestRemoteDataSourceImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'CovidTestRemoteDataSource',
    () {
      group(
        'latest()',
        () {
          late ApiResponseModel<List<CovidTestModel>> data;
          late JSON response;
          setUp(
            () {
              response = Fixture.jsonFromFixture(StatisticFixture.covidTest);
              data = ApiResponseModel<List<CovidTestModel>>.fromJson(
                response,
                (json) {
                  if (json is! List) {
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
                () => mockHttpModule.get(ApiEndpoint.testLatest()),
              ).thenAnswer((_) async => response);

              // act
              final result = await dataSource.latest();

              // assert
              expect(result, data);
              verify(
                () => mockHttpModule.get(ApiEndpoint.testLatest()),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
