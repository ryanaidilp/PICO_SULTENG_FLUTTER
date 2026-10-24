import 'package:network_sdk_api/src/auth/auth_request_markers.dart';

/// The transport layer's view of the app's authenticated session.
///
/// ## Why this lives in `network_sdk_api`
///
/// Attaching a bearer and recovering from a lapsed one are *transport*
/// concerns, so the transport owns the port and the auth feature implements
/// it. The alternative — having `network_sdk_dio` depend on `auth_api` —
/// would make every project that installs a network SDK drag in the auth
/// feature, and would invert the dependency direction between infrastructure
/// and features.
///
/// Nothing here mentions tokens *plural*, refresh tokens, or storage: the
/// transport must not learn how a session is renewed, only that it can ask
/// for one more attempt.
///
/// ## Optionality
///
/// A project may install a network SDK and no auth feature. Client
/// implementations therefore resolve this port **lazily and optionally** —
/// see `network_sdk_dio`'s `resolveAuthTokenProvider`. When nothing is
/// registered the transport behaves exactly as it did before this port
/// existed: no header is attached and a `401` propagates untouched.
///
/// ## Implementing it
///
/// The auth feature registers an implementation in the global service
/// locator:
///
/// ```dart
/// getIt.registerLazySingleton<AuthTokenProvider>(
///   () => AuthSessionTokenProvider(getIt<AuthTokenStore>(), getIt.get<AuthSDK>),
/// );
/// ```
///
/// The registration must be **lazy** and the `AuthSDK` must arrive as a
/// provider rather than an instance: the dependency graph
/// `LoginRepository -> HttpClient -> AuthTokenProvider -> AuthSDK ->
/// LoginRepository` is a cycle, and deferring both lookups until the first
/// request is what breaks it.
abstract interface class AuthTokenProvider() {
  /// The bearer token to attach to outbound requests, or `null` when there
  /// is no session.
  ///
  /// Read on every request that is not [AuthExemptRequest]-marked, so
  /// implementations should keep this cheap — a secure-storage read, not a
  /// network call.
  Future<String?> get accessToken;

  /// Called when a request came back with an authentication failure.
  ///
  /// Returns `true` when a fresh session was obtained and the request should
  /// be replayed, `false` when it should surface the original error.
  ///
  /// **Must be single-flight.** A burst of parallel requests all answering
  /// `401` is the normal case when an access token lapses, not an exotic
  /// race: firing one refresh per failed request hands a rotating-refresh
  /// backend a token it has already rotated away, which it reads as token
  /// reuse and answers by revoking the whole session family.
  ///
  /// **Must not re-enter.** If the implementation renews the session over
  /// the same transport, the renewal request must be exempt from this path
  /// (see [AuthExemptRequest]) or it will join the single flight it is
  /// already inside and wait for itself forever.
  Future<bool> onUnauthorized({required int statusCode, String? endpoint});
}
