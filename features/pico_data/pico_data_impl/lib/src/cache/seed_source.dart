import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';

/// A bundled, read-only copy of the small "latest" resources, so the very first
/// launch works with no network and a cleared store falls back to it (C05).
abstract interface class SeedSource {
  /// The seed copy for [key], dated by the seed itself, or null.
  Future<StoredSnapshot?> read(String key);
}

/// [SeedSource] over the asset written by `tool/snapshot_seed.dart`.
///
/// The asset is `{"version", "generatedAt", "dataThrough", "entries": {key:
/// body}}`. Every body is the raw text the API sent for that key (or, for a
/// `derived:` key, a small JSON value the app derived), so the seed goes
/// through the same parsers as network and cache. Its date is the date of the
/// snapshot, so the "Data per ..." stamp tells the truth.
class AssetSeed implements SeedSource {
  /// Creates the seed over [bundle] (the root bundle by default).
  AssetSeed({AssetBundle? bundle, this.asset = kSeedAsset})
    : _bundle = bundle ?? rootBundle;

  /// Asset path of the seed.
  static const String kSeedAsset =
      'packages/pico_data_impl/assets/seed/seed.json';

  /// Asset path used by this package.
  final String asset;

  final AssetBundle _bundle;
  Future<Map<String, dynamic>?>? _loaded;

  Future<Map<String, dynamic>?> _load() => _loaded ??= () async {
    try {
      final json = jsonDecode(await _bundle.loadString(asset));
      return json is Map<String, dynamic> && json['version'] == 1 ? json : null;
    } on Object {
      // No seed is a normal state (a test, or a build without the asset).
      return null;
    }
  }();

  @override
  Future<StoredSnapshot?> read(String key) async {
    final seed = await _load();
    final entries = seed?['entries'];
    if (seed == null || entries is! Map<String, dynamic>) return null;
    final body = entries[key];
    if (body is! String) return null;
    return StoredSnapshot(
      key: key,
      body: body,
      fetchedAt: DateTime.parse(seed['generatedAt'] as String).toLocal(),
    );
  }
}

/// A seed with nothing in it, for tests and builds without the asset.
class const NoSeed() implements SeedSource {
  @override
  Future<StoredSnapshot?> read(String key) async => null;
}
