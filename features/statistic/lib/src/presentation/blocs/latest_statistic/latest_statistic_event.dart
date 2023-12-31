part of 'latest_statistic_bloc.dart';

@freezed
abstract class LatestStatisticEvent with _$LatestStatisticEvent {
  factory LatestStatisticEvent.load() = _LoadLatestStatisticEvent;

}
