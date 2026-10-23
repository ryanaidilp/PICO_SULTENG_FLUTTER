import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

void main() {
  test('isUiKitInteractive matches kit controls only', () {
    expect(
      isUiKitInteractive(
        PicoButton(label: 'Go', onPressed: () {}).createElement(),
      ),
      isTrue,
    );
    expect(isUiKitInteractive(const PicoTextField().createElement()), isTrue);
    expect(isUiKitInteractive(const Text('Go').createElement()), isFalse);
  });
}
