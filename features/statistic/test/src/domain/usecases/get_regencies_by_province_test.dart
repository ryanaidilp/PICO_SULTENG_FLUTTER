import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/regency_model.dart';
import 'package:statistic/src/domain/domain.dart';

import '../../../fixtures/fixtures.dart';

class MockRegencyRepository extends Mock implements RegencyRepository {}

void main() {
  late final List<Regency> data;
  late final RegencyRepository mockRepository;
  late final GetRegenciesByProvince usecase;
  setUpAll(
    () {
      final json =
          Fixture.jsonFromFixture(StatisticFixture.regenciesByProvince);
      final result = ApiResponseModel<List<RegencyModel>>.fromJson(
        json,
        (json) {
          if (json is! List) {
            return [];
          }

          return json.map((e) => RegencyModel.fromJson(e as JSON)).toList();
        },
      );
      data = result.data.map((e) => e.toEntity()).toList();
      mockRepository = MockRegencyRepository();
      registerTestLazySingleton<RegencyRepository>(mockRepository);
      usecase = GetRegenciesByProvince();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'GetRegenciesByProvince',
    () {
      test(
        'should return list of regencies in the given province with'
        ' latest covid-19 situation when success',
        () async {
          // arrange
          when(
            () => mockRepository.getRegenciesByProvinceCode(
              provinceCode: 72,
            ),
          ).thenAnswer((_) async => Right(data));

          // act
          final result = await usecase.call(72);

          // assert
          expect(result, Right<Failure, List<Regency>>(data));
          verify(
            () => mockRepository.getRegenciesByProvinceCode(
              provinceCode: 72,
            ),
          ).called(1);
        },
      );

      test(
        'should return regency failure when failed',
        () async {
          // arrange
          when(
            () => mockRepository.getRegenciesByProvinceCode(
              provinceCode: 72,
            ),
          ).thenAnswer(
            (_) async => const Left(
              RegencyFailure(message: 'There is something wrong!'),
            ),
          );

          // act
          final result = await usecase.call(72);

          // assert
          expect(
            result,
            const Left<Failure, List<Regency>>(
              RegencyFailure(message: 'There is something wrong!'),
            ),
          );
          verify(
            () => mockRepository.getRegenciesByProvinceCode(
              provinceCode: 72,
            ),
          ).called(1);
        },
      );
    },
  );
}
