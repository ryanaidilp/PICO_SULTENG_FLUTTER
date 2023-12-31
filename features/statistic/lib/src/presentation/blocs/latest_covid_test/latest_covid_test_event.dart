part of 'latest_covid_test_bloc.dart';

@freezed
abstract class LatestCovidTestEvent with _$LatestCovidTestEvent {
  factory LatestCovidTestEvent.load() = _LoadLatestCovidTestEvent;
}
