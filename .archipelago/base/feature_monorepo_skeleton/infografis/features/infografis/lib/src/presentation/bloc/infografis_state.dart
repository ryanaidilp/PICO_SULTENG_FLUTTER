import 'package:freezed_annotation/freezed_annotation.dart';

part 'infografis_state.freezed.dart';

/// State for the Infografis feature bloc.
@freezed
sealed class InfografisState with _$InfografisState {
  const factory initial() = InfografisInitial;
  const factory loading() = InfografisLoading;
  const factory loaded() = InfografisLoaded;
  const factory error(String message) = InfografisError;
}
