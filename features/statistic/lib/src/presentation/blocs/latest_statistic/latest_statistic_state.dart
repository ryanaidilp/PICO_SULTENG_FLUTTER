part of 'latest_statistic_bloc.dart';

@freezed
abstract class LatestStatisticState with _$LatestStatisticState {
  factory LatestStatisticState.initial() = LatestStatisticInitialState;
  factory LatestStatisticState.loading() = LatestStatisticLoadingState;
  factory LatestStatisticState.empty() = LatestStatisticEmptyState;
  factory LatestStatisticState.failed({
    required Failure failure,
  }) = LatestStatisticFailedState;
  factory LatestStatisticState.loaded({
    required Statistic data,
  }) = LatestStatisticLoadedState;
}
