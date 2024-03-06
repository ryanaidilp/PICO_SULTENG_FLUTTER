part of 'pico_color_data.dart';

@immutable
class PicoSemanticColor with PicoMaterialColor {
  const PicoSemanticColor._({
    required this.info,
    required this.error,
    required this.success,
    required this.warning,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  factory PicoSemanticColor.light() => const PicoSemanticColor._(
        info: PicoColors.info,
        error: PicoColors.error,
        success: PicoColors.success,
        warning: PicoColors.warning,
        primary: PicoColors.primary,
        secondary: PicoColors.secondary,
        tertiary: PicoColors.tertiary,
      );

  factory PicoSemanticColor.dark() => const PicoSemanticColor._(
        info: PicoColors.info,
        error: PicoColors.error,
        success: PicoColors.success,
        warning: PicoColors.warning,
        primary: PicoColors.primary,
        secondary: PicoColors.secondary,
        tertiary: PicoColors.tertiary,
      );

  final MaterialColor success;
  final MaterialColor info;
  final MaterialColor error;
  final MaterialColor warning;
  final MaterialColor primary;
  final MaterialColor secondary;
  final MaterialColor tertiary;

  PicoSemanticColor copyWith({
    MaterialColor? success,
    MaterialColor? info,
    MaterialColor? error,
    MaterialColor? warning,
    MaterialColor? primary,
    MaterialColor? secondary,
    MaterialColor? tertiary,
  }) =>
      PicoSemanticColor._(
        success: success ?? this.success,
        info: info ?? this.info,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
      );

  PicoSemanticColor lerp({
    required double t,
    required MaterialColor successVariant,
    required MaterialColor infoVariant,
    required MaterialColor errorVariant,
    required MaterialColor warningVariant,
    required MaterialColor primaryVariant,
    required MaterialColor secondaryVariant,
    required MaterialColor tertiaryVariant,
  }) =>
      PicoSemanticColor._(
        success: lerpMaterialColor(success, successVariant, t),
        info: lerpMaterialColor(info, infoVariant, t),
        error: lerpMaterialColor(error, errorVariant, t),
        warning: lerpMaterialColor(warning, warningVariant, t),
        primary: lerpMaterialColor(primary, primaryVariant, t),
        secondary: lerpMaterialColor(secondary, secondaryVariant, t),
        tertiary: lerpMaterialColor(tertiary, tertiaryVariant, t),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoSemanticColor &&
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
}
