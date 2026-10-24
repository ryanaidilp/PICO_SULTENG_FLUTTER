import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/widgets/layanan_widgets.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/layanan`: the hub of the help services.
@RoutePage()
class LayananPage extends StatelessWidget {
  /// Creates the page. [onOpen] is for tests; it defaults to the router.
  const new({this.onOpen, super.key});

  /// Opens a path.
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    void open(String path) =>
        (onOpen ?? (p) => context.router.navigatePath(p))(path);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(title: t.title),
        const SizedBox(height: 8),
        Text(
          t.archiveNote,
          style: context.typography.body.regular.copyWith(
            color: context.colors.foreground.subtle,
          ),
        ),
        const SizedBox(height: 16),
        ServiceTile(
          iconKey: 'state.recovered',
          title: t.hubVaccine,
          description: t.hubVaccineDesc,
          onTap: () => open(PicoRoutes.vaksin),
        ),
        ServiceTile(
          iconKey: 'facility.hospital',
          title: t.hubHospital,
          description: t.hubHospitalDesc,
          onTap: () => open(PicoRoutes.rumahSakit),
        ),
        ServiceTile(
          iconKey: 'level.kabupaten',
          title: t.hubTaskforce,
          description: t.hubTaskforceDesc,
          onTap: () => open(PicoRoutes.satgas),
        ),
        ServiceTile(
          iconKey: 'facility.bed',
          title: t.hubIsoman,
          description: t.hubIsomanDesc,
          onTap: () => open(PicoRoutes.isoman),
        ),
      ],
    );
  }
}
