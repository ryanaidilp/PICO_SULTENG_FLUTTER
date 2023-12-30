part of 'pico_color_data.dart';

@immutable
class PicoNeutralColor {
  const PicoNeutralColor({
    required this.main,
    required this.subtle,
    required this.strong,
  });
  final Color main;
  final Color subtle;
  final Color strong;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoNeutralColor &&
        other.main == main &&
        other.subtle == subtle &&
        other.strong == strong;
  }

  @override
  int get hashCode => main.hashCode ^ subtle.hashCode ^ strong.hashCode;
}
