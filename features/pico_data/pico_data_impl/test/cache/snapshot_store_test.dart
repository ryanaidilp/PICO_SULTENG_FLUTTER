import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

void main() {
  late Directory dir;
  late SnapshotStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pico_store_');
    store = SnapshotStore(Directory('${dir.path}/snapshots'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('round-trips the raw body and fetchedAt', () async {
    final at = DateTime.utc(2024, 1, 15, 3);
    await store.write('national_all', '{"status":"success","data":[]}', at);
    final s = (await store.read('national_all'))!;
    expect(s.body, '{"status":"success","data":[]}');
    expect(s.fetchedAt.isAtSameMomentAs(at), isTrue);
  });

  test('a missing key is a miss', () async {
    expect(await store.read('nope'), isNull);
  });

  test('stale is decided by the TTL of the resource class', () async {
    final at = DateTime.utc(2024, 1, 15);
    await store.write('k', 'x', at);
    final s = (await store.read('k'))!;
    bool stale(Duration ttl, Duration age) => s.isStale(ttl, at.add(age));
    expect(stale(PicoTtl.latest, const Duration(days: 6)), isFalse);
    expect(stale(PicoTtl.latest, const Duration(days: 8)), isTrue);
    expect(stale(PicoTtl.content, const Duration(days: 2)), isFalse);
    expect(stale(PicoTtl.content, const Duration(days: 4)), isTrue);
    expect(stale(PicoTtl.archiveSeries, const Duration(days: 60)), isFalse);
    expect(stale(PicoTtl.archiveSeries, const Duration(days: 100)), isTrue);
  });

  test('the body is stored as plain text after a one line header', () async {
    await store.write('k', '{"a":"x\\"y"}', DateTime.utc(2024), etag: 'W/"1"');
    final raw = dir
        .listSync(recursive: true)
        .whereType<File>()
        .single
        .readAsStringSync();
    expect(raw.split('\n').length, 2);
    expect(raw.endsWith('{"a":"x\\"y"}'), isTrue);
    final s = (await store.read('k'))!;
    expect(s.body, '{"a":"x\\"y"}');
    expect(s.etag, 'W/"1"');
  });

  test('touch moves the date and keeps body and etag', () async {
    await store.write('k', 'body', DateTime.utc(2024), etag: 'e');
    await store.touch('k', DateTime.utc(2025));
    final s = (await store.read('k'))!;
    expect(s.body, 'body');
    expect(s.etag, 'e');
    expect(s.fetchedAt.isAtSameMomentAs(DateTime.utc(2025)), isTrue);
  });

  test('a corrupt file is a miss and is deleted', () async {
    await store.write('k', 'x', DateTime.utc(2024));
    final f = File(dir.listSync(recursive: true).whereType<File>().single.path)
      ..writeAsStringSync('{"v":2,"bo');
    expect(await store.read('k'), isNull);
    expect(f.existsSync(), isFalse);
  });

  test('a crash-left tmp file never shadows the real copy', () async {
    await store.write('k', 'good', DateTime.utc(2024));
    final real = dir.listSync(recursive: true).whereType<File>().single;
    File('${real.path}.tmp').writeAsStringSync('half a wri');
    expect((await store.read('k'))!.body, 'good');
  });

  test('another schema version is a miss', () async {
    await store.write('k', 'x', DateTime.utc(2024));
    final v3 = SnapshotStore(store.directory, schemaVersion: 3);
    expect(await v3.read('k'), isNull);
  });

  test('keys with slashes and queries are safe file names', () async {
    await store.write('provinces/72/cases?all=true', 'a', DateTime.utc(2024));
    expect((await store.read('provinces/72/cases?all=true'))!.body, 'a');
  });

  test('totalBytes counts and clear empties the store', () async {
    await store.write('a', 'x' * 1000, DateTime.utc(2024));
    expect(await store.totalBytes(), greaterThan(1000));
    await store.clear();
    expect(await store.totalBytes(), 0);
    expect(await store.read('a'), isNull);
  });
}
