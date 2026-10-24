import 'dart:async';

import 'package:consent_api/consent_api.dart';
import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_onesignal_impl/src/onesignal_config.dart';

/// [PushNotificationProviderHandler] implementation backed by the OneSignal
/// Flutter SDK v5.x.
///
/// ## Initialization + consent
///
/// `OneSignal.initialize()` must complete before any other `OneSignal.*`
/// static call behaves correctly (per OneSignal's own SDK contract). But
/// `initialize()` alone also starts device registration/data collection
/// immediately — unlike Firebase, OneSignal has no lazy-until-first-use
/// escape hatch, so this handler must not let it run ahead of the app's
/// consent gate the way a plain DI-timing fix would. `OneSignal.
/// consentRequired(true)` is called *before* `initialize()`, which disables
/// the SDK from collecting or sending anything until `consentGiven(true)`
/// follows — fed from `ConsentGateRegistry` for the configured
/// [OneSignalConfig.consentPurpose] (`marketing` unless the project chose
/// another purpose), both the value at startup and every subsequent change.
/// A `null` purpose skips the gate: the OS notification permission is then
/// the only opt-in.
///
/// Every method below awaits [_ready] first, which resolves once
/// `_initialize()` — called from the constructor — completes (or fails; see
/// that method's own doc comment).
///
/// ## Topic simulation via tags
///
/// OneSignal does not have a first-class "topic" concept. Topics are simulated
/// using OneSignal tags with the key `topic_<topicName>` set to `"true"` for
/// subscriptions and removed for unsubscriptions. Consumer code should
/// document this convention so server-side segments can be built on these tags.
@LazySingleton(as: PushNotificationProviderHandler)
@Named('oneSignal')
class OneSignalPushNotificationHandler(final OneSignalConfig _config)
    implements PushNotificationProviderHandler {
  /// Creates a [OneSignalPushNotificationHandler], initializes the OneSignal
  /// SDK, and wires listeners.
  this {
    _ready = _initialize();
  }

  /// Resolves once the consent-gated initialize sequence in [_initialize]
  /// has run to completion (successfully or not — that method never
  /// rethrows). Every method below awaits this first.
  late final Future<void> _ready;

  // Held to keep the consent-forwarding subscription alive for the
  // singleton lifetime. Must NOT be cancelled -- this handler lives for the
  // app's lifetime (see clearAll()'s rationale for _foregroundController/
  // _tapController). Always assigned synchronously within _initialize()'s
  // try block before any external code can observe this instance.
  // ignore: cancel_subscriptions, unused_field
  late StreamSubscription<ConsentState> _consentSubscription;

  final _foregroundController = StreamController<PushNotification>.broadcast();
  final _tapController = StreamController<PushNotification>.broadcast();

  Future<void> _initialize() async {
    try {
      final purpose = _config.consentPurpose;
      if (purpose == null) {
        await OneSignal.initialize(_config.appId);
        _initListeners();
        return;
      }

      // consentRequired(true) MUST run before initialize() -- it is what
      // makes initialize() start dormant instead of immediately collecting
      // and sending device data.
      await OneSignal.consentRequired(true);
      await OneSignal.initialize(_config.appId);

      final gate = ConsentGateRegistry.instance.gate;
      await OneSignal.consentGiven(gate.isGranted(purpose));
      _consentSubscription = gate.changes.listen((state) {
        unawaited(OneSignal.consentGiven(state.isGranted(purpose)));
      });

      _initListeners();
    } catch (e, s) {
      // Swallow and log rather than reject `_ready` -- every method above
      // awaits it, so a rejected Future would make every one of them
      // rethrow the same error forever, and an unhandled rejection here
      // would surface as an uncaught async error at boot.
      debugPrint('[OneSignalPushNotificationHandler] initialize error: $e\n$s');
    }
  }

  void _initListeners() {
    // In v5, event.preventDefault() holds the OS banner so async work can
    // run, and event.notification.display() shows it later. Every message
    // goes through the notification policy (ADR-037): suppressed ones are
    // never shown or streamed; sensitive ones (publicTitle set) are streamed
    // for the app to display, with no OS banner, because the device cannot
    // give a OneSignal banner lock-screen-safe text.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      unawaited(_applyPolicy(event.notification));
    });

    OneSignal.Notifications.addClickListener((event) {
      _tapController.add(_fromOsNotification(event.notification));
    });
  }

  Future<void> _applyPolicy(OSNotification osNotification) async {
    final decision = await NotificationPolicyRegistry.instance.policy.evaluate(
      _fromOsNotification(osNotification),
    );
    if (decision case ShowNotification(:final notification)) {
      _foregroundController.add(notification);
      if (notification.publicTitle == null) osNotification.display();
    }
  }

  @override
  PushNotificationProvider get provider => PushNotificationProvider.oneSignal;

  @override
  Future<PushNotificationPermission> requestPermission() async {
    await _ready;
    final granted = await OneSignal.Notifications.requestPermission(true);
    return granted
        ? PushNotificationPermission.granted
        : PushNotificationPermission.denied;
  }

  @override
  Future<PushNotificationPermission> getPermissionStatus() async {
    await _ready;
    final granted = OneSignal.Notifications.permission;
    return granted
        ? PushNotificationPermission.granted
        : PushNotificationPermission.denied;
  }

  @override
  Future<PushToken?> getToken() async {
    await _ready;
    final id = OneSignal.User.pushSubscription.id;
    if (id == null || id.isEmpty) return null;
    return PushToken(
      provider: PushNotificationProvider.oneSignal,
      token: id,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _ready;
    // Topics are simulated as tags: key = "topic_<name>", value = "true".
    await OneSignal.User.addTagWithKey('topic_$topic', 'true');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _ready;
    await OneSignal.User.removeTag('topic_$topic');
  }

  @override
  Stream<PushNotification> get foregroundStream => _foregroundController.stream;

  @override
  Stream<PushNotification> get tapStream => _tapController.stream;

  @override
  Future<void> clearAll() async {
    await _ready;
    try {
      await OneSignal.User.pushSubscription.optOut();
    } on Exception {
      // Swallow — subscription may already be opted out.
    }
    // Do NOT close _foregroundController or _tapController here.
    // This handler is a LazySingleton — its stream infrastructure must remain
    // alive across logout/login cycles. Closing the controllers would
    // permanently break the streams after first logout.
    //
    // OneSignal v5 exposes removeForegroundWillDisplayListener and
    // removeClickListener, but since this singleton lives for the app lifetime,
    // listeners are intentionally kept registered. Logout/login flows may
    // receive events during the brief window between optOut and re-login;
    // apps with strict requirements should unregister and re-register listeners
    // around the auth cycle.
  }

  // ──────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────

  PushNotification _fromOsNotification(OSNotification notification) {
    final rawData = notification.additionalData ?? <String, dynamic>{};
    final data = rawData.map((k, v) => MapEntry(k, v.toString()));
    return PushNotification(
      id: notification.notificationId,
      title: notification.title,
      body: notification.body,
      route: data['route'],
      data: data,
      receivedAt: DateTime.now().toUtc(),
    );
  }
}
