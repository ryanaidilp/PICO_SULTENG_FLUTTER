import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/data.dart';
import 'package:statistic/src/domain/domain.dart';

import '../../../fixtures/fixtures.dart';

class MockStatisticRepository extends Mock implements StatisticRepository {}

void main() {
  late final List<Statistic> data;
  late final StatisticRepository mockRepository;
  late final GetAllStatistic usecase;
  setUpAll(
    () {
      final json = Fixture.jsonFromFixture(StatisticFixture.allStatistic);
      final result = ApiResponseModel<List<StatisticModel>>.fromJson(
        json,
        (json) {
          if (json is! List) {
            return [];
          }

          return json.map((e) => StatisticModel.fromJson(e as JSON)).toList();
        },
      );

      data = result.data.map((e) => e.toEntity()).toList();
      mockRepository = MockStatisticRepository();
      registerTestLazySingleton<StatisticRepository>(mockRepository);
      usecase = GetAllStatistic();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'GetAllStatistic',
    () {
      test(
        'should return list of statistic when success',
        () async {
          // arrange
          when(
            () => mockRepository.all(),
          ).thenAnswer((_) async => Right(data));

          // act
          final result = await usecase.call(NoParams());

          // assert
          expect(result, Right<Failure, List<Statistic>>(data));
          verify(
            () => mockRepository.all(),
          ).called(1);
        },
      );

      test(
        'should return statistic failure when failed',
        () async {
          // arrange
          when(
            () => mockRepository.all(),
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
            const Left<Failure, List<Statistic>>(
              StatisticFailure(message: 'There is something wrong!'),
            ),
          );
          verify(
            () => mockRepository.all(),
          ).called(1);
        },
      );
    },
  );
}
