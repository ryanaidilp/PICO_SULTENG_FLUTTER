import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

// =============================================================================
// GOLDEN TEST HELPER
// =============================================================================
//
// This file provides utilities for golden testing UI Kit components.
// It includes helpers for testing components in both light and dark themes,
// generating consistent file names, and wrapping widgets with proper theming.
//
// ## Quick Start
//
// ```dart
// import 'package:flutter_test/flutter_test.dart';
// import 'golden_test_helper.dart';
//
// void main() {
//   GoldenTestHelper.testGoldenVariants(
//     'MyButton',
//     variants: [
//       GoldenTestVariant(
//         name: 'primary',
//         widget: MyButton(label: 'Click me', onPressed: () {}),
//       ),
//       GoldenTestVariant(
//         name: 'disabled',
//         widget: MyButton(label: 'Disabled'),
//       ),
//     ],
//   );
// }
// ```
//
// ## Golden File Naming Convention
//
// Files are named using the format: `{component_name}_{variant}_{theme}.png`
// - Example: `button_primary_light.png`, `button_primary_dark.png`
//
// =============================================================================

/// Represents a theme mode for golden tests.
enum GoldenThemeMode() {
  /// Light theme mode.
  light,

  /// Dark theme mode.
  dark,
}

/// A variant configuration for golden testing.
///
/// Each variant represents a specific state or configuration of a component
/// that should be captured as a golden image.
///
/// ```dart
/// GoldenTestVariant(
///   name: 'primary',
///   widget: AppButton(label: 'Primary', color: AppButtonColor.primary),
/// )
/// ```
@immutable
class const GoldenTestVariant({
  /// The name of this variant, used in golden file names.
  ///
  /// Should be lowercase with underscores (snake_case).
  /// Example: 'primary', 'disabled', 'with_icon'
  required final String name,

  /// The widget to render for this variant.
  required final Widget widget,

  /// Optional fixed size for the golden image.
  ///
  /// If null, the widget will use its intrinsic size.
  final Size? size,

  /// Padding around the widget in the golden image.
  ///
  /// Defaults to 16 pixels on all sides.
  final EdgeInsets padding = const EdgeInsets.all(16),
}) {
  /// Creates a golden test variant.
  this;
}

/// Font family configuration for golden tests.
///
/// Uses locally loaded fonts to avoid Google Fonts network requests
/// during test execution. Font files must be placed in `test/fonts/`.
///
/// ```dart
/// const testFontFamily = GoldenTestFontFamily(
///   bodyFontFamily: 'SourceSans3',
///   headingFontFamily: 'SourceSans3',
///   monoFontFamily: 'SourceSans3',
/// );
/// ```
@immutable
class const GoldenTestFontFamily({
  /// Font family for body text.
  required final String bodyFontFamily,

  /// Font family for heading text.
  required final String headingFontFamily,

  /// Font family for monospace text.
  required final String monoFontFamily,
}) {
  /// Creates a font family configuration for golden tests.
  this;

  /// Default font family for golden tests.
  ///
  /// Uses Source Sans 3 for body and code and Archivo for headings.
  static const standard = GoldenTestFontFamily(
    bodyFontFamily: 'SourceSans3',
    headingFontFamily: 'Archivo',
    monoFontFamily: 'SourceSans3',
  );

  /// Converts to [PicoFontFamily] for use with [PicoTheme].
  PicoFontFamily toAppFontFamily() => PicoFontFamily(
    package: null,
    bodyFontFamily: bodyFontFamily,
    headingFontFamily: headingFontFamily,
    monoFontFamily: monoFontFamily,
  );
}

