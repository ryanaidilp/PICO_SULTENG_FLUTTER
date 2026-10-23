import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the app bar showcase component for Widgetbook.
WidgetbookComponent appBarShowcaseComponent() => WidgetbookComponent(
  name: 'AppBar',
  useCases: [
    WidgetbookUseCase(name: 'PicoAppBar', builder: _buildPicoAppBarUseCase),
    WidgetbookUseCase(
      name: 'PicoSliverAppBar',
      builder: _buildPicoSliverAppBarUseCase,
    ),
  ],
);

Widget _buildPicoAppBarUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Page Title',
  );

  final size = context.knobs.object.dropdown<PicoAppBarSize>(
    label: 'Size',
    options: PicoAppBarSize.values,
    initialOption: PicoAppBarSize.md,
    labelBuilder: (s) => s.name,
  );

  final style = context.knobs.object.dropdown<PicoAppBarStyle>(
    label: 'Style',
    options: PicoAppBarStyle.values,
    initialOption: PicoAppBarStyle.solid,
    labelBuilder: (s) => s.name,
  );

  final centerTitle = context.knobs.boolean(label: 'Center Title');
  final showBackButton = context.knobs.boolean(label: 'Back Button');
  final showActions = context.knobs.boolean(label: 'Show Actions');

  return Column(
    children: [
      PicoAppBar(
        title: title,
        size: size,
        style: style,
        centerTitle: centerTitle,
        showBackButton: showBackButton,
        onBackPressed: () {},
        actions: showActions
            ? [
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ]
            : null,
      ),
      const Expanded(child: Center(child: Text('Page content goes here'))),
    ],
  );
}

Widget _buildPicoSliverAppBarUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Sliver Title',
  );

  final expandedHeight = context.knobs.double.slider(
    label: 'Expanded Height',
    initialValue: 200,
    min: 100,
    max: 350,
  );

  final pinned = context.knobs.boolean(label: 'Pinned', initialValue: true);

  final floating = context.knobs.boolean(label: 'Floating');

  final showBackButton = context.knobs.boolean(label: 'Back Button');

  final showBackground = context.knobs.boolean(
    label: 'Show Background',
    initialValue: true,
  );

  final showActions = context.knobs.boolean(label: 'Show Actions');

  return CustomScrollView(
    slivers: [
      PicoSliverAppBar(
        title: title,
        expandedHeight: expandedHeight,
        pinned: pinned,
        floating: floating,
        showBackButton: showBackButton,
        background: showBackground
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
        actions: showActions
            ? [IconButton(icon: const Icon(Icons.search), onPressed: () {})]
            : null,
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(
            leading: const Icon(Icons.circle_outlined),
            title: Text('List item ${index + 1}'),
          ),
          childCount: 20,
        ),
      ),
    ],
  );
}
