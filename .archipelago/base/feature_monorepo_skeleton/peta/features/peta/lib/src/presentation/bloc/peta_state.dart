import 'package:freezed_annotation/freezed_annotation.dart';

part 'peta_state.freezed.dart';

/// State for the Peta feature bloc.
@freezed
sealed class PetaState with _$PetaState {
  const factory initial() = PetaInitial;
  const factory loading() = PetaLoading;
  const factory loaded() = PetaLoaded;
  const factory error(String message) = PetaError;
}