/// Wrapper widget that provides theming for golden tests.
///
/// Wraps a component in [MaterialApp] with the appropriate theme from
/// [PicoTheme]. Supports both light and dark theme modes.
///
/// ```dart
/// GoldenTestWrapper(
///   themeMode: GoldenThemeMode.light,
///   child: AppButton(label: 'Test'),
/// )
/// ```
class const GoldenTestWrapper({
  /// The widget to wrap with theming.
  required final Widget child,

  /// The theme mode to apply.
  final GoldenThemeMode themeMode = GoldenThemeMode.light,

  /// Font family configuration for the theme.
  final GoldenTestFontFamily fontFamily = GoldenTestFontFamily.standard,

  /// Optional fixed size for the wrapper.
  final Size? size,

  /// Padding around the child widget.
  final EdgeInsets padding = const EdgeInsets.all(16),

  /// Optional background color override.
  ///
  /// If null, uses the theme's scaffold background color.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates a [GoldenTestWrapper].
  this;

  @override
  Widget build(BuildContext context) {
    final theme = themeMode == GoldenThemeMode.dark
        ? PicoTheme.dark(fontFamily: fontFamily.toAppFontFamily())
        : PicoTheme.light(fontFamily: fontFamily.toAppFontFamily());

    final colorExtension = theme.extension<PicoColorExtension>()!;

    Widget content = Padding(padding: padding, child: child);

    if (size != null) {
      content = SizedBox(
        width: size!.width,
        height: size!.height,
        child: content,
      );
    }

    return MaterialApp(
      title: 'Golden Test',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: backgroundColor ?? colorExtension.background.main,
        body: Center(child: content),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<GoldenThemeMode>('themeMode', themeMode))
      ..add(DiagnosticsProperty<GoldenTestFontFamily>('fontFamily', fontFamily))
      ..add(DiagnosticsProperty<Size?>('size', size))
      ..add(DiagnosticsProperty<EdgeInsets>('padding', padding))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}

/// Helper class for golden testing UI Kit components.
///
/// Provides utilities for:
/// - Testing widgets in both light and dark themes
/// - Generating consistent golden file names
/// - Loading fonts for golden tests
/// - Wrapping widgets with proper theming
///
/// ## Basic Usage
///
/// ```dart
/// void main() {
///   group('Button Golden Tests', () {
///     GoldenTestHelper.testGoldenVariants(
///       'button',
///       variants: [
///         GoldenTestVariant(
///           name: 'primary',
///           widget: AppButton(label: 'Primary', onPressed: () {}),
///         ),
///         GoldenTestVariant(
///           name: 'secondary',
///           widget: AppButton(
///             label: 'Secondary',
///             color: AppButtonColor.secondary,
///             onPressed: () {},
///           ),
///         ),
///       ],
///     );
///   });
/// }
/// ```
///
/// ## Custom Golden Directory
///
/// ```dart
/// GoldenTestHelper.testGoldenVariants(
///   'button',
///   goldenDirectory: './goldens/buttons',
///   variants: [...],
/// );
/// ```
///
/// ## Single Theme Testing
///
/// ```dart
/// testWidgets('button primary light', (tester) async {
///   await GoldenTestHelper.testGolden(
///     tester,
///     componentName: 'button',
///     variantName: 'primary',
///     widget: AppButton(label: 'Primary', onPressed: () {}),
///   );
/// });
/// ```
abstract final class GoldenTestHelper() {
  /// Default directory for golden files.
  static const String defaultGoldenDirectory = './goldens';

  /// Default font family for golden tests.
  static const GoldenTestFontFamily defaultFontFamily =
      GoldenTestFontFamily.standard;

  /// Font directory relative to test directory.
  static const String fontDirectory = 'test/fonts';

  /// Creates a golden file name following the naming convention.
  ///
  /// Format: `{componentName}_{variantName}_{theme}.png`
  ///
  /// ```dart
  /// final fileName = GoldenTestHelper.createGoldenFileName(
  ///   componentName: 'button',
  ///   variantName: 'primary',
  ///   themeMode: GoldenThemeMode.light,
  /// );
  /// // Returns: 'button_primary_light.png'
  /// ```
  static String createGoldenFileName({
    required String componentName,
    required String variantName,
    required GoldenThemeMode themeMode,
  }) {
    final themeName = themeMode.name;
    final sanitizedComponent = _sanitizeName(componentName);
    final sanitizedVariant = _sanitizeName(variantName);
    return '${sanitizedComponent}_${sanitizedVariant}_$themeName.png';
  }

  /// Creates a golden file path including directory.
  ///
  /// ```dart
  /// final path = GoldenTestHelper.createGoldenFilePath(
  ///   componentName: 'button',
  ///   variantName: 'primary',
  ///   themeMode: GoldenThemeMode.light,
  ///   directory: './goldens',
  /// );
  /// // Returns: './goldens/button_primary_light.png'
  /// ```
  static String createGoldenFilePath({
    required String componentName,
    required String variantName,
    required GoldenThemeMode themeMode,
    String directory = defaultGoldenDirectory,
  }) {
    final fileName = createGoldenFileName(
      componentName: componentName,
      variantName: variantName,
      themeMode: themeMode,
    );
    return '$directory/$fileName';
  }

  /// Sanitizes a name for use in file names.
  ///
  /// Converts to lowercase and replaces non-alphanumeric characters
  /// with underscores.
  static String _sanitizeName(String name) => name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  /// Loads a font file for golden tests.
  ///
  /// Call this before running golden tests to ensure fonts render correctly.
  static Future<void> loadFont(String fontFamily, String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      await ui.loadFontFromList(
        Uint8List.fromList(bytes),
        fontFamily: fontFamily,
      );
    }
  }

  /// Loads the static 400, 600 and 700 instances of Source Sans 3 under one
  /// family. The variable file resolves to its ExtraLight default on Linux,
  /// which is too faint for the contrast checks.
  static Future<void> loadStaticSourceSans(String family, String dir) async {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'SemiBold', 'Bold']) {
      final f = File('$dir/static/SourceSans3-$w.ttf');
      if (f.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await loader.load();
  }

  /// Loads all standard fonts for golden tests.
  ///
  /// Loads Archivo, Source Sans 3 and Material Icons from the test/fonts directory.
  /// Material Icons should be loaded separately via flutter_test_config.dart.
  ///
  /// Silently returns if the font directory does not exist, since brick users
  /// may not have fonts initially.
  ///
  /// ```dart
  /// setUpAll(() async {
  ///   await GoldenTestHelper.loadStandardFonts();
  /// });
  /// ```
  static Future<void> loadStandardFonts({String? fontDir}) async {
    final testDir = Directory(fontDir ?? fontDirectory);
    if (!testDir.existsSync()) return;

    // Brand fonts (variable files) under the bare names used by tests.
    await loadFont('Archivo', '${testDir.path}/Archivo.ttf');
    await loadStaticSourceSans('SourceSans3', testDir.path);
    // The default theme resolves the bundled fonts through the package.
    await loadFont(
      'packages/pico_ui_kit/Archivo',
      '${testDir.path}/Archivo.ttf',
    );
    await loadStaticSourceSans(
      'packages/pico_ui_kit/SourceSans3',
      testDir.path,
    );

    // Load Material Icons
    await loadFont(
      'MaterialIcons',
      '${testDir.path}/MaterialIcons-Regular.otf',
    );
  }

  /// Tests a single widget variant in a specific theme mode.
  ///
  /// This is a low-level method for testing a single widget configuration.
  /// For testing multiple variants across themes, use [testGoldenVariants].
  ///
  /// ```dart
  /// testWidgets('button primary light', (tester) async {
  ///   await GoldenTestHelper.loadStandardFonts();
  ///
  ///   await GoldenTestHelper.testGolden(
  ///     tester,
  ///     componentName: 'button',
  ///     variantName: 'primary',
  ///     widget: AppButton(label: 'Primary', onPressed: () {}),
  ///   );
  /// });
  /// ```
  static Future<void> testGolden(
    WidgetTester tester, {
    required String componentName,
    required String variantName,
    required Widget widget,
    GoldenThemeMode themeMode = GoldenThemeMode.light,
    GoldenTestFontFamily fontFamily = defaultFontFamily,
    String goldenDirectory = defaultGoldenDirectory,
    Size? size,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) async {
    // Set the test surface size if provided.
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    final wrappedWidget = GoldenTestWrapper(
      themeMode: themeMode,
      fontFamily: fontFamily,
      padding: padding,
      child: widget,
    );

    await tester.pumpWidget(wrappedWidget);
    await tester.pumpAndSettle();

    final goldenPath = createGoldenFilePath(
      componentName: componentName,
      variantName: variantName,
      themeMode: themeMode,
      directory: goldenDirectory,
    );

    await expectLater(find.byType(MaterialApp), matchesGoldenFile(goldenPath));
  }

  /// Tests multiple widget variants in both light and dark themes.
  ///
  /// This is the recommended method for comprehensive golden testing.
  /// It automatically creates test cases for each variant in both themes.
  ///
  /// ```dart
  /// void main() {
  ///   GoldenTestHelper.testGoldenVariants(
  ///     'button',
  ///     variants: [
  ///       GoldenTestVariant(
  ///         name: 'primary',
  ///         widget: AppButton(label: 'Primary', onPressed: () {}),
  ///       ),
  ///       GoldenTestVariant(
  ///         name: 'disabled',
  ///         widget: AppButton(label: 'Disabled'),
  ///       ),
  ///     ],
  ///   );
  /// }
  /// ```
  ///
  /// This creates the following golden files:
  /// - `button_primary_light.png`
  /// - `button_primary_dark.png`
  /// - `button_disabled_light.png`
  /// - `button_disabled_dark.png`
  @isTest
  static void testGoldenVariants(
    String componentName, {
    required List<GoldenTestVariant> variants,
    GoldenTestFontFamily fontFamily = defaultFontFamily,
    String goldenDirectory = defaultGoldenDirectory,
    List<String>? tags,
    bool skip = false,
  }) {
    for (final variant in variants) {
      for (final themeMode in GoldenThemeMode.values) {
        final testName =
            '$componentName ${variant.name} ${themeMode.name} theme';

        testWidgets(
          testName,
          (tester) async {
            await loadStandardFonts();

            await testGolden(
              tester,
              componentName: componentName,
              variantName: variant.name,
              widget: variant.widget,
              themeMode: themeMode,
              fontFamily: fontFamily,
              goldenDirectory: goldenDirectory,
              size: variant.size,
              padding: variant.padding,
            );
          },
          // Always tagged `golden` so the workspace's `--exclude-tags golden`
          // gate (Archipelago-6649) can't leak an untagged caller's goldens.
          tags: {'golden', ...?tags},
          skip: skip,
        );
      }
    }
  }

  /// Tests a single variant in both light and dark themes.
  ///
  /// Convenience method when you only have one variant to test.
  ///
  /// ```dart
  /// void main() {
  ///   GoldenTestHelper.testGoldenBothThemes(
  ///     componentName: 'button',
  ///     variantName: 'primary',
  ///     widget: AppButton(label: 'Primary', onPressed: () {}),
  ///   );
  /// }
  /// ```
  @isTest
  static void testGoldenBothThemes({
    required String componentName,
    required String variantName,
    required Widget widget,
    GoldenTestFontFamily fontFamily = defaultFontFamily,
    String goldenDirectory = defaultGoldenDirectory,
    Size? size,
    EdgeInsets padding = const EdgeInsets.all(16),
    List<String>? tags,
    bool skip = false,
  }) {
    testGoldenVariants(
      componentName,
      variants: [
        GoldenTestVariant(
          name: variantName,
          widget: widget,
          size: size,
          padding: padding,
        ),
      ],
      fontFamily: fontFamily,
      goldenDirectory: goldenDirectory,
      tags: tags,
      skip: skip,
    );
  }

  /// Creates a side-by-side comparison widget for light and dark themes.
  ///
  /// Useful for documentation or visual comparison of theme variants.
  ///
  /// ```dart
  /// final comparison = GoldenTestHelper.buildThemeComparison(
  ///   widget: AppButton(label: 'Button', onPressed: () {}),
  /// );
  /// ```
  static Widget buildThemeComparison({
    required Widget widget,
    GoldenTestFontFamily fontFamily = defaultFontFamily,
    EdgeInsets padding = const EdgeInsets.all(16),
    double spacing = 16,
  }) {
    final lightTheme = PicoTheme.light(
      fontFamily: fontFamily.toAppFontFamily(),
    );
    final darkTheme = PicoTheme.dark(fontFamily: fontFamily.toAppFontFamily());

    final lightColors = lightTheme.extension<PicoColorExtension>()!;
    final darkColors = darkTheme.extension<PicoColorExtension>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Light theme
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: lightColors.background.main,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Light',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: lightColors.foreground.main,
                ),
              ),
              SizedBox(height: spacing / 2),
              Theme(data: lightTheme, child: widget),
            ],
          ),
        ),
        SizedBox(width: spacing),
        // Dark theme
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: darkColors.background.main,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dark',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkColors.foreground.main,
                ),
              ),
              SizedBox(height: spacing / 2),
              Theme(data: darkTheme, child: widget),
            ],
          ),
        ),
      ],
    );
  }

  /// Creates a gallery widget showing multiple states of a component.
  ///
  /// Useful for testing multiple states in a single golden image.
  ///
  /// ```dart
  /// final gallery = GoldenTestHelper.buildVariantGallery(
  ///   title: 'Button States',
  ///   variants: [
  ///     ('Enabled', AppButton(label: 'Button', onPressed: () {})),
  ///     ('Disabled', AppButton(label: 'Button')),
  ///     ('Loading', AppButton(label: 'Button', isLoading: true)),
  ///   ],
  ///   themeMode: GoldenThemeMode.light,
  /// );
  /// ```
  static Widget buildVariantGallery({
    required String title,
    required List<(String label, Widget widget)> variants,
    GoldenThemeMode themeMode = GoldenThemeMode.light,
    GoldenTestFontFamily fontFamily = defaultFontFamily,
    EdgeInsets padding = const EdgeInsets.all(16),
    double itemSpacing = 24,
    double labelSpacing = 8,
  }) {
    final theme = themeMode == GoldenThemeMode.dark
        ? PicoTheme.dark(fontFamily: fontFamily.toAppFontFamily())
        : PicoTheme.light(fontFamily: fontFamily.toAppFontFamily());

    final colorExtension = theme.extension<PicoColorExtension>()!;

    return Theme(
      data: theme,
      child: Container(
        padding: padding,
        color: colorExtension.background.main,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorExtension.foreground.main,
              ),
            ),
            SizedBox(height: padding.top),
            Wrap(
              spacing: itemSpacing,
              runSpacing: itemSpacing,
              children: [
                for (final (label, widget) in variants)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget,
                      SizedBox(height: labelSpacing),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorExtension.foreground.subtle,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
