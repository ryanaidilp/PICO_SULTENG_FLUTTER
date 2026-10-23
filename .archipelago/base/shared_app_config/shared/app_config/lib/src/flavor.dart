/// Defines the available flavor states for the application.
///
/// Each flavor corresponds to a different environment configuration.
enum FlavorStatus() {
  /// Development flavor
  development,

  /// Staging flavor
  staging,

  /// Production flavor
  production;

  /// Returns the short code for this flavor.
  ///
  /// Used for file naming conventions (e.g., `.env.dev`, `.env.stg`).
  String get code => switch (this) {
    FlavorStatus.development => 'dev',
    FlavorStatus.staging => 'sta',
    FlavorStatus.production => 'pro',
  };

  /// Returns the display name for this flavor.
  String get displayName => switch (this) {
    FlavorStatus.development => 'Development',
    FlavorStatus.staging => 'Staging',
    FlavorStatus.production => 'Production',
  };
}

/// Manages the current application flavor status.
///
/// Set [status] early in the app lifecycle (typically in `main()`) to
/// configure which environment variables are used throughout the app.
abstract final class Flavor() {
  /// The current flavor status of the application.
  ///
  /// Must be set before accessing any environment variables.
  static FlavorStatus? status;

  /// Returns the current flavor status, throwing if not initialized.
  static FlavorStatus get current {
    final currentStatus = status;
    if (currentStatus == null) {
      throw StateError(
        'Flavor.status has not been initialized. '
        'Call Flavor.status = FlavorStatus.xxx in main() before accessing.',
      );
    }
    return currentStatus;
  }

  /// Whether the current flavor is development.
  static bool get isDevelopment => status == FlavorStatus.development;

  /// Whether the current flavor is staging.
  static bool get isStaging => status == FlavorStatus.staging;

  /// Whether the current flavor is production.
  static bool get isProduction => status == FlavorStatus.production;
}
