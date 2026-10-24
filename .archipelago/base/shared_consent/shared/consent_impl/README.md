# consent_impl

Persisted `ConsentGate`, the default `TelemetryScrubber` rule set, and the
debug-build override that keeps a fail-closed default workable in QA.

Contracts live in [`shared/consent_api`](../consent_api/README.md).

## Wiring

`ConsentInitializer` is a **blocking pre-launch** step. Every telemetry vendor
family asks the gate before dispatching, so a gate installed after the first
tracked event does not gate that event.

```dart
// apps/template_app/lib/bootstrap.dart — before initializeInjector().
await ConsentInitializer.initialize(GetIt.I);
```

It hydrates the persisted state, installs the gate and scrubber into their
ambient registries, and registers both in GetIt:

```dart
final gate = getIt<ConsentGate>();
final scrubber = getIt<TelemetryScrubber>();
```

It is a plain initializer rather than an injectable micro-package module
because the gate must be read from storage (`await`) and installed *before*
anything resolves `AppMonitoring` or `AnalyticTracker` — an ordering a lazy DI
registration cannot guarantee.

## Recording consent

Nothing is granted until the app records a decision. Wire your consent sheet to:

```dart
await getIt<ConsentGate>().recordAll({
  ConsentPurpose.analytics: analyticsAccepted,
  ConsentPurpose.diagnostics: diagnosticsAccepted,
  ConsentPurpose.marketing: marketingAccepted,
  ConsentPurpose.targeting: targetingAccepted,
}, policyVersion: '2026-03-01');
```

Each decision is persisted with a UTC timestamp, the surface it came from, and
the policy version in force — being able to *prove* when and how consent was
captured is itself a compliance requirement, not just a nice-to-have.

`revokeAll()` handles "reject all" and withdrawal; `clear()` erases the record
entirely for "delete my data" flows.

## Debug override

A fail-closed gate silences telemetry in QA, integration tests and manual smoke
runs that never show a consent sheet. Without a sanctioned escape hatch, the
predictable outcome is a team "temporarily" seeding a granted state in
production code — which is how a fail-closed gate quietly becomes fail-open.

So the override is explicit, narrow and loud:

```sh
flutter run --dart-define=CONSENT_DEBUG_GRANT_ALL=true
```

- **Debug builds only.** `ConsentDebugOverride.isActive` is hard-gated on
  `kDebugMode`. In profile and release builds every method is inert; there is
  no configuration that turns it on in production.
- **Off unless asked for.** Even in debug it does nothing until the dart-define
  is set or `ConsentDebugOverride.enable()` is called.
- **Visible.** Grants it produces are tagged `ConsentSource.debugOverride`, so
  `gate.state` distinguishes forced grants from real consent. The Analytics tab
  of the app debugger renders `ConsentStatusBanner`, which reads that tag and
  says plainly when consent is forced — and, when it is denied, explains why
  the event list is empty instead of leaving QA to guess.

`ConsentInitializer` calls `applyDebugOverride()` unconditionally; it is a
no-op unless all of the above line up.

## Tuning redaction

Value-shape detection produces false positives — a support-ticket ID that looks
like a long digit run is the canonical case. Rather than weakening the defaults
pre-emptively, `DefaultTelemetryScrubber` prints every redaction in debug
builds with its key and reason (never its value):

```
[scrubber] redacted analytics:ticket_id (digit_run)
```

Tune against that evidence:

```dart
await ConsentInitializer.initialize(
  GetIt.I,
  rules: const ScrubRules(digitRunThreshold: 14),
);
```

## Storage

`SharedPreferencesConsentStore` writes the record as a single JSON document
under one key, so a decision set is written atomically — a partial write that
granted analytics but lost the matching refusal of marketing would be worse
than no record at all.

The record holds purposes, booleans and timestamps only — no personal data — so
plain preferences are appropriate. **Do not extend it to hold user
identifiers.** Swap in `ConsentStore` implementations backed by encrypted
storage or a server-side record via `ConsentInitializer(store: ...)`.

A read failure leaves the gate undecided (denied) rather than throwing: a
corrupt preferences file must not brick startup, and must never be interpreted
as consent.
