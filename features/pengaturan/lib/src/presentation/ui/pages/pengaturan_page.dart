import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:locale_core/locale_core.dart' show PicoLocale;
import 'package:pengaturan/src/domain/format_bytes.dart';
import 'package:pengaturan/src/l10n/translations.g.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_bloc.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_event.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_state.dart';
import 'package:pengaturan/src/presentation/ui/widgets/alerts_widgets.dart';
import 'package:pengaturan/src/presentation/ui/widgets/option_tile.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/pengaturan`: language, theme, notifications (only when push exists, S51),
/// saved data and version.
@RoutePage()
class PengaturanPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final t = context.t;
    final bloc = context.read<PengaturanBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.clearTitle),
        content: Text(t.clearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.clear),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(const SavedDataCleared());
  }

  /// ADR-0112 step 3: the explain sheet. Only "Izinkan" starts the flow.
  Future<void> _askAlerts(BuildContext context) async {
    final bloc = context.read<PengaturanBloc>();
    final t = context.t;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      // The sheet lives in the root overlay, outside this feature's
      // translation provider, so the strings travel as a value.
      builder: (_) => AlertsExplainSheet(t: t),
    );
    if (ok ?? false) bloc.add(const AlertsEnableRequested());
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PengaturanBloc, PengaturanState>(
    listenWhen: (a, b) =>
        a.saveFailed != b.saveFailed || a.clearedCount != b.clearedCount,
    listener: (context, s) {
      final t = context.t;
      final failed = s.saveFailed > 0;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              failed && s.clearedCount == 0 ? t.saveFailed : t.cleared,
            ),
          ),
        );
    },
    builder: (context, s) {
      final t = context.t;
      final bloc = context.read<PengaturanBloc>();
      final body = context.typography.body;
      final bytes = s.cachedBytes;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PicoSectionHeader(title: t.language),
          OptionTile(
            label: t.langId,
            selected: s.locale == PicoLocale.id,
            onTap: () => bloc.add(const LanguageChosen(PicoLocale.id)),
          ),
          OptionTile(
            label: t.langEn,
            selected: s.locale == PicoLocale.en,
            onTap: () => bloc.add(const LanguageChosen(PicoLocale.en)),
          ),
          const SizedBox(height: 16),
          PicoSectionHeader(title: t.theme),
          for (final (mode, label) in [
            (PicoThemeMode.system, t.themeSystem),
            (PicoThemeMode.light, t.themeLight),
            (PicoThemeMode.dark, t.themeDark),
          ])
            OptionTile(
              label: label,
              selected: s.themeMode == mode,
              onTap: () => bloc.add(ThemeChosen(mode)),
            ),
          const SizedBox(height: 16),
          if (s.alertsAvailable) ...[
            PicoSectionHeader(title: t.notifications),
            AlertsSwitchTile(
              value: s.alertsOn,
              busy: s.alertsBusy,
              onChanged: (on) => on
                  ? _askAlerts(context)
                  : bloc.add(const AlertsDisableRequested()),
            ),
            if (s.alertsDenied) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${t.alertsDeniedTitle}. ${t.alertsDeniedBody}',
                  style: body.small.copyWith(
                    color: context.colors.foreground.subtle,
                  ),
                ),
              ),
              AlertsActionRow(
                label: t.alertsOpenSystem,
                icon: Icons.settings_outlined,
                onTap: () => bloc.add(const SystemSettingsRequested()),
              ),
            ],
            if (s.alertsOn)
              AlertsActionRow(
                label: t.alertsManage,
                icon: Icons.tune,
                onTap: () => context.router.root.pushPath(
                  PicoRoutes.notificationSettings,
                ),
              ),
            const SizedBox(height: 16),
          ],
          PicoSectionHeader(title: t.savedData),
          if (bytes != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.savedSize(
                  size: formatBytes(
                    bytes,
                    comma: Localizations.localeOf(context).languageCode == 'id',
                  ),
                ),
                style: body.regular.copyWith(
                  color: context.colors.foreground.main,
                ),
              ),
            ),
          PicoButton(label: t.clear, onPressed: () => _confirmClear(context)),
          const SizedBox(height: 16),
          PicoSectionHeader(title: t.about),
          if (s.version != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.version(version: s.version!, build: s.build ?? ''),
                style: body.regular.copyWith(
                  color: context.colors.foreground.main,
                ),
              ),
            ),
          Text(
            t.systemNote,
            style: body.small.copyWith(color: context.colors.foreground.subtle),
          ),
        ],
      );
    },
  );
}
