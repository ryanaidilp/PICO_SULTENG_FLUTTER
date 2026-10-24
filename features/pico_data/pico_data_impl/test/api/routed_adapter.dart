import 'dart:typed_data';

import 'package:dependencies/network.dart';

import 'fake_adapter.dart';

/// A dio adapter that answers by request path, and records the order of calls.
class RoutedAdapter implements HttpClientAdapter {
  RoutedAdapter(this.routes);

  /// Path to reply (a [FakeReply] or a [DioException]). Missing path: 404.
  final Map<String, Object> routes;

  /// Paths in call order.
  final List<String> calls = [];

  /// Optional delay before answering, to keep requests in flight.
  Duration delay = Duration.zero;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final r = routes[options.path];
    if (r is DioException) throw r;
    final reply =
        (r as FakeReply?) ??
        const FakeReply(404, '{"status":"error","error":"nf"}');
    return ResponseBody.fromString(
      reply.body,
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
