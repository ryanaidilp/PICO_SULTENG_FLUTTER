import 'dart:async';

import 'package:consent_api/consent_api.dart';
import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:monitoring_impl/src/monitoring_fanout_impl.dart';

/// An error whose message has been redacted before leaving the device.
///
/// Exception messages are a routine PII leak (`FormatException: invalid email
/// jane@example.com`), so [ConsentAwareMonitoring] scrubs them. The original
/// runtime type is preserved in [typeName] and in [toString] so vendor-side
/// crash grouping still separates a `FormatException` from a `StateError`.
class const ScrubbedTelemetryError({
  /// Runtime type name of the original error.
  required final String typeName,

  /// The scrubbed message.
  required final String message,
}) implements Exception {
  /// Creates a redacted stand-in for [typeName] with a scrubbed [message].
  this;

  @override
  String toString() => 'ScrubbedTelemetryError($typeName): $message';
}

/// Consent gate + PII scrubber for the monitoring vendor family.
///
/// Monitoring had no interception point at all — `AppMonitoring` calls went
/// straight to the vendor fanout — so this decorator is the monitoring
/// equivalent of the analytics interceptor chain: one place where every
/// outbound call is checked against consent and passed through the shared
/// scrubber.
///
/// ## What is gated
///
/// [log], [breadcrumb], [recordError], [recordFlutterError], [setUserContext]
/// and [recordTransaction] all require [ConsentPurpose.diagnostics]. Note that
/// [recordTransaction] still *runs* the action when consent is denied and
/// returns its result — suppressing telemetry must never change application
/// behaviour.
///
/// [clearUserContext] and [dispose] are never gated: both reduce data held by
/// vendors, so blocking them would be backwards.
///
/// ## Deferred vendor initialisation
///
/// [initialize] does not start the vendors while diagnostics consent is
/// denied. A gate is worth little if the SDK begins collecting at construction
/// or init time, so initialisation is deferred and retried when the gate
/// flips.
///
/// ## Withdrawal
///
/// The decorator keeps listening after the first grant. When diagnostics
/// consent is withdrawn it calls `ConsentWithdrawalAware.onConsentWithdrawn`
/// on the delegate (or `dispose` when the delegate has no such hook), so
/// vendors stop collecting and drop what they buffered; a later grant
/// initialises them again.
///
/// ## Wiring
///
/// The gate and scrubber are read from their ambient registries on every call
/// rather than injected once, so `ConsentInitializer` can install them at any
/// point during bootstrap without ordering constraints against DI, and a
/// revocation takes effect immediately.
@LazySingleton(as: AppMonitoring)
class ConsentAwareMonitoring({
  /// The wrapped implementation.
  ///
  /// Resolving this directly bypasses both the consent gate and the scrubber
  /// and should not appear in application code.
  required final AppMonitoring delegate,

  /// Gate override. When `null`, the ambient `ConsentGateRegistry` is read on
  /// every call.
  final ConsentGate? gate,

  /// Scrubber override. When `null`, the ambient
  /// `TelemetryScrubberRegistry` is read on every call.
  final TelemetryScrubber? scrubber,

  /// The consent purpose required for monitoring telemetry.
  final ConsentPurpose purpose = ConsentPurpose.diagnostics,

  /// Label attached to redaction records from this decorator.
  final String channel = 'monitoring',

  /// Whether error messages are scrubbed in addition to error context.
  ///
  /// Turning this off keeps vendor-side messages verbatim, which is easier to
  /// debug and riskier to ship.
  final bool scrubErrorMessages = true,
}) implements AppMonitoring {
  /// Creates a decorator around [delegate].
  ///
  /// [gate] and [scrubber] default to the ambient registries; pass them
  /// explicitly in tests.
  this;

  /// Injectable entry point: wraps the vendor fanout.
  @factoryMethod
  factory fromDi(MonitoringFanoutImpl delegate) =>
      ConsentAwareMonitoring(delegate: delegate);

  StreamSubscription<ConsentState>? _consentSubscription;
  bool _vendorsInitialized = false;

  // Grant and withdrawal steps run strictly in order, so a quick
  // withdraw-then-grant cannot interleave a dispose with an initialize.
  Future<void> _lifecycle = Future.value();

  ConsentGate get _consent => gate ?? ConsentGateRegistry.instance.gate;

  TelemetryScrubber get _scrub =>
      scrubber ?? TelemetryScrubberRegistry.instance.scrubber;

  bool get _isGranted => _consent.isGranted(purpose);

  @override
  bool get isEnabled => _isGranted && delegate.isEnabled;

  @override
  Future<void> initialize() {
    _consentSubscription ??= _consent.changes.listen(
      (state) => unawaited(
        state.isGranted(purpose) ? _initializeDelegate() : _withdraw(),
      ),
    );
    return _isGranted ? _initializeDelegate() : Future.value();
  }

  @override
  Future<void> dispose() async {
    await _consentSubscription?.cancel();
    _consentSubscription = null;
    await _lifecycle;
    _vendorsInitialized = false;
    await delegate.dispose();
  }

  @override
  Future<void> setUserContext(
    String userId, {
    Map<String, dynamic>? extras,
  }) async {
    if (!_isGranted) return;
    final scrubbedId = _scrub.scrubText(
      userId,
      channel: channel,
      key: 'userId',
    );
    final scrubbedExtras = extras == null
        ? null
        : _scrub.scrubProperties(extras, channel: channel).values;
    await delegate.setUserContext(scrubbedId.text, extras: scrubbedExtras);
  }

  @override
  Future<void> clearUserContext() => delegate.clearUserContext();

  @override
  void log(
    String message, {
    String? tag,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {
    if (!_isGranted) return;
    delegate.log(
      _scrub.scrubText(message, channel: channel).text,
      tag: tag,
      level: level,
    );
  }

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    if (!_isGranted) return;
    await delegate.recordError(
      _scrubException(exception),
      stackTrace,
      fatal: fatal,
      context: context == null
          ? null
          : _scrub.scrubProperties(context, channel: channel).values,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_isGranted) return;
    await delegate.recordFlutterError(
      details.copyWith(exception: _scrubException(details.exception)),
    );
  }

  @override
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  }) {
    // Suppressing telemetry must not suppress the work being measured.
    if (!_isGranted) return action();
    return delegate.recordTransaction<T>(
      name,
      action,
      operation: operation,
      data: data == null
          ? null
          : _scrub.scrubProperties(data, channel: channel).values,
    );
  }

  @override
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {
    if (!_isGranted) return;
    delegate.breadcrumb(
      _scrub.scrubText(message, channel: channel).text,
      category: category,
      data: data == null
          ? null
          : _scrub.scrubProperties(data, channel: channel).values,
      level: level,
    );
  }

  Object _scrubException(Object exception) {
    if (!scrubErrorMessages) return exception;
    final rendered = exception.toString();
    final scrubbed = _scrub.scrubText(
      rendered,
      channel: channel,
      key: 'exception',
    );
    if (!scrubbed.hasRedactions) return exception;
    return ScrubbedTelemetryError(
      typeName: exception.runtimeType.toString(),
      message: scrubbed.text,
    );
  }

  Future<void> _initializeDelegate() => _enqueue(() async {
    if (_vendorsInitialized) return;
    _vendorsInitialized = true;
    await delegate.initialize();
  });

  Future<void> _withdraw() => _enqueue(() async {
    if (!_vendorsInitialized) return;
    _vendorsInitialized = false;
    final target = delegate;
    await (target is ConsentWithdrawalAware
        ? (target as ConsentWithdrawalAware).onConsentWithdrawn()
        : target.dispose());
  });

  Future<void> _enqueue(Future<void> Function() step) => _lifecycle = _lifecycle
      .then((_) => step())
      .catchError((Object e) => debugPrint('[monitoring] lifecycle: $e'));
}
