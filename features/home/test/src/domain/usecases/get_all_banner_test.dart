import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:home/src/data/models/banner_model.dart';
import 'package:home/src/domain/entities/banner.dart';
import 'package:home/src/domain/failures/banner_failure.dart';
import 'package:home/src/domain/repositories/banner_repository.dart';
import 'package:home/src/domain/usecases/get_all_banner.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixture.dart';

class MockBannerRepository extends Mock implements BannerRepository {}

void main() {
  late BannerRepository mockRepository;
  late GetAllBanner usecase;
  late List<Banner> data;

  setUpAll(
    () {
      mockRepository = MockBannerRepository();
      registerTestLazySingleton<BannerRepository>(mockRepository);
      usecase = GetAllBanner();

      final json = Fixture.jsonFromFixture(BannerFixture.data);
      final response = ApiResponseModel<List<BannerModel>>.fromJson(
        json,
        (json) {
          if (json is! List) {
            return [];
          }

          return json.map((e) => BannerModel.fromJson(e as JSON)).toList();
        },
      );
      data = response.data.map((e) => e.toEntity()).toList();
    },
  );

  tearDownAll(unregisterTestInjection);

  group(
    'GetAllBanner',
    () {
      test(
        'should return list of banners if call success',
        () async {
          when(
            () => mockRepository.get(),
          ).thenAnswer((_) async => Right(data));

          // act
          final result = await usecase(
            NoParams(),
          );

          // assert
          expect(
            result,
            equals(
              Right<Failure, List<Banner>>(data),
            ),
          );
          verify(
            () => mockRepository.get(),
          ).called(1);
        },
      );

      test(
        'should return failure if exception if failed ',
        () async {
          // arrange
          when(
            () => mockRepository.get(),
          ).thenAnswer(
            (_) async => const Left(
              BannerFailure(message: 'Error'),
            ),
          );

          // act
          final result = await usecase(
            NoParams(),
          );

          // assert
          expect(
            result,
            equals(
              const Left<Failure, List<Banner>>(
                BannerFailure(message: 'Error'),
              ),
            ),
          );
          verify(
            () => mockRepository.get(),
          );
        },
      );
    },
  );
}
