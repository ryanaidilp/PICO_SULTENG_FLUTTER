part of 'pico_color_data.dart';

@immutable
class PicoSemanticColor with PicoMaterialColor {
  const PicoSemanticColor({
    required this.info,
    required this.error,
    required this.success,
    required this.warning,
  });
  final MaterialColor success;
  final MaterialColor info;
  final MaterialColor error;
  final MaterialColor warning;

  PicoSemanticColor copyWith({
    MaterialColor? success,
    MaterialColor? info,
    MaterialColor? error,
    MaterialColor? warning,
  }) =>
      PicoSemanticColor(
        success: success ?? this.success,
        info: info ?? this.info,
        error: error ?? this.error,
        warning: warning ?? this.warning,
      );

  PicoSemanticColor lerp({
    required double t,
    required MaterialColor successVariant,
    required MaterialColor infoVariant,
    required MaterialColor errorVariant,
    required MaterialColor warningVariant,
  }) =>
      PicoSemanticColor(
        success: lerpMaterialColor(success, successVariant, t),
        info: lerpMaterialColor(info, infoVariant, t),
        error: lerpMaterialColor(error, errorVariant, t),
        warning: lerpMaterialColor(warning, warningVariant, t),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoSemanticColor &&
        other.success == success &&
        other.info == info &&
        other.error == error &&
        other.warning == warning;
  }

  @override
  int get hashCode {
    return success.hashCode ^ info.hashCode ^ error.hashCode ^ warning.hashCode;
  }
}