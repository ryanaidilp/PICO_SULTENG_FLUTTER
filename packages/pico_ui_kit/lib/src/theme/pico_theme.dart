import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          primaryColor: PicoColors.primary,
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: PicoColors.primary,
            onPrimary: Colors.white,
            secondary: PicoColors.secondary,
            onSecondary: Colors.white,
            error: PicoColors.error,
            onError: Colors.white,
            background: PicoColors.bgMain,
            onBackground: PicoColors.textMain,
            surface: PicoColors.bgSubtle,
            onSurface: PicoColors.textStrong,
          ),
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
          textButtonTheme: TextButtonThemeData(
            style: themeData.textButtonTheme.style?.copyWith(
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
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
          primaryColor: PicoColors.primary,
          colorScheme: ColorScheme.dark(
            primary: PicoColors.primary,
            onPrimary: Colors.white,
            secondary: PicoColors.secondary,
            onSecondary: Colors.white,
            error: PicoColors.error,
            onError: Colors.white,
            background: PicoColors.bgMainDark,
            onBackground: PicoColors.textMainDark,
            surface: PicoColors.bgSubtleDark,
          ),
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
          textButtonTheme: TextButtonThemeData(
            style: themeData.textButtonTheme.style?.copyWith(
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ),
      );
  final Brightness brightness;
  final ThemeData themeData;
}
