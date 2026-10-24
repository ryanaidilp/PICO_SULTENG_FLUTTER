/// Vendor-neutral consent and PII-scrubbing contracts for outbound telemetry.
///
/// This package is deliberately dependency-free (only `meta`). Analytics,
/// monitoring, feature-flag and attribution infrastructure all depend on it
/// so they can share one consent decision and one redaction rule set without
/// depending on each other.
library;

export 'src/consent/consent.dart';
export 'src/scoped/scoped.dart';
export 'src/scrubbing/scrubbing.dart';
