import 'package:freezed_annotation/freezed_annotation.dart';

part 'layanan_state.freezed.dart';

/// State for the Layanan feature bloc.
@freezed
sealed class LayananState with _$LayananState {
  const factory initial() = LayananInitial;
  const factory loading() = LayananLoading;
  const factory loaded() = LayananLoaded;
  const factory error(String message) = LayananError;
}
