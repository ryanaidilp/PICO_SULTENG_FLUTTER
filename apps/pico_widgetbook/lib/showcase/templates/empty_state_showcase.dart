import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the empty state template showcase component for Widgetbook.
WidgetbookComponent emptyStateShowcaseComponent() => WidgetbookComponent(
  name: 'EmptyStateTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoEmptyStateTemplate',
      builder: _buildPicoEmptyStateTemplateUseCase,
    ),
  ],
);

Widget _buildPicoEmptyStateTemplateUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'No Items Found',
  );

  final message = context.knobs.string(
    label: 'Message',
    initialValue:
        'There are no items to display yet. Start by adding something.',
  );

  final hasIcon = context.knobs.boolean(label: 'Has Icon', initialValue: true);

  final hasAction = context.knobs.boolean(
    label: 'Has Action',
    initialValue: true,
  );

  final actionLabel = context.knobs.string(
    label: 'Action Label',
    initialValue: 'Add Item',
  );

  return PicoEmptyStateTemplate(
    title: title.isEmpty ? null : title,
    message: message.isEmpty ? null : message,
    icon: hasIcon ? const Icon(Icons.inbox_outlined) : null,
    action: hasAction
        ? PicoButton(
            label: actionLabel,
            leadingIcon: Icons.add,
            onPressed: () {},
          )
        : null,
  );
}
