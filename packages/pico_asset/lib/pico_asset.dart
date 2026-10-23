/// Type-safe asset package with icons, illustrations, animations, and logos.
///
/// This package provides:
/// - Auto-generated enums for all assets
/// - Theme-aware asset resolution
///
/// ## Usage
///
/// ```dart
/// import 'package:pico_asset/pico_asset.dart';
///
/// // Accessing asset data directly
/// final data = PicoActionsIcons.search.data;
/// print(data.path); // 'assets/icons/actions/search.svg'
/// ```
library;

export 'package:asset_core/asset_core.dart';

export 'src/generated/generated.dart';
