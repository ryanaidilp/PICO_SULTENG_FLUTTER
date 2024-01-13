part of 'pico_color_data.dart';

@immutable
class PicoBackgroundColor {
  const PicoBackgroundColor._({
    required this.card,
    required this.neutral,
  });

  factory PicoBackgroundColor.light() => PicoBackgroundColor._(
        card: PicoCardBackgroundColor.light(),
        neutral: PicoBackgroundNeutralColor.light(),
      );

  factory PicoBackgroundColor.dark() => PicoBackgroundColor._(
        card: PicoCardBackgroundColor.dark(),
        neutral: PicoBackgroundNeutralColor.dark(),
      );

  final PicoCardBackgroundColor card;
  final PicoBackgroundNeutralColor neutral;

  PicoBackgroundColor lerp({
    required double t,
    required PicoCardBackgroundColor cardVariant,
    required PicoBackgroundNeutralColor neutralVariant,
  }) =>
      PicoBackgroundColor._(
        card: card.lerp(t: t, mainVariant: cardVariant.main),
        neutral: neutral.lerp(
          t: t,
          mainVariant: neutralVariant.main,
          subtleVariant: neutralVariant.subtle,
          strongVariant: neutralVariant.strong,
          whiteVariant: neutralVariant.white,
          inverseVariant: neutralVariant.inverse,
        ),
      );

  PicoBackgroundColor copyWith({
    PicoCardBackgroundColor? card,
    PicoBackgroundNeutralColor? neutral,
  }) =>
      PicoBackgroundColor._(
        card: card ?? this.card,
        neutral: neutral ?? this.neutral,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoBackgroundColor &&
        other.card == card &&
        other.neutral == neutral;
  }

  @override
  int get hashCode => card.hashCode ^ neutral.hashCode;
}
