import 'package:dependencies/auto_route.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico/router/pico_shell_page.dart';
import 'package:pico/router/pico_tab.dart';
import 'package:pico/router/pico_tab_placeholder_page.dart';
import 'package:router_registry/router_registry.dart';

part 'app_router.gr.dart';

String _norm(String? p) => '/${(p ?? '').replaceAll(RegExp(r'^/+|/+$'), '')}';

/// Main app router: the 4-tab shell plus every route that features register
/// through the [RouteRegistry] during pre-launch (ADR-0110, contract C07).
///
/// A feature that registers a route at a tab path (`/beranda`, `/statistik`,
/// `/layanan`, `/info`) becomes that tab's root. A tab with no feature yet
/// shows a placeholder. Every other registered route is a sibling of the shell
/// and opens above the tab bar. An unknown path redirects to `/beranda`.
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter(final RouteRegistry _registry) extends RootStackRouter {
  /// A plain cross-fade: the default Material transition drew a light
  /// layer for a few frames in dark mode. Every route uses this one.
  @override
  RouteType get defaultRouteType => RouteType.custom(
    transitionsBuilder: TransitionsBuilders.fadeIn,
    durationInMilliseconds: 200,
    reverseDurationInMilliseconds: 160,
  );

  /// Registered routes that are tab roots.
  late final List<AutoRoute> _featureTabRoots = [
    for (final tab in PicoTab.values)
      ?_registry.routes.where((r) => _norm(r.path) == tab.path).firstOrNull,
  ];

  /// Shell children: the feature's tab root with a relative path (auto_route
  /// children cannot start with `/`), or the placeholder.
  late final List<AutoRoute> _tabRoutes = [
    for (final tab in PicoTab.values)
      _registry.routes
              .where((r) => _norm(r.path) == tab.path)
              .firstOrNull
              ?.changePath(tab.path.substring(1)) ??
          _placeholder(tab),
  ];

  AutoRoute _placeholder(PicoTab tab) {
    final page = switch (tab) {
      PicoTab.beranda => BerandaPlaceholderRoute.page,
      PicoTab.statistik => StatistikPlaceholderRoute.page,
      PicoTab.layanan => LayananPlaceholderRoute.page,
      PicoTab.info => InfoPlaceholderRoute.page,
    };
    return AutoRoute(page: page, path: tab.path.substring(1));
  }

  /// Route names of the four tabs, in tab order.
  List<String> get tabRouteNames => [for (final r in _tabRoutes) r.name];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: PicoShellRoute.page, path: '/', children: [..._tabRoutes]),
    ..._registry.routes.where((r) => !_featureTabRoots.contains(r)),
    RedirectRoute(path: '*', redirectTo: PicoRoutes.beranda),
  ];

  /// Returns the initial path: Beranda (the generated resolver falls back to
  /// `/` when no feature claims it).
  String get initialPath => PicoRoutes.beranda;
}
