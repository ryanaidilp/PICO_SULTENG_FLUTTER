import 'package:dependencies_core/meta.dart';

/// Declarative redaction policy for outbound telemetry payloads.
///
/// One instance is shared by analytics events, monitoring log lines and crash
/// breadcrumbs so there is a single rule set to review, not three.
///
/// Every field is overridable per app — the risk that value-shape detection
/// produces false positives (a support-ticket ID that happens to be a long
/// digit run) is real, and the answer is tuning, not switching the scrubber
/// off. Pair tuning with `DefaultTelemetryScrubber`'s debug-build redaction
/// log so you can see what is actually being redacted before you relax a rule.
@immutable
class const ScrubRules({
  /// Key fragments that make a property personal irrespective of value.
  final List<String> deniedKeySubstrings = defaultDeniedKeySubstrings,

  /// Whole-token key fragments that make a property personal.
  final List<String> deniedKeyTokens = defaultDeniedKeyTokens,

  /// When non-null, switches the scrubber to **default-deny**: any key whose
  /// normalised form is absent from this set is redacted.
  ///
  /// Use for high-risk surfaces (payments, health) where enumerating what is
  /// safe to send is more tractable than enumerating what is not.
  final Set<String>? allowedKeys,

  /// Replacement for redacted values.
  final String redactionMarker = defaultRedactionMarker,

  /// Whether string values shaped like an email address are redacted.
  final bool detectEmailValues = true,

  /// Whether string values containing a long digit run are redacted.
  final bool detectDigitRuns = true,

  /// Whether string values shaped like a credential are redacted.
  final bool detectBearerTokens = true,

  /// Digits in a row before a string value is redacted.
  final int digitRunThreshold = defaultDigitRunThreshold,

  /// Map entries examined before the remainder is redacted wholesale.
  ///
  /// Bounds worst-case cost on a hostile or accidental mega-payload. The
  /// overflow is redacted rather than passed through, so the bound fails
  /// closed.
  final int maxScannedEntries = defaultMaxScannedEntries,

  /// Characters examined per payload before the remainder is redacted.
  final int maxScannedCharacters = defaultMaxScannedCharacters,

  /// Nesting levels walked before a subtree is redacted wholesale.
  final int maxDepth = defaultMaxDepth,
}) {
  /// Creates a rule set. All parameters have production-safe defaults.
  this;

  /// The marker substituted for a redacted value.
  ///
  /// Stable and non-empty on purpose: dropping the key entirely makes an
  /// event indistinguishable from one that never had the property, which
  /// hides redaction from anyone reviewing vendor data.
  static const String defaultRedactionMarker = '[redacted]';

  /// Digits in a row before a string value is treated as an identifier.
  ///
  /// 10 rather than 9 so an ISO-ish `20240115` date (8) and a 9-digit order
  /// number stay intact while Indonesian NIK (16), phone numbers (10-13) and
  /// card numbers (13-19) are caught.
  static const int defaultDigitRunThreshold = 10;

  /// Map entries examined before the remainder is redacted wholesale.
  static const int defaultMaxScannedEntries = 128;

  /// Characters examined per payload before the remainder is redacted.
  static const int defaultMaxScannedCharacters = 16384;

  /// Nesting levels walked before a subtree is redacted wholesale.
  static const int defaultMaxDepth = 3;

  /// Key fragments that mark a property as personal regardless of its value.
  ///
  /// Matched as substrings of the *normalised* key (lower-cased, separators
  /// and camelCase boundaries removed), so `userEmail`, `user_email` and
  /// `USER-EMAIL` all match `email`.
  ///
  /// Only fragments long and specific enough to be unambiguous belong here;
  /// short ambiguous ones go in [deniedKeyTokens].
  ///
  /// Kept in sync by hand with `app_lints`' `no_pii_in_telemetry` rule, which
  /// cannot depend on this package (analyzer plugins resolve their own
  /// dependency graph, so the plugin is kept dependency-free).
  static const List<String> defaultDeniedKeySubstrings = [
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

  /// Short, ambiguous key fragments matched as whole tokens only.
  ///
  /// `nik` must not match `technik` or `picnik`, so these are compared
  /// against individual key tokens rather than as substrings.
  static const List<String> defaultDeniedKeyTokens = [
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

  /// Whether the scrubber is operating in default-deny mode.
  bool get isDefaultDeny => allowedKeys != null;

  /// Returns a copy with the given overrides applied.
  ScrubRules copyWith({
    List<String>? deniedKeySubstrings,
    List<String>? deniedKeyTokens,
    Set<String>? allowedKeys,
    String? redactionMarker,
    bool? detectEmailValues,
    bool? detectDigitRuns,
    bool? detectBearerTokens,
    int? digitRunThreshold,
    int? maxScannedEntries,
    int? maxScannedCharacters,
    int? maxDepth,
  }) => ScrubRules(
    deniedKeySubstrings: deniedKeySubstrings ?? this.deniedKeySubstrings,
    deniedKeyTokens: deniedKeyTokens ?? this.deniedKeyTokens,
    allowedKeys: allowedKeys ?? this.allowedKeys,
    redactionMarker: redactionMarker ?? this.redactionMarker,
    detectEmailValues: detectEmailValues ?? this.detectEmailValues,
    detectDigitRuns: detectDigitRuns ?? this.detectDigitRuns,
    detectBearerTokens: detectBearerTokens ?? this.detectBearerTokens,
    digitRunThreshold: digitRunThreshold ?? this.digitRunThreshold,
    maxScannedEntries: maxScannedEntries ?? this.maxScannedEntries,
    maxScannedCharacters: maxScannedCharacters ?? this.maxScannedCharacters,
    maxDepth: maxDepth ?? this.maxDepth,
  );
}
