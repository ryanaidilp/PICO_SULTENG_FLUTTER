import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(
  path: '.env',

  /// Replace this to different environment
  obfuscate: true,
  useConstantCase: true,
)
abstract class Env {
  @EnviedField()
  static final String baseUrl = _Env.baseUrl;

  @EnviedField()
  static final String onesignalAppId = _Env.onesignalAppId;

  @EnviedField()
  static final String newsapiApiKey = _Env.newsapiApiKey;
}
