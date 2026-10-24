import 'package:flutter/material.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the icon showcase component for Widgetbook.
WidgetbookComponent iconShowcaseComponent() => WidgetbookComponent(
  name: 'Icons',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoIcon — Flutter IconData',
      builder: _buildFlutterIconUseCase,
    ),
    WidgetbookUseCase(
      name: 'PicoIcon — Design System Asset',
      builder: _buildAssetIconUseCase,
    ),
  ],
);

Widget _buildFlutterIconUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 24,
    min: 12,
    max: 64,
    divisions: 13,
  );

  final useColor = context.knobs.boolean(label: 'Custom Color');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoIcon.data(
        Icons.star,
        size: size,
        color: useColor ? context.colors.action.primary.active : null,
      ),
    ),
  );
}

Widget _buildAssetIconUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 24,
    min: 12,
    max: 64,
    divisions: 13,
  );

  final useColor = context.knobs.boolean(label: 'Custom Color');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoIcon.asset(
        PicoActionsIcons.search,
        size: size,
        color: useColor ? context.colors.action.primary.active : null,
      ),
    ),
  );
}
