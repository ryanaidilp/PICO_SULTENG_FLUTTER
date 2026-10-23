import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the sliver scaffold template showcase component for Widgetbook.
WidgetbookComponent sliverScaffoldShowcaseComponent() => WidgetbookComponent(
  name: 'SliverScaffoldTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoSliverScaffoldTemplate',
      builder: _buildPicoSliverScaffoldTemplateUseCase,
    ),
  ],
);

Widget _buildPicoSliverScaffoldTemplateUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Sliver Scaffold',
  );

  final expandedHeight = context.knobs.double.slider(
    label: 'Expanded Height',
    initialValue: 200,
    min: 100,
    max: 350,
  );

  final pinned = context.knobs.boolean(label: 'Pinned', initialValue: true);

  final floating = context.knobs.boolean(label: 'Floating');

  final snap = context.knobs.boolean(label: 'Snap');

  final stretch = context.knobs.boolean(label: 'Stretch');

  final hasFlexibleSpace = context.knobs.boolean(
    label: 'Has Flexible Space',
    initialValue: true,
  );

  final hasFab = context.knobs.boolean(label: 'Has FAB');

  return PicoSliverScaffoldTemplate(
    title: title,
    expandedHeight: expandedHeight,
    pinned: pinned,
    floating: floating,
    snap: snap,
    stretch: stretch,
    flexibleSpace: hasFlexibleSpace
        ? Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
          )
        : null,
    floatingActionButton: hasFab
        ? FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add))
        : null,
    slivers: [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(
            leading: const Icon(Icons.circle_outlined),
            title: Text('List item ${index + 1}'),
            subtitle: Text('Subtitle for item ${index + 1}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          childCount: 20,
        ),
      ),
    ],
  );
}
