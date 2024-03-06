part of 'latest_national_statistic_cubit.dart';

@freezed
abstract class LatestNationalStatisticState
    with _$LatestNationalStatisticState {
  factory LatestNationalStatisticState.initial() =
      LatestNationalStatisticInitialState;
  factory LatestNationalStatisticState.loading() =
      LatestNationalStatisticLoadingState;
  factory LatestNationalStatisticState.failed({
    required Failure failure,
  }) = LatestNationalStatisticFailedState;
  factory LatestNationalStatisticState.loaded({
    required Statistic data,
  }) = LatestNationalStatisticLoadedState;
}
