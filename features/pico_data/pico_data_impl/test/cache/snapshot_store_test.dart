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

  test('stale is decided by the TTL', () async {
    final at = DateTime.utc(2024, 1, 15);
    await store.write('k', 'x', at);
    final s = (await store.read('k'))!;
    expect(s.isStale(PicoTtl.data, at.add(const Duration(hours: 23))), isFalse);
    expect(s.isStale(PicoTtl.data, at.add(const Duration(hours: 25))), isTrue);
    expect(
      s.isStale(PicoTtl.content, at.add(const Duration(hours: 7))),
      isTrue,
    );
  });

  test('a corrupt file is a miss and is deleted', () async {
    await store.write('k', 'x', DateTime.utc(2024));
    final f = File(dir.listSync(recursive: true).whereType<File>().single.path)
      ..writeAsStringSync('{"v":1,"body"');
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
    final v2 = SnapshotStore(store.directory, schemaVersion: 2);
    expect(await v2.read('k'), isNull);
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
