import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dependencies/network.dart';

/// A scripted dio adapter: each request takes the next reply.
class FakeAdapter implements HttpClientAdapter {
  new(this.replies);

  /// Each reply is a [FakeReply] or a [DioException] to throw.
  final List<Object> replies;

  /// Every request seen.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = replies.length > 1 ? replies.removeAt(0) : replies.first;
    if (r is DioException) throw r;
    final reply = r as FakeReply;
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

class FakeReply {
  const new(this.status, this.body);

  /// A 200 reply with [json] as the whole body.
  new ok(Object json) : status = 200, body = jsonEncode(json);

  final int status;
  final String body;
}

/// Reads a recorded API fixture as text.
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Reads a fixture as a ready 200 reply.
FakeReply fixtureReply(String name) => FakeReply(200, fixture(name));
