import 'package:flutter/material.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// One infographic in the grid: first image (or the designed missing state),
/// title and the number of images. One semantics node.
class InfographicCard extends StatelessWidget {
  const new({required this.item, required this.onTap, super.key});

  final Infographic item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final count = item.imageUrls.length == 1
        ? t.imagesCountOne
        : t.imagesCount(count: k.number(item.imageUrls.length));
    return Semantics(
      button: true,
      label: '${item.title}, $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.background.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colors.outline.subtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: PicoImage(
                    kind: PicoImageKind.infographic,
                    url: item.imageUrls.isEmpty ? null : item.imageUrls.first,
                    title: item.title,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.typography.heading.h5.copyWith(
                        color: context.colors.foreground.main,
                      ),
                    ),
                    Text(
                      count,
                      style: context.typography.body.small.copyWith(
                        color: context.colors.foreground.subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
