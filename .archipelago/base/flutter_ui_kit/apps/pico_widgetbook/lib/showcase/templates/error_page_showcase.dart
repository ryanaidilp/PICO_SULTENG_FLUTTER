import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the error page template showcase component for Widgetbook.
WidgetbookComponent errorPageShowcaseComponent() => WidgetbookComponent(
  name: 'ErrorPageTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoErrorPageTemplate',
      builder: _buildPicoErrorPageTemplateUseCase,
    ),
  ],
);

Widget _buildPicoErrorPageTemplateUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Something Went Wrong',
  );

  final message = context.knobs.string(
    label: 'Message',
    initialValue:
        'An unexpected error occurred. Please try again or contact support.',
  );

  final retryLabel = context.knobs.string(
    label: 'Retry Label',
    initialValue: 'Try Again',
  );

  final hasIcon = context.knobs.boolean(label: 'Has Custom Icon');

  final hasRetry = context.knobs.boolean(
    label: 'Has Retry',
    initialValue: true,
  );

  return PicoErrorPageTemplate(
    title: title.isEmpty ? null : title,
    message: message.isEmpty ? null : message,
    retryLabel: retryLabel,
    icon: hasIcon
        ? const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.orange)
        : null,
    onRetry: hasRetry ? () {} : null,
  );
}
