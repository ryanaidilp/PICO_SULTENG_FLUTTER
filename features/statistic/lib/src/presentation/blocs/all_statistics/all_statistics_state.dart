part of 'all_statistics_bloc.dart';

@freezed
abstract class AllStatisticsState with _$AllStatisticsState {
  factory AllStatisticsState.initial() = AllStatisticsInitial;
  factory AllStatisticsState.loading() = AllStatisticsLoading;
  factory AllStatisticsState.empty() = AllStatisticsEmpty;
  factory AllStatisticsState.failed({
    required Failure failure,
  }) = AllStatisticsFailed;
  factory AllStatisticsState.loaded({
    required List<Statistic> data,
  }) = AllStatisticsLoaded;
}
