import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(
  path: '.env',
  obfuscate: true,
  useConstantCase: true,
  name: 'EnvProd',
)
abstract class EnvProd {
  @EnviedField()
  static final String baseUrl = _EnvProd.baseUrl;

  @EnviedField()
  static final String onesignalAppId = _EnvProd.onesignalAppId;

  @EnviedField()
  static final String newsapiApiKey = _EnvProd.newsapiApiKey;

   
  @EnviedField()
  static final String appName = _EnvProd.appName;
}

@Envied(
  path: '.env.dev',
  obfuscate: true,
  useConstantCase: true,
  name: 'EnvDev',
)
abstract class EnvDev {
  @EnviedField()
  static final String baseUrl = _EnvDev.baseUrl;

  @EnviedField()
  static final String onesignalAppId = _EnvDev.onesignalAppId;

  @EnviedField()
  static final String newsapiApiKey = _EnvDev.newsapiApiKey;
  
  @EnviedField()
  static final String appName = _EnvDev.appName;
}


@Envied(
  path: '.env.stg',
  obfuscate: true,
  useConstantCase: true,
  name: 'EnvStg',
)
abstract class EnvStg {
  @EnviedField()
  static final String baseUrl = _EnvStg.baseUrl;

  @EnviedField()
  static final String onesignalAppId = _EnvStg.onesignalAppId;

  @EnviedField()
  static final String newsapiApiKey = _EnvStg.newsapiApiKey;

   
  @EnviedField()
  static final String appName = _EnvStg.appName;
}
