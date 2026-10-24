import 'package:freezed_annotation/freezed_annotation.dart';

part 'pengaturan_event.freezed.dart';

/// Events for the Pengaturan feature bloc.
@freezed
sealed class PengaturanEvent with _$PengaturanEvent {
  const factory started() = PengaturanStarted;
  const factory loadRequested() = PengaturanLoadRequested;
  const factory refreshed() = PengaturanRefreshed;
}
