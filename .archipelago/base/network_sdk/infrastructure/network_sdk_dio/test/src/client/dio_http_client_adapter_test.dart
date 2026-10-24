import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/network_sdk_dio.dart';

/// A [dio.HttpClientAdapter] test double that never touches the network.
///
/// Captures the last outgoing [dio.RequestOptions] (so tests can assert on
/// headers set by interceptors) and returns a scripted [dio.ResponseBody].
class _FakeHttpClientAdapter(
  final dio.ResponseBody Function(dio.RequestOptions options) _respond,
) implements dio.HttpClientAdapter {
  dio.RequestOptions? lastRequestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return _respond(options);
  }
}

/// A minimal [dio.Interceptor] standing in for a real `AuthInterceptor`:
/// attaches a bearer token to every outgoing request. Used to prove a
/// request issued through [DioHttpClientAdapter] traverses the SAME
/// interceptor chain as a request issued directly through [dio.Dio].
class _BearerTokenInterceptor(final String token) extends dio.Interceptor {
  @override
  void onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) {
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

void main() {
  late dio.Dio dioClient;
  late _FakeHttpClientAdapter adapter;
  late DioHttpClientAdapter subject;

  dio.ResponseBody jsonResponse(int statusCode, String body) =>
      dio.ResponseBody.fromString(
        body,
        statusCode,
        headers: {
          dio.Headers.contentTypeHeader: [dio.Headers.jsonContentType],
        },
      );

  setUp(() {
    dioClient = dio.Dio(dio.BaseOptions(baseUrl: 'https://api.example.com'));
    adapter = _FakeHttpClientAdapter((_) => jsonResponse(200, '{"ok":true}'));
    dioClient.httpClientAdapter = adapter;
    subject = DioHttpClientAdapter(dioClient);
  });

  group('interceptor parity', () {
    test('a request made through the HttpClient port carries the same '
        'interceptors (e.g. bearer auth header) as one made through Dio '
        'directly', () async {
      dioClient.interceptors.add(_BearerTokenInterceptor('token-123'));

      await subject.get('/profile');

      expect(
        adapter.lastRequestOptions?.headers['Authorization'],
        'Bearer token-123',
      );
    });

    test(
      'addInterceptor wraps an api.HttpInterceptor onto the shared Dio',
      () async {
        subject.addInterceptor(_HeaderInjectingInterceptor());

        await subject.get('/profile');

        expect(
          adapter.lastRequestOptions?.headers['X-From-Api-Interceptor'],
          'yes',
        );
      },
    );

    test('removeInterceptor detaches a previously added interceptor', () async {
      final interceptor = _HeaderInjectingInterceptor();
      subject.addInterceptor(interceptor);
      subject.removeInterceptor(interceptor);

      await subject.get('/profile');

      expect(
        adapter.lastRequestOptions?.headers.containsKey(
          'X-From-Api-Interceptor',
        ),
        isFalse,
      );
    });
  });

  group('exception translation', () {
    test(
      'a failing request throws api.HttpException, never DioException',
      () async {
        adapter = _FakeHttpClientAdapter(
          (_) => jsonResponse(404, '{"message":"not found"}'),
        );
        dioClient.httpClientAdapter = adapter;

        await expectLater(
          subject.get('/missing'),
          throwsA(isA<api.HttpException>()),
        );
      },
    );

    test('preserves the status code carried by an already-wrapped '
        'api.HttpException from the interceptor chain (e.g. RetryInterceptor '
        "reject path) instead of re-deriving one from the outer exception's "
        'type', () async {
      dioClient.interceptors.add(_RejectingInterceptor());

      try {
        await subject.get('/orders');
        fail('expected an api.HttpException to be thrown');
      } on api.HttpException catch (e) {
        expect(e, isA<api.HttpRequestException>());
        expect(e.statusCode, 401);
      }
    });
  });

  group('cancellation', () {
    test('a token cancelled before the request starts never reaches the '
        'transport', () async {
      final token = api.HttpCancelToken()..cancel('closed');

      await expectLater(
        subject.get(
          '/profile',
          options: api.RequestOptions(cancelToken: token),
        ),
        throwsA(isA<api.HttpCancelledException>()),
      );
      expect(adapter.lastRequestOptions, isNull);
    });

    test('cancelling an in-flight request aborts it with '
        'HttpCancelledException', () async {
      final hanging = _HangingAdapter();
      dioClient.httpClientAdapter = hanging;
      final token = api.HttpCancelToken();

      final request = subject.get(
        '/slow',
        options: api.RequestOptions(cancelToken: token),
      );
      await hanging.started.future;
      token.cancel('closed');

      await expectLater(request, throwsA(isA<api.HttpCancelledException>()));
      expect(hanging.cancelled, isTrue);
    });

    test('cancelling after the request completed does nothing', () async {
      final token = api.HttpCancelToken();

      final response = await subject.get(
        '/profile',
        options: api.RequestOptions(cancelToken: token),
      );
      token.cancel();

      expect(response.statusCode, 200);
      // The finished request detached its listener, so a long-lived token
      // holds nothing per settled request.
      expect(token.listenerCount, 0);
    });
  });

  group('dispose', () {
    test('closes the underlying Dio instance', () async {
      var closed = false;
      final closingAdapter = _ClosingAdapter(() => closed = true);
      dioClient.httpClientAdapter = closingAdapter;

      subject.dispose();

      expect(closed, isTrue);
    });
  });
}

class _HeaderInjectingInterceptor() implements api.HttpInterceptor {
  @override
  Future<api.HttpRequest> onRequest(api.HttpRequest request) async =>
      request.copyWith(
        options: (request.options ?? const api.RequestOptions()).copyWith(
          headers: {
            ...?request.options?.headers,
            'X-From-Api-Interceptor': 'yes',
          },
        ),
      );

  @override
  Future<api.HttpResponse> onResponse(api.HttpResponse response) async =>
      response;

  @override
  Future<Object> onError(api.HttpException error) async => error;
}

class _RejectingInterceptor() extends dio.Interceptor {
  @override
  void onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) {
    handler.reject(
      dio.DioException(
        requestOptions: options,
        error: const api.HttpRequestException('Unauthorized', statusCode: 401),
      ),
    );
  }
}

class _ClosingAdapter(final void Function() onClose)
    implements dio.HttpClientAdapter {
  @override
  void close({bool force = false}) => onClose();

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw UnimplementedError();
}

/// Holds every request open until Dio signals cancellation.
class _HangingAdapter() implements dio.HttpClientAdapter {
  final started = Completer<void>();
  bool cancelled = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    started.complete();
    await cancelFuture;
    cancelled = true;
    throw dio.DioException.requestCancelled(
      requestOptions: options,
      reason: 'closed',
    );
  }
}
