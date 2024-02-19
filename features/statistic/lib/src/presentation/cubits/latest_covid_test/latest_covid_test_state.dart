part of 'latest_covid_test_cubit.dart';

@freezed
abstract class LatestCovidTestState with _$LatestCovidTestState {
  factory LatestCovidTestState.initial() = LatestCovidTestInitialState;
  factory LatestCovidTestState.loading() = LatestCovidTestLoadingState;
  factory LatestCovidTestState.empty() = LatestCovidTestEmptyState;
  factory LatestCovidTestState.failed({
    required Failure failure,
  }) = LatestCovidTestFailedState;
  factory LatestCovidTestState.loaded({
    required List<CovidTest> data,
    required int total,
  }) = LatestCovidTestLoadedState;
}
