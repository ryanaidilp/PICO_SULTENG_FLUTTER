part of 'banner_bloc.dart';

@freezed
abstract class BannerState with _$BannerState {
  factory BannerState.initial() = BannerInitialState;
  factory BannerState.loading() = BannerLoadingState;
  factory BannerState.loaded({
    required List<Banner> data,
  }) = BannerLoadedState;
  factory BannerState.failed({
    required Failure failure,
  }) = BannerFailedState;
}
