import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:flutter/services.dart';

/// Bridges the native deeplink channels to Dart.
///
/// The native side exposes two channels:
/// - `archipelago/deeplink/initial` — MethodChannel returning the cold-start
///   deeplink URI (once, then null on subsequent calls).
/// - `archipelago/deeplink/events` — EventChannel streaming subsequent deeplink
///   URIs while the app is in the foreground or background (via onNewIntent /
///   UIApplicationDelegate callbacks).
///
/// Register as a lazy singleton via DI. Dispose when the app is torn down.
@lazySingleton
class DeeplinkService() {
  static const MethodChannel _initialChannel = MethodChannel(
    'archipelago/deeplink/initial',
  );
  static const EventChannel _eventsChannel = EventChannel(
    'archipelago/deeplink/events',
  );

  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  StreamSubscription<dynamic>? _eventSub;

  this {
    _eventSub = _eventsChannel.receiveBroadcastStream().listen((event) {
      if (event is String) {
        try {
          _controller.add(Uri.parse(event));
        } catch (_) {
          // Invalid URI — drop silently.
        }
      }
    });
  }

  /// Stream of subsequent deeplinks received after cold-start.
  ///
  /// Emits each time the app is opened via a deeplink while already running.
  /// Does NOT include the cold-start link — use [unifiedStream] for that.
  Stream<Uri> get deeplinkStream => _controller.stream;

  /// Cold-start deeplink captured before Flutter engine initialised.
  ///
  /// Returns `null` when the app was launched normally (no deeplink).
  /// Returned exactly once; subsequent calls return `null`.
  Future<Uri?> getInitialLink() async {
    final result = await _initialChannel.invokeMethod<String?>(
      'getInitialLink',
    );
    if (result == null) return null;
    try {
      return Uri.parse(result);
    } catch (_) {
      return null;
    }
  }

  /// Unified stream of all deeplinks — cold-start first, then subsequent.
  ///
  /// Convenience for callers that do not need to distinguish between sources.
  Stream<Uri> get unifiedStream async* {
    final initial = await getInitialLink();
    if (initial != null) yield initial;
    yield* _controller.stream;
  }

  /// Cancels the event subscription and closes the internal controller.
  Future<void> dispose() async {
    await _eventSub?.cancel();
    await _controller.close();
  }
}
