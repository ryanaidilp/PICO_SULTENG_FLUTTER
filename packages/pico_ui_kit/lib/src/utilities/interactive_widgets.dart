import 'package:flutter/widgets.dart';
import 'package:pico_ui_kit/src/components/atoms/buttons/pico_button.dart';
import 'package:pico_ui_kit/src/components/atoms/buttons/pico_icon_button.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_checkbox.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_masked_input.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_password_field.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_pin_input.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_text_field.dart';
import 'package:pico_ui_kit/src/components/molecules/otp/pico_otp_input.dart';

/// Whether [element] is a kit control a UI driver (Marionette, debug builds)
/// should report as tappable or typeable.
///
/// The controls wrap Material widgets the driver already finds; matching the
/// kit type as well lets an agent target them by their design-system name.
/// Add a new interactive kit control here.
bool isUiKitInteractive(Element element) => switch (element.widget) {
  PicoButton() ||
  PicoIconButton() ||
  PicoTextField() ||
  PicoPasswordField() ||
  PicoMaskedInput() ||
  PicoPinInput() ||
  PicoOtpInput() ||
  PicoCheckbox() => true,
  _ => false,
};
