part of 'pico_color_data.dart';

class PicoBackgroundNeutralColor extends PicoNeutralColor {
  const PicoBackgroundNeutralColor({
    required super.main,
    required super.subtle,
    required super.strong,
    required this.white,
    required this.inverse,
  });

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
      PicoBackgroundNeutralColor(
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
  }) {
    return PicoBackgroundNeutralColor(
      main: main ?? this.main,
      subtle: subtle ?? this.subtle,
      strong: strong ?? this.strong,
      white: white ?? this.white,
      inverse: inverse ?? this.inverse,
    );
  }
}
