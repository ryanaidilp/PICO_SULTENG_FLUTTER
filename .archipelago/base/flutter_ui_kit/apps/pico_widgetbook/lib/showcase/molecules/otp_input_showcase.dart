import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the OTP input showcase component for Widgetbook.
WidgetbookComponent otpInputShowcaseComponent() => WidgetbookComponent(
  name: 'OtpInput',
  useCases: [
    WidgetbookUseCase(name: 'PicoOtpInput', builder: _buildPicoOtpInputUseCase),
  ],
);

Widget _buildPicoOtpInputUseCase(BuildContext context) {
  final cellStyle = context.knobs.object.dropdown<PicoOtpCellStyle>(
    label: 'Cell Style',
    options: PicoOtpCellStyle.values,
    initialOption: PicoOtpCellStyle.boxed,
    labelBuilder: (style) => style.name,
  );

  final length = context.knobs.double
      .slider(label: 'Length', initialValue: 6, min: 4, max: 8)
      .round();

  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Verification Code',
  );

  final subtitle = context.knobs.string(
    label: 'Subtitle',
    initialValue: 'Enter the code we sent to your phone',
  );

  final errorText = context.knobs.string(label: 'Error Text');

  final obscure = context.knobs.boolean(label: 'Obscure');

  final isEnabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  final cellSize = context.knobs.double.slider(
    label: 'Cell Size',
    initialValue: 48,
    min: 36,
    max: 64,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: PicoOtpInput(
        length: length,
        cellStyle: cellStyle,
        title: title.isEmpty ? null : title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        errorText: errorText.isEmpty ? null : errorText,
        obscure: obscure,
        enabled: isEnabled,
        autofocus: false,
        cellSize: cellSize,
        onCompleted: (_) {},
        onResend: () {},
      ),
    ),
  );
}
