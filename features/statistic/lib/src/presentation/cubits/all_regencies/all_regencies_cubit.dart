import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/regency_model.dart';
import 'package:statistic/src/domain/domain.dart';

part 'all_regencies_state.dart';
part 'all_regencies_cubit.freezed.dart';

class AllRegenciesCubit extends HydratedCubit<AllRegenciesState> {
  AllRegenciesCubit() : super(AllRegenciesInitial());

  final _usecase = getIt<GetRegenciesByProvince>();

  Future<void> fetch({
    int provinceCode = 72,
  }) async {
    emit(AllRegenciesState.loading());
    final result = await _usecase.call(provinceCode);
    result.fold(
      (l) => emit(
        AllRegenciesState.failed(failure: l),
      ),
      (r) {
        if (r.isEmpty) {
          emit(AllRegenciesState.empty());
        } else {
          emit(AllRegenciesState.loaded(data: r));
        }
      },
    );
  }

  static const String _storageKey = 'regency_by_province';

  @override
  AllRegenciesState? fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_storageKey)) {
      final jsonData = json[_storageKey] as List;
      final data =
          jsonData.map((e) => RegencyModel.fromJson(e as JSON)).toList();
      return AllRegenciesState.loaded(
        data: data.map((e) => e.toEntity()).toList(),
      );
    }

    return null;
  }

  @override
  Map<String, dynamic>? toJson(AllRegenciesState state) {
    if (state is AllRegenciesLoaded) {
      return {
        _storageKey: state.data
            .map(
              (e) => RegencyModel.fromEntity(e).toJson(),
            )
            .toList(),
      };
    }

    return null;
  }
}
