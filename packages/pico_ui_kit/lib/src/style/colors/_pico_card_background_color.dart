part of 'pico_color_data.dart';

@immutable
class PicoCardBackgroundColor {
  const PicoCardBackgroundColor._({
    required this.main,
  });

  factory PicoCardBackgroundColor.light() => const PicoCardBackgroundColor._(
        main: PicoColors.bgWhite,
      );

  factory PicoCardBackgroundColor.dark() => PicoCardBackgroundColor._(
        main: PicoColors.gray.shade800,
      );

  final Color main;

  PicoCardBackgroundColor lerp({
    required double t,
    required Color mainVariant,
  }) =>
      PicoCardBackgroundColor._(
        main: Color.lerp(main, mainVariant, t) ?? main,
      );

  PicoCardBackgroundColor copyWith({
    Color? main,
  }) =>
      PicoCardBackgroundColor._(
        main: main ?? this.main,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoCardBackgroundColor && other.main == main;
  }

  @override
  int get hashCode => main.hashCode;
}
