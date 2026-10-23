import 'package:identifiers/src/page_identifier.dart';

/// Aggregates all [PageIdentifier]s contributed by features so the host
/// app can resolve them by name or deep-link path.
///
/// Features call [register] during their FeatureSDK launch. The host app
/// queries the registry from deep-link handlers, FCM payload routers,
/// auth guards, and analytics screen-logging middleware.
class PageIdentifierRegistry() {
  /// Creates an empty [PageIdentifierRegistry].
  this;

  final List<PageIdentifier> _identifiers = [];

  /// Adds [identifiers] to the registry. Idempotent — duplicates by
  /// `name` are ignored so re-registering a feature is safe.
  void register(Iterable<PageIdentifier> identifiers) {
    for (final id in identifiers) {
      if (_identifiers.any((existing) => existing.name == id.name)) {
        continue;
      }
      _identifiers.add(id);
    }
  }

  /// All registered identifiers.
  List<PageIdentifier> get all => List.unmodifiable(_identifiers);

  /// Finds an identifier by its [PageIdentifier.name]. Returns null if
  /// not registered.
  PageIdentifier? findByName(String name) {
    for (final id in _identifiers) {
      if (id.name == name) return id;
    }
    return null;
  }

  /// Finds an identifier whose `config.deeplinkPath` matches [path]
  /// exactly. Returns null if none found.
  ///
  /// For path-template matching with parameters (e.g. matching
  /// `/assignment/123` against `/assignment/:id`), the host app should
  /// use a deep-link router on top of [all] rather than this method.
  PageIdentifier? findByDeeplinkPath(String path) {
    for (final id in _identifiers) {
      if (id.config.deeplinkPath == path) return id;
    }
    return null;
  }

  /// Removes all registered identifiers. Mainly for testing.
  void clear() => _identifiers.clear();
}
