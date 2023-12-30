import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoImages {
  caugh,
  covid,
  detexi,
  fever,
  headache,
  pico,
  picoWhite,
  socialDistancing,
  virus,
  washHands,
  wearMask;

  PicoAssetData get data => switch (this) {
        caugh => PicoAssetData(path: Assets.images.caugh.path),
        covid => PicoAssetData(path: Assets.images.covid.path),
        detexi => PicoAssetData(path: Assets.images.detexi.path),
        fever => PicoAssetData(path: Assets.images.fever.path),
        headache => PicoAssetData(path: Assets.images.headache.path),
        pico => PicoAssetData(path: Assets.images.pico.path),
        picoWhite => PicoAssetData(path: Assets.images.picoWhite.path),
        socialDistancing =>
          PicoAssetData(path: Assets.images.socialDistancing.path),
        virus => PicoAssetData(path: Assets.images.virus.path),
        washHands => PicoAssetData(path: Assets.images.washHands.path),
        wearMask => PicoAssetData(path: Assets.images.wearMask.path),
      };
}
