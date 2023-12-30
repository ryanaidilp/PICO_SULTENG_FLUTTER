import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoIcons {
  ambulance,
  ambulanceOutline,
  barChart,
  check,
  close,
  cog,
  donation,
  github,
  hospitalBed,
  hospitalBedOutline,
  hospital,
  hospitalOutline,
  image,
  linkedin,
  menu,
  moon,
  moonOutline,
  newspaper,
  questionCircle,
  selfIsolation,
  stetoschope,
  sun,
  sunOutline,
  syringe,
  vaccine,
  youtube;

  PicoAssetData get data => switch (this) {
        ambulance => PicoAssetData(
            path: Assets.icons.ambulance.path,
          ),
        ambulanceOutline => PicoAssetData(
            path: Assets.icons.ambulanceOutline.path,
          ),
        barChart => PicoAssetData(
            path: Assets.icons.barChart.path,
          ),
        check => PicoAssetData(
            path: Assets.icons.check.path,
          ),
        close => PicoAssetData(
            path: Assets.icons.close.path,
          ),
        cog => PicoAssetData(
            path: Assets.icons.cog.path,
          ),
        donation => PicoAssetData(
            path: Assets.icons.donation.path,
          ),
        github => PicoAssetData(
            path: Assets.icons.github.path,
          ),
        hospital => PicoAssetData(
            path: Assets.icons.hospital.path,
          ),
        hospitalBed => PicoAssetData(
            path: Assets.icons.hospitalBed.path,
          ),
        hospitalBedOutline => PicoAssetData(
            path: Assets.icons.hospitalBedOutline.path,
          ),
        hospitalOutline => PicoAssetData(
            path: Assets.icons.hospitalOutline.path,
          ),
        image => PicoAssetData(
            path: Assets.icons.image.path,
          ),
        linkedin => PicoAssetData(
            path: Assets.icons.linkedin.path,
          ),
        menu => PicoAssetData(
            path: Assets.icons.menu.path,
          ),
        moon => PicoAssetData(
            path: Assets.icons.moonBold.path,
          ),
        moonOutline => PicoAssetData(
            path: Assets.icons.moon.path,
          ),
        newspaper => PicoAssetData(
            path: Assets.icons.newspapper.path,
          ),
        questionCircle => PicoAssetData(
            path: Assets.icons.questionCircle.path,
          ),
        selfIsolation => PicoAssetData(
            path: Assets.icons.selfIsolation.path,
          ),
        stetoschope => PicoAssetData(
            path: Assets.icons.stetoschope.path,
          ),
        sun => PicoAssetData(
            path: Assets.icons.sunBold.path,
          ),
        sunOutline => PicoAssetData(
            path: Assets.icons.sun.path,
          ),
        syringe => PicoAssetData(
            path: Assets.icons.syringe.path,
          ),
        vaccine => PicoAssetData(
            path: Assets.icons.vaccine.path,
          ),
        youtube => PicoAssetData(
            path: Assets.icons.youtube.path,
          ),
      };
}
