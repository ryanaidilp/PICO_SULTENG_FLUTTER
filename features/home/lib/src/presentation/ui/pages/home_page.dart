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

/// Beranda: archive note, national and Sulawesi Tengah figures, the data
/// stamp and quick links. The banners sit between the note and Nasional.
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
      final national = state.national;
      if (national.loading) return const PicoStateView.loading();
      final failure = national.failure;
      if (failure != null) {
        return failure.kind == PicoFailureKind.network
            ? PicoStateView.offline(onRetry: retry)
            : PicoStateView.error(onRetry: retry);
      }
      final snap = national.snapshot!;
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
            PicoSectionHeader(title: context.t.national),
            const SizedBox(height: 12),
            CaseTiles(day: snap.data),
            const SizedBox(height: 8),
            LatestRtLine(rt: state.rt, onOpen: open),
            const SizedBox(height: 16),
            PicoSectionHeader(title: context.t.sulteng),
            const SizedBox(height: 12),
            _Sulteng(section: state.sulteng, onOpen: open, onRetry: retry),
            const SizedBox(height: 16),
            PicoDataStamp(
              dataDate: snap.data.date,
              fetchedAt: snap.fetchedAt,
              fromCache: snap.source == DataSource.cache,
              isStale: snap.isStale,
            ),
            const SizedBox(height: 16),
            PicoSectionHeader(title: context.t.quickLinks),
            const SizedBox(height: 12),
            QuickLinksGrid(onOpen: open),
          ],
        ),
      );
    },
  );
}

class _Sulteng extends StatelessWidget {
  const new({
    required this.section,
    required this.onOpen,
    required this.onRetry,
  });

  final HomeSection<CaseDay> section;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final day = section.data;
    if (section.loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (day == null) {
      return SizedBox(
        height: 240,
        child: PicoStateView.error(onRetry: onRetry),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaseTiles(day: day),
        RegencyLink(onOpen: onOpen),
      ],
    );
  }
}
