import 'package:pico_ui_kit/src/assets/assets.gen.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

enum PicoIcons {
  menu;

  PicoAssetData get data => switch (this) {
        menu => PicoAssetData(
            path: Assets.icons.menu.path,
          ),
      };
}
