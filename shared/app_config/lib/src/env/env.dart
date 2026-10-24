import 'package:envied/envied.dart';

part 'env.g.dart';

/// Single source of environment variables for the active flavor.
///
/// Values are populated by build_runner from the `.env` file at the package
/// root. To switch flavors, run:
/// ```bash
/// dart run monorepo_toolkit env switch <flavor>
/// dart run build_runner build
/// ```
///
/// The `.env` file is gitignored — it is written at build time by `env switch`.
/// Never edit it directly.
@Envied(path: '.env', obfuscate: true, useConstantCase: true)
abstract final class Env() {
  /// The API base URL for the active flavor.
  @EnviedField()
  static final String apiBaseUrl = _Env.apiBaseUrl;

  /// The application name.
  @EnviedField()
  static final String appName = _Env.appName;

  /// The AES encryption key.
  @EnviedField()
  static final String aesKey = _Env.aesKey;

  /// The database connection URL.
  @EnviedField()
  static final String databaseUrl = _Env.databaseUrl;

  /// The OneSignal App ID.
  @EnviedField()
  static final String onesignalAppId = _Env.onesignalAppId;
}
