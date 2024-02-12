part of 'all_statistics_bloc.dart';

@freezed
abstract class AllStatisticsEvent with _$AllStatisticsEvent {
  factory AllStatisticsEvent.fetch() = _AllStatisticsFetched;
}
