part of 'pico_color_data.dart';

@immutable
class PicoOutlineNeutralColor extends PicoNeutralColor {
  const PicoOutlineNeutralColor._({
    required super.main,
    required super.subtle,
    required super.strong,
  });

  factory PicoOutlineNeutralColor.light() => PicoOutlineNeutralColor._(
        main: Colors.black.withOpacity(0.1),
        subtle: Colors.black.withOpacity(0.05),
        strong: Colors.black.withOpacity(0.25),
      );
  factory PicoOutlineNeutralColor.dark() => PicoOutlineNeutralColor._(
        main: Colors.white.withOpacity(0.1),
        subtle: Colors.white.withOpacity(0.05),
        strong: Colors.white.withOpacity(0.25),
      );

  PicoOutlineNeutralColor? copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
  }) =>
      PicoOutlineNeutralColor._(
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
      PicoOutlineNeutralColor._(
        main: Color.lerp(main, mainVariant, t) ?? main,
        subtle: Color.lerp(subtle, subtleVariant, t) ?? subtle,
        strong: Color.lerp(strong, strongVariant, t) ?? strong,
      );
}

@immutable
class PicoOutlineColor {
  const PicoOutlineColor._({
    required this.neutral,
    required this.semantic,
  });

  factory PicoOutlineColor.light() => PicoOutlineColor._(
        neutral: PicoOutlineNeutralColor.light(),
        semantic: PicoForegroundSemanticColor.lightOutline(),
      );
  factory PicoOutlineColor.dark() => PicoOutlineColor._(
        neutral: PicoOutlineNeutralColor.dark(),
        semantic: PicoForegroundSemanticColor.darkOutline(),
      );

  final PicoOutlineNeutralColor neutral;
  final PicoForegroundSemanticColor semantic;

  PicoOutlineColor copyWith({
    PicoOutlineNeutralColor? neutral,
    PicoForegroundSemanticColor? semantic,
  }) =>
      PicoOutlineColor._(
        neutral: neutral ?? this.neutral,
        semantic: semantic ?? this.semantic,
      );

  PicoOutlineColor lerp({
    required double t,
    required PicoOutlineNeutralColor neutralVariant,
    required PicoForegroundSemanticColor semanticVariant,
  }) =>
      PicoOutlineColor._(
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
