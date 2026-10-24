import 'dart:async';

import 'package:async/async.dart';
import 'package:consent_api/consent_api.dart';
import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/src/di/push_notification_global_module.dart';
import 'package:push_notification_impl/src/policy/notification_policy_store.dart';
import 'package:push_notification_impl/src/presentation/notification_settings_page.dart';
import 'package:router_registry/router_registry.dart';

/// Orchestrates push notifications across one (or more) provider handlers.
///
/// ## DI strategy
///
/// Registered globally via [PushNotificationGlobalModule] as an eager
/// singleton: building it builds the provider handlers, which attach their
/// message and tap listeners at boot.
///
/// Provider handlers ([PushNotificationProviderHandler] implementations) are
/// registered by their respective packages (`push_notification_fcm_impl` or
/// `push_notification_onesignal_impl`) and resolved via `getIt.getAll()`
/// before this SDK is created.
///
/// ## Single-handler design
///
/// The brick generates exactly ONE provider (FCM or OneSignal). This class
/// supports multiple handlers for safety, but warns at construction time if
/// more than one handler is registered, as that is an atypical configuration.
///
/// When multiple handlers are registered, [foregroundStream] and [tapStream]
/// merge events from all of them. All other methods delegate to the first
/// registered handler.
class PushNotificationSDKImpl._({
  required List<PushNotificationProviderHandler> handlers,
  required final NotificationPolicyStore _store,
  required final Future<String> Function() _localTimezone,
}) implements PushNotificationSDK {
  /// Creates a [PushNotificationSDKImpl] and self-registers with
  /// [FeatureSDKRegistry].
  this {
    if (_handlers.length > 1) {
      debugPrint(
        'PushNotificationSDK: ${_handlers.length} handlers registered. '
        'Only the first handler is used for token/permission operations. '
        'This is an atypical configuration — typically only one provider '
        '(FCM or OneSignal) is wired into the app.',
      );
    }
  }

  /// Factory that self-registers with [FeatureSDKRegistry].
  ///
  /// `localTimezone` returns the device's IANA zone; it defaults to
  /// `flutter_timezone` and is only called by [notificationPreferences].
  factory create({
    required List<PushNotificationProviderHandler> handlers,
    NotificationPolicyStore store = const NotificationPolicyStore(),
    Future<String> Function()? localTimezone,
  }) {
    final sdk = PushNotificationSDKImpl._(
      handlers: handlers,
      store: store,
      localTimezone: localTimezone ?? _deviceTimezone,
    );
    FeatureSDKRegistry.instance.register(sdk);
    return sdk;
  }

  final List<PushNotificationProviderHandler> _handlers = List.unmodifiable(
    handlers,
  );
  static Future<String> _deviceTimezone() =>
      FlutterTimezone.getLocalTimezone().then((zone) => zone.identifier);

  PushNotificationProviderHandler? get _primary =>
      _handlers.isEmpty ? null : _handlers.first;

  // ──────────────────────────────────────────────────────────────
  // FeatureSDK lifecycle
  // ──────────────────────────────────────────────────────────────

  @override
  bool get isEnabled => true;

  @override
  Map<PageIdentifier, PageConfig> get pageConfigurations => {
    for (final page in PushNotificationPage.values) page: page.config,
  };

  @override
  void registerRoutes(RouteRegistry registry) {
    // No route codegen: the page takes this SDK directly.
    registry.register([
      AutoRoute(
        page: PageInfo(
          'NotificationSettingsRoute',
          builder: (_) => NotificationSettingsPage(sdk: this),
        ),
        path: PushNotificationSDK.settingsPath,
      ),
    ]);
  }

  @override
  Future<void> initialize() async {
    // No-op: provider SDKs handle their own initialisation.
  }

  @override
  Future<void> dispose() async {
    // No-op.
  }

  /// Opens the notification settings page.
  @override
  Future<void> launch(BuildContext context) =>
      context.router.root.pushPath(PushNotificationSDK.settingsPath);

  // ──────────────────────────────────────────────────────────────
  // PushNotificationSDK contract
  // ──────────────────────────────────────────────────────────────

  @override
  Set<PushNotificationProvider> get availableProviders =>
      _handlers.map((h) => h.provider).toSet();

  @override
  Future<PushNotificationPermission> requestPermission() async {
    if (_primary == null) return PushNotificationPermission.notDetermined;
    return await _primary!.requestPermission();
  }

  @override
  Future<PushNotificationPermission> getPermissionStatus() async {
    if (_primary == null) return PushNotificationPermission.notDetermined;
    return await _primary!.getPermissionStatus();
  }

  @override
  Future<PushToken?> getToken() async {
    if (_primary == null) return null;
    return await _primary!.getToken();
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (_primary == null) return;
    await _primary!.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_primary == null) return;
    await _primary!.unsubscribeFromTopic(topic);
  }

  @override
  Stream<PushNotification> get foregroundStream {
    if (_handlers.isEmpty) return const Stream.empty();
    if (_handlers.length == 1) return _handlers.first.foregroundStream;
    return StreamGroup.merge(_handlers.map((h) => h.foregroundStream));
  }

  @override
  Future<QuietHours?> getQuietHours() => _store.readQuietHours();

  @override
  Future<void> setQuietHours(QuietHours? quietHours) =>
      _store.writeQuietHours(quietHours);

  @override
  bool get marketingEnabled =>
      ConsentGateRegistry.instance.isGranted(ConsentPurpose.marketing);

  @override
  Future<void> setMarketingEnabled({required bool enabled}) =>
      ConsentGateRegistry.instance.gate.record(
        purpose: ConsentPurpose.marketing,
        granted: enabled,
      );

  @override
  Future<NotificationPreferences> notificationPreferences() async =>
      NotificationPreferences(
        timeZone: await _localTimezone(),
        quietHours: await _store.readQuietHours(),
        marketing: marketingEnabled,
      );

  @override
  Stream<PushNotification> get tapStream {
    if (_handlers.isEmpty) return const Stream.empty();
    if (_handlers.length == 1) return _handlers.first.tapStream;
    return StreamGroup.merge(_handlers.map((h) => h.tapStream));
  }

  @override
  Future<void> clearAll() async {
    await Future.wait<void>(_handlers.map(_safeClear));
  }

  // ──────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────

  Future<void> _safeClear(PushNotificationProviderHandler handler) async {
    try {
      await handler.clearAll();
    } on Object {
      // Swallow per-handler errors (including Errors, not just Exceptions) so
      // all handlers are attempted even if one throws.
    }
  }
}

/// Page identifiers for the routes [PushNotificationSDKImpl] registers, so
/// other features find the settings page through
/// `FeatureSDKRegistry.enabledPageConfigurations` without importing this
/// package.
enum PushNotificationPage(@override final PageConfig config)
    implements PageIdentifier {
  /// Quiet hours and the marketing opt-out.
  settings(
    PageConfig(
      deeplinkPath: PushNotificationSDK.settingsPath,
      analyticsName: 'notification_settings',
    ),
  );

  @override
  String get name => toString().split('.').last;
}
