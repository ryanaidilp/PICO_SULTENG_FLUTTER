import 'package:freezed_annotation/freezed_annotation.dart';

part 'vaksin_state.freezed.dart';

/// State for the Vaksin feature bloc.
@freezed
sealed class VaksinState with _$VaksinState {
  const factory initial() = VaksinInitial;
  const factory loading() = VaksinLoading;
  const factory loaded() = VaksinLoaded;
  const factory error(String message) = VaksinError;
}
