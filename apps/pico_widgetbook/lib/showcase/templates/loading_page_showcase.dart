import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the loading page template showcase component for Widgetbook.
WidgetbookComponent loadingPageShowcaseComponent() => WidgetbookComponent(
  name: 'LoadingPageTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoLoadingPageTemplate',
      builder: _buildPicoLoadingPageTemplateUseCase,
    ),
  ],
);

Widget _buildPicoLoadingPageTemplateUseCase(BuildContext context) {
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'Loading your data...',
  );

  final hasCustomIndicator = context.knobs.boolean(label: 'Custom Indicator');

  return PicoLoadingPageTemplate(
    message: message.isEmpty ? null : message,
    indicator: hasCustomIndicator ? const _CustomLoadingIndicator() : null,
  );
}

class const _CustomLoadingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        backgroundColor: colors.action.primary.active.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(colors.action.primary.active),
      ),
    );
  }
}
