part of 'all_national_statistics_cubit.dart';

@freezed
abstract class AllNationalStatisticsState with _$AllNationalStatisticsState {
  factory AllNationalStatisticsState.initial() = AllNationalStatisticsInitial;
  factory AllNationalStatisticsState.loading() = AllNationalStatisticsLoading;
  factory AllNationalStatisticsState.empty() = AllNationalStatisticsEmpty;
  factory AllNationalStatisticsState.failed({
    required Failure failure,
  }) = AllNationalStatisticsFailed;
  factory AllNationalStatisticsState.loaded({
    required List<Statistic> data,
  }) = AllNationalStatisticsLoaded;
}
