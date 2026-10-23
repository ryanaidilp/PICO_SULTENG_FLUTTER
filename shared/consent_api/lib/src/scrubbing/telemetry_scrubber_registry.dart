import 'package:consent_api/src/scrubbing/rule_based_telemetry_scrubber.dart';
import 'package:consent_api/src/scrubbing/telemetry_scrubber.dart';
import 'package:dependencies_core/meta.dart';

/// Ambient holder for the app's [TelemetryScrubber].
///
/// Unlike `ConsentGateRegistry`, the default here is **not** inert: an app
/// that never installs a scrubber still gets [RuleBasedTelemetryScrubber] with
/// the default rule set. Consent has to fail closed because only the user can
/// answer it; redaction has a safe answer the template can supply itself, and
/// silently shipping unredacted payloads because nobody called `install` would
/// reproduce exactly the gap this package exists to close.
class TelemetryScrubberRegistry._() {
  /// The process-wide registry.
  static final TelemetryScrubberRegistry instance =
      TelemetryScrubberRegistry._();

  TelemetryScrubber? _scrubber;
  bool _installed = false;

  /// The installed scrubber, or a default-ruled one when none is installed.
  TelemetryScrubber get scrubber => _scrubber ??= RuleBasedTelemetryScrubber();

  /// Whether a scrubber has been explicitly installed.
  bool get isInstalled => _installed;

  /// Installs the app's scrubber. Call once during bootstrap.
  void install(TelemetryScrubber scrubber) {
    _scrubber = scrubber;
    _installed = true;
  }

  /// Drops the installed scrubber so the next read recreates the default.
  ///
  /// Intended for tests only — do not call in production code.
  @visibleForTesting
  void reset() {
    _scrubber = null;
    _installed = false;
  }
}
