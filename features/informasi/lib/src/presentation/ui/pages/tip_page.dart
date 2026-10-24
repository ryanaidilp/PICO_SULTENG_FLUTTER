import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/bloc/informasi_bloc.dart';
import 'package:informasi/src/presentation/bloc/informasi_state.dart';
import 'package:informasi/src/presentation/ui/widgets/informasi_widgets.dart';
import 'package:informasi/src/presentation/ui/widgets/markdown_view.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Default launcher: external browser.
Future<bool> defaultOpenExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// `/info/tips/:slug`: illustration on a woven plate, title, body, sources and
/// the review note while `reviewed` is false.
@RoutePage()
class TipPage extends StatelessWidget {
  const new({
    @PathParam('slug') required this.slug,
    this.launcher = defaultOpenExternal,
    this.onOpenPath,
    super.key,
  });

  final String slug;

  /// Opens an external link. For tests.
  final UriLauncher launcher;

  /// Opens an in-app path (link starting with `/`). Defaults to the router.
  final ValueChanged<String>? onOpenPath;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<InformasiBloc, InformasiState>(
      builder: (context, s) {
        if (s.tips == null) return const PicoStateView.loading();
        final tip = s.tip(locale, slug);
        if (tip == null) {
          return PicoStateView.notFound(message: t.tipNotFound);
        }
        void onLink(String target) {
          if (target.startsWith('/')) {
            (onOpenPath ?? (p) => context.router.navigatePath(p))(target);
          } else {
            final u = Uri.tryParse(target);
            if (u != null) launcher(u);
          }
        }

        final small = context.typography.body.small;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PageHeader(title: tip.title, backLabel: t.back),
            const SizedBox(height: 16),
            Center(child: TipArt(tip: tip)),
            const SizedBox(height: 16),
            if (!tip.reviewed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  t.notReviewed,
                  style: small.copyWith(
                    color: context.colors.foreground.subtle,
                  ),
                ),
              ),
            MarkdownView(source: tip.body, onLink: onLink),
            if (tip.sources.isNotEmpty) ...[
              PicoSectionHeader(title: t.sources),
              for (final u in tip.sources)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => launcher(u),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(u.host + u.path, textAlign: TextAlign.start),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
