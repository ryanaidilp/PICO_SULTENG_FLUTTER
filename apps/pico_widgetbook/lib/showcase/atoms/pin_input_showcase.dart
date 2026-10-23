import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the PIN input showcase component for Widgetbook.
WidgetbookComponent pinInputShowcaseComponent() => WidgetbookComponent(
  name: 'PIN Input',
  useCases: [
    WidgetbookUseCase(name: 'PicoPinInput', builder: _buildPicoPinInputUseCase),
  ],
);

Widget _buildPicoPinInputUseCase(BuildContext context) {
  final length = context.knobs.double.slider(
    label: 'Length',
    initialValue: 6,
    min: 4,
    max: 8,
    divisions: 4,
  );

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final useNativeKeyboard = context.knobs.boolean(
    label: 'Use Native Keyboard',
    initialValue: true,
  );

  final hasError = context.knobs.boolean(label: 'Show Error');

  final dotSize = context.knobs.double.slider(
    label: 'Dot Size',
    initialValue: 16,
    min: 8,
    max: 24,
    divisions: 8,
  );

  final dotSpacing = context.knobs.double.slider(
    label: 'Dot Spacing',
    initialValue: 16,
    min: 8,
    max: 32,
    divisions: 8,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter PIN', style: context.typography.heading.h4),
          const SizedBox(height: 8),
          Text(
            'Tap the dots to enter your PIN',
            style: context.typography.body.small.copyWith(
              color: context.colors.foreground.muted,
            ),
          ),
          const SizedBox(height: 32),
          PicoPinInput(
            key: ValueKey('$length-$dotSize-$dotSpacing'),
            length: length.toInt(),
            enabled: !isDisabled,
            useNativeKeyboard: useNativeKeyboard,
            errorText: hasError ? 'Incorrect PIN. Please try again.' : null,
            dotSize: dotSize,
            dotSpacing: dotSpacing,
            onCompleted: (_) {},
          ),
        ],
      ),
    ),
  );
}
