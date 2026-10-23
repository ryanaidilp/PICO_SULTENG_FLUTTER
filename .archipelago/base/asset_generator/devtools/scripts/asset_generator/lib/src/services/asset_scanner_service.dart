import 'dart:io';

import 'package:asset_generator/src/models/asset_generator_config.dart';
import 'package:asset_generator/src/models/discovered_asset.dart';
import 'package:path/path.dart' as p;

/// Service for scanning asset directories and discovering assets, and for
/// rendering the type-safe Dart enum source for each discovered group.
class const AssetScannerService({
  /// Configuration for scanning.
  required final AssetGeneratorConfig config,

  /// Invoked with a warning message for every asset that is skipped.
  final void Function(String message)? onWarning,
}) {
  /// Creates a new [AssetScannerService].
  ///
  /// [onWarning], if provided, is invoked with a human-readable message for
  /// every asset that is discovered but cannot be generated (e.g. Rive
  /// files, which `asset_core`'s `AppAssetType` has no mapping for yet).
  this;

  /// Scans the assets directory and returns grouped assets.
  ///
  /// Top-level category directories and icon subcategory directories are
  /// both sorted alphabetically (by directory name) so output is
  /// deterministic across platforms/filesystems.
  List<AssetGroup> scan() {
    final assetsDir = Directory(config.assetsPath);
    if (!assetsDir.existsSync()) return [];

    final groups = <AssetGroup>[];
    final topLevelDirs = _sortedSubdirectories(assetsDir);

    for (final entity in topLevelDirs) {
      final dirName = p.basename(entity.path);
      final category = _categoryFromDirName(dirName);
      if (category == null) continue;

      if (category == AssetCategory.icon && config.iconCategories.isNotEmpty) {
        for (final subDir in _sortedSubdirectories(entity)) {
          final subName = p.basename(subDir.path);
          final assets = _scanDirectory(subDir, category);
          if (assets.isEmpty) continue;

          groups.add(
            AssetGroup(
              name: subName,
              category: category,
              subcategory: subName,
              sourceDir: p.relative(subDir.path, from: config.packagePath),
              assets: assets,
            ),
          );
        }
      } else {
        final assets = _scanDirectory(entity, category);
        if (assets.isEmpty) continue;

        groups.add(
          AssetGroup(
            name: dirName,
            category: category,
            sourceDir: p.relative(entity.path, from: config.packagePath),
            assets: assets,
          ),
        );
      }
    }

    return groups;
  }

  List<Directory> _sortedSubdirectories(Directory dir) {
    final subDirs = dir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return subDirs;
  }

  List<DiscoveredAsset> _scanDirectory(Directory dir, AssetCategory category) {
    final assets = <DiscoveredAsset>[];
    final files = dir.listSync(recursive: true).whereType<File>().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    // A `.lottie` beside a same-named `.json` wins: the zip is what ships,
    // the `.json` stays on disk as the design source.
    final dotLotties = {
      for (final f in files)
        if (p.extension(f.path).toLowerCase() == '.lottie')
          p.withoutExtension(f.path),
    };

    for (final entity in files) {
      final ext = p.extension(entity.path);
      final type = AssetType.fromExtension(ext);
      if (type == null) continue;

      final filename = p.basenameWithoutExtension(entity.path);
      // Skip dark variants (they are paired with light variants below).
      if (filename.endsWith('_dark')) continue;
      if (ext.toLowerCase() == '.json' &&
          dotLotties.contains(p.withoutExtension(entity.path))) {
        continue;
      }

      if (type == AssetType.rive) {
        onWarning?.call(
          'Skipping Rive asset '
          '"${p.relative(entity.path, from: config.packagePath)}": '
          'asset_core has no AppAssetType mapping for Rive files yet.',
        );
        continue;
      }

      final relativePath = p.relative(entity.path, from: config.packagePath);

      final darkPath = entity.path.replaceAll(
        p.basename(entity.path),
        '${filename}_dark$ext',
      );
      final hasDark = File(darkPath).existsSync();

      assets.add(
        DiscoveredAsset(
          path: relativePath,
          type: type,
          category: category,
          darkPath: hasDark
              ? p.relative(darkPath, from: config.packagePath)
              : null,
          colorOverride: category == AssetCategory.icon,
        ),
      );
    }

    return assets;
  }

  AssetCategory? _categoryFromDirName(String name) => switch (name) {
    'icons' || 'icon' => AssetCategory.icon,
    'illustrations' || 'illustration' => AssetCategory.illustration,
    'animations' || 'animation' => AssetCategory.animation,
    'logos' || 'logo' => AssetCategory.logo,
    _ => null,
  };

  /// Generates Dart enum file content for an asset group.
  ///
  /// Output matches the hand-verified reference shape at
  /// `packages/app_asset/lib/src/generated/` in template_base: icons
  /// implement `AppIconAsset` with no `type` field (icons are always SVG),
  /// while animations/logos/illustrations implement their respective
  /// contracts with a required `type` field mapped from the scanner's
  /// internal [AssetType].
  String generateEnumFile(AssetGroup group) {
    final className = group.enumClassName(config.prefix);
    return switch (group.category) {
      AssetCategory.icon => _generateIconEnum(group, className),
      AssetCategory.animation => _generateAnimationEnum(group, className),
      AssetCategory.logo => _generateTypedAssetEnum(
        group,
        className,
        assetLabel: 'logo',
        interfaceName: '${config.prefix}LogoAsset',
        dataConstructor: 'logo',
      ),
      AssetCategory.illustration => _generateTypedAssetEnum(
        group,
        className,
        assetLabel: 'illustration',
        interfaceName: '${config.prefix}IllustrationAsset',
        dataConstructor: 'illustration',
      ),
    };
  }

  String _generateIconEnum(AssetGroup group, String className) {
    final interfaceName = '${config.prefix}IconAsset';
    final hasDark = _hasDarkVariant(group);
    final buffer = StringBuffer()
      ..writeln("import '${config.assetCoreImport}';")
      ..writeln()
      ..writeln('/// Auto-generated icon assets.')
      ..writeln('///')
      ..writeln('/// Generated from: ${group.sourceDir}');
    _writeEnumHeader(
      buffer,
      className,
      interfaceName,
      withType: false,
      hasDark: hasDark,
    );

    _writeAssetValues(buffer, group.assets, withType: false);

    buffer
      ..writeln()
      ..writeln("  static const _basePath = '${group.sourceDir}';")
      ..writeln();

    _writePathGetters(buffer, hasDark: hasDark);

    buffer
      ..writeln('  @override')
      ..writeln(
        '  ${config.prefix}AssetData get data => '
        '${config.prefix}AssetData.icon(',
      )
      ..writeln('    path: path,')
      ..writeln('    darkPath: darkPath,')
      ..writeln("    packageName: '${config.packageName}',")
      ..writeln('  );')
      ..writeln();

    _writeSemanticLabelGetterAndHelper(buffer);
    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateAnimationEnum(AssetGroup group, String className) {
    final interfaceName = '${config.prefix}AnimationAsset';
    final hasDark = _hasDarkVariant(group);
    final buffer = StringBuffer()
      ..writeln("import '${config.assetCoreImport}';")
      ..writeln()
      ..writeln('/// Auto-generated animation assets.')
      ..writeln('///')
      ..writeln('/// Generated from: ${group.sourceDir}');
    _writeEnumHeader(
      buffer,
      className,
      interfaceName,
      withType: true,
      hasDark: hasDark,
    );

    _writeAssetValues(buffer, group.assets, withType: true);

    buffer
      ..writeln()
      ..writeln("  static const _basePath = '${group.sourceDir}';")
      ..writeln();

    _writePathGetters(buffer, hasDark: hasDark);

    buffer
      ..writeln('  @override')
      ..writeln(
        '  ${config.prefix}AssetData get data => '
        '${config.prefix}AssetData.lottie(',
      )
      ..writeln('    path: path,')
      ..writeln('    darkPath: darkPath,')
      ..writeln("    packageName: '${config.packageName}',")
      ..writeln('  );')
      ..writeln();

    _writeSemanticLabelGetterAndHelper(buffer);

    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln('  bool get shouldRepeat => false;')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  bool get shouldAutoPlay => true;')
      ..writeln('}');

    return buffer.toString();
  }

  /// Shared generator for logo and illustration enums — both contracts are
  /// structurally identical (svg or raster, optional dark variant, no
  /// animation-specific overrides), differing only in the interface they
  /// implement and the `AppAssetData` named constructor they call.
  String _generateTypedAssetEnum(
    AssetGroup group,
    String className, {
    required String assetLabel,
    required String interfaceName,
    required String dataConstructor,
  }) {
    final hasDark = _hasDarkVariant(group);
    final buffer = StringBuffer()
      ..writeln("import '${config.assetCoreImport}';")
      ..writeln()
      ..writeln('/// Auto-generated $assetLabel assets.')
      ..writeln('///')
      ..writeln('/// Generated from: ${group.sourceDir}');
    _writeEnumHeader(
      buffer,
      className,
      interfaceName,
      withType: true,
      hasDark: hasDark,
    );

    _writeAssetValues(buffer, group.assets, withType: true);

    buffer
      ..writeln()
      ..writeln("  static const _basePath = '${group.sourceDir}';")
      ..writeln();

    _writePathGetters(buffer, hasDark: hasDark);

    buffer
      ..writeln('  @override')
      ..writeln(
        '  ${config.prefix}AssetData get data => '
        '${config.prefix}AssetData.$dataConstructor(',
      )
      ..writeln('    path: path,')
      ..writeln('    type: type,')
      ..writeln('    darkPath: darkPath,')
      ..writeln("    packageName: '${config.packageName}',")
      ..writeln('  );')
      ..writeln();

    _writeSemanticLabelGetterAndHelper(buffer);
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Writes the declaring primary-constructor enum header in the exact shape
  /// `dart fix` + `dart format` settle on, so regenerating is a no-op.
  void _writeEnumHeader(
    StringBuffer buffer,
    String className,
    String interfaceName, {
    required bool withType,
    required bool hasDark,
  }) {
    buffer
      ..writeln('enum $className(')
      ..writeln('  /// The asset filename.');
    if (!withType && !hasDark) {
      buffer.writeln('  final String filename,');
    } else {
      buffer.writeln('  final String filename, {');
      if (withType) {
        buffer
          ..writeln()
          ..writeln('  /// The type of this asset.')
          ..writeln('  required final ${config.prefix}AssetType type,');
      }
      if (hasDark) buffer.writeln('  final String? _darkFilename,');
      buffer.write('}');
    }
    buffer.writeln(') implements $interfaceName {');
  }

  void _writeAssetValues(
    StringBuffer buffer,
    List<DiscoveredAsset> assets, {
    required bool withType,
  }) {
    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final isLast = i == assets.length - 1;
      final filename = p.basename(asset.path);

      buffer.write("  ${asset.enumName}('$filename'");
      if (withType) {
        buffer.write(', type: ${_appAssetTypeLiteral(asset.type)}');
      }
      if (asset.darkPath != null) {
        // Dart maps a named initializing formal that targets a private
        // field (`this._darkFilename`) to the public callsite name with
        // the leading underscore stripped, so callers pass `darkFilename:`
        // even though the backing field is private.
        buffer.write(", darkFilename: '${p.basename(asset.darkPath!)}'");
      }
      buffer.writeln(')${isLast ? ';' : ','}');
    }
  }

  String _appAssetTypeLiteral(AssetType type) {
    final name = switch (type) {
      AssetType.svg => 'svg',
      AssetType.lottie => 'lottie',
      AssetType.raster => 'raster',
      AssetType.rive => throw StateError(
        'Rive assets must be filtered out before code generation — '
        'asset_core has no AppAssetType.rive mapping.',
      ),
    };
    return '${config.prefix}AssetType.$name';
  }

  /// Whether any asset in [group] has a dark theme variant.
  ///
  /// Drives whether the generated enum carries the `_darkFilename` field and
  /// initializing formal at all: a param/field that no enum value would ever
  /// populate is dead weight the analyzer correctly flags
  /// (`unused_element_parameter`), so groups with no dark variants get a
  /// simpler enum with a constant `darkPath => null` instead.
  bool _hasDarkVariant(AssetGroup group) =>
      group.assets.any((asset) => asset.hasThemeVariant);

  void _writePathGetters(StringBuffer buffer, {required bool hasDark}) {
    buffer
      ..writeln('  /// The full asset path.')
      ..writeln(r"  String get path => '$_basePath/$filename';")
      ..writeln()
      ..writeln('  /// The dark theme variant path, if any.')
      ..writeln(
        hasDark
            ? '  String? get darkPath =>\n'
                  r"      _darkFilename != null ? '$_basePath/$_darkFilename' : null;"
            : '  String? get darkPath => null;',
      );

    buffer.writeln();
  }

  void _writeSemanticLabelGetterAndHelper(StringBuffer buffer) {
    buffer
      ..writeln('  @override')
      ..writeln('  String get defaultSemanticLabel => _toReadableLabel(name);')
      ..writeln()
      ..writeln('  /// Converts camelCase enum name to human-readable label.')
      ..writeln('  static String _toReadableLabel(String name) {')
      ..writeln('    if (name.isEmpty) return name;')
      ..writeln('    final words = name.replaceAllMapped(')
      ..writeln("      RegExp('([A-Z])'),")
      ..writeln(r"      (m) => ' ${m.group(1)}',")
      ..writeln('    );')
      ..writeln(
        '    return words.trim().replaceRange(0, 1, '
        'words.trim()[0].toUpperCase());',
      )
      ..writeln('  }');
  }

  /// Generates the `icons/icons.dart` barrel that aggregates every
  /// `*_icons.dart` subcategory file, alphabetically.
  String generateIconsBarrel(List<String> fileNames) {
    final sorted = [...fileNames]..sort();
    final buffer = StringBuffer()
      ..writeln('/// Auto-generated icon asset exports.')
      ..writeln('library;')
      ..writeln();

    for (final fileName in sorted) {
      buffer.writeln("export '$fileName';");
    }

    return buffer.toString();
  }

  /// Generates the top-level `generated.dart` barrel that aggregates every
  /// category file that was actually written, alphabetically. Categories
  /// with zero discovered assets must not be passed in — no dangling
  /// exports for empty categories.
  String generateTopLevelBarrel(List<String> exportPaths) {
    final sorted = [...exportPaths]..sort();
    final buffer = StringBuffer()
      ..writeln('/// Auto-generated asset exports.')
      ..writeln('///')
      ..writeln('/// This file is generated by the asset_generator script.')
      ..writeln('/// Do not modify manually.')
      ..writeln('library;')
      ..writeln();

    for (final path in sorted) {
      buffer.writeln("export '$path';");
    }

    return buffer.toString();
  }
}
