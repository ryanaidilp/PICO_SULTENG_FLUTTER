part of 'pico_color_data.dart';

class PicoForegroundNeutralColor extends PicoNeutralColor {
  const PicoForegroundNeutralColor._({
    required super.main,
    required super.subtle,
    required super.strong,
    required this.disabled,
    required this.inverse,
    required this.onImageStrong,
    required this.onImageSubtle,
  });

  factory PicoForegroundNeutralColor.light() => PicoForegroundNeutralColor._(
        main: PicoColors.textMain,
        subtle: PicoColors.textSubtle,
        strong: PicoColors.textStrong,
        disabled: PicoColors.textDisabled,
        inverse: PicoColors.textInverse,
        onImageStrong: PicoColors.textOnImageStrong,
        onImageSubtle: PicoColors.textOnImageSubtle,
      );

  factory PicoForegroundNeutralColor.dark() => PicoForegroundNeutralColor._(
        main: PicoColors.textMainDark,
        subtle: PicoColors.textSubtleDark,
        strong: PicoColors.textStrongDark,
        disabled: PicoColors.textDisabledDark,
        inverse: PicoColors.textInverseDark,
        onImageStrong: PicoColors.textOnImageStrongDark,
        onImageSubtle: PicoColors.textOnImageSubtleDark,
      );

  final Color onImageStrong;
  final Color onImageSubtle;
  final Color disabled;
  final Color inverse;

  PicoForegroundNeutralColor lerp({
    required double t,
    required Color mainVariant,
    required Color subtleVariant,
    required Color strongVariant,
    required Color disabledVariant,
    required Color inverseVariant,
    required Color onImageStrongVariant,
    required Color onImageSubtleVariant,
  }) =>
      PicoForegroundNeutralColor._(
        main: Color.lerp(main, mainVariant, t) ?? main,
        subtle: Color.lerp(subtle, subtleVariant, t) ?? subtle,
        strong: Color.lerp(strong, strongVariant, t) ?? strong,
        disabled: Color.lerp(disabled, disabledVariant, t) ?? disabled,
        inverse: Color.lerp(inverse, inverseVariant, t) ?? inverse,
        onImageStrong:
            Color.lerp(onImageStrong, onImageStrongVariant, t) ?? onImageStrong,
        onImageSubtle:
            Color.lerp(onImageSubtle, onImageSubtleVariant, t) ?? onImageSubtle,
      );

  PicoForegroundNeutralColor copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
    Color? onImageStrong,
    Color? onImageSubtle,
    Color? disabled,
    Color? inverse,
  }) {
    return PicoForegroundNeutralColor._(
      main: main ?? this.main,
      strong: strong ?? this.strong,
      subtle: subtle ?? this.subtle,
      onImageStrong: onImageStrong ?? this.onImageStrong,
      onImageSubtle: onImageSubtle ?? this.onImageSubtle,
      disabled: disabled ?? this.disabled,
      inverse: inverse ?? this.inverse,
    );
  }
}
