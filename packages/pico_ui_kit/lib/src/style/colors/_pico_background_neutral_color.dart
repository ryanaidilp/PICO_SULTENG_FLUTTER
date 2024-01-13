part of 'pico_color_data.dart';

class PicoBackgroundNeutralColor extends PicoNeutralColor {
  const PicoBackgroundNeutralColor._({
    required super.main,
    required super.subtle,
    required super.strong,
    required this.white,
    required this.inverse,
  });

  factory PicoBackgroundNeutralColor.light() => PicoBackgroundNeutralColor._(
        main: PicoColors.bgMain,
        subtle: PicoColors.bgSubtle,
        strong: PicoColors.bgStrong,
        white: PicoColors.bgWhite,
        inverse: PicoColors.bgInverse,
      );

  factory PicoBackgroundNeutralColor.dark() => PicoBackgroundNeutralColor._(
       main: PicoColors.bgMainDark,
        subtle: PicoColors.bgSubtleDark,
        strong: PicoColors.bgStrongDark,
        white: PicoColors.bgWhiteDark,
        inverse: PicoColors.bgInverseDark,
      );

  final Color white;
  final Color inverse;

  PicoBackgroundNeutralColor lerp({
    required double t,
    required Color mainVariant,
    required Color subtleVariant,
    required Color strongVariant,
    required Color whiteVariant,
    required Color inverseVariant,
  }) =>
      PicoBackgroundNeutralColor._(
        main: Color.lerp(main, mainVariant, t) ?? main,
        subtle: Color.lerp(subtle, subtleVariant, t) ?? subtle,
        strong: Color.lerp(strong, strongVariant, t) ?? strong,
        white: Color.lerp(white, whiteVariant, t) ?? white,
        inverse: Color.lerp(inverse, inverseVariant, t) ?? inverse,
      );

  PicoBackgroundNeutralColor copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
    Color? white,
    Color? inverse,
  }) => PicoBackgroundNeutralColor._(
      main: main ?? this.main,
      subtle: subtle ?? this.subtle,
      strong: strong ?? this.strong,
      white: white ?? this.white,
      inverse: inverse ?? this.inverse,
    );
}
