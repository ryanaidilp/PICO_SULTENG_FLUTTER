part of 'http_exception.dart';

/// Exception thrown when an HTTP request is cancelled.
final class const HttpCancelledException([String? message])
    extends HttpException {
  this : super(message ?? 'Request was cancelled');

  @override
  String toString() => 'HttpCancelledException: $message';
}
