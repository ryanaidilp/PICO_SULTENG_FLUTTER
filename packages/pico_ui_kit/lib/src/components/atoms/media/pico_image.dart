import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:pico_ui_kit/src/components/atoms/brand/pico_brand_icon.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_woven_plate.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// What an image is for. Chooses the designed missing state.
enum PicoImageKind {
  /// Home banner: a text card with the title.
  banner('infographic'),

  /// Infographic page.
  infographic('infographic'),

  /// Bank logo in a donation.
  bankLogo('donation'),

  /// Partner logo.
  partner('info');

  new(this.iconKey);

  /// Registry key of the icon on the plate.
  final String iconKey;
}

/// Hosts that cannot serve images (ADR-0113). When PICO hosts its own images,
/// only this list changes.
const List<String> kDeadImageHosts = ['banuacoders.com'];

/// URL rules of ADR-0113. A URL that fails them goes straight to the missing
/// state with no network call.
abstract final class PicoImageUrl {
  /// True when [url] is an absolute http(s) URL with a host that is not dead.
  static bool isUsable(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return !kDeadImageHosts.any((d) => host == d || host.endsWith('.$d'));
  }
}

/// A [http.Client] that gives up when the connection takes longer than 8 s.
class _TimeoutClient extends http.BaseClient {
  new(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(const Duration(seconds: 8));
}

/// Disk cache limits: 200 objects, 30 days (S12c).
final CacheManager picoImageCache = CacheManager(
  Config(
    'picoImages',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
    fileService: HttpFileService(httpClient: _TimeoutClient(http.Client())),
  ),
);

/// Remote image with designed missing states (ADR-0113). Failed URLs stay in
/// the missing state for the rest of the session. Viewed images are kept on
/// disk, so they stay readable offline.
class PicoImage extends StatefulWidget {
  /// Creates an image. [title] shows on the missing state, [semanticLabel]
  /// describes the real image.
  const new({
    required this.kind,
    this.url,
    this.title,
    this.semanticLabel,
    this.fit = BoxFit.cover,
    super.key,
  });

  /// Image URL. Null, empty, relative or dead-host URLs show the missing state.
  final String? url;

  /// Kind.
  final PicoImageKind kind;

  /// Title for the missing state.
  final String? title;

  /// Screen reader label of the loaded image.
  final String? semanticLabel;

  /// Fit of the loaded image.
  final BoxFit fit;

  /// URLs that failed in this session.
  static final Set<String> failedUrls = {};

  @override
  State<PicoImage> createState() => _PicoImageState();
}

class _PicoImageState extends State<PicoImage> {
  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (!PicoImageUrl.isUsable(url) || PicoImage.failedUrls.contains(url)) {
      final missing = PicoImageMissing(kind: widget.kind, title: widget.title);
      // A missing image keeps its alt text, read once instead of the title.
      return widget.semanticLabel == null
          ? missing
          : Semantics(
              image: true,
              label: widget.semanticLabel,
              child: ExcludeSemantics(child: missing),
            );
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? widget.title,
      child: CachedNetworkImage(
        imageUrl: url!,
        cacheManager: picoImageCache,
        fit: widget.fit,
        fadeInDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        placeholder: (context, _) => PicoImageMissing(
          kind: widget.kind,
          title: widget.title,
          loading: true,
        ),
        errorWidget: (context, _, _) {
          PicoImage.failedUrls.add(url);
          return PicoImageMissing(kind: widget.kind, title: widget.title);
        },
      ),
    );
  }
}

/// The designed missing state: a woven plate with the icon of the kind and the
/// title as text. A banner is a plain text card. It is a calm state, not an
/// error.
class PicoImageMissing extends StatelessWidget {
  /// Creates the state.
  const new({required this.kind, this.title, this.loading = false, super.key});

  /// Kind.
  final PicoImageKind kind;

  /// Title shown as text.
  final String? title;

  /// True while the real image loads: same layout, no title change.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.body.small.copyWith(
      color: context.colors.foreground.main,
    );
    if (kind == PicoImageKind.banner) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.chartSurface.tint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.colors.outline.subtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              PicoBrandIcon(
                kind.iconKey,
                size: 28,
                duotone: true,
                color: context.colors.foreground.main,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? '',
                  style: style,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final plate =
        kind == PicoImageKind.bankLogo || kind == PicoImageKind.partner
        ? 64.0
        : 120.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PicoWovenPlate(
            size: plate,
            knot: false,
            child: PicoBrandIcon(
              kind.iconKey,
              size: plate * .36,
              duotone: true,
              color: context.colors.foreground.main,
            ),
          ),
          if (title != null && title!.isNotEmpty && plate > 64) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              style: style,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
