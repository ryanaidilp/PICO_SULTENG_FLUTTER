import 'package:dependencies/meta.dart';

/// Configuration for Dio HTTP client.
@immutable
class const DioConfig({
  /// Base URL for all requests.
  final String baseUrl = '',

  /// Timeout for establishing a connection.
  final Duration connectTimeout = const Duration(seconds: 30),

  /// Timeout for receiving data.
  final Duration receiveTimeout = const Duration(seconds: 30),

  /// Timeout for sending data.
  final Duration sendTimeout = const Duration(seconds: 30),

  /// Default content type for requests.
  final String contentType = 'application/json',

  /// Whether to follow redirects.
  final bool followRedirects = true,

  /// Maximum number of redirects to follow.
  final int maxRedirects = 5,

  /// Default headers for all requests.
  final Map<String, String>? headers,
}) {
  /// Creates a copy with updated values.
  DioConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? contentType,
    bool? followRedirects,
    int? maxRedirects,
    Map<String, String>? headers,
  }) => DioConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    sendTimeout: sendTimeout ?? this.sendTimeout,
    contentType: contentType ?? this.contentType,
    followRedirects: followRedirects ?? this.followRedirects,
    maxRedirects: maxRedirects ?? this.maxRedirects,
    headers: headers ?? this.headers,
  );
}
