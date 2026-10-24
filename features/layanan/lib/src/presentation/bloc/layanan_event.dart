import 'package:freezed_annotation/freezed_annotation.dart';

part 'layanan_event.freezed.dart';

/// Events for the Layanan feature bloc.
@freezed
sealed class LayananEvent with _$LayananEvent {
  const factory started() = LayananStarted;
  const factory loadRequested() = LayananLoadRequested;
  const factory refreshed() = LayananRefreshed;
}
