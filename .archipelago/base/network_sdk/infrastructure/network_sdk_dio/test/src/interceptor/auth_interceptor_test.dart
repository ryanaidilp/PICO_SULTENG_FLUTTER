import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/network_sdk_dio.dart';

/// A [dio.HttpClientAdapter] that answers from a script instead of the
/// network, and records every request it was handed.
///
/// The script is a queue: each request consumes the next entry, so a test can
/// say "answer 401, then 200" and assert the second call really happened.
class _ScriptedAdapter(
  final List<dio.ResponseBody Function(dio.RequestOptions options)> _script,
) implements dio.HttpClientAdapter {
  /// Every request handed to the adapter, in order.
  final List<dio.RequestOptions> requests = [];

  /// The `Authorization` header of each request, snapshotted **at send
  /// time**.
  ///
  /// A replay reuses (and mutates) the original [dio.RequestOptions] — the
  /// standard Dio retry idiom — so reading the header off the recorded
  /// objects afterwards would show every entry with the final token. Only a
  /// snapshot taken as the request leaves distinguishes "replayed with the
  /// rotated bearer" from "replayed with the stale one".
  final List<String?> authorizationHeaders = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    authorizationHeaders.add(options.headers['Authorization'] as String?);
    final step = _script.isEmpty ? null : _script.removeAt(0);
    if (step == null) {
      throw StateError(
        'Adapter ran out of scripted responses at request #${requests.length} '
        '(${options.method} ${options.path}). The interceptor issued more '
        'requests than the test expected.',
      );
    }
    return step(options);
  }
}

/// An [api.AuthTokenProvider] whose renewal outcome is fully controllable,
/// and which counts how many times the transport asked for one.
///
/// It rotates the access token on every successful renewal, so a test can
/// tell a replay that picked up the fresh bearer from one that pasted the
/// stale one back.
class _FakeAuthTokenProvider({
  /// The token handed to outbound requests.
  var String? token = 'access-0',

  /// What [onUnauthorized] answers.
  var bool renewSucceeds = true,
}) implements api.AuthTokenProvider {
  /// Every `(statusCode, endpoint)` the transport reported.
  final List<(int, String?)> unauthorizedCalls = [];

  /// How many times [accessToken] was read.
  int accessTokenReads = 0;

  int _rotation = 0;

  @override
  Future<String?> get accessToken async {
    accessTokenReads++;
    return token;
  }

  @override
  Future<bool> onUnauthorized({
    required int statusCode,
    String? endpoint,
  }) async {
    unauthorizedCalls.add((statusCode, endpoint));
    if (!renewSucceeds) return false;
    token = 'access-${++_rotation}';
    return true;
  }
}

