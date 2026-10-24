import 'dart:io';

import 'package:asset_core/asset_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../../util/app_component_test_wrapper.dart';

const _path = 'assets/animations/pulse.lottie';

class const _Pulse() implements PicoAnimationAsset {
  @override
  PicoAssetData get data =>
      const PicoAssetData.lottie(path: _path, packageName: 'pico_asset');

  @override
  String get defaultSemanticLabel => 'Pulse';

  @override
  bool get shouldRepeat => false;

  @override
  bool get shouldAutoPlay => true;
}

/// Serves the fixture zip under the key `Lottie.asset` asks for.
class _FixtureBundle(final Uint8List bytes) extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'packages/pico_asset/$_path') {
      throw FlutterError('No $key');
    }
    return ByteData.sublistView(bytes);
  }
}

void main() {
  // A real dotLottie: manifest.json + animations/pulse.json, deflated.
  final bytes = File('test/fixtures/pulse.lottie').readAsBytesSync();

  test('.lottie paths resolve to PicoAssetType.lottie', () {
    expect(PicoAssetTypeExtension.fromPath(_path), PicoAssetType.lottie);
    expect(PicoAssetType.lottie.extensions, contains('.lottie'));
  });

  testWidgets('PicoAssetWidget renders a .lottie zip', (tester) async {
    Object? error;
    await tester.pumpWidget(
      AppComponentTestWrapper(
        child: DefaultAssetBundle(
          bundle: _FixtureBundle(bytes),
          child: PicoAssetWidget(
            const _Pulse(),
            size: 100,
            errorBuilder: (context, e, _) {
              error = e;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(error, isNull);
    final lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.composition?.layers, isNotEmpty);
  });
}
