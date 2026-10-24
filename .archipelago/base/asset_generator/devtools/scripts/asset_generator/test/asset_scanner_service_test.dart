import 'dart:io';

import 'package:asset_generator/src/models/asset_generator_config.dart';
import 'package:asset_generator/src/models/discovered_asset.dart';
import 'package:asset_generator/src/services/asset_scanner_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  // A real dotLottie: manifest.json + animations/pulse.json, deflated.
  final fixture = File('test/fixtures/pulse.lottie');
  late Directory root;
  late Directory animations;
  late AssetScannerService service;

  setUp(() {
    root = Directory.systemTemp.createTempSync('asset_gen_');
    animations = Directory(p.join(root.path, 'assets', 'animations'))
      ..createSync(recursive: true);
    service = AssetScannerService(
      config: AssetGeneratorConfig(
        packagePath: root.path,
        assetsPath: p.join(root.path, 'assets'),
        outputPath: p.join(root.path, 'lib'),
        prefix: 'App',
        packageName: 'app_asset',
      ),
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  void addJson(String name) =>
      File(p.join(animations.path, '$name.json')).writeAsStringSync('{}');
  void addLottie(String name) =>
      fixture.copySync(p.join(animations.path, '$name.lottie'));

  List<String> scannedPaths() =>
      service.scan().single.assets.map((a) => p.basename(a.path)).toList();

  test('fixture is a zip', () {
    expect(fixture.readAsBytesSync().take(2), [0x50, 0x4B]);
  });

  test('maps .lottie to AssetType.lottie', () {
    expect(AssetType.fromExtension('.lottie'), AssetType.lottie);
    expect(AssetType.fromExtension('.LOTTIE'), AssetType.lottie);
  });

  test('a lone .json is still scanned', () {
    addJson('wifi');
    expect(scannedPaths(), ['wifi.json']);
  });

  test('a lone .lottie is scanned', () {
    addLottie('pulse');
    expect(scannedPaths(), ['pulse.lottie']);
  });

  test('.lottie wins over a same-named .json', () {
    addJson('pulse');
    addLottie('pulse');
    addJson('wifi');
    expect(scannedPaths(), ['pulse.lottie', 'wifi.json']);
  });

  test('a .lottie keeps its dark variant', () {
    addLottie('pulse');
    addLottie('pulse_dark');
    addJson('pulse');
    final asset = service.scan().single.assets.single;
    expect(asset.darkPath, endsWith('pulse_dark.lottie'));
  });

  test('emits one AppAssetType.lottie member for a .lottie', () {
    addJson('pulse');
    addLottie('pulse');
    final source = service.generateEnumFile(service.scan().single);
    expect(
      source,
      contains("pulse('pulse.lottie', type: AppAssetType.lottie)"),
    );
    expect(source, isNot(contains('pulse.json')));
  });

  test('a group without dark variants omits _darkFilename', () {
    addJson('wifi');
    final source = service.generateEnumFile(service.scan().single);
    expect(source, contains('enum AppAnimations('));
    expect(source, isNot(contains('_darkFilename')));
    expect(source, contains('String? get darkPath => null;'));
  });

  test('a group with a dark variant keeps _darkFilename', () {
    addLottie('pulse');
    addLottie('pulse_dark');
    final source = service.generateEnumFile(service.scan().single);
    expect(source, contains('final String? _darkFilename,\n}) implements'));
    expect(source, contains("darkFilename: 'pulse_dark.lottie'"));
  });

  test('emits declaring primary-constructor enums, no separate fields', () {
    addJson('wifi');
    final source = service.generateEnumFile(service.scan().single);
    expect(
      source,
      contains(
        'enum AppAnimations(\n'
        '  /// The asset filename.\n'
        '  final String filename, {\n'
        '\n'
        '  /// The type of this asset.\n'
        '  required final AppAssetType type,\n'
        '}) implements AppAnimationAsset {',
      ),
    );
    expect(source, isNot(contains('this.filename')));
    expect(source, isNot(contains('final String filename;')));
  });
}
