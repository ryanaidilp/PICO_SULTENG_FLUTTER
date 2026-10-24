import 'package:freezed_annotation/freezed_annotation.dart';

part 'infografis_event.freezed.dart';

/// Events for the Infografis feature bloc.
@freezed
sealed class InfografisEvent with _$InfografisEvent {
  const factory started() = InfografisStarted;
  const factory loadRequested() = InfografisLoadRequested;
  const factory refreshed() = InfografisRefreshed;
}
