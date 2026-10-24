import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the page template showcase component for Widgetbook.
WidgetbookComponent pageTemplateShowcaseComponent() => WidgetbookComponent(
  name: 'PageTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoPageTemplate',
      builder: _buildPicoPageTemplateUseCase,
    ),
  ],
);

Widget _buildPicoPageTemplateUseCase(BuildContext context) {
  final scrollable = context.knobs.boolean(
    label: 'Scrollable',
    initialValue: true,
  );

  final hasHeader = context.knobs.boolean(
    label: 'Has Header',
    initialValue: true,
  );

  final hasFooter = context.knobs.boolean(
    label: 'Has Footer',
    initialValue: true,
  );

  final footerPinned = context.knobs.boolean(label: 'Footer Pinned');

  final safeAreaTop = context.knobs.boolean(
    label: 'Safe Area Top',
    initialValue: true,
  );

  final safeAreaBottom = context.knobs.boolean(
    label: 'Safe Area Bottom',
    initialValue: true,
  );

  return PicoPageTemplate(
    scrollable: scrollable,
    footerPinned: footerPinned,
    safeAreaTop: safeAreaTop,
    safeAreaBottom: safeAreaBottom,
    header: hasHeader
        ? const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _PageHeader(),
          )
        : null,
    footer: hasFooter
        ? PicoButton(label: 'Continue', isExpanded: true, onPressed: () {})
        : null,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        8,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContentItem(index: index),
        ),
      ),
    ),
  );
}

class const _PageHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Page Title', style: typography.heading.h3),
        const SizedBox(height: 4),
        Text(
          'This is a subtitle for the page template.',
          style: typography.body.regular.copyWith(
            color: colors.foreground.subtle,
          ),
        ),
      ],
    );
  }
}

class const _ContentItem({required final int index}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return PicoCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.action.primary.active.withValues(
              alpha: 0.1,
            ),
            child: Icon(
              Icons.article_outlined,
              color: colors.action.primary.active,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item ${index + 1}', style: typography.body.regular),
                Text(
                  'Description for item ${index + 1}',
                  style: typography.body.small.copyWith(
                    color: colors.foreground.subtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
