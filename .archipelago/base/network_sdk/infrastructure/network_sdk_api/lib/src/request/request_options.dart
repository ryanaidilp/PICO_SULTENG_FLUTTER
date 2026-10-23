import 'package:dependencies_core/meta.dart';
import 'package:network_sdk_api/src/request/http_cancel_token.dart';

/// Configuration options for HTTP requests.
@immutable
class const RequestOptions({
  /// HTTP headers to send with the request.
  final Map<String, String>? headers,

  /// Query parameters to append to the URL.
  final Map<String, dynamic>? queryParameters,

  /// Timeout for establishing a connection.
  final Duration? connectTimeout,

  /// Timeout for receiving data.
  final Duration? receiveTimeout,

  /// Timeout for sending data.
  final Duration? sendTimeout,

  /// Whether to follow redirects.
  final bool followRedirects = true,

  /// Maximum number of redirects to follow.
  final int maxRedirects = 5,

  /// Extra data to pass to interceptors.
  final Map<String, dynamic>? extra,

  /// Cancels this request when cancelled; see [HttpCancelToken].
  final HttpCancelToken? cancelToken,
}) {
  /// Creates a copy with updated values.
  RequestOptions copyWith({
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? followRedirects,
    int? maxRedirects,
    Map<String, dynamic>? extra,
    HttpCancelToken? cancelToken,
  }) => RequestOptions(
    headers: headers ?? this.headers,
    queryParameters: queryParameters ?? this.queryParameters,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    sendTimeout: sendTimeout ?? this.sendTimeout,
    followRedirects: followRedirects ?? this.followRedirects,
    maxRedirects: maxRedirects ?? this.maxRedirects,
    extra: extra ?? this.extra,
    cancelToken: cancelToken ?? this.cancelToken,
  );

  /// Merges this options with another, preferring values from [other].
  RequestOptions merge(RequestOptions? other) => other == null
      ? this
      : RequestOptions(
          headers: {...?headers, ...?other.headers},
          queryParameters: {...?queryParameters, ...?other.queryParameters},
          connectTimeout: other.connectTimeout ?? connectTimeout,
          receiveTimeout: other.receiveTimeout ?? receiveTimeout,
          sendTimeout: other.sendTimeout ?? sendTimeout,
          followRedirects: other.followRedirects,
          maxRedirects: other.maxRedirects,
          extra: {...?extra, ...?other.extra},
          cancelToken: other.cancelToken ?? cancelToken,
        );
}

/// Predefined request configurations for common scenarios.
abstract final class RequestConfigs() {
  /// Standard request with 30 second timeout.
  static const standard = RequestOptions(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 30),
  );

  /// Fast request with 10 second timeout.
  static const fast = RequestOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 10),
  );

  /// Long request with 2 minute timeout.
  static const long = RequestOptions(
    connectTimeout: Duration(minutes: 2),
    receiveTimeout: Duration(minutes: 2),
    sendTimeout: Duration(minutes: 2),
  );

  /// File upload/download with extended timeout.
  static const fileTransfer = RequestOptions(
    connectTimeout: Duration(minutes: 5),
    receiveTimeout: Duration(minutes: 10),
    sendTimeout: Duration(minutes: 10),
  );
}
