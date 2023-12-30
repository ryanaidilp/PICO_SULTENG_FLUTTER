part of 'banner_bloc.dart';

@freezed
abstract class BannerEvent with _$BannerEvent {
  factory BannerEvent.load() = _LoadBannerEvent;
}
