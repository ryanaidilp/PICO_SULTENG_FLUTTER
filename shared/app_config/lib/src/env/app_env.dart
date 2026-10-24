import 'package:app_config/src/env/env.dart';

/// Centralized access point for environment variables.
///
/// Delegates directly to [Env], which reads from the active `.env` file
/// populated at build time by `dart run monorepo_toolkit env switch <flavor>`.
///
/// ## Usage
///
/// ```dart
/// final baseUrl = AppEnv.apiBaseUrl;
/// ```
///
/// ## Adding New Environment Variables
///
/// 1. Add `@EnviedField()` to `env.dart`.
/// 2. Add the placeholder to all `.env.<flavor>` files.
/// 3. Run `dart run monorepo_toolkit env switch <flavor>` then
///    `dart run build_runner build` to regenerate.
abstract final class AppEnv() {
  /// The API base URL for the active flavor.
  static String get apiBaseUrl => Env.apiBaseUrl;

  /// The application name for the active flavor.
  static String get appName => Env.appName;

  /// The AES encryption key for the active flavor.
  static String get aesKey => Env.aesKey;

  /// The database connection URL for the active flavor.
  static String get databaseUrl => Env.databaseUrl;

  /// The OneSignal App ID for the active flavor.
  static String get onesignalAppId => Env.onesignalAppId;
}
