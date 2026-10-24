import 'package:identifiers/identifiers.dart';
import 'package:locale_core/locale_core.dart';

/// The four tabs of the shell (C07, ADR-0110).
enum PicoTab {
  /// Beranda.
  beranda(PicoRoutes.beranda, 'nav.home'),

  /// Statistik.
  statistik(PicoRoutes.statistikRoot, 'nav.stats'),

  /// Layanan.
  layanan(PicoRoutes.layanan, 'nav.services'),

  /// Info.
  info(PicoRoutes.info, 'nav.info');

  const PicoTab(this.path, this.iconKey);

  /// Path of the tab root.
  final String path;

  /// Brand icon registry key.
  final String iconKey;

  /// Localised label, read at build time so a language change applies at once.
  String label(Translations t) => switch (this) {
    PicoTab.beranda => t.general.tabHome,
    PicoTab.statistik => t.general.tabStats,
    PicoTab.layanan => t.general.tabServices,
    PicoTab.info => t.general.tabInfo,
  };
}
