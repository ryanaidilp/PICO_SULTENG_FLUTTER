import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/data.dart';

import '../../../fixtures/fixtures.dart';

class MockPicoHttpModule extends Mock implements PicoHttpModule {}

void main() {
  late final PicoHttpModule mockHttpModule;
  late final RegencyRemoteDataSource dataSource;

  setUpAll(
    () {
      mockHttpModule = MockPicoHttpModule();
      registerTestLazySingleton<PicoHttpModule>(mockHttpModule);
      dataSource = RegencyRemoteDataSourceImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'RegencyRemoteDataSource',
    () {
      group(
        'fetchRegenciesByProvinceCode()',
        () {
          late ApiResponseModel<List<RegencyModel>> data;
          late JSON response;
          setUp(
            () {
              response =
                  Fixture.jsonFromFixture(StatisticFixture.regenciesByProvince);
              data = ApiResponseModel<List<RegencyModel>>.fromJson(
                response,
                (json) {
                  if (json is! List) {
                    return [];
                  }

                  return json
                      .map((e) => RegencyModel.fromJson(e as JSON))
                      .toList();
                },
              );
            },
          );

          test(
            'should return list of regencies for the given province with '
            'latest data of covid-19 when success',
            () async {
              // arrange
              when(
                () => mockHttpModule.get(
                  ApiEndpoint.regenciesStatisticsByProvince(
                    provinceCode: '72',
                  ),
                ),
              ).thenAnswer((_) async => response);

              // act
              final result = await dataSource.fetchRegenciesByProvinceCode(
                provinceCode: 72,
              );

              // assert
              expect(result, data);
              verify(
                () => mockHttpModule.get(
                  ApiEndpoint.regenciesStatisticsByProvince(
                    provinceCode: '72',
                  ),
                ),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
