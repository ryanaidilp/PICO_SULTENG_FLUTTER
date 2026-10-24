import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';

/// A simple LRU cache for Lottie compositions.
class LottieCache({final int maxSize = 100}) {
  @visibleForTesting
  final Map<String, LottieComposition> cache = {};
  @visibleForTesting
  final List<String> accessOrder = [];

  int get size => cache.length;
  bool get isEmpty => cache.isEmpty;
  bool get isFull => cache.length >= maxSize;
  bool contains(String path) => cache.containsKey(path);

  LottieComposition? get(String path) {
    final composition = cache[path];
    if (composition != null) _updateAccessOrder(path);
    return composition;
  }

  Future<LottieComposition> load(String path, {String? package}) async {
    final cached = get(path);
    if (cached != null) return cached;
    final composition = await AssetLottie(path, package: package).load();
    put(path, composition);
    return composition;
  }

  void put(String path, LottieComposition composition) {
    if (cache.containsKey(path)) {
      cache[path] = composition;
      _updateAccessOrder(path);
      return;
    }
    while (cache.length >= maxSize && accessOrder.isNotEmpty) {
      cache.remove(accessOrder.removeAt(0));
    }
    cache[path] = composition;
    accessOrder.add(path);
  }

  Future<void> preCache(List<String> paths, {String? package}) async {
    await Future.wait(paths.map((path) => load(path, package: package)));
  }

  LottieComposition? remove(String path) {
    accessOrder.remove(path);
    return cache.remove(path);
  }

  void clear() {
    cache.clear();
    accessOrder.clear();
  }

  void _updateAccessOrder(String path) {
    accessOrder
      ..remove(path)
      ..add(path);
  }
}

/// Global Lottie cache instance.
LottieCache lottieCache = LottieCache();
