import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/bloc/informasi_bloc.dart';
import 'package:informasi/src/presentation/bloc/informasi_state.dart';
import 'package:informasi/src/presentation/ui/widgets/informasi_widgets.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/info`: Infografis, the health tips, Tentang and Pengaturan.
@RoutePage()
class InformasiPage extends StatelessWidget {
  const new({this.onOpen, super.key});

  /// Opens a path. Defaults to the router.
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = Localizations.localeOf(context).languageCode;
    void open(String p) => (onOpen ?? (x) => context.router.navigatePath(x))(p);
    final color = context.colors.foreground.main;
    return BlocBuilder<InformasiBloc, InformasiState>(
      builder: (context, s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeader(title: t.title),
          const SizedBox(height: 12),
          HubTile(
            icon: PicoBrandIcon('infographic', duotone: true, color: color),
            title: t.hubInfographic,
            description: t.hubInfographicDesc,
            onTap: () => open(PicoRoutes.infografis),
          ),
          HubTile(
            icon: PicoBrandIcon('info', duotone: true, color: color),
            title: t.hubAbout,
            description: t.hubAboutDesc,
            onTap: () => open(PicoRoutes.tentang),
          ),
          HubTile(
            icon: PicoBrandIcon('settings', duotone: true, color: color),
            title: t.hubSettings,
            description: t.hubSettingsDesc,
            onTap: () => open(PicoRoutes.pengaturan),
          ),
          const SizedBox(height: 12),
          PicoSectionHeader(title: t.tips),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t.tipsNote,
              style: context.typography.body.small.copyWith(
                color: context.colors.foreground.subtle,
              ),
            ),
          ),
          for (final tip in s.list(locale))
            HubTile(
              icon: PicoBrandIcon(
                tip.icon ?? _iconFor(tip.slug),
                duotone: true,
                color: color,
              ),
              title: tip.title,
              onTap: () => open(PicoRoutes.tips(tip.slug)),
            ),
        ],
      ),
    );
  }
}

String _iconFor(String slug) => switch (slug) {
  'cuci-tangan' => 'prevention.handwash',
  'pakai-masker' => 'prevention.mask',
  'jaga-jarak' => 'prevention.distancing',
  'vaksinasi' => 'vaccine',
  'gejala' => 'symptoms',
  'isolasi-mandiri' => 'isoman',
  _ => 'info',
};
