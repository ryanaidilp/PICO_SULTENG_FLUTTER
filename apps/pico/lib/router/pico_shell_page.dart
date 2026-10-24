import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico/router/pico_tab_bar.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Widest content on large screens, centred.
const double kMaxContentWidth = 640;

/// The 4-tab shell: wordmark app bar with a settings button, the tab content
/// (each tab keeps its own state) and the selvedge tab bar. Re-tapping the
/// active tab pops that tab to its root.
@RoutePage()
class PicoShellPage extends StatelessWidget {
  /// Creates the shell.
  const PicoShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AutoTabsRouter(
      routes: [
        for (final name in (context.router.root as AppRouter).tabRouteNames)
          PageRouteInfo(name),
      ],
      builder: (context, child) {
        final tabs = AutoTabsRouter.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const PicoWordmark(),
            actions: [
              IconButton(
                tooltip: t.general.settings,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => context.router.pushPath(PicoRoutes.pengaturan),
                icon: PicoBrandIcon(
                  'settings',
                  color: context.colors.foreground.main,
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: child,
            ),
          ),
          bottomNavigationBar: PicoTabBar(
            index: tabs.activeIndex,
            onTap: (i) {
              if (i == tabs.activeIndex) {
                tabs.stackRouterOfIndex(i)?.popUntilRoot();
              } else {
                tabs.setActiveIndex(i);
              }
            },
          ),
        );
      },
    );
  }
}
