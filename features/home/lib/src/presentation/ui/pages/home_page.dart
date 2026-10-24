import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:home/src/l10n/translations.g.dart';
import 'package:home/src/presentation/bloc/home_bloc.dart';
import 'package:home/src/presentation/bloc/home_event.dart';
import 'package:home/src/presentation/bloc/home_state.dart';
import 'package:home/src/presentation/ui/widgets/banner_carousel.dart';
import 'package:home/src/presentation/ui/widgets/home_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Beranda: archive note, Sulawesi Tengah figures, its kabupaten and kota, a
/// small national card, and quick links. The banners sit between the note and
/// the province.
@RoutePage()
class HomePage extends StatelessWidget {
  /// Creates the page. [onOpen] opens a path, replaced in tests.
  const new({this.onOpen, this.onOpenLink, super.key});

  /// Opens a C07 path. Defaults to the auto_route `navigatePath`.
  final ValueChanged<String>? onOpen;

  /// Opens a banner link outside the app. Defaults to the system browser.
  final ValueChanged<Uri>? onOpenLink;

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeBloc, HomeState>(
    builder: (context, state) {
      final bloc = context.read<HomeBloc>();
      void retry() => bloc.add(const HomeRefreshed());
      // Sulawesi Tengah leads: without it the page is a state view. Indonesia
      // and the kabupaten list never block it.
      final lead = state.sulteng;
      if (lead.loading) return const PicoStateView.loading();
      final failure = lead.failure;
      if (failure != null) {
        return failure.kind == PicoFailureKind.network
            ? PicoStateView.offline(onRetry: retry)
            : PicoStateView.error(onRetry: retry);
      }
      final snap = lead.snapshot!;
      final national = state.national.data;
      final regencies = state.regencies.data;
      final open =
          onOpen ?? (path) => unawaited(context.router.navigatePath(path));
      return RefreshIndicator.adaptive(
        onRefresh: () {
          final done = Completer<void>();
          bloc.add(HomeRefreshed(done: done));
          return done.future;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ArchiveNote(end: snap.data.date),
            const SizedBox(height: 16),
            if (state.banners.data?.isNotEmpty ?? false) ...[
              BannerCarousel(
                banners: state.banners.data!,
                onOpen:
                    onOpenLink ??
                    (u) => unawaited(
                      launchUrl(u, mode: LaunchMode.externalApplication),
                    ),
              ),
              const SizedBox(height: 16),
            ],
            PicoSectionHeader(title: context.t.sulteng),
            const SizedBox(height: 12),
            CaseTiles(day: snap.data),
            const SizedBox(height: 8),
            PicoDataStamp(
              dataDate: snap.data.date,
              fetchedAt: snap.fetchedAt,
              isStale: snap.isStale,
              offline: snap.isOffline,
              refreshFailed: snap.refreshFailed,
            ),
            if (regencies != null && regencies.isNotEmpty) ...[
              const SizedBox(height: 16),
              PicoSectionHeader(title: context.t.regencies),
              const SizedBox(height: 12),
              RegencyList(rows: regencies, onOpen: open),
            ],
            RegencyLink(onOpen: open),
            const SizedBox(height: 16),
            if (national != null) ...[
              NationalCompact(day: national),
              LatestRtLine(rt: state.rt, onOpen: open),
              const SizedBox(height: 16),
            ],
            PicoSectionHeader(title: context.t.quickLinks),
            const SizedBox(height: 12),
            QuickLinksGrid(onOpen: open),
          ],
        ),
      );
    },
  );
}
