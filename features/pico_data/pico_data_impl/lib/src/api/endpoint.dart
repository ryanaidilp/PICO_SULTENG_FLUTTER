/// One API request with its mapper: path, query and how to turn the decoded
/// `data` into a domain value. API classes build these, and the repositories
/// reuse the same descriptor for caching, so path and mapping live once.
class Endpoint<T> {
  /// Creates an endpoint.
  const Endpoint(this.path, this.map, {this.query, this.unwrapPage = true});

  /// Request path below the base URL.
  final String path;

  /// Query parameters.
  final Map<String, Object?>? query;

  /// Maps the decoded envelope `data`.
  final T Function(Object? data) map;

  /// Unwrap `{data: [...], pagination}` to its list.
  final bool unwrapPage;

  /// Canonical request: path and sorted query. The snapshot store key.
  String get key {
    final q = query == null
        ? ''
        : (query!.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => '${e.key}=${e.value}')
              .join('&');
    return q.isEmpty ? path : '$path?$q';
  }
}
