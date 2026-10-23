import 'package:asset_core/src/pico_asset_category.dart';
import 'package:asset_core/src/pico_asset_type.dart';
import 'package:meta/meta.dart';

/// Immutable data class containing all metadata for an asset.
@immutable
final class PicoAssetData {
  const new({
    required this.path,
    required this.type,
    required this.category,
    this.darkPath,
    this.colorOverride = false,
    this.packageName,
  });

  const new icon({
    required this.path,
    this.darkPath,
    this.colorOverride = true,
    this.packageName,
  }) : type = PicoAssetType.svg,
       category = PicoAssetCategory.icon;

  const new illustration({
    required this.path,
    required this.type,
    this.darkPath,
    this.colorOverride = false,
    this.packageName,
  }) : category = PicoAssetCategory.illustration;

  const new lottie({required this.path, this.darkPath, this.packageName})
    : type = PicoAssetType.lottie,
      category = PicoAssetCategory.animation,
      colorOverride = false;

  const new logo({
    required this.path,
    required this.type,
    this.darkPath,
    this.colorOverride = false,
    this.packageName,
  }) : category = PicoAssetCategory.logo;

  final String path;
  final String? darkPath;
  final PicoAssetType type;
  final PicoAssetCategory category;
  final bool colorOverride;
  final String? packageName;

  bool get hasThemeVariant => darkPath != null;

  PicoAssetData copyWith({
    String? path,
    String? darkPath,
    PicoAssetType? type,
    PicoAssetCategory? category,
    bool? colorOverride,
    String? packageName,
  }) => PicoAssetData(
    path: path ?? this.path,
    darkPath: darkPath ?? this.darkPath,
    type: type ?? this.type,
    category: category ?? this.category,
    colorOverride: colorOverride ?? this.colorOverride,
    packageName: packageName ?? this.packageName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PicoAssetData &&
          path == other.path &&
          darkPath == other.darkPath &&
          type == other.type &&
          category == other.category &&
          colorOverride == other.colorOverride &&
          packageName == other.packageName;

  @override
  int get hashCode =>
      Object.hash(path, darkPath, type, category, colorOverride, packageName);
}
