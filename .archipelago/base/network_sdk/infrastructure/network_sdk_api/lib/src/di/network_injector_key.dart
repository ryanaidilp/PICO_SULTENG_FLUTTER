/// Constants for HTTP client DI registration keys.
///
/// Use these keys when registering named `HttpClient` instances with
/// dependency injection so the in-app debugger (`app_debugger_network`)
/// can enumerate every registered client and attach Alice adapters
/// without hardcoding individual names.
///
/// Apps register clients using `@Named(NetworkInjectorKey.authClient)`
/// (or via manual GetIt registration with `instanceName`). Whatever
/// keys an app actually uses must be present in [allClientNames] so
/// the debugger picks them up.
abstract final class NetworkInjectorKey() {
  /// Primary API client. Apps that only need one client use this key.
  static const String defaultClient = 'default';

  /// Auth/identity endpoint client.
  ///
  /// Useful when auth requests need different settings than the rest of
  /// the API (e.g. no interceptor that auto-attaches the access token,
  /// since auth endpoints issue tokens rather than consume them).
  static const String authClient = 'auth';

  /// CDN/asset downloader client.
  ///
  /// Typically configured without auth headers and with longer timeouts
  /// for large blob downloads.
  static const String cdnClient = 'cdn';

  /// Analytics endpoint client.
  ///
  /// Some apps route analytics events through a dedicated client so
  /// retries and offline queuing don't interfere with the primary API.
  static const String analyticsClient = 'analytics';

  /// Every named client key registered above.
  ///
  /// Iterate this list to enumerate all standard clients (e.g. when
  /// attaching an Alice adapter to each in the debugger overlay). Apps
  /// that introduce their own client names should add them here as
  /// well.
  static const List<String> allClientNames = [
    defaultClient,
    authClient,
    cdnClient,
    analyticsClient,
  ];
}
