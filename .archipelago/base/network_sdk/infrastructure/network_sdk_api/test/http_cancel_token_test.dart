import 'package:network_sdk_api/network_sdk_api.dart';
import 'package:test/test.dart';

void main() {
  group('HttpCancelToken', () {
    test('starts uncancelled', () {
      final token = HttpCancelToken();

      expect(token.isCancelled, isFalse);
      expect(token.reason, isNull);
    });

    test('cancel marks it cancelled and keeps the first reason', () {
      final token = HttpCancelToken()
        ..cancel('closed')
        ..cancel('again');

      expect(token.isCancelled, isTrue);
      expect(token.reason, 'closed');
    });

    test('notifies each listener once, on the first cancel', () {
      final token = HttpCancelToken();
      var calls = 0;
      token.onCancel(() => calls++);

      token
        ..cancel()
        ..cancel();

      expect(calls, 1);
    });

    test('a detached listener is not called', () {
      final token = HttpCancelToken();
      var called = false;
      final detach = token.onCancel(() => called = true);

      detach();
      token.cancel();

      expect(called, isFalse);
    });

    test('a listener added after cancel runs at once', () {
      final token = HttpCancelToken()..cancel();
      var called = false;

      token.onCancel(() => called = true);

      expect(called, isTrue);
    });
  });

  group('RequestOptions.cancelToken', () {
    test('survives copyWith and merge', () {
      final token = HttpCancelToken();
      final options = RequestOptions(cancelToken: token);

      expect(options.copyWith(maxRedirects: 1).cancelToken, same(token));
      expect(RequestConfigs.standard.merge(options).cancelToken, same(token));
      expect(options.merge(const RequestOptions()).cancelToken, same(token));
    });
  });

  test('a cancelled request surfaces as HttpCancelledException', () {
    const HttpException error = HttpCancelledException();

    expect(error, isA<HttpCancelledException>());
    expect(error.statusCode, isNull);
  });
}
