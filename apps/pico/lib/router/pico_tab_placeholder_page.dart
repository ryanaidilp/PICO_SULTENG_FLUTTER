import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) =>
      PicoStateView.empty(message: context.l10n.general.comingSoon);
}

/// Stand-ins for tabs whose feature is not installed yet. A feature that
/// registers a route at the tab path replaces its placeholder, with no change
/// here. One class per tab: auto_route matches tab routes by name.
@RoutePage()
class BerandaPlaceholderPage extends StatelessWidget {
  /// Creates the placeholder.
  const BerandaPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon();
}

/// See [BerandaPlaceholderPage].
@RoutePage()
class StatistikPlaceholderPage extends StatelessWidget {
  /// Creates the placeholder.
  const StatistikPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon();
}

/// See [BerandaPlaceholderPage].
@RoutePage()
class LayananPlaceholderPage extends StatelessWidget {
  /// Creates the placeholder.
  const LayananPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon();
}

/// See [BerandaPlaceholderPage].
@RoutePage()
class InfoPlaceholderPage extends StatelessWidget {
  /// Creates the placeholder.
  const InfoPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon();
}
