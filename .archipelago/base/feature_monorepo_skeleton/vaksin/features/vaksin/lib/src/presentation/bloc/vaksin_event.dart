import 'package:freezed_annotation/freezed_annotation.dart';

part 'vaksin_event.freezed.dart';

/// Events for the Vaksin feature bloc.
@freezed
sealed class VaksinEvent with _$VaksinEvent {
  const factory started() = VaksinStarted;
  const factory loadRequested() = VaksinLoadRequested;
  const factory refreshed() = VaksinRefreshed;
}
