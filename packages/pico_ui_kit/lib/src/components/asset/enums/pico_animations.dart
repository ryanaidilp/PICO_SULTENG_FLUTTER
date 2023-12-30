import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoAnimations {
  comingSoon,
  error,
  noInternet,
  success,
  vaccinatedNational,
  vaccinated;

  PicoAssetData get data => switch (this) {
        comingSoon => PicoAssetData(
            path: Assets.animations.comingSoon.path,
          ),
        error => PicoAssetData(
            path: Assets.animations.error.path,
          ),
        noInternet => PicoAssetData(
            path: Assets.animations.noInternet.path,
          ),
        success => PicoAssetData(
            path: Assets.animations.success.path,
          ),
        vaccinatedNational => PicoAssetData(
            path: Assets.animations.vaccinatedNational.path,
          ),
        vaccinated => PicoAssetData(
            path: Assets.animations.vaccinated.path,
          ),
      };
}
