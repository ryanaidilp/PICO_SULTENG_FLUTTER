# pico_asset

Type-safe asset package with icons, illustrations, animations, and logos for Pico.

## Usage

```dart
import 'package:pico_asset/pico_asset.dart';

// Accessing asset data directly
final data = PicoActionsIcons.search.data;
print(data.path); // 'assets/icons/actions/search.svg'

// For rendering assets, use the UI Kit's asset widget:
// PicoAssetWidget(PicoActionsIcons.search, size: 24)
```

## Asset Categories

- **Icons**: SVG icons organized by category (actions, arrows, etc.)
- **Logos**: Brand logos with light/dark variants
- **Animations**: Lottie JSON animations

## Regenerating

Run the `asset_generator` brick to regenerate enum files from asset directories.
