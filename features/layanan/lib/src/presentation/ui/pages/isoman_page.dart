import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/watch_cubit.dart';
import 'package:layanan/src/presentation/ui/widgets/layanan_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

typedef DonationsCubit = WatchCubit<List<Donation>>;
typedef TelemedicineCubit = WatchCubit<List<Telemedicine>>;

enum IsomanSegment { donation, telemedicine }

Future<bool> _open(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// `/layanan/isoman`: archived donation drives and telemedicine doctors. The
/// safety note comes first, so a screen reader reads it before anything else.
@RoutePage()
class IsomanPage extends StatefulWidget {
  const new({this.launcher, super.key});

  /// Opens a link. For tests.
  final UriLauncher? launcher;

  @override
  State<IsomanPage> createState() => _IsomanPageState();
}

class _IsomanPageState extends State<IsomanPage> {
  var _segment = IsomanSegment.donation;
  var _freeOnly = false;

  UriLauncher get _launch => widget.launcher ?? _open;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // First in the tree: the first thing a screen reader reads.
        ArchiveNote(text: t.isomanNote),
        const SizedBox(height: 12),
        PageHeader(title: t.isomanTitle),
        const SizedBox(height: 8),
        PicoSegmented<IsomanSegment>(
          values: IsomanSegment.values,
          selected: _segment,
          label: (v) => v == IsomanSegment.donation
              ? t.segmentDonation
              : t.segmentTelemedicine,
          onChanged: (v) => setState(() => _segment = v),
        ),
        const SizedBox(height: 8),
        if (_segment == IsomanSegment.donation)
          _Donations(launcher: _launch)
        else ...[
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(t.filterAll),
                selected: !_freeOnly,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _freeOnly = false),
              ),
              ChoiceChip(
                label: Text(t.filterFree),
                selected: _freeOnly,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _freeOnly = true),
              ),
            ],
          ),
          _Telemedicine(freeOnly: _freeOnly, launcher: _launch),
        ],
      ],
    );
  }
}

Widget _failure(Object cubit, PicoFailure? f, VoidCallback retry) => SizedBox(
  height: 320,
  child: f?.kind == PicoFailureKind.network
      ? PicoStateView.offline(onRetry: retry)
      : PicoStateView.error(onRetry: retry),
);

class _Donations extends StatelessWidget {
  const new({required this.launcher});

  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DonationsCubit, WatchState<List<Donation>>>(
        builder: (context, s) {
          final cubit = context.read<DonationsCubit>();
          if (s.loading) {
            return const SizedBox(height: 320, child: PicoStateView.loading());
          }
          final items = s.data;
          if (items == null) {
            return _failure(cubit, s.failure, () => unawaited(cubit.refresh()));
          }
          if (items.isEmpty) {
            return SizedBox(
              height: 240,
              child: PicoStateView.empty(message: context.t.noDonations),
            );
          }
          return Column(
            children: [
              for (final d in items) _DonationCard(d: d, launcher: launcher),
            ],
          );
        },
      );
}

class _DonationCard extends StatelessWidget {
  const new({required this.d, required this.launcher});

  final Donation d;
  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = context.typography;
    final main = context.colors.foreground.main;
    return ListingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A designed missing state when the image is gone, never a broken icon.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: PicoImage(
              kind: PicoImageKind.banner,
              url: d.imageUrl,
              title: d.title,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(d.title, style: text.heading.h5.copyWith(color: main)),
          ),
          Text(
            t.initiator(name: d.initiator),
            style: text.body.small.copyWith(
              color: context.colors.foreground.subtle,
            ),
          ),
          if (d.description != null && d.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                d.description!,
                style: text.body.regular.copyWith(color: main),
              ),
            ),
          if (d.acceptsGoods) ...[
            const SizedBox(height: 8),
            Text(
              t.acceptsGoods,
              style: text.label.caption.copyWith(color: main),
            ),
            if (d.deliveryAddress != null && d.deliveryAddress!.isNotEmpty)
              Text(
                t.deliveryAddress(address: d.deliveryAddress!),
                style: text.body.regular.copyWith(color: main),
              ),
          ],
          for (final a in d.accounts) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: PicoImage(
                    kind: PicoImageKind.bankLogo,
                    url: a.logoUrl,
                    title: a.bankName,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PicoCopyField(
                    label: t.accountLabel(
                      bank: a.bankName,
                      holder: a.accountHolder,
                    ),
                    value: a.accountNumber,
                    // Only the digits go on the clipboard.
                    copyValue: a.accountNumber.replaceAll(RegExp(r'\D'), ''),
                    copiedMessage: t.accountCopied,
                  ),
                ),
              ],
            ),
          ],
          if (d.contacts.isNotEmpty) contactActions(d.contacts, launcher),
          if (d.url != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => launcher(d.url!),
                icon: const Icon(Icons.open_in_new),
                label: Text(t.campaignLink),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Telemedicine extends StatelessWidget {
  const new({required this.freeOnly, required this.launcher});

  final bool freeOnly;
  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TelemedicineCubit, WatchState<List<Telemedicine>>>(
        builder: (context, s) {
          final cubit = context.read<TelemedicineCubit>();
          final t = context.t;
          if (s.loading) {
            return const SizedBox(height: 320, child: PicoStateView.loading());
          }
          final all = s.data;
          if (all == null) {
            return _failure(cubit, s.failure, () => unawaited(cubit.refresh()));
          }
          final items = [
            for (final m in all)
              if (!freeOnly || m.isFree) m,
          ];
          if (items.isEmpty) {
            return SizedBox(
              height: 240,
              child: PicoStateView.empty(
                message: all.isEmpty ? t.noTelemedicine : t.noTelemedicineFree,
              ),
            );
          }
          return Column(
            children: [
              for (final m in items) _DoctorCard(m: m, launcher: launcher),
            ],
          );
        },
      );
}

class _DoctorCard extends StatelessWidget {
  const new({required this.m, required this.launcher});

  final Telemedicine m;
  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = context.typography;
    final main = context.colors.foreground.main;
    return ListingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(m.name, style: text.heading.h5.copyWith(color: main)),
          ),
          // The price is text, never colour only.
          Text(
            m.isFree ? t.free : t.paid,
            style: text.label.caption.copyWith(color: main),
          ),
          const SizedBox(height: 4),
          if (m.schedules.isEmpty)
            Text(
              t.noSchedule,
              style: text.body.regular.copyWith(
                color: context.colors.foreground.subtle,
              ),
            ),
          for (final s in m.schedules)
            Text(
              t.scheduleLine(days: s.days, time: s.time, zone: s.timezone),
              style: text.body.regular.copyWith(color: main),
            ),
          if (m.contacts.isNotEmpty) contactActions(m.contacts, launcher),
        ],
      ),
    );
  }
}
