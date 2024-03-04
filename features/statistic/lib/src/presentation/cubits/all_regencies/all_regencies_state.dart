part of 'all_regencies_cubit.dart';

@freezed
abstract class AllRegenciesState with _$AllRegenciesState {
  factory AllRegenciesState.initial() = AllRegenciesInitial;
  factory AllRegenciesState.loading() = AllRegenciesLoading;
  factory AllRegenciesState.empty() = AllRegenciesEmpty;
  factory AllRegenciesState.failed({
    required Failure failure,
  }) = AllRegenciesFailed;
  factory AllRegenciesState.loaded({
    required List<Regency> data,
    required double maxValue,
  }) = AllRegenciesLoaded;
}
