import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class const PicoApp({required final AppRouter router, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Pico',
    theme: PicoTheme.light(),
    darkTheme: PicoTheme.dark(),
    routerConfig: router.config(
      deepLinkBuilder: (_) => DeepLink.path(router.initialPath),
      // Brick-owned: observer bricks' post_gen fill this region. auto_route
      // calls the builder once per navigator, so return new instances.
      navigatorObservers: () => [
        // archipelago:navigator_observers:start
        // archipelago:navigator_observers:end
      ],
    ),
    // Brick-owned: app_debugger's post_gen fills this region.
    // archipelago:app_builder:start
    // archipelago:app_builder:end
  );
}
