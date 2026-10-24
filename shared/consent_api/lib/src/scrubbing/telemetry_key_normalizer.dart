import 'package:dependencies_core/meta.dart';

/// A property key reduced to a comparable form.
@immutable
class const NormalizedKey({
  /// All tokens lower-cased and concatenated, e.g. `userEmail` -> `useremail`.
  ///
  /// Substring rules match against this so `user_email`, `userEmail` and
  /// `USER-EMAIL` behave identically.
  required final String flattened,

  /// The individual lower-cased tokens, e.g. `['user', 'email']`.
  ///
  /// Whole-token rules match against these so short, ambiguous fragments like
  /// `nik` do not fire on `technik`.
  required final List<String> tokens,
}) {
  /// Creates a normalised key.
  this;
}

/// Splits telemetry property keys into comparable tokens.
///
/// Handles the three casings that appear in practice across vendor SDKs:
/// `snake_case`, `kebab-case`, `dotted.path` and `camelCase`.
abstract final class TelemetryKeyNormalizer() {
  static const int _zero = 0x30;
  static const int _nine = 0x39;
  static const int _upperA = 0x41;
  static const int _upperZ = 0x5A;
  static const int _lowerA = 0x61;
  static const int _lowerZ = 0x7A;

  /// Normalises [key].
  static NormalizedKey normalize(String key) {
    final tokens = <String>[];
    final current = StringBuffer();
    var previousWasLowerOrDigit = false;

    void flush() {
      if (current.isNotEmpty) {
        tokens.add(current.toString());
        current.clear();
      }
    }

    for (var i = 0; i < key.length; i++) {
      final unit = key.codeUnitAt(i);
      final isUpper = unit >= _upperA && unit <= _upperZ;
      final isLower = unit >= _lowerA && unit <= _lowerZ;
      final isDigit = unit >= _zero && unit <= _nine;

      if (!isUpper && !isLower && !isDigit) {
        flush();
        previousWasLowerOrDigit = false;
        continue;
      }
      if (isUpper && previousWasLowerOrDigit) flush();
      current.writeCharCode(isUpper ? unit + 32 : unit);
      previousWasLowerOrDigit = isLower || isDigit;
    }
    flush();

    return NormalizedKey(flattened: tokens.join(), tokens: tokens);
  }
}
