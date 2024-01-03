import 'package:config/config.dart';
import 'package:config/src/env/env.dart';

class Env {
  const Env._();

  static String apiBaseUrl = switch (Flavor.flavor) {
    FlavorStatus.DEVELOPMENT => EnvDev.baseUrl,
    FlavorStatus.STAGING => EnvStg.baseUrl,
    FlavorStatus.PRODUCTION => EnvProd.baseUrl,
    _ => EnvDev.baseUrl,
  };
  static String onesignalAppID = switch (Flavor.flavor) {
    FlavorStatus.DEVELOPMENT => EnvDev.onesignalAppId,
    FlavorStatus.STAGING => EnvStg.onesignalAppId,
    FlavorStatus.PRODUCTION => EnvProd.onesignalAppId,
    _ => EnvDev.onesignalAppId,
  };
  static String newsapiApiKey = switch (Flavor.flavor) {
    FlavorStatus.DEVELOPMENT => EnvDev.newsapiApiKey,
    FlavorStatus.STAGING => EnvStg.newsapiApiKey,
    FlavorStatus.PRODUCTION => EnvProd.newsapiApiKey,
    _ => EnvDev.newsapiApiKey,
  };
}