void main() {
  dio.ResponseBody json(int statusCode, String body) =>
      dio.ResponseBody.fromString(
        body,
        statusCode,
        headers: {
          dio.Headers.contentTypeHeader: [dio.Headers.jsonContentType],
        },
      );

  dio.ResponseBody Function(dio.RequestOptions) ok([
    String body = '{"ok":true}',
  ]) =>
      (_) => json(200, body);

  dio.ResponseBody Function(dio.RequestOptions) unauthorized() =>
      (_) => json(401, '{"error":"token expired"}');

  /// Builds a real [DioHttpClient] — the same construction path
  /// `RegisterModule.httpClient()` uses — wired to [provider] and answering
  /// from [script].
  (DioHttpClient, _ScriptedAdapter) buildClient({
    required List<dio.ResponseBody Function(dio.RequestOptions)> script,
    api.AuthTokenProvider? provider,
  }) {
    final adapter = _ScriptedAdapter(script);
    final client = DioHttpClient.init(
      config: const DioConfig(baseUrl: 'https://api.example.test'),
      authTokenProvider: () => provider,
    )..httpClientAdapter = adapter;
    return (client, adapter);
  }

  group('attaching the bearer', () {
    test('reads the token from the provider and sends it', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(script: [ok()], provider: provider);

      await client.get<dynamic>('/profile');

      expect(adapter.authorizationHeaders, ['Bearer access-0']);
      expect(provider.accessTokenReads, 1);
    });

    test('sends no Authorization header when there is no session', () async {
      final provider = _FakeAuthTokenProvider(token: null);
      final (client, adapter) = buildClient(script: [ok()], provider: provider);

      await client.get<dynamic>('/profile');

      expect(adapter.authorizationHeaders, [null]);
    });

    test('never overwrites an Authorization header the caller set', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(script: [ok()], provider: provider);

      await client.get<dynamic>(
        '/profile',
        options: dio.Options(headers: {'Authorization': 'Basic caller-owned'}),
      );

      expect(adapter.authorizationHeaders, ['Basic caller-owned']);
      expect(provider.accessTokenReads, 0);
    });
  });

  group('401 -> renew -> replay, driven through a real client', () {
    test('replays the request once with the rotated bearer and returns the '
        'replayed response', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        script: [unauthorized(), ok('{"id":"u1"}')],
        provider: provider,
      );

      final response = await client.get<dynamic>('/profile');

      // The caller sees the successful replay, not the 401.
      expect(response.statusCode, 200);
      expect(response.data, {'id': 'u1'});

      // Exactly one renewal was requested, for the failing endpoint.
      expect(provider.unauthorizedCalls, [(401, '/profile')]);

      // Two round trips: the original with the stale bearer, the replay with
      // the rotated one. A replay that pasted the stale token back would show
      // 'Bearer access-0' twice.
      expect(adapter.requests, hasLength(2));
      expect(adapter.authorizationHeaders, [
        'Bearer access-0',
        'Bearer access-1',
      ]);
    });

    test('the vendor-agnostic HttpClient port sees the recovered response, '
        'not an HttpException', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, _) = buildClient(
        script: [unauthorized(), ok('{"id":"u1"}')],
        provider: provider,
      );
      final port = DioHttpClientAdapter(client);

      final response = await port.get('/profile');

      expect(response.statusCode, 200);
      expect(response.dataAsMap, {'id': 'u1'});
    });

    test('does not replay when renewal fails, and surfaces the original '
        'failure', () async {
      final provider = _FakeAuthTokenProvider(renewSucceeds: false);
      final (client, adapter) = buildClient(
        script: [unauthorized()],
        provider: provider,
      );

      await expectLater(
        client.get<dynamic>('/profile'),
        throwsA(
          isA<dio.DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(provider.unauthorizedCalls, hasLength(1));
      expect(adapter.requests, hasLength(1));
    });

    test('leaves non-401 failures completely alone', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        script: [(_) => json(500, '{"error":"boom"}')],
        provider: provider,
      );

      await expectLater(
        client.get<dynamic>('/profile'),
        throwsA(isA<dio.DioException>()),
      );

      expect(provider.unauthorizedCalls, isEmpty);
      expect(adapter.requests, hasLength(1));
    });

    test('does not renew on 403 by default — an authorization failure is not '
        'a lapsed session', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, _) = buildClient(
        script: [(_) => json(403, '{"error":"forbidden"}')],
        provider: provider,
      );

      await expectLater(
        client.get<dynamic>('/admin'),
        throwsA(isA<dio.DioException>()),
      );

      expect(provider.unauthorizedCalls, isEmpty);
    });
  });

  group('bounded retry', () {
    test('a replay that also 401s does not trigger a second renewal or a '
        'third request', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        // If the retry marker did not stop the loop, the adapter would run
        // out of script and throw a StateError naming the request count.
        script: [unauthorized(), unauthorized()],
        provider: provider,
      );

      await expectLater(
        client.get<dynamic>('/profile'),
        throwsA(
          isA<dio.DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(provider.unauthorizedCalls, hasLength(1));
      expect(adapter.requests, hasLength(2));
    });
  });

  group('auth-exempt requests', () {
    test('carry no bearer and never trigger a renewal, so the renewal '
        'request itself cannot re-enter the refresh path', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        script: [unauthorized()],
        provider: provider,
      );

      // Exactly how the auth datasource issues `POST /auth/refresh`.
      await expectLater(
        client.post<dynamic>(
          '/auth/refresh',
          data: {'refresh_token': 'r0'},
          options: dio.Options(extra: api.AuthExemptRequest.extra),
        ),
        throwsA(isA<dio.DioException>()),
      );

      expect(provider.unauthorizedCalls, isEmpty);
      expect(adapter.requests, hasLength(1));
      expect(adapter.authorizationHeaders, [null]);
    });

    test('AuthExemptRequest.mark preserves the options it is merged into', () {
      const base = api.RequestOptions(
        headers: {'X-Trace': 'abc'},
        queryParameters: {'v': 2},
      );

      final marked = api.AuthExemptRequest.mark(base);

      expect(api.AuthRequestMarkers.isExempt(marked.extra), isTrue);
      expect(marked.headers, {'X-Trace': 'abc'});
      expect(marked.queryParameters, {'v': 2});
    });

    test('exempt options survive the RequestOptions -> Dio conversion used '
        'by the HttpClient port', () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        script: [unauthorized()],
        provider: provider,
      );
      final port = DioHttpClientAdapter(client);

      await expectLater(
        port.post(
          '/auth/login',
          body: {'email': 'a@b.c'},
          options: api.AuthExemptRequest.options,
        ),
        throwsA(isA<api.HttpRequestException>()),
      );

      expect(provider.unauthorizedCalls, isEmpty);
      expect(adapter.requests, hasLength(1));
    });
  });

  group('no auth feature installed', () {
    test('a client whose resolver returns null behaves exactly as it did '
        'before the auth port existed', () async {
      final (client, adapter) = buildClient(script: [unauthorized()]);

      await expectLater(
        client.get<dynamic>('/profile'),
        throwsA(isA<dio.DioException>()),
      );

      expect(adapter.requests, hasLength(1));
      expect(adapter.authorizationHeaders, [null]);
    });

    test('a client built without an authTokenProvider installs no auth '
        'interceptor at all', () async {
      final adapter = _ScriptedAdapter([ok()]);
      final client = DioHttpClient.init()..httpClientAdapter = adapter;

      expect(client.interceptors.whereType<AuthInterceptor>(), isEmpty);

      await client.get<dynamic>('/profile');
      expect(adapter.authorizationHeaders, [null]);
    });
  });

  group('concurrent 401s', () {
    test('every failing request is replayed once; de-duplicating the renewal '
        "itself is the provider's job", () async {
      final provider = _FakeAuthTokenProvider();
      final (client, adapter) = buildClient(
        script: [
          unauthorized(),
          unauthorized(),
          unauthorized(),
          ok(),
          ok(),
          ok(),
        ],
        provider: provider,
      );

      final responses = await Future.wait([
        client.get<dynamic>('/a'),
        client.get<dynamic>('/b'),
        client.get<dynamic>('/c'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(provider.unauthorizedCalls, hasLength(3));
      expect(adapter.requests, hasLength(6));
    });
  });
}
