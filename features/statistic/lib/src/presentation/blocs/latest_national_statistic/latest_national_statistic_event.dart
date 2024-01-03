part of 'latest_national_statistic_bloc.dart';

@freezed
abstract class LatestNationalStatisticEvent
    with _$LatestNationalStatisticEvent {
  factory LatestNationalStatisticEvent.load() =
      _LoadLatestNationalStatisticEvent;
}
