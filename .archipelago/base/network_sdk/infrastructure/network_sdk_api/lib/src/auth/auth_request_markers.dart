import 'package:network_sdk_api/src/request/request_options.dart';

/// Keys the auth lifecycle stores in [RequestOptions.extra].
///
/// `extra` is the one request field every client implementation already
/// carries end-to-end (Dio's `RequestOptions.extra`, and the `http` client's
/// own copy of [RequestOptions]), which makes it the natural place to mark a
/// request without widening the [RequestOptions] contract or teaching the
/// transport about auth-specific fields.
abstract final class AuthRequestMarkers() {
  /// Opts a request out of the auth lifecycle entirely: no bearer is
  /// attached to it, and an authentication failure on it never triggers a
  /// refresh.
  ///
  /// Prefer the [AuthExemptRequest] helpers over writing this key by hand.
  static const String exempt = 'network_sdk.auth.exempt';

  /// Set by the client on a request it has already replayed once after a
  /// successful refresh.
  ///
  /// A retry re-enters the full interceptor chain (that is how it picks up
  /// the rotated bearer), so without this marker a backend that answers
  /// `401` to the replay too would drive an unbounded refresh/retry loop.
  static const String retried = 'network_sdk.auth.retried';

  /// Whether [extra] carries the [exempt] marker.
  static bool isExempt(Map<String, dynamic>? extra) => extra?[exempt] == true;

  /// Whether [extra] carries the [retried] marker.
  static bool isRetried(Map<String, dynamic>? extra) => extra?[retried] == true;
}

/// Marks a request as exempt from the auth lifecycle.
///
/// ## Why an explicit opt-out is required
///
/// The requests that *establish* a session — sign-in, sign-up, anonymous
/// sign-in, OTP request/verify — and the one that *renews* it must never
/// enter the refresh path:
///
/// - A `401` from a sign-in endpoint means "wrong password". Treating it as
///   a lapsed session starts a refresh that, with no stored refresh token,
///   fails terminally and signs the user out — so a mistyped password would
///   emit a session-expired event and a sign-out.
/// - A `401` from the renewal endpoint (an expired or rejected refresh
///   token — exactly when it is most likely) would re-enter the single
///   flight it is already inside.
///
/// The auth SDK defends the second case from its own side with a zone
/// marker, but that defence is scoped to the renewal call it wraps; it says
/// nothing about sign-in, and it cannot express "do not attach a stale
/// bearer to this request" at all. That is what this marker is for.
///
/// ## Usage
///
/// With Dio:
/// ```dart
/// await dio.post<Map<String, dynamic>>(
///   '/auth/login',
///   data: {'email': email, 'password': password},
///   options: Options(extra: AuthExemptRequest.extra),
/// );
/// ```
///
/// With the vendor-agnostic `HttpClient` port:
/// ```dart
/// await httpClient.post(
///   '/auth/login',
///   body: credentials,
///   options: AuthExemptRequest.options,
/// );
/// ```
abstract final class AuthExemptRequest() {
  /// The raw `extra` map to merge into an outbound request.
  static const Map<String, dynamic> extra = {AuthRequestMarkers.exempt: true};

  /// Ready-made [RequestOptions] carrying nothing but the exemption.
  static const RequestOptions options = RequestOptions(extra: extra);

  /// Returns [base] with the exemption merged in, preserving its other
  /// values. Returns [options] when [base] is `null`.
  static RequestOptions mark([RequestOptions? base]) =>
      base == null ? options : base.merge(options);
}
