import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_event.freezed.dart';

/// Events for the Home feature bloc.
@freezed
sealed class HomeEvent with _$HomeEvent {
  const factory started() = HomeStarted;
  const factory loadRequested() = HomeLoadRequested;
  const factory refreshed() = HomeRefreshed;
}
