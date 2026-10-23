import 'package:dependencies/di.dart';

/// Signature for the host app's navigation handler.
///
/// Receives a path (e.g. `/profile`, `/order/123`) and dispatches it to
/// the underlying router. Implementations typically call something like
/// `router.pushPath(path)` from the auto_route API.
typedef NavigateHandler = Future<void> Function(String path);

/// Hook for triggering navigation from outside the widget tree.
///
/// Used by features that need to navigate without a `BuildContext`:
/// push notification deep-link handlers, in-app debugger panels, FCM
/// payload routers, and external URL launches.
///
/// The host app calls [attach] once after the app router is built,
/// passing a handler closure that dispatches paths to the active
/// router. After that, any feature can resolve [ExternalNavigator]
/// from DI and call [navigate].
abstract class ExternalNavigator() {
  /// Attach the host app's navigation handler.
  ///
  /// Called once after the router is built. Subsequent calls replace
  /// the previous handler (useful for hot-reload).
  void attach(NavigateHandler handler);

  /// Whether [attach] has been called.
  bool get isAttached;

  /// Dispatches [path] to the attached handler.
  ///
  /// Throws [StateError] if no handler is attached.
  Future<void> navigate(String path);

  /// Detaches the handler. Mainly for testing.
  void detach();
}

/// Default implementation of [ExternalNavigator].
@LazySingleton(as: ExternalNavigator)
class ExternalNavigatorImpl() implements ExternalNavigator {
  NavigateHandler? _handler;

  @override
  void attach(NavigateHandler handler) => _handler = handler;

  @override
  bool get isAttached => _handler != null;

  @override
  Future<void> navigate(String path) {
    final handler = _handler;
    if (handler == null) {
      throw StateError(
        'ExternalNavigator is not attached. Call attach(handler) after the '
        'app router is built.',
      );
    }
    return handler(path);
  }

  @override
  void detach() => _handler = null;
}
