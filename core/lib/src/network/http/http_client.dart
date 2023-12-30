// ignore_for_file: public_member_api_docs

// Dart imports:
import 'dart:developer' as dev;
import 'dart:math' as math;

// Project imports:

// Package imports:
import 'package:config/config.dart';
import 'package:core/src/network/http/http_setting.dart';
import 'package:core/src/network/interceptors/logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class HttpClient extends DioMixin {
  HttpClient._(HttpSetting setting) {
    options = BaseOptions(
      baseUrl: setting.baseUrl,
      contentType: setting.contentType,
      connectTimeout: Duration(milliseconds: setting.timeout.connectTimeout),
      sendTimeout: Duration(milliseconds: setting.timeout.sendTimeout),
      receiveTimeout: Duration(milliseconds: setting.timeout.receiveTimeout),
    );

    httpClientAdapter = IOHttpClientAdapter();
    final retryInterceptor = RetryInterceptor(
      dio: this,
      logPrint: dev.log,
      retries: 7,
      retryDelays: List.generate(
        7,
        (index) => Duration(
          milliseconds: math.min(
            (3 ^ (index + 1)) + (index * 1000 + math.Random().nextInt(1000)),
            5000,
          ),
        ),
      ),
    );

    interceptors
      ..add(retryInterceptor)
      ..addAll(defaultInterceptors)
      ..addAll(
        setting.interceptors ?? [],
      );
  }

  // ignore: prefer_constructors_over_static_methods
  static HttpClient init([HttpSetting? setting]) {
    return HttpClient._(setting ?? HttpSetting(baseUrl: Env.baseUrl));
  }

  static List<Interceptor> defaultInterceptors = [
    LoggingInterceptor(),
  ];
}
