import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/data.dart';
import 'package:statistic/src/domain/domain.dart';

import '../../../fixtures/fixtures.dart';

class MockRegencyRemoteDataSource extends Mock
    implements RegencyRemoteDataSource {}

void main() {
  late final RegencyRemoteDataSource mockRemoteDataSource;
  late RegencyRepository repository;

  setUpAll(
    () {
      mockRemoteDataSource = MockRegencyRemoteDataSource();
      registerTestLazySingleton<RegencyRemoteDataSource>(
        mockRemoteDataSource,
      );
      repository = RegencyRepositoryImpl();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'RegencyRepositoryImpl',
    () {
      group(
        'getRegenciesByProvinceCode()',
        () {
          late ApiResponseModel<List<RegencyModel>> response;
          late ApiResponseModel<List<RegencyModel>> failedResponse;
          late List<Regency> data;

          setUp(
            () {
              final json =
                  Fixture.jsonFromFixture(StatisticFixture.regenciesByProvince);
              response = ApiResponseModel<List<RegencyModel>>.fromJson(
                json,
                (json) {
                  if (json is! List) {
                    return [];
                  }

                  return json
                      .map((e) => RegencyModel.fromJson(e as JSON))
                      .toList();
                },
              );
              data = response.data.map((e) => e.toEntity()).toList();
              final failedJson = Fixture.jsonFromFixture(
                StatisticFixture.failed,
              );
              failedResponse = ApiResponseModel<List<RegencyModel>>.fromJson(
                failedJson,
                (json) {
                  if (json == null || json is! List) {
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
            'should return list of regencies for the given province '
            'with its latest covid-19 situation when success',
            () async {
              // arrange
              when(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).thenAnswer((_) async => response);

              // act
              final result = await repository.getRegenciesByProvinceCode(
                provinceCode: 72,
              );

              // assert
              expect(
                result,
                isA<Right<Failure, List<Regency>>>().having(
                  (item) => item.value,
                  'data',
                  data,
                ),
              );
              verify(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).called(1);
            },
          );

          test(
            'should return failure when response not success',
            () async {
              /// arrange
              const errorMessage = 'There is something wrong!';
              when(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).thenAnswer((_) async => failedResponse);

              /// act
              final result = await repository.getRegenciesByProvinceCode(
                provinceCode: 72,
              );

              /// assert
              expect(
                result,
                const Left<Failure, List<Regency>>(
                  RegencyFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).called(1);
            },
          );

          test(
            'should return failure when exception occured',
            () async {
              /// arrange
              const errorMessage = 'There is something wrong!';
              when(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).thenThrow(
                const RegencyException(
                  message: errorMessage,
                ),
              );

              /// act
              final result = await repository.getRegenciesByProvinceCode(
                provinceCode: 72,
              );

              /// assert
              expect(
                result,
                const Left<Failure, List<Regency>>(
                  RegencyFailure(message: errorMessage),
                ),
              );
              verify(
                () => mockRemoteDataSource.fetchRegenciesByProvinceCode(
                  provinceCode: 72,
                ),
              ).called(1);
            },
          );
        },
      );
    },
  );
}
