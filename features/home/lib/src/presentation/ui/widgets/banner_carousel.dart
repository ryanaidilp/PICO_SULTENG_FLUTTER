
import 'package:flutter/material.dart' hide Banner;
import 'package:home/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Active banners as a manual carousel: swipe or the two buttons, no
/// auto-advance (WCAG 2.2.2), a page label "1 dari 3". A banner with no usable
/// image is a text card with its title. Tap opens the link outside the app.
/// Zero banners: nothing at all.
class BannerCarousel extends StatefulWidget {
  /// Creates the carousel.
  const new({required this.banners, required this.onOpen, super.key});

  /// The active banners.
  final List<Banner> banners;

  /// Opens a banner link.
  final ValueChanged<Uri> onOpen;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    // animateToPage asserts on a zero duration, so reduced motion jumps.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(i);
    } else {
      
        _controller.animateToPage(
          i,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.banners;
    if (items.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    final k = PicoKitText.of(context);
    final total = items.length;
    final label = t.bannerPage(n: k.number(_index + 1), total: k.number(total));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A text card needs room at large text; the image keeps 16:9.
        SizedBox(
          height:
              120 +
              80 *
                  (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(
                    0,
                    1,
                  ),
          child: PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final b = items[i];
              final link = b.link;
              return Semantics(
                button: link != null,
                label: t.bannerLabel(
                  title: b.title,
                  n: k.number(i + 1),
                  total: k.number(total),
                ),
                excludeSemantics: true,
                onTap: link == null ? null : () => widget.onOpen(link),
                child: InkWell(
                  onTap: link == null ? null : () => widget.onOpen(link),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: PicoImage(
                        kind: PicoImageKind.banner,
                        url: b.imageUrl,
                        title: b.title,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (total > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: t.bannerPrev,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: _index == 0 ? null : () => _go(_index - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Semantics(
                liveRegion: true,
                label: label,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: context.typography.body.small.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: t.bannerNext,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: _index == total - 1 ? null : () => _go(_index + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}
