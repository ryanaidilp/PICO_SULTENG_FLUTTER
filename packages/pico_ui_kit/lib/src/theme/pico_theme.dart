import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pico_ui_kit/src/style/styles.dart';
import 'package:pico_ui_kit/src/theme/pico_color_theme.dart';

class PicoTheme {
  const PicoTheme._({
    required this.brightness,
    required this.themeData,
  });

  factory PicoTheme.light(
    ThemeData themeData,
  ) =>
      PicoTheme._(
        brightness: Brightness.light,
        themeData: themeData.copyWith(
          scaffoldBackgroundColor: PicoColors.bgMain,
          textTheme: GoogleFonts.sourceSans3TextTheme(themeData.textTheme),
          extensions: [
            PicoColorTheme.light(),
          ],
          appBarTheme: AppBarTheme(
            color: PicoColors.bgMain,
            foregroundColor: PicoColors.textMain,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
        ),
      );

  factory PicoTheme.dark(
    ThemeData themeData,
  ) =>
      PicoTheme._(
        brightness: Brightness.dark,
        themeData: themeData.copyWith(
          scaffoldBackgroundColor: PicoColors.bgMainDark,
          textTheme: GoogleFonts.sourceSans3TextTheme(themeData.textTheme),
          extensions: [
            PicoColorTheme.dark(),
          ],
          appBarTheme: AppBarTheme(
            color: PicoColors.bgMainDark,
            foregroundColor: PicoColors.textMainDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
        ),
      );
  final Brightness brightness;
  final ThemeData themeData;
}
