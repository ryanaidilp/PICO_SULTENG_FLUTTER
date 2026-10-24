/// Metadata for a page in the app, attached to a `PageIdentifier`.
///
/// This is the unit each feature contributes about its pages so the host
/// app can drive cross-feature concerns (deep-link routing, auth gating,
/// analytics screen logging, build-time stripping) without importing
/// feature internals.
class const PageConfig({
  /// Deep-link path template (e.g. `/assignment/:id`).
  ///
  /// Apps with auto_route should keep this in sync with the route's
  /// `path` argument. Path parameters use `:name` syntax.
  required final String deeplinkPath,

  /// Whether this page requires the user to be authenticated.
  ///
  /// Used by route guards and the auth-aware deep-link resolver to
  /// redirect unauthenticated users to a sign-in page.
  final bool requiresAuth = false,

  /// Analytics screen name. If null, `PageIdentifier.name` is used.
  final String? analyticsName,

  /// Free-form tags for build-time stripping or feature-flag gating
  /// (e.g. `['experimental', 'admin-only']`).
  final List<String> tags = const [],
}) {
  /// Creates a [PageConfig].
  this;
}
