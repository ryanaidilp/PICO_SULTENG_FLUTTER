import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_asset_extension.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoAnimations {
  comingSoon,
  error,
  noInternet,
  success,
  vaccinatedNational,
  vaccinated;

  PicoAssetData<LottieGenImage> get data => switch (this) {
        comingSoon => PicoAssetData<LottieGenImage>(
            file: Assets.animations.comingSoon,
            extension: PicoAssetExtension.lottie,
          ),
        error => PicoAssetData<LottieGenImage>(
            file: Assets.animations.error,
            extension: PicoAssetExtension.lottie,
          ),
        noInternet => PicoAssetData<LottieGenImage>(
            file: Assets.animations.noInternet,
            extension: PicoAssetExtension.lottie,
          ),
        success => PicoAssetData<LottieGenImage>(
            file: Assets.animations.success,
            extension: PicoAssetExtension.lottie,
          ),
        vaccinatedNational => PicoAssetData<LottieGenImage>(
            file: Assets.animations.vaccinatedNational,
            extension: PicoAssetExtension.lottie,
          ),
        vaccinated => PicoAssetData<LottieGenImage>(
            file: Assets.animations.vaccinated,
            extension: PicoAssetExtension.lottie,
          ),
      };
}
