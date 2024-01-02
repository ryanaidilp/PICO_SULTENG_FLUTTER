import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_asset_extension.dart';
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

  PicoAssetData<SvgGenImage> get data => switch (this) {
        ambulance => PicoAssetData<SvgGenImage>(
            file: Assets.icons.ambulance,
            extension: PicoAssetExtension.svg,
          ),
        ambulanceOutline => PicoAssetData<SvgGenImage>(
            file: Assets.icons.ambulanceOutline,
            extension: PicoAssetExtension.svg,
          ),
        barChart => PicoAssetData<SvgGenImage>(
            file: Assets.icons.barChart,
            extension: PicoAssetExtension.svg,
          ),
        check => PicoAssetData<SvgGenImage>(
            file: Assets.icons.check,
            extension: PicoAssetExtension.svg,
          ),
        close => PicoAssetData<SvgGenImage>(
            file: Assets.icons.close,
            extension: PicoAssetExtension.svg,
          ),
        cog => PicoAssetData<SvgGenImage>(
            file: Assets.icons.cog,
            extension: PicoAssetExtension.svg,
          ),
        donation => PicoAssetData<SvgGenImage>(
            file: Assets.icons.donation,
            extension: PicoAssetExtension.svg,
          ),
        github => PicoAssetData<SvgGenImage>(
            file: Assets.icons.github,
            extension: PicoAssetExtension.svg,
          ),
        hospital => PicoAssetData<SvgGenImage>(
            file: Assets.icons.hospital,
            extension: PicoAssetExtension.svg,
          ),
        hospitalBed => PicoAssetData<SvgGenImage>(
            file: Assets.icons.hospitalBed,
            extension: PicoAssetExtension.svg,
          ),
        hospitalBedOutline => PicoAssetData<SvgGenImage>(
            file: Assets.icons.hospitalBedOutline,
            extension: PicoAssetExtension.svg,
          ),
        hospitalOutline => PicoAssetData<SvgGenImage>(
            file: Assets.icons.hospitalOutline,
            extension: PicoAssetExtension.svg,
          ),
        image => PicoAssetData<SvgGenImage>(
            file: Assets.icons.image,
            extension: PicoAssetExtension.svg,
          ),
        linkedin => PicoAssetData<SvgGenImage>(
            file: Assets.icons.linkedin,
            extension: PicoAssetExtension.svg,
          ),
        menu => PicoAssetData<SvgGenImage>(
            file: Assets.icons.menu,
            extension: PicoAssetExtension.svg,
          ),
        moon => PicoAssetData<SvgGenImage>(
            file: Assets.icons.moonBold,
            extension: PicoAssetExtension.svg,
          ),
        moonOutline => PicoAssetData<SvgGenImage>(
            file: Assets.icons.moon,
            extension: PicoAssetExtension.svg,
          ),
        newspaper => PicoAssetData<SvgGenImage>(
            file: Assets.icons.newspapper,
            extension: PicoAssetExtension.svg,
          ),
        questionCircle => PicoAssetData<SvgGenImage>(
            file: Assets.icons.questionCircle,
            extension: PicoAssetExtension.svg,
          ),
        selfIsolation => PicoAssetData<SvgGenImage>(
            file: Assets.icons.selfIsolation,
            extension: PicoAssetExtension.svg,
          ),
        stetoschope => PicoAssetData<SvgGenImage>(
            file: Assets.icons.stetoschope,
            extension: PicoAssetExtension.svg,
          ),
        sun => PicoAssetData<SvgGenImage>(
            file: Assets.icons.sunBold,
            extension: PicoAssetExtension.svg,
          ),
        sunOutline => PicoAssetData<SvgGenImage>(
            file: Assets.icons.sun,
            extension: PicoAssetExtension.svg,
          ),
        syringe => PicoAssetData<SvgGenImage>(
            file: Assets.icons.syringe,
            extension: PicoAssetExtension.svg,
          ),
        vaccine => PicoAssetData<SvgGenImage>(
            file: Assets.icons.vaccine,
            extension: PicoAssetExtension.svg,
          ),
        youtube => PicoAssetData<SvgGenImage>(
            file: Assets.icons.youtube,
            extension: PicoAssetExtension.svg,
          ),
      };
}
