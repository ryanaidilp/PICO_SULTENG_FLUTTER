import 'dart:async';

import 'package:identifiers/identifiers.dart';
import 'package:push_notification_api/push_notification_api.dart';

/// Turns a notification's `data.route` into a path the router opens.
///
/// A path of contract C07 (any pattern, with or without a query) is returned
/// as is. Anything else, including null, a full URL or an unknown path,
/// returns `/beranda` (ADR-0112 step 7).
String resolvePushRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return PicoRoutes.beranda;
  }
  final Uri uri;
  try {
    uri = Uri.parse(route);
  } on FormatException {
    return PicoRoutes.beranda;
  }
  if (uri.hasAuthority || uri.hasScheme) return PicoRoutes.beranda;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  for (final pattern in PicoRoutes.patterns) {
    final parts = pattern.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length != segments.length) continue;
    var match = true;
    for (var i = 0; i < parts.length; i++) {
      if (!parts[i].startsWith(':') && parts[i] != segments[i]) {
        match = false;
        break;
      }
    }
    if (match) return route;
  }
  return PicoRoutes.beranda;
}

/// Carries notification taps to the router.
///
/// It subscribes at boot, before the router exists, because OneSignal can
/// deliver the tap that cold-started the app before the first frame. The last
/// tap waits until [attach] gives it somewhere to open the path.
class PushTapRouter {
  /// Subscribes to [taps]. Call [attach] once the router can navigate.
  PushTapRouter(Stream<PushNotification> taps) {
    _sub = taps.listen((n) {
      _pending = resolvePushRoute(n.route);
      _flush();
    });
  }

  late final StreamSubscription<PushNotification> _sub;
  void Function(String path)? _open;
  String? _pending;

  /// Opens pending and later taps through [open].
  void attach(void Function(String path) open) {
    _open = open;
    _flush();
  }

  /// The tap that is waiting for a router, once. The app uses it as its first
  /// route on a cold start.
  String? takePending() {
    final path = _pending;
    _pending = null;
    return path;
  }

  /// Stops opening paths. The subscription stays, so a tap that arrives
  /// while no router is attached is kept for the next [attach].
  void detach() => _open = null;

  void _flush() {
    final open = _open;
    final path = _pending;
    if (open == null || path == null) return;
    _pending = null;
    open(path);
  }

  /// Cancels the subscription.
  Future<void> dispose() => _sub.cancel();
}
