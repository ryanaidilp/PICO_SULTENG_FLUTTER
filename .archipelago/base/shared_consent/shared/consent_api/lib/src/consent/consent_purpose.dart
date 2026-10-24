/// A lawful purpose a user can independently accept or refuse.
///
/// Purposes are deliberately separate rather than one global boolean: under
/// GDPR (and Indonesia's UU PDP) a user may lawfully accept crash diagnostics
/// while refusing marketing, so a single "telemetry on/off" switch cannot
/// represent a valid consent record.
///
/// Each purpose maps to one vendor family:
///
/// | Purpose        | Vendor family                                  |
/// |----------------|------------------------------------------------|
/// | [analytics]    | Firebase / Mixpanel / MoEngage product events  |
/// | [diagnostics]  | Crashlytics / Sentry / Grafana / New Relic     |
/// | [marketing]    | AppsFlyer attribution, campaign / push events  |
/// | [targeting]    | Feature-flag & remote-config user targeting    |
enum ConsentPurpose(
  /// Stable key used when persisting a decision.
  ///
  /// Never derive this from [name] — renaming an enum value must not silently
  /// invalidate previously stored consent records.
  final String storageKey,
) {
  /// Product analytics — behavioural events used to understand feature usage.
  analytics('analytics'),

  /// Crash reporting, error logs, breadcrumbs and performance traces.
  diagnostics('diagnostics'),

  /// Attribution, campaign measurement and marketing automation.
  marketing('marketing'),

  /// Personalisation and experiment targeting (feature flags, remote config).
  targeting('targeting');

  /// Resolves a purpose from its [storageKey], or `null` when unknown.
  ///
  /// Unknown keys are ignored rather than throwing so that downgrading an app
  /// (a build that no longer knows a purpose) cannot corrupt the stored state.
  static ConsentPurpose? fromStorageKey(String key) {
    for (final purpose in ConsentPurpose.values) {
      if (purpose.storageKey == key) return purpose;
    }
    return null;
  }
}
