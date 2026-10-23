# consent_api

Vendor-neutral contracts for **telemetry consent** and **PII scrubbing**.

Every telemetry vendor family — analytics, monitoring, feature flags,
attribution — depends on this package so they can share one consent decision
and one redaction rule set without depending on each other. It has no
dependency beyond `meta`, which is what makes that possible.

## Why this exists

"We told the team not to log PII" is not a control. Under GDPR and Indonesia's
UU PDP, what an auditor looks for is a *mechanism*: a point in the code every
outbound payload passes through, where a consent decision is enforced and
identifying fields are removed.

Without one, the number of places a compliance regression can be introduced
equals the number of `track`, `log`, `breadcrumb` and `recordError` call sites
in the app. One `{'user_email': user.email}` added during a hotfix lands in
several vendor warehouses across two jurisdictions with no deletion path.

## The two controls

They answer different questions and you need both.

| Control | Question | Type |
|---|---|---|
| `ConsentGate` | May we send anything at all, for this purpose? | Per-user, runtime |
| `TelemetryScrubber` | Is this specific payload safe to send? | Per-payload |

A user can lawfully consent to product analytics without consenting to their
email address being inside it.

## ConsentPurpose

Purposes are independent, not one global boolean — a user may accept crash
diagnostics and refuse marketing, and a single switch cannot represent that.

| Purpose | Vendor family |
|---|---|
| `analytics` | Firebase / Mixpanel / MoEngage product events |
| `diagnostics` | Crashlytics / Sentry / Grafana / New Relic |
| `marketing` | AppsFlyer attribution, campaign and push events |
| `targeting` | Feature-flag and remote-config user targeting |

## Fail closed

`ConsentState.isGranted` returns `false` for any purpose without a recorded
decision. There is no "unknown → allow" path. `ConsentGateRegistry` hands out
`DeniedConsentGate` until a real gate is installed, so an app that forgets to
wire consent is silent rather than leaky.

This is deliberate and it has a cost: telemetry is off in QA runs that never
show a consent sheet. See `consent_impl`'s `ConsentDebugOverride` for the
sanctioned, debug-build-only escape hatch.

## Scrubbing rules

`ScrubRules` is declarative and fully overridable per app:

- **Deny-listed keys** — `email`, `phone`, `password`, `token`, `address`, … as
  substrings of the normalised key, so `userEmail`, `user_email` and
  `USER-EMAIL` all match. Short ambiguous fragments (`nik`, `ssn`, `otp`) match
  whole tokens only, so `nik` does not fire on `technik`.
- **Value shapes** — email addresses, long digit runs, credential-shaped
  strings, regardless of key.
- **Default-deny** — set `allowedKeys` to redact everything not explicitly
  permitted, for high-risk surfaces.

Redacted values are replaced with a stable marker (`[redacted]`) rather than
dropped, so redaction is visible to anyone reviewing vendor data. Every
redaction increments `redactionCount` and emits a `RedactionRecord` carrying
the key and reason — **never the value**.

### Deliberate non-detections

Rules that would fire on these were tuned back, because a scrubber nobody
trusts gets switched off:

| Value | Why it survives |
|---|---|
| `1735689600000` (int) | Digit-run detection is not applied to numeric values; a millisecond epoch is 13 digits |
| `550e8400-e29b-41d4-a716-446655440000` | UUIDs are exempt from digit-run detection; the final group is often all digits |
| `2026-01-15 10:30:45` | Whitespace resets a digit run |

Known false positives that remain — a support-ticket ID that is a long digit
run is the canonical one — are handled by tuning `ScrubRules` against the
debug-build redaction log in `consent_impl`, not by weakening the defaults.

## Performance

The scrubber runs on every event, so its cost is a product decision.

**There is no `RegExp` anywhere in the detection path.** A regex with adjacent
quantifiers — the natural way to write an email or token pattern — can
backtrack catastrophically on a hostile or merely unlucky payload, turning a
telemetry call into a multi-second stall on the UI isolate. Every detector is a
single bounded forward scan over code units instead.

Traversal is budgeted by `maxScannedEntries`, `maxScannedCharacters` and
`maxDepth`; anything past a budget is redacted rather than passed through, so
the bounds fail closed too.

Measured on an M-series Mac (`dart run benchmark/scrubber_benchmark.dart`):

| Scenario | Per call |
|---|---|
| Clean 12-key event | 1.8 µs |
| Leaky 15-key event (3 redactions) | 2.0 µs |
| Nested event (maps + lists) | 3.4 µs |
| Monitoring log line | 1.7 µs |
| 500-key payload (entry budget trips) | 43 µs |
| Adversarial 18 KB payload | 140 µs |

A realistic event costs ~0.01% of a 16.6 ms frame budget. Under CPU contention
these rise to roughly 10 / 18 / 15 / 16 / 186 / 275 µs respectively — still far
from a dropped frame. The adversarial case degrades linearly, which is the
point of the bound.

## Usage

```dart
// Reading consent — synchronous, safe on the hot path.
if (gate.isGranted(ConsentPurpose.analytics)) { /* ... */ }

// Recording a decision from a consent sheet.
await gate.recordAll({
  ConsentPurpose.analytics: true,
  ConsentPurpose.diagnostics: true,
  ConsentPurpose.marketing: false,
  ConsentPurpose.targeting: false,
});

// Scrubbing a payload.
final result = scrubber.scrubProperties(params, channel: 'analytics');
if (result.hasRedactions) { /* result.values holds the safe copy */ }
```

Wiring, persistence and the default rule set live in `shared/consent_impl`.

## Not to be confused with

`SharedEventSanitizer` in `analytics_api` normalises event *names* and
truncates *lengths* for vendor compatibility. It never inspects a value for
content. The two are siblings, not substitutes.
