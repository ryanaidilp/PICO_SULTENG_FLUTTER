/// Port through which a package that cannot import the app's HTTP client
/// (the debug network inspector) hands it a vendor-native interceptor.
///
/// Registration and client construction are independent: [listen] replays
/// everything registered so far and then every later [register], so the
/// result does not depend on DI order. Each client adopts only the entries
/// it understands and ignores the rest:
///
/// - `network_sdk_dio`: a Dio `Interceptor`.
/// - `network_sdk_http`: a `void Function(http.Response)` observer.
///
/// Nothing registers in a production build, where the inspector is swapped
/// for its noop twin.
final class NetworkInterceptorRegistry._() {
  /// The process-wide registry.
  static final NetworkInterceptorRegistry instance =
      NetworkInterceptorRegistry._();

  final List<Object> _registered = [];
  final List<void Function(Object)> _listeners = [];

  /// Offers [interceptor] to every client, present and future.
  void register(Object interceptor) {
    _registered.add(interceptor);
    for (final listener in _listeners.toList()) {
      listener(interceptor);
    }
  }

  /// Calls [onRegistered] for each entry registered so far, then for each
  /// later one.
  void listen(void Function(Object interceptor) onRegistered) {
    _listeners.add(onRegistered);
    _registered.toList().forEach(onRegistered);
  }

  /// Forgets every entry and listener. For tests.
  void clear() {
    _registered.clear();
    _listeners.clear();
  }
}
