import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the numeric keyboard showcase component for Widgetbook.
WidgetbookComponent keyboardShowcaseComponent() => WidgetbookComponent(
  name: 'Numeric Keyboard',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoNumericKeyboard',
      builder: _buildPicoNumericKeyboardUseCase,
    ),
  ],
);

Widget _buildPicoNumericKeyboardUseCase(BuildContext context) {
  final configVariant = context.knobs.object.dropdown<_KeyboardConfigVariant>(
    label: 'Config',
    options: _KeyboardConfigVariant.values,
    initialOption: _KeyboardConfigVariant.pin,
    labelBuilder: (v) => v.label,
  );

  final showBiometric = context.knobs.boolean(label: 'Show Biometric');

  final isEnabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  final enableHaptic = context.knobs.boolean(
    label: 'Haptic Feedback',
    initialValue: true,
  );

  final buttonHeight = context.knobs.double.slider(
    label: 'Button Height',
    initialValue: 56,
    min: 40,
    max: 72,
    divisions: 8,
  );

  final horizontalSpacing = context.knobs.double.slider(
    label: 'Horizontal Spacing',
    max: 16,
    divisions: 8,
  );

  final verticalSpacing = context.knobs.double.slider(
    label: 'Vertical Spacing',
    max: 16,
    divisions: 8,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _KeyboardDemo(
        key: ValueKey('$configVariant-$showBiometric-$buttonHeight'),
        configVariant: configVariant,
        showBiometric: showBiometric,
        enabled: isEnabled,
        enableHapticFeedback: enableHaptic,
        buttonHeight: buttonHeight,
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing,
      ),
    ),
  );
}

enum _KeyboardConfigVariant(final String label) {
  pin('PIN'),
  decimal('Decimal'),
  phone('Phone'),
  calculator('Calculator'),
}

class const _KeyboardDemo({
  required final _KeyboardConfigVariant configVariant,
  required final bool showBiometric,
  required final bool enabled,
  required final bool enableHapticFeedback,
  required final double buttonHeight,
  required final double horizontalSpacing,
  required final double verticalSpacing,
  super.key,
}) extends StatefulWidget {
  @override
  State<_KeyboardDemo> createState() => _KeyboardDemoState();
}

class _KeyboardDemoState() extends State<_KeyboardDemo> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  NumericKeyboardConfig _buildConfig() => switch (widget.configVariant) {
    _KeyboardConfigVariant.pin => NumericKeyboardConfig.pin(
      showBiometric: widget.showBiometric,
    ),
    _KeyboardConfigVariant.decimal => NumericKeyboardConfig.decimal(),
    _KeyboardConfigVariant.phone => NumericKeyboardConfig.phone(),
    _KeyboardConfigVariant.calculator => NumericKeyboardConfig.calculator(),
  };

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.background.subtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.outline.main),
          ),
          child: Text(
            _controller.text.isEmpty ? 'Start typing...' : _controller.text,
            style: context.typography.heading.h3.copyWith(
              color: _controller.text.isEmpty
                  ? context.colors.foreground.muted
                  : context.colors.foreground.main,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        PicoNumericKeyboard(
          config: _buildConfig(),
          textController: _controller,
          enabled: widget.enabled,
          enableHapticFeedback: widget.enableHapticFeedback,
          horizontalSpacing: widget.horizontalSpacing,
          verticalSpacing: widget.verticalSpacing,
          buttonStyle: NumericKeyboardButtonStyle(height: widget.buttonHeight),
        ),
      ],
    ),
  );
}
