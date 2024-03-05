import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statistic/src/data/data.dart';
import 'package:statistic/src/domain/domain.dart';
import 'package:statistic/src/presentation/cubits/all_regencies/all_regencies_cubit.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetRegenciesByProvince extends Mock
    implements GetRegenciesByProvince {}

class MockStorage extends Mock implements Storage {}

void main() {
  late GetRegenciesByProvince mockUseCase;
  late List<Regency> data;
  late Storage hydratedStorage;

  setUpAll(
    () {
      final json =
          Fixture.jsonFromFixture(StatisticFixture.regenciesByProvince);
      final result = ApiResponseModel<List<RegencyModel>>.fromJson(
        json,
        (json) => (json! as List)
            .map((e) => RegencyModel.fromJson(e as JSON))
            .toList(),
      );
      data = result.data.map((e) => e.toEntity()).toList();
      mockUseCase = MockGetRegenciesByProvince();
      registerTestLazySingleton<GetRegenciesByProvince>(mockUseCase);
      TestWidgetsFlutterBinding.ensureInitialized();
      hydratedStorage = MockStorage();
      when(
        () => hydratedStorage.write(any(), any<dynamic>()),
      ).thenAnswer((_) async {});
      HydratedBloc.storage = hydratedStorage;
    },
  );

  tearDownAll(unregisterTestInjection);

  const errorMessage = 'There is something wrong!';

  group(
    'AllRegenciesCubit',
    () {
      blocTest<AllRegenciesCubit, AllRegenciesState>(
        'should emit nothing when initialize',
        build: AllRegenciesCubit.new,
        expect: () => <AllRegenciesState>[],
      );

      blocTest<AllRegenciesCubit, AllRegenciesState>(
        'should emit [Loading,Loaded] states when success',
        build: AllRegenciesCubit.new,
        setUp: () => when(() => mockUseCase.call(72)).thenAnswer(
          (_) async => Right(data),
        ),
        act: (cubit) => cubit.fetch(),
        expect: () => <AllRegenciesState>[
          AllRegenciesState.loading(),
          AllRegenciesState.loaded(
            data: data,
            maxValue: data
                .map((e) => e.newCase.underTreatment.toDouble())
                .reduce(max),
          ),
        ],
        verify: (_) => verify(() => mockUseCase.call(72)),
      );

      blocTest<AllRegenciesCubit, AllRegenciesState>(
        'should emit [Loading,Empty] states when success and data empty',
        build: AllRegenciesCubit.new,
        setUp: () => when(() => mockUseCase.call(72)).thenAnswer(
          (_) async => const Right([]),
        ),
        act: (cubit) => cubit.fetch(),
        expect: () => <AllRegenciesState>[
          AllRegenciesState.loading(),
          AllRegenciesState.empty(),
        ],
        verify: (_) => verify(() => mockUseCase.call(72)),
      );

      blocTest<AllRegenciesCubit, AllRegenciesState>(
        'should emit [Loading,Failed] states when failed',
        build: AllRegenciesCubit.new,
        setUp: () => when(() => mockUseCase.call(72)).thenAnswer(
          (_) async => const Left(RegencyFailure(message: errorMessage)),
        ),
        act: (cubit) => cubit.fetch(),
        expect: () => <AllRegenciesState>[
          AllRegenciesState.loading(),
          AllRegenciesState.failed(
            failure: const RegencyFailure(message: errorMessage),
          ),
        ],
        verify: (_) => verify(() => mockUseCase.call(72)),
      );
    },
  );
}
