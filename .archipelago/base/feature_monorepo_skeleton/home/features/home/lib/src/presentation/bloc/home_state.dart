import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

/// State for the Home feature bloc.
@freezed
sealed class HomeState with _$HomeState {
  const factory initial() = HomeInitial;
  const factory loading() = HomeLoading;
  const factory loaded() = HomeLoaded;
  const factory error(String message) = HomeError;
}
