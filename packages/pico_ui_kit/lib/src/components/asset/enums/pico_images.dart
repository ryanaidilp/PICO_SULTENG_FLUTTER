import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_asset_extension.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoImages {
  caugh,
  covid,
  detexi,
  fever,
  flatten,
  headache,
  pico,
  picoWhite,
  socialDistancing,
  virus,
  washHands,
  wearMask;

  PicoAssetData<dynamic> get data => switch (this) {
        caugh => PicoAssetData<AssetGenImage>(
            file: Assets.images.caugh,
            extension: PicoAssetExtension.png,
          ),
        covid => PicoAssetData<AssetGenImage>(
            file: Assets.images.covid,
            extension: PicoAssetExtension.png,
          ),
        detexi => PicoAssetData<AssetGenImage>(
            file: Assets.images.detexi,
            extension: PicoAssetExtension.png,
          ),
        fever => PicoAssetData<AssetGenImage>(
            file: Assets.images.fever,
            extension: PicoAssetExtension.png,
          ),
        flatten => PicoAssetData<AssetGenImage>(
            file: Assets.images.flatten,
            extension: PicoAssetExtension.jpg,
          ),
        headache => PicoAssetData<AssetGenImage>(
            file: Assets.images.headache,
            extension: PicoAssetExtension.png,
          ),
        pico => PicoAssetData<SvgGenImage>(
            file: Assets.images.pico,
            extension: PicoAssetExtension.svg,
          ),
        picoWhite => PicoAssetData<AssetGenImage>(
            file: Assets.images.picoWhite,
            extension: PicoAssetExtension.png,
          ),
        socialDistancing => PicoAssetData<AssetGenImage>(
            file: Assets.images.socialDistancing,
            extension: PicoAssetExtension.png,
          ),
        virus => PicoAssetData<AssetGenImage>(
            file: Assets.images.virus,
            extension: PicoAssetExtension.png,
          ),
        washHands => PicoAssetData<AssetGenImage>(
            file: Assets.images.washHands,
            extension: PicoAssetExtension.png,
          ),
        wearMask => PicoAssetData<AssetGenImage>(
            file: Assets.images.wearMask,
            extension: PicoAssetExtension.png,
          ),
      };
}
