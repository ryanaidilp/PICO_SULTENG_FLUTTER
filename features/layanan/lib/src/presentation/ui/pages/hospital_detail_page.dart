import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:layanan/src/domain/hospital_math.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/hospitals_bloc.dart';
import 'package:layanan/src/presentation/bloc/hospitals_event.dart';
import 'package:layanan/src/presentation/bloc/hospitals_state.dart';
import 'package:layanan/src/presentation/ui/widgets/layanan_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// `/layanan/rumah-sakit/:code`: address, map link, contacts and beds.
@RoutePage()
class HospitalDetailPage extends StatelessWidget {
  /// Creates the page. [launcher] is for tests.
  const new({@PathParam('code') required this.code, this.launcher, super.key});

  /// Hospital code, for example `7271025`.
  final String code;

  /// Opens a link. Defaults to `url_launcher` in external mode.
  final UriLauncher? launcher;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<HospitalsBloc, HospitalsState>(
        builder: (context, s) {
          final bloc = context.read<HospitalsBloc>();
          final data = s.data;
          if (s.loading) return const PicoStateView.loading();
          if (data == null) {
            void retry() => bloc.add(const HospitalsRefreshed());
            return s.failure?.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry);
          }
          final found = data.hospitals.where((h) => h.code == code);
          if (found.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PageHeader(title: context.t.hospitalTitle),
                ),
                Expanded(
                  child: PicoStateView.notFound(message: context.t.notFound),
                ),
              ],
            );
          }
          final h = found.first;
          return _Detail(
            hospital: h,
            regencyName:
                {
                  for (final r in data.regencies) r.code: r.name,
                }[h.regencyCode] ??
                h.regencyCode,
            launcher: launcher ?? _launch,
          );
        },
      );
}

Future<bool> _launch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class _Detail extends StatelessWidget {
  const new({
    required this.hospital,
    required this.regencyName,
    required this.launcher,
  });

  final Hospital hospital;
  final String regencyName;
  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final map = mapUri(hospital);
    final body = context.typography.body;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(title: hospital.name),
        const SizedBox(height: 4),
        Text(
          regencyName,
          style: body.small.copyWith(color: context.colors.foreground.subtle),
        ),
        const SizedBox(height: 12),
        if (hospital.address.isNotEmpty)
          Text(
            hospital.address,
            style: body.regular.copyWith(color: context.colors.foreground.main),
          ),
        if (map != null) ...[
          const SizedBox(height: 12),
          PicoButton(label: t.openMap, onPressed: () => launcher(map)),
        ],
        const SizedBox(height: 16),
        PicoSectionHeader(title: t.contacts),
        if (hospital.contacts.isEmpty)
          Text(
            t.noContacts,
            style: body.regular.copyWith(
              color: context.colors.foreground.subtle,
            ),
          )
        else
          PicoContactActions(contacts: hospital.contacts, launcher: launcher),
        const SizedBox(height: 16),
        BedSection(hospital: hospital),
      ],
    );
  }
}
