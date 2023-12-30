part of 'pico_color_data.dart';

@immutable
class PicoForegroundSemanticColor {
  const PicoForegroundSemanticColor({
    required this.success,
    required this.info,
    required this.error,
    required this.warning,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
  final Color success;
  final Color info;
  final Color error;
  final Color warning;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  PicoForegroundSemanticColor lerp({
    required double t,
    required Color successVariant,
    required Color infoVariant,
    required Color errorVariant,
    required Color warningVariant,
    required Color primaryVariant,
    required Color secondaryVariant,
    required Color tertiaryVariant,
  }) =>
      PicoForegroundSemanticColor(
        success: Color.lerp(success, successVariant, t) ?? success,
        info: Color.lerp(info, infoVariant, t) ?? info,
        error: Color.lerp(error, errorVariant, t) ?? error,
        warning: Color.lerp(warning, warningVariant, t) ?? warning,
        primary: Color.lerp(primary, primaryVariant, t) ?? primary,
        secondary: Color.lerp(secondary, secondaryVariant, t) ?? secondary,
        tertiary: Color.lerp(tertiary, tertiaryVariant, t) ?? tertiary,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoForegroundSemanticColor &&
        other.success == success &&
        other.info == info &&
        other.error == error &&
        other.warning == warning &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.tertiary == tertiary;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        info.hashCode ^
        error.hashCode ^
        warning.hashCode ^
        primary.hashCode ^
        secondary.hashCode ^
        tertiary.hashCode;
  }

  PicoForegroundSemanticColor copyWith({
    Color? success,
    Color? info,
    Color? error,
    Color? warning,
    Color? primary,
    Color? secondary,
    Color? tertiary,
  }) =>
      PicoForegroundSemanticColor(
        success: success ?? this.success,
        info: info ?? this.info,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
      );
}
