import 'dart:convert';
import 'dart:io';

/// A saved response body and when it came from the network.
final class StoredSnapshot {
  /// Creates a stored snapshot.
  const new({
    required this.key,
    required this.body,
    required this.fetchedAt,
    this.etag,
  });

  /// Store key (the canonical request, for example `national_all`).
  final String key;

  /// The raw response body as received. Network and cache parse the same text.
  final String body;

  /// When the body was fetched, or last confirmed current by a 304.
  final DateTime fetchedAt;

  /// The `ETag` the API sent with the body, if any.
  final String? etag;

  /// Whether the copy is older than [ttl] at [now].
  bool isStale(Duration ttl, DateTime now) => now.difference(fetchedAt) > ttl;
}

/// Offline snapshot store (ADR-0109): one file per canonical request in
/// [directory].
///
/// File format (schema 2): a first line with the small header
/// `{"v":2,"key":...,"fetchedAt":...,"etag":...}`, then the raw response body.
/// The body is never escaped into JSON, so a 0.8 MB series is written and read
/// as plain text with no encode or decode of the whole file on the UI isolate.
///
/// Writes go to `*.tmp` and are renamed, which is atomic. A file that cannot be
/// read, or has another schema version, is a cache miss and is deleted.
class SnapshotStore {
  /// Creates a store in [directory]. Bump [schemaVersion] to drop old copies.
  new(this.directory, {this.schemaVersion = 2});

  /// Where files live (the app support directory plus `snapshots`).
  final Directory directory;

  /// Copies saved with another version are ignored.
  final int schemaVersion;

  File _file(String key) => File(
    '${directory.path}/${Uri.encodeComponent(key).replaceAll('%', '_')}.json',
  );

  /// Saves [body] for [key], stamped [fetchedAt].
  Future<void> write(
    String key,
    String body,
    DateTime fetchedAt, {
    String? etag,
  }) async {
    await directory.create(recursive: true);
    final target = _file(key);
    final tmp = File('${target.path}.tmp');
    final header = jsonEncode({
      'v': schemaVersion,
      'key': key,
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'etag': ?etag,
    });
    await tmp.writeAsString('$header\n$body', flush: true);
    await tmp.rename(target.path);
  }

  /// Reads the copy for [key], or null on a miss or a damaged file.
  Future<StoredSnapshot?> read(String key) async {
    final file = _file(key);
    try {
      if (!file.existsSync()) return null;
      final text = await file.readAsString();
      final cut = text.indexOf('\n');
      if (cut < 0) throw const FormatException('no header');
      final header = jsonDecode(text.substring(0, cut)) as Map<String, dynamic>;
      if (header['v'] != schemaVersion) {
        await _delete(file);
        return null;
      }
      return StoredSnapshot(
        key: key,
        body: text.substring(cut + 1),
        fetchedAt: DateTime.parse(header['fetchedAt'] as String).toLocal(),
        etag: header['etag'] as String?,
      );
    } on Object {
      await _delete(file);
      return null;
    }
  }

  /// A 304 answer: the copy is still current, so only its date moves.
  Future<void> touch(String key, DateTime checkedAt) async {
    final saved = await read(key);
    if (saved == null) return;
    await write(key, saved.body, checkedAt, etag: saved.etag);
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
