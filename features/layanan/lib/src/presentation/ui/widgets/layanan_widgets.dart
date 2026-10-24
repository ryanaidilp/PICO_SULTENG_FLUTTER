import 'package:flutter/material.dart';
import 'package:layanan/src/domain/hospital_math.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// A page title with a back button when the page can pop.
class PageHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.title, super.key});

  /// Title text.
  final String title;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
      children: [
        if (canPop)
          Tooltip(
            message: context.t.back,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.typography.heading.h3.copyWith(
                color: context.colors.foreground.main,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One entry of the hub: brand icon, title and a one-line description.
class ServiceTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.iconKey,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  /// Registry key of the brand icon.
  final String iconKey;

  /// Title.
  final String title;

  /// Description.
  final String description;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      button: true,
      label: '$title, $description',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.background.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colors.outline.subtle),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PicoBrandIcon(
                    iconKey,
                    duotone: true,
                    size: 32,
                    color: context.colors.foreground.main,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.typography.heading.h5.copyWith(
                            color: context.colors.foreground.main,
                          ),
                        ),
                        Text(
                          description,
                          style: context.typography.body.small.copyWith(
                            color: context.colors.foreground.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.foreground.subtle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One hospital in the list: name, kabupaten and beds free of all.
class HospitalRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.hospital,
    required this.regencyName,
    required this.onTap,
    super.key,
  });

  /// The hospital.
  final Hospital hospital;

  /// Name of its kabupaten.
  final String regencyName;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final totals = bedTotals(hospital);
    final beds = totals.total == 0
        ? t.noBeds
        : t.bedsSummary(
            available: k.number(totals.available),
            total: k.number(totals.total),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        button: true,
        label: t.rowLabel(
          name: hospital.name,
          regency: regencyName,
          beds: beds,
        ),
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.background.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colors.outline.subtle),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: context.typography.heading.h5.copyWith(
                              color: context.colors.foreground.main,
                            ),
                          ),
                          Text(
                            regencyName,
                            style: context.typography.body.small.copyWith(
                              color: context.colors.foreground.subtle,
                            ),
                          ),
                          Text(
                            beds,
                            style: context.typography.body.small.copyWith(
                              color: context.colors.foreground.main,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: context.colors.foreground.subtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Free beds of each type as woven bars, with the emergency room count. The
/// API sends no date for these rows, so they are labelled "latest".
class BedSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.hospital, super.key});

  /// The hospital.
  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PicoSectionHeader(title: t.lastData),
        const SizedBox(height: 8),
        if (hospital.beds.isEmpty)
          Text(
            t.noBeds,
            style: context.typography.body.regular.copyWith(
              color: context.colors.foreground.subtle,
            ),
          ),
        for (final b in hospital.beds)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PicoWovenBar(
              items: [
                WovenBarItem(
                  label: b.typeName,
                  value: b.available,
                  // Never draw more than the track holds.
                  max: b.total > b.available ? b.total : b.available,
                  state: PicoState.recovered,
                ),
              ],
              valueFormat: (v) =>
                  t.bedsOf(available: k.number(v), total: k.number(b.total)),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          t.igd(count: k.number(hospital.igdCount)),
          style: context.typography.body.regular.copyWith(
            color: context.colors.foreground.main,
          ),
        ),
      ],
    );
  }
}

/// [PicoContactActions] with an optional launcher (tests).
Widget contactActions(List<Contact> contacts, UriLauncher? launcher) =>
    launcher == null
    ? PicoContactActions(contacts: contacts)
    : PicoContactActions(contacts: contacts, launcher: launcher);

/// A bordered surface for one listing.
class ListingCard extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outline.subtle),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    ),
  );
}

/// A calm note that stays visible: archived data, check before you act.
class ArchiveNote extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.chartSurface.tint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: context.typography.body.regular.copyWith(
            color: context.colors.foreground.main,
          ),
        ),
      ),
    ),
  );
}
