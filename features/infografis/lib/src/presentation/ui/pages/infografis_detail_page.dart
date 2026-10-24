import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/bloc/infografis_bloc.dart';
import 'package:infografis/src/presentation/bloc/infografis_event.dart';
import 'package:infografis/src/presentation/bloc/infografis_state.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shares [text] with the system share sheet.
typedef ShareText = Future<void> Function(String text, String subject);

/// Default [ShareText]: the system share sheet.
Future<void> defaultShare(String text, String subject) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

/// Default launcher: external browser.
Future<bool> defaultOpen(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// `/info/infografis/:id?page=`: the images page by page with zoom, the title,
/// the source link and share.
@RoutePage()
class InfografisDetailPage extends StatefulWidget {
  const new({
    @PathParam('id') required this.id,
    @QueryParam('page') this.page,
    this.launcher = defaultOpen,
    this.share = defaultShare,
    this.syncUrl = true,
    super.key,
  });

  /// Infographic id.
  final int id;

  /// 1 based image number from the URL.
  final int? page;

  /// Opens a link. For tests.
  final UriLauncher launcher;

  /// Shares text. For tests.
  final ShareText share;

  /// Whether a page change rewrites the URL. Off in tests.
  final bool syncUrl;

  @override
  State<InfografisDetailPage> createState() => _InfografisDetailPageState();
}

class _InfografisDetailPageState extends State<InfografisDetailPage> {
  late final PageController _pages;
  final _zoom = TransformationController();
  late int _index = (widget.page ?? 1) - 1;
  Offset _tap = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _index < 0 ? 0 : _index);
    if (_index < 0) _index = 0;
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _onPage(Infographic item, int i) {
    // Zoom resets on every page change.
    _zoom.value = Matrix4.identity();
    setState(() => _index = i);
    if (widget.syncUrl) {
      context.router.replacePath(
        PicoRoutes.infografisDetail(item.id, page: i + 1),
      );
    }
  }

  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
    } else {
      const s = 2.5;
      _zoom.value = Matrix4.identity()
        ..translateByDouble(-_tap.dx * (s - 1), -_tap.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InfografisBloc, InfografisState>(
        builder: (context, s) {
          final bloc = context.read<InfografisBloc>();
          final item = s.byId(widget.id);
          if (item == null) {
            if (s.loading) return const PicoStateView.loading();
            // A deep link to an older item: keep loading pages until found.
            if (s.hasNext && s.failure == null) {
              if (!s.loadingMore) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => bloc.add(const InfografisMoreRequested()),
                );
              }
              return const PicoStateView.loading();
            }
            if (s.items.isEmpty && s.failure != null) {
              void retry() => bloc.add(const InfografisRefreshed());
              return s.failure!.kind == PicoFailureKind.network
                  ? PicoStateView.offline(onRetry: retry)
                  : PicoStateView.error(onRetry: retry);
            }
            return PicoStateView.notFound(message: context.t.notFound);
          }
          return _Viewer(
            item: item,
            index: _index.clamp(
              0,
              item.imageUrls.isEmpty ? 0 : item.imageUrls.length - 1,
            ),
            controller: _pages,
            zoom: _zoom,
            onPage: (i) => _onPage(item, i),
            onTapDown: (p) => _tap = p,
            onDoubleTap: _toggleZoom,
            launcher: widget.launcher,
            share: widget.share,
          );
        },
      );
}

class _Viewer extends StatelessWidget {
  const new({
    required this.item,
    required this.index,
    required this.controller,
    required this.zoom,
    required this.onPage,
    required this.onTapDown,
    required this.onDoubleTap,
    required this.launcher,
    required this.share,
  });

  final Infographic item;
  final int index;
  final PageController controller;
  final TransformationController zoom;
  final ValueChanged<int> onPage;
  final ValueChanged<Offset> onTapDown;
  final VoidCallback onDoubleTap;
  final UriLauncher launcher;
  final ShareText share;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final total = item.imageUrls.length;
    final source = item.source;
    final shareText = [
      item.title,
      if (source != null) source.toString(),
    ].join('\n');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              header: true,
              child: Text(
                item.title,
                style: context.typography.heading.h4.copyWith(
                  color: context.colors.foreground.main,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: total == 0
              ? PicoStateView.empty(message: t.noImages)
              : PageView.builder(
                  controller: controller,
                  itemCount: total,
                  onPageChanged: onPage,
                  itemBuilder: (context, i) => GestureDetector(
                    onDoubleTapDown: (d) => onTapDown(d.localPosition),
                    onDoubleTap: onDoubleTap,
                    child: InteractiveViewer(
                      transformationController: i == index ? zoom : null,
                      maxScale: 5,
                      child: PicoImage(
                        kind: PicoImageKind.infographic,
                        url: item.imageUrls[i],
                        title: item.title,
                        semanticLabel: t.imageAlt(
                          title: item.title,
                          n: k.number(i + 1),
                          total: k.number(total),
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              if (total > 0)
                Text(
                  t.pageOf(n: k.number(index + 1), total: k.number(total)),
                  style: context.typography.body.regular.copyWith(
                    color: context.colors.foreground.main,
                  ),
                ),
              if (source != null)
                TextButton.icon(
                  onPressed: () => launcher(source),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(t.viewSource),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              TextButton.icon(
                onPressed: () => share(shareText, item.title),
                icon: const Icon(Icons.share),
                label: Text(t.share),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
