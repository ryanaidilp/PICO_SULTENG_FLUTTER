import 'package:envied/envied.dart';

part 'test_env.g.dart';

@Envied(
  path: 'test/.env.test',

  /// Replace this to different environment
  obfuscate: true,
  useConstantCase: true,
  name: 'TestEnv',
)
abstract class TestEnv {
  @EnviedField()
  static final String baseUrl = _TestEnv.baseUrl;

  @EnviedField()
  static final String onesignalAppId = _TestEnv.onesignalAppId;

  @EnviedField()
  static final String newsapiApiKey = _TestEnv.newsapiApiKey;
}
