part of 'http_exception.dart';

/// Exception thrown when an HTTP request fails with an error response.
final class const HttpRequestException(
  super.message, {
  super.statusCode,
  super.data,
}) extends HttpException {
  @override
  String toString() =>
      'HttpRequestException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
