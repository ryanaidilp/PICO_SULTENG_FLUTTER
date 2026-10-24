import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistik_state.freezed.dart';

/// State for the Statistik feature bloc.
@freezed
sealed class StatistikState with _$StatistikState {
  const factory initial() = StatistikInitial;
  const factory loading() = StatistikLoading;
  const factory loaded() = StatistikLoaded;
  const factory error(String message) = StatistikError;
}
