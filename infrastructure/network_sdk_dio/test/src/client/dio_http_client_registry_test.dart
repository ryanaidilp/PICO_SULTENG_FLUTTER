import 'dart:typed_data';

import 'package:dio/dio.dart' hide RequestOptions;
import 'package:dio/dio.dart' as dio show RequestOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/network_sdk_dio.dart' show DioHttpClient;

class _OkAdapter() implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 200);
}

class _Recorder() extends Interceptor {
  final paths = <String>[];

  @override
  void onRequest(
    dio.RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    paths.add(options.path);
    handler.next(options);
  }
}

void main() {
  final registry = api.NetworkInterceptorRegistry.instance;
  setUp(registry.clear);
  tearDown(registry.clear);

  DioHttpClient buildClient() =>
      DioHttpClient.init()..httpClientAdapter = _OkAdapter();

  test(
    'a request reaches an interceptor registered before the client',
    () async {
      final recorder = _Recorder();
      registry.register(recorder);

      await buildClient().get<void>('/a');

      expect(recorder.paths, ['/a']);
    },
  );

  test(
    'a request reaches an interceptor registered after the client',
    () async {
      final client = buildClient();
      final recorder = _Recorder();
      registry.register(recorder);

      await client.get<void>('/b');

      expect(recorder.paths, ['/b']);
    },
  );

  test('entries that are not Dio interceptors are ignored', () async {
    registry.register('not an interceptor');

    await buildClient().get<void>('/c');
  });
}
