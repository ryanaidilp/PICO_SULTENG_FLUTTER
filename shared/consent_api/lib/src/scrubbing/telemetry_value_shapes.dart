/// Value-shape detectors used by the scrubber.
///
/// ## Why there is no `RegExp` in this file
///
/// These detectors run on every property of every analytics event, log line
/// and breadcrumb. A regex with nested or adjacent quantifiers (the natural
/// way to write an email or token pattern) can backtrack catastrophically on
/// a hostile or merely unlucky payload, turning a telemetry call into a
/// multi-second CPU stall on the UI isolate.
///
/// Every detector below is a single forward scan over code units with an
/// explicit upper bound, so cost is linear and predictable. This is a
/// deliberate trade of a little precision for a hard worst-case guarantee.
library;

/// Character-scan detectors for personally-identifying value shapes.
abstract final class TelemetryValueShapes() {
  static const int _at = 0x40; // @
  static const int _dot = 0x2E; // .
  static const int _dash = 0x2D; // -
  static const int _underscore = 0x5F; // _
  static const int _plus = 0x2B; // +
  static const int _percent = 0x25; // %
  static const int _space = 0x20;
  static const int _openParen = 0x28;
  static const int _closeParen = 0x29;
  static const int _zero = 0x30;
  static const int _nine = 0x39;
  static const int _upperA = 0x41;
  static const int _upperZ = 0x5A;
  static const int _lowerA = 0x61;
  static const int _lowerZ = 0x7A;

  /// Longest domain suffix examined after an `@`. Bounds the inner scan so a
  /// pathological string of `@` characters stays O(n * 253), never O(n^2)
  /// unbounded. 253 is the maximum length of a DNS name.
  static const int _maxDomainScan = 253;

  /// Minimum length of a base64url-ish run before it is treated as a secret.
  static const int _minTokenRun = 32;

  /// Whether [value] contains something shaped like an email address.
  ///
  /// Matches `local@domain.tld` anywhere in the string, requiring at least
  /// one local-part character, at least one domain label, and a TLD of two or
  /// more letters.
  static bool looksLikeEmail(String value) {
    final length = value.length;
    for (var i = 1; i < length; i++) {
      if (value.codeUnitAt(i) != _at) continue;
      if (!_isLocalPartChar(value.codeUnitAt(i - 1))) continue;

      final limit = (i + 1 + _maxDomainScan) < length
          ? i + 1 + _maxDomainScan
          : length;
      var cursor = i + 1;
      var lastDot = -1;
      while (cursor < limit) {
        final unit = value.codeUnitAt(cursor);
        if (unit == _dot) {
          lastDot = cursor;
        } else if (!_isDomainChar(unit)) {
          break;
        }
        cursor++;
      }

      // Need at least one label character between '@' and the final dot.
      if (lastDot <= i + 1) continue;

      var tldLength = 0;
      var tldIsAlpha = true;
      for (var k = lastDot + 1; k < cursor; k++) {
        if (!_isAlpha(value.codeUnitAt(k))) {
          tldIsAlpha = false;
          break;
        }
        tldLength++;
      }
      if (tldIsAlpha && tldLength >= 2) return true;
    }
    return false;
  }

  /// Whether [value] contains a run of at least [threshold] digits.
  ///
  /// Intra-number separators (`-`, `.`, `+`, parentheses) do not break a run,
  /// so `+62 812-3456-7890` reaches 11 digits and a dotted IPv4 address —
  /// itself personal data under GDPR — reaches its total. Whitespace and every
  /// other character *do* reset the run, which is what keeps
  /// `2026-01-15 10:30:45` at 8 rather than 10.
  ///
  /// Deliberately **not** applied to numeric values by the scrubber — a
  /// millisecond epoch is 13 digits and would otherwise be redacted from
  /// every event.
  static bool hasLongDigitRun(String value, int threshold) {
    if (threshold <= 0) return false;
    // A UUID's final group is 12 hex characters and is all-digits often
    // enough to matter. Session, trace and correlation IDs are among the most
    // common values in telemetry, so redacting them would break exactly the
    // debugging the payload exists for.
    if (isUuid(value)) return false;

    var run = 0;
    for (var i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (unit >= _zero && unit <= _nine) {
        run++;
        if (run >= threshold) return true;
      } else if (!_isDigitSeparator(unit)) {
        run = 0;
      }
    }
    return false;
  }

