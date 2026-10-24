import 'package:asset_core/asset_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Asset theme extension for the design system.
///
/// Provides access to all asset collections organized by category:
/// - [icons] - Icon asset collections
/// - [logos] - Logo assets
/// - [animations] - Animation assets
///
/// Access via `context.assets`:
/// ```dart
/// // Get specific icon
/// final icon = context.assets.icons.all.first;
///
/// // Iterate over all icons
/// for (final icon in context.assets.icons.all) { ... }
/// ```
@immutable
class const PicoAssetExtension({
  /// Icon asset collections.
  required final PicoIconsCollection icons,

  /// Logo assets.
  required final PicoLogosCollection logos,

  /// Animation assets.
  required final PicoAnimationsCollection animations,
}) extends ThemeExtension<PicoAssetExtension> {
  /// Creates a [PicoAssetExtension].
  this;

  /// Default instance with all asset collections.
  factory instance() => const PicoAssetExtension(
    icons: PicoIconsCollection(),
    logos: PicoLogosCollection(),
    animations: PicoAnimationsCollection(),
  );

  @override
  ThemeExtension<PicoAssetExtension> copyWith({
    PicoIconsCollection? icons,
    PicoLogosCollection? logos,
    PicoAnimationsCollection? animations,
  }) => PicoAssetExtension(
    icons: icons ?? this.icons,
    logos: logos ?? this.logos,
    animations: animations ?? this.animations,
  );

  @override
  ThemeExtension<PicoAssetExtension> lerp(
    covariant ThemeExtension<PicoAssetExtension>? other,
    double t,
  ) {
    if (other is! PicoAssetExtension) return this;
    return t < 0.5 ? this : other;
  }
}

/// Collection of all icon categories.
///
/// Override [all] to provide your generated icon assets.
///
/// Access all icons:
/// ```dart
/// final allIcons = context.assets.icons.all;
/// ```
@immutable
class const PicoIconsCollection() extends Equatable {
  /// Creates a [PicoIconsCollection].
  this;

  /// All icons flattened into a single list.
  ///
  /// Override this getter to return your generated icon enum values.
  List<PicoAsset> get all => const [];

  @override
  List<Object?> get props => [all];
}

/// Collection of logo assets.
///
/// Override [all] to provide your generated logo assets.
///
/// Access individual logos:
/// ```dart
/// final logo = context.assets.logos.all.first;
/// ```
@immutable
class const PicoLogosCollection() extends Equatable {
  /// Creates a [PicoLogosCollection].
  this;

  /// All logo assets.
  ///
  /// Override this getter to return your generated logo enum values.
  List<PicoAsset> get all => const [];

  @override
  List<Object?> get props => [all];
}

/// Collection of animation assets.
///
/// Override [all] to provide your generated animation assets.
///
/// Access individual animations:
/// ```dart
/// final anim = context.assets.animations.all.first;
/// ```
@immutable
class const PicoAnimationsCollection() extends Equatable {
  /// Creates a [PicoAnimationsCollection].
  this;

  /// All animation assets.
  ///
  /// Override this getter to return your generated animation enum values.
  List<PicoAsset> get all => const [];

  @override
  List<Object?> get props => [all];
}
