import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the scaffold template showcase component for Widgetbook.
WidgetbookComponent scaffoldTemplateShowcaseComponent() => WidgetbookComponent(
  name: 'ScaffoldTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoScaffoldTemplate',
      builder: _buildPicoScaffoldTemplateUseCase,
    ),
  ],
);

Widget _buildPicoScaffoldTemplateUseCase(BuildContext context) {
  final hasAppBar = context.knobs.boolean(
    label: 'Has AppBar',
    initialValue: true,
  );

  final hasFab = context.knobs.boolean(label: 'Has FAB');

  final hasBottomNav = context.knobs.boolean(label: 'Has Bottom Nav');

  final extendBody = context.knobs.boolean(label: 'Extend Body');

  final extendBodyBehindAppBar = context.knobs.boolean(
    label: 'Extend Behind AppBar',
  );

  final useSafeArea = context.knobs.boolean(
    label: 'Use Safe Area',
    initialValue: true,
  );

  final appBarTitle = context.knobs.string(
    label: 'AppBar Title',
    initialValue: 'Scaffold Template',
  );

  return PicoScaffoldTemplate(
    extendBody: extendBody,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
    useSafeArea: useSafeArea,
    appBar: hasAppBar
        ? PicoAppBar(
            title: appBarTitle,
            showBackButton: true,
            onBackPressed: () {},
          )
        : null,
    floatingActionButton: hasFab
        ? FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add))
        : null,
    bottomNavigationBar: hasBottomNav
        ? NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onDestinationSelected: (_) {},
          )
        : null,
    body: ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.circle_outlined),
        title: Text('List item ${index + 1}'),
        subtitle: Text('Subtitle for item ${index + 1}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    ),
  );
}
