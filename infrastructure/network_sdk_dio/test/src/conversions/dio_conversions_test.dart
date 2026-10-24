import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/src/conversions/dio_conversions.dart';

void main() {
  group('DioConversions.toHttpException', () {
    test('prefers an already-wrapped api.HttpException carried in '
        'DioException.error over re-deriving one from the outer exception', () {
      final requestOptions = dio.RequestOptions(path: '/login');
      const wrapped = api.HttpRequestException('Unauthorized', statusCode: 401);
      // A DioException produced by an interceptor's reject path always
      // defaults to `type == unknown`, which would otherwise lose the
      // status code if re-derived from `type` alone.
      final dioException = dio.DioException(
        requestOptions: requestOptions,
        error: wrapped,
      );

      final result = DioConversions.toHttpException(dioException);

      expect(identical(result, wrapped), isTrue);
      expect(result.statusCode, 401);
    });

    test('derives HttpTimeoutException from connectionTimeout', () {
      final dioException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/ping'),
        type: dio.DioExceptionType.connectionTimeout,
      );

      expect(
        DioConversions.toHttpException(dioException),
        isA<api.HttpTimeoutException>(),
      );
    });

    test('derives HttpCancelledException from cancel', () {
      final dioException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/ping'),
        type: dio.DioExceptionType.cancel,
      );

      expect(
        DioConversions.toHttpException(dioException),
        isA<api.HttpCancelledException>(),
      );
    });

    test('derives HttpNetworkException from connectionError', () {
      final dioException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/ping'),
        type: dio.DioExceptionType.connectionError,
      );

      expect(
        DioConversions.toHttpException(dioException),
        isA<api.HttpNetworkException>(),
      );
    });

    test('derives HttpRequestException with statusCode from badResponse', () {
      final requestOptions = dio.RequestOptions(path: '/orders');
      final response = dio.Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 404,
        data: {'message': 'not found'},
      );
      final dioException = dio.DioException(
        requestOptions: requestOptions,
        type: dio.DioExceptionType.badResponse,
        response: response,
      );

      final result = DioConversions.toHttpException(dioException);

      expect(result, isA<api.HttpRequestException>());
      expect(result.statusCode, 404);
    });
  });

  group('DioConversions response round-trip', () {
    test('toHttpResponse maps status, data and joined headers', () {
      final requestOptions = dio.RequestOptions(path: '/ping');
      final response = dio.Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
        statusMessage: 'OK',
        data: {'ok': true},
        headers: dio.Headers.fromMap({
          'x-trace-id': ['abc', 'def'],
        }),
      );

      final result = DioConversions.toHttpResponse(response);

      expect(result.statusCode, 200);
      expect(result.statusMessage, 'OK');
      expect(result.data, {'ok': true});
      expect(result.headers['x-trace-id'], 'abc, def');
    });

    test('toDioResponse reuses the original requestOptions', () {
      final requestOptions = dio.RequestOptions(path: '/ping');
      final original = dio.Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
      );
      const httpResponse = api.HttpResponse.success({
        'ok': true,
      }, statusCode: 201);

      final result = DioConversions.toDioResponse(httpResponse, original);

      expect(identical(result.requestOptions, requestOptions), isTrue);
      expect(result.statusCode, 201);
      expect(result.data, {'ok': true});
    });
  });

  group('DioConversions.toDioOptions', () {
    test('maps method and api.RequestOptions fields onto dio.Options', () {
      const options = api.RequestOptions(
        headers: {'X-Custom': '1'},
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 6),
        sendTimeout: Duration(seconds: 7),
        followRedirects: false,
        maxRedirects: 2,
      );

      final result = DioConversions.toDioOptions('POST', options);

      expect(result.method, 'POST');
      expect(result.headers, {'X-Custom': '1'});
      expect(result.connectTimeout, const Duration(seconds: 5));
      expect(result.receiveTimeout, const Duration(seconds: 6));
      expect(result.sendTimeout, const Duration(seconds: 7));
      expect(result.followRedirects, isFalse);
      expect(result.maxRedirects, 2);
    });

    test('falls back to followRedirects=true/maxRedirects=5 when null', () {
      final result = DioConversions.toDioOptions('GET', null);

      expect(result.method, 'GET');
      expect(result.followRedirects, isTrue);
      expect(result.maxRedirects, 5);
    });
  });
}
