import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/bloc/watch_cubit.dart';
import 'package:informasi/src/presentation/ui/widgets/informasi_widgets.dart';
import 'package:informasi/src/presentation/ui/widgets/tentang_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cubit of the partners.
typedef PartnersCubit = WatchCubit<List<Partner>>;

/// Ids of the sections, also the anchors of `/info/tentang#<id>`.
const kTentangAnchors = [
  'tentang',
  'sumber',
  'metodologi',
  'mitra',
  'lisensi',
  'kredit',
];

/// Default external opener.
Future<bool> defaultOpenLink(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// `/info/tentang`: about PICO, where the data comes from, how it is
/// processed, what is missing, partners, licences and the cultural note.
/// `#metodologi` (or any anchor above) scrolls to its section.
@RoutePage()
class TentangPage extends StatefulWidget {
  const TentangPage({
    this.anchor,
    this.launcher = defaultOpenLink,
    this.onShowLicenses,
    super.key,
  });

  /// The anchor to scroll to. Defaults to the fragment of the route.
  final String? anchor;

  /// Opens a link. For tests.
  final UriLauncher launcher;

  /// Shows the open source licence page. For tests.
  final VoidCallback? onShowLicenses;

  @override
  State<TentangPage> createState() => _TentangPageState();
}

class _TentangPageState extends State<TentangPage> {
  final _keys = {for (final a in kTentangAnchors) a: GlobalKey()};
  var _scrolled = false;

  void _scrollToAnchor() {
    if (_scrolled) return;
    _scrolled = true;
    var anchor = widget.anchor;
    if (anchor == null) {
      try {
        anchor = context.routeData.fragment;
      } on Object {
        anchor = null;
      }
    }
    final ctx = _keys[anchor]?.currentContext;
    if (ctx != null) {
      unawaited(Scrollable.ensureVisible(ctx, duration: Duration.zero));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToAnchor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final main = context.colors.foreground.main;
    final rtEnd = k.date(RtMethod.nationalLastDay);
    final start = k.date(kDataStart);
    final end = k.date(kDataEnd);
    Widget heading(String id, String title) =>
        AnchorHeading(title: title, anchor: _keys[id]!);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: t.aboutTitle, backLabel: t.back),
          heading('tentang', t.sAbout),
          Para(t.aboutName),
          Para(t.aboutArchive(start: start, end: end)),
          Para(t.aboutMaker),
          Para(t.aboutApi(api: ArchiveFacts.apiBase)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => widget.launcher(
                Uri.parse('https://pico-api.banuacoder.com/swagger/index.html'),
              ),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(t.aboutOpenApi),
            ),
          ),
          heading('sumber', t.sSource),
          Para(t.source1),
          Para(t.source2(start: start, end: end)),
          Para(t.source3),
          Para(t.source4),
          heading('metodologi', t.sMethod),
          Semantics(
            header: true,
            child: Text(
              t.mDailyTitle,
              style: context.typography.heading.h5.copyWith(color: main),
            ),
          ),
          const SizedBox(height: 6),
          Para(t.mDaily1),
          Para(t.mDaily2),
          Para(t.mDaily3),
          Semantics(
            header: true,
            child: Text(
              t.mRtTitle,
              style: context.typography.heading.h5.copyWith(color: main),
            ),
          ),
          const SizedBox(height: 6),
          Para(t.mRt1),
          Para(
            t.mRt2(
              mean: k.decimal(RtMethod.serialIntervalMean, digits: 1),
              sd: k.decimal(RtMethod.serialIntervalSd, digits: 1),
            ),
          ),
          Para(t.mRt3(window: k.number(RtMethod.windowDays))),
          Para(t.mRt4(min: k.number(RtMethod.minCasesInWindow))),
          Para(t.mRt5(percent: k.number(RtMethod.credibleIntervalPercent))),
          Para(
            t.mRt6(
              national: rtEnd,
              sulteng: k.date(ArchiveFacts.sultengRtLastDay),
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              t.mGapTitle,
              style: context.typography.heading.h5.copyWith(color: main),
            ),
          ),
          const SizedBox(height: 6),
          Para(t.mGap1(odp: k.date(ArchiveFacts.odpLastDay))),
          Para(t.mGap2),
          Para(t.mGap3(tests: k.date(ArchiveFacts.testsLastDay))),
          Para(t.mGap4(vaccination: k.date(ArchiveFacts.vaccinationLastDay))),
          Para(t.mGap5),
          Para(t.mGap6),
          Para(t.mHealth),
          heading('mitra', t.sPartners),
          const _Partners(),
          heading('lisensi', t.sLicense),
          Para(t.licenseData),
          Para(
            t.licenseCode,
            trailing: const ReviewMarker(id: 'metodologi-kode'),
          ),
          Para(
            t.licenseMap,
            trailing: const ReviewMarker(id: 'metodologi-peta'),
          ),
          Para(t.licenseFonts),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  widget.onShowLicenses ??
                  () => showLicensePage(
                    context: context,
                    applicationName: 'PICO Sulteng',
                  ),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(t.licenseOpen),
            ),
          ),
          heading('kredit', t.sCredit),
          Para(t.creditBrand),
          Para(t.culture1),
          Para(t.culture2),
          Para(t.culture3),
          Para(t.culture4),
          Para(
            t.cultureReview,
            trailing: const ReviewMarker(id: 'metodologi-budaya'),
          ),
        ],
      ),
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PartnersCubit, WatchState<List<Partner>>>(
        builder: (context, s) {
          final t = context.t;
          final launcher = context
              .findAncestorStateOfType<_TentangPageState>()!
              .widget
              .launcher;
          final list = s.data;
          if (s.loading) {
            return const SizedBox(height: 80, child: PicoStateView.loading());
          }
          if (list == null || list.isEmpty) return Para(t.partnersNone);
          // Text only: the partner logos are on the dead image host (ADR-0113).
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in list)
                p.link == null
                    ? Para(p.name)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => launcher(p.link!),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(p.name, textAlign: TextAlign.start),
                        ),
                      ),
            ],
          );
        },
      );
}