  /// Whether [value] is exactly a canonical 8-4-4-4-12 hex UUID.
  static bool isUuid(String value) {
    if (value.length != 36) return false;
    for (var i = 0; i < 36; i++) {
      final unit = value.codeUnitAt(i);
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        if (unit != _dash) return false;
      } else if (!_isHexDigit(unit)) {
        return false;
      }
    }
    return true;
  }

  /// Whether [value] looks like a credential.
  ///
  /// Recognises three shapes: an explicit `Bearer ` prefix, a JWT (`eyJ` plus
  /// two dots), and any sufficiently long base64url-ish run that mixes case
  /// and digits (API keys, session tokens).
  static bool looksLikeBearerToken(String value) {
    if (_startsWithIgnoreCase(value, 'bearer ')) return true;
    if (_looksLikeJwt(value)) return true;

    var run = 0;
    var hasDigit = false;
    var hasUpper = false;
    var hasLower = false;
    for (var i = 0; i <= value.length; i++) {
      final unit = i < value.length ? value.codeUnitAt(i) : _space;
      if (_isTokenChar(unit)) {
        run++;
        if (unit >= _zero && unit <= _nine) {
          hasDigit = true;
        } else if (unit >= _upperA && unit <= _upperZ) {
          hasUpper = true;
        } else if (unit >= _lowerA && unit <= _lowerZ) {
          hasLower = true;
        }
        continue;
      }
      if (run >= _minTokenRun && hasDigit && hasUpper && hasLower) return true;
      run = 0;
      hasDigit = false;
      hasUpper = false;
      hasLower = false;
    }
    return false;
  }

  static bool _looksLikeJwt(String value) {
    final start = value.indexOf('eyJ');
    if (start < 0) return false;
    var dots = 0;
    for (var i = start; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (unit == _dot) {
        dots++;
        if (dots >= 2) return true;
      } else if (!_isTokenChar(unit)) {
        return false;
      }
    }
    return false;
  }

  static bool _startsWithIgnoreCase(String value, String prefix) {
    if (value.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (_toLower(value.codeUnitAt(i)) != prefix.codeUnitAt(i)) return false;
    }
    return true;
  }

  static int _toLower(int unit) =>
      (unit >= _upperA && unit <= _upperZ) ? unit + 32 : unit;

  static bool _isAlpha(int unit) =>
      (unit >= _upperA && unit <= _upperZ) ||
      (unit >= _lowerA && unit <= _lowerZ);

  static bool _isAlphaNumeric(int unit) =>
      _isAlpha(unit) || (unit >= _zero && unit <= _nine);

  static bool _isLocalPartChar(int unit) =>
      _isAlphaNumeric(unit) ||
      unit == _dot ||
      unit == _dash ||
      unit == _underscore ||
      unit == _plus ||
      unit == _percent;

  static bool _isDomainChar(int unit) => _isAlphaNumeric(unit) || unit == _dash;

  static bool _isTokenChar(int unit) =>
      _isAlphaNumeric(unit) || unit == _dash || unit == _underscore;

  static bool _isDigitSeparator(int unit) =>
      unit == _dash ||
      unit == _dot ||
      unit == _plus ||
      unit == _openParen ||
      unit == _closeParen;

  static bool _isHexDigit(int unit) =>
      (unit >= _zero && unit <= _nine) ||
      (unit >= 0x41 && unit <= 0x46) ||
      (unit >= 0x61 && unit <= 0x66);
}
