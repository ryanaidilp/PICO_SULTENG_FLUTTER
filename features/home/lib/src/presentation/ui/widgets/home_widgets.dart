import 'package:flutter/material.dart';
import 'package:home/src/l10n/translations.g.dart';
import 'package:home/src/presentation/bloc/home_state.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// "PICO menyimpan data COVID-19 dari 2 Mar 2020 sampai 14 Jan 2024." The end
/// date is the date of the latest national row.
class ArchiveNote extends StatelessWidget {
  /// Creates the note.
  const ArchiveNote({required this.end, super.key});

  /// Date of the latest national row.
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final k = PicoKitText.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.chartSurface.tint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          context.t.archiveNote(start: k.date(kDataStart), end: k.date(end)),
          style: context.typography.body.regular.copyWith(
            color: context.colors.foreground.main,
          ),
        ),
      ),
    );
  }
}

/// The four tiles of one area: cumulative value and the daily change.
class CaseTiles extends StatelessWidget {
  /// Creates the tiles for [day].
  const CaseTiles({required this.day, super.key});

  /// The latest day of the area.
  final CaseDay day;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;
    return LayoutBuilder(
      builder: (context, box) {
        final w = large ? box.maxWidth : (box.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (state, metric) in const [
              (PicoState.positive, CaseMetric.positive),
              (PicoState.recovered, CaseMetric.recovered),
              (PicoState.deceased, CaseMetric.deceased),
              (PicoState.active, CaseMetric.active),
            ])
              SizedBox(
                width: w,
                child: PicoStatTile(
                  state: state,
                  value: day.cumulative.of(metric),
                  delta: day.daily.of(metric),
                  date: day.date,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The latest computed national Rt with its date, or "not computed". A null
/// Rt is never shown as 0.
class LatestRtLine extends StatelessWidget {
  /// Creates the line.
  const LatestRtLine({required this.rt, required this.onOpen, super.key});

  /// Section state of the Rt source.
  final HomeSection<LatestRt?> rt;

  /// Opens a path.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final k = PicoKitText.of(context);
    final latest = rt.data;
    final text = rt.loading
        ? ''
        : latest == null
        ? context.t.rtNone
        : context.t.latestRt(
            value: k.decimal(latest.rt.value),
            date: k.date(latest.date),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Text(
            text,
            style: context.typography.body.regular.copyWith(
              color: context.colors.foreground.main,
            ),
          ),
        _LinkButton(
          label: context.t.seeRt,
          onTap: () => onOpen(PicoRoutes.rt(area: 'national')),
        ),
      ],
    );
  }
}

/// A text link of at least 48 dp.
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label),
    ),
  );
}

/// "Lihat kabupaten" link under the Sulawesi Tengah tiles.
class RegencyLink extends StatelessWidget {
  /// Creates the link.
  const RegencyLink({required this.onOpen, super.key});

  /// Opens a path.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => _LinkButton(
    label: context.t.seeRegencies,
    onTap: () => onOpen(PicoRoutes.kabupatenList),
  );
}

/// One quick link: icon key, label and C07 path.
typedef QuickLinkSpec = ({String icon, String label, String path});

/// The eight quick links of Beranda, in order.
List<QuickLinkSpec> quickLinks(Translations t) => [
  (icon: 'nav.stats', label: t.linkStats, path: PicoRoutes.statistik()),
  (icon: 'map', label: t.linkMap, path: PicoRoutes.peta()),
  (icon: 'vaccine', label: t.linkVaccine, path: PicoRoutes.vaksin),
  (
    icon: 'facility.hospital',
    label: t.linkHospital,
    path: PicoRoutes.rumahSakit,
  ),
  (icon: 'task-force', label: t.linkTaskforce, path: PicoRoutes.satgas),
  (icon: 'isoman', label: t.linkIsoman, path: PicoRoutes.isoman),
  (icon: 'infographic', label: t.linkInfographic, path: PicoRoutes.infografis),
  (icon: 'prevention.mask', label: t.linkTips, path: PicoRoutes.info),
];

/// Two-column grid of quick links with brand icons. Each is a labelled button
/// of at least 56 dp.
class QuickLinksGrid extends StatelessWidget {
  /// Creates the grid.
  const QuickLinksGrid({required this.onOpen, super.key});

  /// Opens a path.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;
      final w = large ? box.maxWidth : (box.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final l in quickLinks(context.t))
            SizedBox(
              width: w,
              child: Semantics(
                button: true,
                label: l.label,
                child: ExcludeSemantics(
                  child: Material(
                    color: context.colors.background.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: context.colors.outline.subtle),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onOpen(l.path),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              PicoBrandIcon(
                                l.icon,
                                duotone: true,
                                color: context.colors.foreground.main,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l.label,
                                  style: context.typography.body.regular
                                      .copyWith(
                                        color: context.colors.foreground.main,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
