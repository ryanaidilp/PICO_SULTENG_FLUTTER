/// Deny-list matching for telemetry property keys.
///
/// ## Intentional duplication
///
/// These lists mirror `ScrubRules.defaultDeniedKeySubstrings` and
/// `ScrubRules.defaultDeniedKeyTokens` in `shared/consent_api`. They are
/// duplicated rather than imported on purpose: this package is loaded by the
/// analysis server as a plugin, which resolves its own dependency graph in a
/// separate isolate, and every extra dependency is another way for the plugin
/// to fail to load in a consumer's IDE. A lint that silently stops running is
/// worse than a lint that needs a two-line update when the rule set changes.
///
/// Keep the two in sync when either changes.
abstract final class PiiKeyMatcher() {
  /// Key fragments matched as substrings of the normalised key.
  static const List<String> deniedSubstrings = [
    'email',
    'phone',
    'msisdn',
    'password',
    'passwd',
    'passphrase',
    'secret',
    'token',
    'apikey',
    'authorization',
    'credential',
    'address',
    'postcode',
    'zipcode',
    'birthdate',
    'dateofbirth',
    'fullname',
    'firstname',
    'lastname',
    'givenname',
    'surname',
    'creditcard',
    'cardnumber',
    'accountnumber',
    'taxid',
    'passport',
    'latitude',
    'longitude',
  ];

  /// Short, ambiguous fragments matched as whole tokens only, so `nik` does
  /// not fire on `technik`.
  static const List<String> deniedTokens = [
    'nik',
    'ktp',
    'npwp',
    'ssn',
    'dob',
    'cvv',
    'cvc',
    'pin',
    'otp',
    'iban',
    'pan',
  ];

  /// Whether [key] names a personal field.
  static bool isDenied(String key) {
    final tokens = tokenize(key);
    for (final token in tokens) {
      if (deniedTokens.contains(token)) return true;
    }
    final flattened = tokens.join();
    for (final fragment in deniedSubstrings) {
      if (flattened.contains(fragment)) return true;
    }
    return false;
  }

  /// Splits [key] into lower-cased tokens, handling `snake_case`,
  /// `kebab-case`, `dotted.path` and `camelCase`.
  ///
  /// Mirrors `TelemetryKeyNormalizer.normalize` in `consent_api`.
  static List<String> tokenize(String key) {
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
      final isUpper = unit >= 0x41 && unit <= 0x5A;
      final isLower = unit >= 0x61 && unit <= 0x7A;
      final isDigit = unit >= 0x30 && unit <= 0x39;

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
    return tokens;
  }
}
