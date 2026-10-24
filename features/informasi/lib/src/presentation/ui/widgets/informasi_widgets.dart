import 'package:flutter/material.dart';
import 'package:informasi/src/domain/tip.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// A title with a back button when the page can pop.
class PageHeader extends StatelessWidget {
  const new({required this.title, this.backLabel, super.key});

  final String title;
  final String? backLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (Navigator.canPop(context))
        Tooltip(
          message: backLabel ?? '',
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: context.typography.heading.h3.copyWith(
              color: context.colors.foreground.main,
            ),
          ),
        ),
      ),
    ],
  );
}

/// One row of the hub: icon, title, one line. One semantics node.
class HubTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.description,
    super.key,
  });

  final Widget icon;
  final String title;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      button: true,
      label: description == null ? title : '$title, $description',
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 32, height: 32, child: Center(child: icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.typography.heading.h5.copyWith(
                            color: context.colors.foreground.main,
                          ),
                        ),
                        if (description != null)
                          Text(
                            description!,
                            style: context.typography.body.small.copyWith(
                              color: context.colors.foreground.subtle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.foreground.subtle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The illustration of an article on a woven plate, or its brand icon.
class TipArt extends StatelessWidget {
  const new({required this.tip, this.size = 160, super.key});

  final Tip tip;
  final double size;

  @override
  Widget build(BuildContext context) => PicoWovenPlate(
    size: size,
    knot: false,
    child: tip.illustration != null
        ? PicoIllustration(
            tip.illustration!,
            width: size * .62,
            height: size * .62,
          )
        : PicoBrandIcon(
            tip.icon ?? 'info',
            size: size * .36,
            duotone: true,
            color: context.colors.foreground.main,
          ),
  );
}
