part of 'pico_color_data.dart';

@immutable
class PicoOutlineNeutralColor extends PicoNeutralColor {
  const PicoOutlineNeutralColor({
    required super.main,
    required super.subtle,
    required super.strong,
  });

  PicoOutlineNeutralColor? copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
  }) =>
      PicoOutlineNeutralColor(
        main: main ?? this.main,
        subtle: subtle ?? this.subtle,
        strong: strong ?? this.strong,
      );

  PicoOutlineNeutralColor? lerp({
    required double t,
    required Color mainVariant,
    required Color subtleVariant,
    required Color strongVariant,
  }) =>
      PicoOutlineNeutralColor(
        main: Color.lerp(main, mainVariant, t) ?? main,
        subtle: Color.lerp(subtle, subtleVariant, t) ?? subtle,
        strong: Color.lerp(strong, strongVariant, t) ?? strong,
      );
}

@immutable
class PicoOutlineSemanticColor extends PicoForegroundSemanticColor {
  const PicoOutlineSemanticColor({
    required super.info,
    required super.error,
    required super.success,
    required super.warning,
    required super.primary,
    required super.secondary,
    required super.tertiary,
  });

  @override
  PicoOutlineSemanticColor lerp({
    required double t,
    required Color successVariant,
    required Color infoVariant,
    required Color errorVariant,
    required Color warningVariant,
    required Color primaryVariant,
    required Color secondaryVariant,
    required Color tertiaryVariant,
  }) =>
      PicoOutlineSemanticColor(
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

    return other is PicoOutlineSemanticColor &&
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

  @override
  PicoOutlineSemanticColor copyWith({
    Color? success,
    Color? info,
    Color? error,
    Color? warning,
    Color? primary,
    Color? secondary,
    Color? tertiary,
  }) =>
      PicoOutlineSemanticColor(
        success: success ?? this.success,
        info: info ?? this.info,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
      );
}

@immutable
class PicoOutlineColor {
  const PicoOutlineColor({
    required this.neutral,
    required this.semantic,
  });
  final PicoOutlineNeutralColor neutral;
  final PicoOutlineSemanticColor semantic;

  PicoOutlineColor copyWith({
    PicoOutlineNeutralColor? neutral,
    PicoOutlineSemanticColor? semantic,
  }) =>
      PicoOutlineColor(
        neutral: neutral ?? this.neutral,
        semantic: semantic ?? this.semantic,
      );

  PicoOutlineColor lerp({
    required double t,
    required PicoOutlineNeutralColor neutralVariant,
    required PicoOutlineSemanticColor semanticVariant,
  }) =>
      PicoOutlineColor(
        neutral: neutral.lerp(
              t: t,
              mainVariant: neutralVariant.main,
              subtleVariant: neutralVariant.subtle,
              strongVariant: neutralVariant.strong,
            ) ??
            neutral,
        semantic: semantic.lerp(
          t: t,
          successVariant: semanticVariant.success,
          infoVariant: semanticVariant.info,
          errorVariant: semanticVariant.error,
          warningVariant: semanticVariant.warning,
          primaryVariant: semanticVariant.primary,
          secondaryVariant: semanticVariant.secondary,
          tertiaryVariant: semanticVariant.tertiary,
        ),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoOutlineColor &&
        other.neutral == neutral &&
        other.semantic == semantic;
  }

  @override
  int get hashCode => neutral.hashCode ^ semantic.hashCode;
}
