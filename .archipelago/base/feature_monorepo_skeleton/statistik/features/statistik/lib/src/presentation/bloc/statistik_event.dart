import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistik_event.freezed.dart';

/// Events for the Statistik feature bloc.
@freezed
sealed class StatistikEvent with _$StatistikEvent {
  const factory started() = StatistikStarted;
  const factory loadRequested() = StatistikLoadRequested;
  const factory refreshed() = StatistikRefreshed;
}
