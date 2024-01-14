import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/failures/statistic_failure.dart';
import 'package:statistic/src/domain/repositories/statistic_repository.dart';
import 'package:statistic/src/domain/usecases/get_latest_national_statistic.dart';
import 'package:statistic/statistic.dart';

import '../../../fixtures/fixtures.dart';

class MockStatisticRepository extends Mock implements StatisticRepository {}

void main() {
  late final Statistic data;
  late final StatisticRepository mockRepository;
  late final GetLatestNationalStatistic usecase;
  setUpAll(
    () {
      final json =
          Fixture.jsonFromFixture(StatisticFixture.latestNationalStatistic);
      final result = ApiResponseModel<StatisticModel?>.fromJson(
        json,
        (json) => json == null ? null : StatisticModel.fromJson(json as JSON),
      );
      data = result.data?.toEntity() ?? Statistic();
      mockRepository = MockStatisticRepository();
      registerTestLazySingleton<StatisticRepository>(mockRepository);
      usecase = GetLatestNationalStatistic();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'GetLatestNationalStatistic',
    () {
      test(
        'should return latest national covid-19 statistic when success',
        () async {
          // arrange
          when(
            () => mockRepository.latestNational(),
          ).thenAnswer((_) async => Right(data));

          // act
          final result = await usecase.call(NoParams());

          // assert
          expect(result, Right<Failure, Statistic>(data));
          verify(
            () => mockRepository.latestNational(),
          ).called(1);
        },
      );

      test(
        'should return statistic failure when failed',
        () async {
          // arrange
          when(
            () => mockRepository.latestNational(),
          ).thenAnswer(
            (_) async => const Left(
              StatisticFailure(message: 'There is something wrong!'),
            ),
          );

          // act
          final result = await usecase.call(NoParams());

          // assert
          expect(
            result,
            const Left<Failure, Statistic>(
              StatisticFailure(message: 'There is something wrong!'),
            ),
          );
          verify(
            () => mockRepository.latestNational(),
          ).called(1);
        },
      );
    },
  );
}
