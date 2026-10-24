import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the sheet showcase component for Widgetbook.
WidgetbookComponent sheetShowcaseComponent() => WidgetbookComponent(
  name: 'Sheet',
  useCases: [
    WidgetbookUseCase(name: 'PicoSheet', builder: _buildPicoSheetUseCase),
  ],
);

Widget _buildPicoSheetUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Select an Option',
  );

  final hasTitle = context.knobs.boolean(
    label: 'Has Title',
    initialValue: true,
  );

  final itemCount = context.knobs.double
      .slider(label: 'Item Count', initialValue: 3, min: 1, max: 8)
      .round();

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoButton(
        label: 'Show Sheet',
        onPressed: () {
          PicoSheet.show<void>(
            context: context,
            title: hasTitle ? title : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                itemCount,
                (index) => ListTile(
                  leading: const Icon(Icons.circle_outlined),
                  title: Text('Option ${index + 1}'),
                  subtitle: Text('Description for option ${index + 1}'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
