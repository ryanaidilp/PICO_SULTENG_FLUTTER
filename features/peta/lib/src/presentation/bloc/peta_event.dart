import 'package:freezed_annotation/freezed_annotation.dart';

part 'peta_event.freezed.dart';

/// Events for the Peta feature bloc.
@freezed
sealed class PetaEvent with _$PetaEvent {
  const factory started() = PetaStarted;
  const factory loadRequested() = PetaLoadRequested;
  const factory refreshed() = PetaRefreshed;
}
