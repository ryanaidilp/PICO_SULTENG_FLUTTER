import 'package:dio/dio.dart' as dio;
import 'package:network_sdk_api/network_sdk_api.dart' as api;

/// Header this interceptor writes the bearer token into.
const _authorizationHeader = 'Authorization';

/// Attaches the session bearer to outbound requests, and recovers from a
/// lapsed access token by renewing the session once and replaying the
/// request.
///
/// ## Why this is a Dio interceptor and not an [api.HttpInterceptor]
///
/// The vendor-agnostic port's error hook is
/// `Future<Object> onError(HttpException)` — it receives the *failure* and
/// nothing else. Replaying a request needs the request (method, path, body,
/// headers, cancel token) and a transport to reissue it on, neither of which
/// that signature carries. Widening it would change a published contract
/// every project's hand-written interceptors implement, to express something
/// only the client can do anyway. So the replay lives where the request
/// still exists: inside the vendor package, on the vendor's own extension
/// point. The [api.AuthTokenProvider] port keeps the *auth* half
/// vendor-neutral, which is the part that actually needed decoupling.
///
/// ## Optionality
///
/// [_resolveProvider] is called per request rather than captured at
/// construction. That is deliberate, and does three things at once:
///
/// - **Breaks the DI cycle.** `LoginRepository -> Dio ->
///   AuthTokenProvider -> AuthSDK -> LoginRepository` is a cycle if any edge
///   is resolved eagerly. Resolving on first use — the same technique
///   `AuthSDKImpl` already uses for its repository — cuts it.
/// - **Removes registration-order coupling.** The network module and the
///   auth module can be registered in either order.
/// - **Makes auth optional.** A project with a network SDK and no auth
///   feature resolves `null` forever, and every request behaves exactly as
///   it did before this interceptor existed.
///
/// ## Replay semantics
///
/// The replay goes back through [dio.Dio.fetch], so it re-enters the whole
/// interceptor chain and picks up the rotated bearer from [onRequest] rather
/// than pasting in a token this interceptor read separately. That also means
/// it can come back `401` again, which is why the replayed request is
/// stamped with [api.AuthRequestMarkers.retried]: at most one replay per
/// original request, always.
///
/// A request whose body is a single-subscription `Stream` cannot be
/// replayed — the stream is already drained. Such a request surfaces its
/// original error instead of being retried.
class AuthInterceptor(
  /// The transport the replay is issued on.
  ///
  /// This is the same [dio.Dio] the interceptor is installed on, so the
  /// replay traverses the identical interceptor chain and connection pool as
  /// the original request.
  final dio.Dio _dio,

  /// Resolves the app's session port, or `null` when no auth feature is
  /// installed. Called per request — see the class doc.
  final api.AuthTokenProvider? Function() _resolveProvider, {

  /// Status codes that mean "this session needs renewing".
  ///
  /// `401` only by default. `403` is deliberately excluded: it means
  /// *authenticated but not permitted*, and renewing a token does not change
  /// what a user is allowed to do — so refreshing on `403` burns a
  /// refresh-token rotation on a request that is going to fail again.
  /// Projects whose backend answers `403` for an expired token can pass
  /// `renewOn: {401, 403}`.
  final Set<int> renewOn = const {401},
}) extends dio.Interceptor {
  @override
  Future<void> onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) async {
    if (api.AuthRequestMarkers.isExempt(options.extra)) {
      handler.next(options);
      return;
    }

    // An explicitly-set Authorization header wins: a caller that supplied
    // its own credentials (Basic auth against a token endpoint, a
    // pre-signed download) means it.
    if (options.headers.containsKey(_authorizationHeader)) {
      handler.next(options);
      return;
    }

    final token = await _resolveProvider()?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers[_authorizationHeader] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    dio.DioException err,
    dio.ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final options = err.requestOptions;

    if (statusCode == null ||
        !renewOn.contains(statusCode) ||
        api.AuthRequestMarkers.isExempt(options.extra) ||
        api.AuthRequestMarkers.isRetried(options.extra)) {
      handler.next(err);
      return;
    }

    final provider = _resolveProvider();
    if (provider == null) {
      handler.next(err);
      return;
    }

    final renewed = await provider.onUnauthorized(
      statusCode: statusCode,
      endpoint: options.path,
    );
    if (!renewed) {
      handler.next(err);
      return;
    }

    if (options.data is Stream) {
      // Already drained; replaying it would send an empty body. Surface the
      // original failure rather than a silently different request.
      //
      // Checked *after* the renewal, not before: the session really was
      // stale, and renewing it is right for the app even when this
      // particular request cannot be replayed. Every subsequent request
      // — and the caller's own retry — then works.
      handler.next(err);
      return;
    }

    // Replaced rather than mutated in place: a caller that built its request
    // with a `const` extra map would otherwise get
    // "Cannot modify unmodifiable map" instead of a retried request.
    options.extra = {...options.extra, api.AuthRequestMarkers.retried: true};
    // Drop the stale bearer so `onRequest` attaches the rotated one instead
    // of leaving the token that just failed in place.
    options.headers.remove(_authorizationHeader);

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on dio.DioException catch (e) {
      handler.next(e);
    }
  }
}
