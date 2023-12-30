part of 'pico_color_data.dart';

class PicoForegroundNeutral extends PicoNeutralColor {
  const PicoForegroundNeutral({
    required super.main,
    required super.subtle,
    required super.strong,
    required this.disabled,
    required this.inverse,
    required this.onImageStrong,
    required this.onImageSubtle,
  });

  final Color onImageStrong;
  final Color onImageSubtle;
  final Color disabled;
  final Color inverse;

  PicoForegroundNeutral lerp({
    required double t,
    required Color mainVariant,
    required Color subtleVariant,
    required Color strongVariant,
    required Color disabledVariant,
    required Color inverseVariant,
    required Color onImageStrongVariant,
    required Color onImageSubtleVariant,
  }) =>
      PicoForegroundNeutral(
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

  PicoForegroundNeutral copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
    Color? onImageStrong,
    Color? onImageSubtle,
    Color? disabled,
    Color? inverse,
  }) {
    return PicoForegroundNeutral(
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

class PicoTextNeutral extends PicoForegroundNeutral {
  const PicoTextNeutral({
    required super.main,
    required super.subtle,
    required super.strong,
    required super.disabled,
    required super.inverse,
    required super.onImageStrong,
    required super.onImageSubtle,
  });
}
