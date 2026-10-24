import 'package:dependencies_core/meta.dart';
import 'package:network_sdk_api/src/enums/http_method.dart';
import 'package:network_sdk_api/src/request/request_options.dart';

/// Represents an HTTP request.
@immutable
class HttpRequest {
  const new({
    required this.method,
    required this.path,
    this.baseUrl,
    this.body,
    this.options,
  });

  /// Creates a GET request.
  const new get(this.path, {this.baseUrl, this.options})
    : method = HttpMethod.get,
      body = null;

  /// Creates a POST request.
  const new post(this.path, {this.baseUrl, this.body, this.options})
    : method = HttpMethod.post;

  /// Creates a PUT request.
  const new put(this.path, {this.baseUrl, this.body, this.options})
    : method = HttpMethod.put;

  /// Creates a PATCH request.
  const new patch(this.path, {this.baseUrl, this.body, this.options})
    : method = HttpMethod.patch;

  /// Creates a DELETE request.
  const new delete(this.path, {this.baseUrl, this.body, this.options})
    : method = HttpMethod.delete;

  /// The HTTP method.
  final HttpMethod method;

  /// The request path (relative to base URL).
  final String path;

  /// Optional base URL override.
  final String? baseUrl;

  /// The request body.
  final Object? body;

  /// Request configuration options.
  final RequestOptions? options;

  /// The full URL including query parameters.
  String get fullUrl => '${baseUrl ?? ''}$path${_buildQueryString()}';

  String _buildQueryString() {
    final params = options?.queryParameters;
    if (params == null || params.isEmpty) return '';

    final entries = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
    return '?$entries';
  }

  /// Creates a copy with updated values.
  HttpRequest copyWith({
    HttpMethod? method,
    String? path,
    String? baseUrl,
    Object? body,
    RequestOptions? options,
  }) => HttpRequest(
    method: method ?? this.method,
    path: path ?? this.path,
    baseUrl: baseUrl ?? this.baseUrl,
    body: body ?? this.body,
    options: options ?? this.options,
  );
}
