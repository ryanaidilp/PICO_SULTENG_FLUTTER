part of 'http_exception.dart';

/// Exception thrown when response parsing fails.
final class const HttpParseException(super.message, {super.data})
    extends HttpException {
  @override
  String toString() => 'HttpParseException: $message';
}
