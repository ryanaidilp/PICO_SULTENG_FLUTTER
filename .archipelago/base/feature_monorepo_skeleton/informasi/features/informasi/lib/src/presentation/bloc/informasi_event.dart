import 'package:freezed_annotation/freezed_annotation.dart';

part 'informasi_event.freezed.dart';

/// Events for the Informasi feature bloc.
@freezed
sealed class InformasiEvent with _$InformasiEvent {
  const factory started() = InformasiStarted;
  const factory loadRequested() = InformasiLoadRequested;
  const factory refreshed() = InformasiRefreshed;
}
