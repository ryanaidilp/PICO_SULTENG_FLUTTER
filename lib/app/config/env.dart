// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'BASE_URL')
  static final baseUrl = _Env.baseUrl;
  @EnviedField(varName: 'ONESIGNAL_APP_ID')
  static final oneSignalAppId = _Env.oneSignalAppId;
  @EnviedField(varName: 'NEWSAPI_API_KEY')
  static final newsapiApiKey = _Env.newsapiApiKey;
}
