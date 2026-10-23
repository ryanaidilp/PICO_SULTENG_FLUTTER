/// Persisted consent gate, default telemetry scrubbing rules, and the
/// debug-build override that keeps a fail-closed default workable in QA.
library;

export 'package:consent_api/consent_api.dart';

export 'src/consent_debug_override.dart';
export 'src/consent_initializer.dart';
export 'src/default_telemetry_scrubber.dart';
export 'src/persisted_consent_gate.dart';
export 'src/persisted_scoped_consent_gate.dart';
export 'src/shared_preferences_consent_store.dart';
export 'src/shared_preferences_scoped_consent_store.dart';
