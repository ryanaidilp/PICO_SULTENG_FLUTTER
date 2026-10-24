import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';

/// The disk image cache, seen from the data layer. The kit's `PicoImage` owns
/// the cache (key `picoImages`); this reads its size and empties it.
abstract interface class ImageCacheAdmin {
  /// Bytes on disk.
  Future<int> bytes();

  /// Deletes every cached image.
  Future<void> clear();
}

/// [ImageCacheAdmin] for the `picoImages` cache of `flutter_cache_manager`.
class DiskImageCacheAdmin implements ImageCacheAdmin {
  /// Creates the admin. [key] must match the kit's cache key.
  DiskImageCacheAdmin({this.key = 'picoImages'});

  /// Cache key (directory name under the temporary directory).
  final String key;

  @override
  Future<int> bytes() async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/$key');
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  @override
  Future<void> clear() => CacheManager(Config(key)).emptyCache();
}

/// [LocalDataAdmin]: snapshot store plus image cache (C05, Pengaturan).
class LocalDataAdminImpl implements LocalDataAdmin {
  /// Creates the admin.
  LocalDataAdminImpl(this._store, this._images);

  final SnapshotStore _store;
  final ImageCacheAdmin _images;

  @override
  Future<int> cachedBytes() async =>
      await _store.totalBytes() + await _images.bytes();

  @override
  Future<void> clearAll() async {
    await _store.clear();
    await _images.clear();
  }
}
