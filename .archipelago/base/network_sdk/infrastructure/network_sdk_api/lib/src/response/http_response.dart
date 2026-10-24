import 'package:dependencies_core/meta.dart';

/// Represents an HTTP response.
@immutable
class HttpResponse {
  const new({
    required this.statusCode,
    this.data,
    this.headers = const {},
    this.statusMessage,
  });

  /// Creates a successful response.
  const new success(
    this.data, {
    this.statusCode = 200,
    this.headers = const {},
    this.statusMessage,
  });

  /// Creates an empty successful response.
  const new empty({
    this.statusCode = 204,
    this.headers = const {},
    this.statusMessage,
  }) : data = null;

  /// The HTTP status code.
  final int statusCode;

  /// The response data.
  final Object? data;

  /// The response headers.
  final Map<String, String> headers;

  /// The status message from the server.
  final String? statusMessage;

  /// Whether the response indicates success (2xx status code).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether the response indicates a client error (4xx status code).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether the response indicates a server error (5xx status code).
  bool get isServerError => statusCode >= 500;

  /// Returns the data as a Map if it is one, otherwise null.
  Map<String, dynamic>? get dataAsMap =>
      data is Map<String, dynamic> ? data! as Map<String, dynamic> : null;

  /// Returns the data as a List if it is one, otherwise null.
  List<dynamic>? get dataAsList =>
      data is List<dynamic> ? data! as List<dynamic> : null;

  @override
  String toString() =>
      'HttpResponse(statusCode: $statusCode, statusMessage: $statusMessage)';
}
