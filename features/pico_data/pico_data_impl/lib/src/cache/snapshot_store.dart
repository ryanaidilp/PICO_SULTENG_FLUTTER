import 'dart:convert';
import 'dart:io';

/// A saved response body and when it came from the network.
final class StoredSnapshot {
  /// Creates a stored snapshot.
  const new({required this.key, required this.body, required this.fetchedAt});

  /// Store key (the canonical request, for example `national_all`).
  final String key;

  /// The raw response body as received. Network and cache parse the same text.
  final String body;

  /// When the body came from the network.
  final DateTime fetchedAt;

  /// Whether the copy is older than [ttl] at [now].
  bool isStale(Duration ttl, DateTime now) => now.difference(fetchedAt) > ttl;
}

/// Offline snapshot store (ADR-0109): one file per canonical request in
/// [directory], holding the raw response body with `{fetchedAt, schemaVersion}`.
///
/// Writes go to `*.tmp` and are renamed, which is atomic. A file that cannot be
/// read, or has another schema version, is a cache miss and is deleted.
class SnapshotStore {
  /// Creates a store in [directory]. Bump [schemaVersion] to drop old copies.
  new(this.directory, {this.schemaVersion = 1});

  /// Where files live (the app support directory plus `snapshots`).
  final Directory directory;

  /// Copies saved with another version are ignored.
  final int schemaVersion;

  File _file(String key) => File(
    '${directory.path}/${Uri.encodeComponent(key).replaceAll('%', '_')}.json',
  );

  /// Saves [body] for [key], stamped [fetchedAt].
  Future<void> write(String key, String body, DateTime fetchedAt) async {
    await directory.create(recursive: true);
    final target = _file(key);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'v': schemaVersion,
        'key': key,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
        'body': body,
      }),
      flush: true,
    );
    await tmp.rename(target.path);
  }

  /// Reads the copy for [key], or null on a miss or a damaged file.
  Future<StoredSnapshot?> read(String key) async {
    final file = _file(key);
    try {
      if (!file.existsSync()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (json['v'] != schemaVersion) {
        await _delete(file);
        return null;
      }
      return StoredSnapshot(
        key: key,
        body: json['body'] as String,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String).toLocal(),
      );
    } on Object {
      await _delete(file);
      return null;
    }
  }

  /// Deletes the copy for [key], if any.
  Future<void> remove(String key) => _delete(_file(key));

  /// Bytes used by the store.
  Future<int> totalBytes() async {
    if (!directory.existsSync()) return 0;
    var total = 0;
    await for (final e in directory.list()) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  /// Deletes every saved copy.
  Future<void> clear() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  }

  Future<void> _delete(File f) async {
    try {
      if (f.existsSync()) await f.delete();
    } on FileSystemException {
      // A file we cannot delete stays a miss on every read.
    }
  }
}
