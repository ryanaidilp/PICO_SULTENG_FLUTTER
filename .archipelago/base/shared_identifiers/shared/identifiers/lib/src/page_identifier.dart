import 'package:identifiers/src/page_config.dart';

/// Contract for a typed page identifier.
///
/// Each feature defines its own enum that implements this interface so
/// each value carries its [PageConfig]. The host app aggregates all
/// feature enums via `PageIdentifierRegistry`.
///
/// Example:
/// ```dart
/// enum HomePage implements PageIdentifier {
///   dashboard(PageConfig(deeplinkPath: '/dashboard', requiresAuth: true)),
///   profile(PageConfig(deeplinkPath: '/profile', requiresAuth: true));
///
///   const HomePage(this.config);
///
///   @override
///   final PageConfig config;
///
///   @override
///   String get name => toString().split('.').last;
/// }
/// ```
abstract interface class PageIdentifier() {
  /// Stable string name used as a fallback for analytics and logging.
  String get name;

  /// Metadata for this page.
  PageConfig get config;
}
