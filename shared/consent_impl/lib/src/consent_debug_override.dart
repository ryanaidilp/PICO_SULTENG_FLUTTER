import 'package:consent_api/consent_api.dart';
import 'package:flutter/foundation.dart';

/// Debug-build escape hatch for the fail-closed consent default.
///
/// ## Why this exists
///
/// The gate denies every purpose until the user decides. That is the correct
/// production behaviour, but it silences telemetry in QA, integration tests
/// and manual smoke runs that never show a consent sheet. Without a sanctioned
/// override, the predictable outcome is a team "temporarily" seeding a granted
/// state in production code — which is how a fail-closed gate quietly becomes
/// fail-open.
///
/// So the override is explicit, narrow and loud:
///
/// * **Debug builds only.** [isActive] is hard-gated on [kDebugMode]; in a
///   profile or release build every method here is inert. There is no
///   configuration that turns it on in production.
/// * **Off unless asked for.** Even in debug it does nothing until either the
///   `CONSENT_DEBUG_GRANT_ALL` dart-define is set or [enable] is called.
/// * **Visible.** Grants it produces are recorded with
///   [ConsentSource.debugOverride], so `ConsentGate.state` shows exactly which
///   decisions are real and which are forced. The app debugger surfaces this.
///
/// ## Usage
///
/// ```sh
/// flutter run --dart-define=CONSENT_DEBUG_GRANT_ALL=true
/// ```
///
/// or, from a debug-only surface such as the debugger panel:
///
/// ```dart
/// ConsentDebugOverride.enable();
/// await gate.applyDebugOverride();
/// ```
abstract final class ConsentDebugOverride() {
  /// Dart-define that force-grants every purpose in debug builds.
  static const String dartDefineKey = 'CONSENT_DEBUG_GRANT_ALL';

  static const bool _grantAllFromEnvironment = bool.fromEnvironment(
    dartDefineKey,
  );

  static bool _enabledAtRuntime = false;

  /// Whether the override is currently in force.
  ///
  /// Always `false` outside debug builds.
  static bool get isActive =>
      kDebugMode && (_grantAllFromEnvironment || _enabledAtRuntime);

  /// Whether the override came from the dart-define rather than a runtime
  /// toggle. Useful for explaining *why* consent looks granted.
  static bool get isFromEnvironment => kDebugMode && _grantAllFromEnvironment;

  /// Turns the override on for the rest of the process.
  ///
  /// No-op outside debug builds.
  static void enable() {
    if (!kDebugMode) return;
    _enabledAtRuntime = true;
  }

  /// Turns a runtime-enabled override back off.
  ///
  /// Does not clear the dart-define; a build launched with
  /// `CONSENT_DEBUG_GRANT_ALL=true` stays overridden.
  static void disable() {
    _enabledAtRuntime = false;
  }

  /// Human-readable explanation for debug UI and logs.
  static String get description {
    if (!kDebugMode) {
      return 'Consent debug override is unavailable outside debug builds.';
    }
    if (_grantAllFromEnvironment) {
      return 'Consent debug override ACTIVE via --dart-define=$dartDefineKey. '
          'All purposes are force-granted; decisions are tagged '
          '"${ConsentSource.debugOverride.storageKey}".';
    }
    if (_enabledAtRuntime) {
      return 'Consent debug override ACTIVE (enabled at runtime). '
          'All purposes are force-granted; decisions are tagged '
          '"${ConsentSource.debugOverride.storageKey}".';
    }
    return 'Consent debug override inactive. Telemetry is gated by real '
        'user consent. Launch with --dart-define=$dartDefineKey=true to '
        'force-grant in debug builds.';
  }

  /// Resets runtime state between tests.
  @visibleForTesting
  static void reset() {
    _enabledAtRuntime = false;
  }
}
