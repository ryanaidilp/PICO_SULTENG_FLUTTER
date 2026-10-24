import 'package:freezed_annotation/freezed_annotation.dart';

part 'pengaturan_state.freezed.dart';

/// State for the Pengaturan feature bloc.
@freezed
sealed class PengaturanState with _$PengaturanState {
  const factory initial() = PengaturanInitial;
  const factory loading() = PengaturanLoading;
  const factory loaded() = PengaturanLoaded;
  const factory error(String message) = PengaturanError;
}
