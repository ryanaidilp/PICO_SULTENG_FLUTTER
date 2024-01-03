part of 'latest_national_statistic_bloc.dart';

@freezed
abstract class LatestNationalStatisticState
    with _$LatestNationalStatisticState {
  factory LatestNationalStatisticState.initial() =
      LatestNationalStatisticInitialState;
  factory LatestNationalStatisticState.loading() =
      LatestNationalStatisticLoadingState;
  factory LatestNationalStatisticState.failed({required Failure failure}) =
      LatestNationalStatisticFailedState;
  factory LatestNationalStatisticState.loaded({
    required Statistic data,
  }) = LatestNationalStatisticLoadedState;
}
