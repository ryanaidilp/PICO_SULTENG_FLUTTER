import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico/router/pico_tab.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Bottom tab bar styled as a selvedge band: indigo ground with a sky warp
/// block behind the active icon. Icons with one-line labels below. Labels
/// never use an ellipsis: at large text they shrink to fit (never clip).
class PicoTabBar extends StatelessWidget {
  /// Creates the bar.
  const PicoTabBar({required this.index, required this.onTap, super.key});

  /// Active tab index.
  final int index;

  /// Called with the tapped index (also for the active tab: pop to root).
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final band = dark
        ? context.colors.background.subtle
        : context.colors.background.inverse;
    final on = dark
        ? context.colors.foreground.main
        : context.colors.foreground.inverse;
    final activeBlock = dark
        ? PicoBrandPalette.tintDark
        : PicoBrandPalette.skyLight;
    final activeInk = dark
        ? PicoBrandPalette.indigoDark
        : PicoBrandPalette.indigoLight;
    final t = context.l10n;
    return Material(
      color: band,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final (i, tab) in PicoTab.values.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: tab.label(t),
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 64),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: i == index
                                      ? activeBlock
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: PicoBrandIcon(
                                  tab.iconKey,
                                  color: i == index && !dark ? activeInk : on,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tab.label(t),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: context.typography.label.caption
                                      .copyWith(
                                        color: on,
                                        fontWeight: i == index
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
