import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// The icon of a data role, in a soft round badge: a virus for positive, a bed
/// for active, a person at rest for recovered, a grave for deceased and a bar
/// chart for Rt. Each role has its own shape, so the role never depends on
/// colour alone. The icons come from the original PICO app.
class PicoStateIcon extends StatelessWidget {
  /// Creates the badge for [state] with an icon of [size].
  const PicoStateIcon({
    required this.state,
    this.size = 20,
    this.color,
    this.badge = true,
    super.key,
  });

  /// Data role.
  final PicoState state;

  /// Icon size in logical pixels. The badge is 1.8 times larger.
  final double size;

  /// Icon colour. Defaults to the role colour of the theme.
  final Color? color;

  /// Whether to draw the soft round badge behind the icon.
  final bool badge;

  /// Asset path of the icon of [state].
  static String assetOf(PicoState state) => switch (state) {
    PicoState.positive => 'assets/icons/legacy/virus.svg',
    PicoState.active => 'assets/icons/legacy/hospital_bed_outline.svg',
    PicoState.recovered => 'assets/icons/legacy/self_isolation.svg',
    PicoState.deceased => 'assets/icons/legacy/cemetery.svg',
    PicoState.rt => 'assets/icons/legacy/bar_chart.svg',
  };

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.picoStates.of(state);
    final icon = SvgPicture.asset(
      assetOf(state),
      package: 'pico_ui_kit',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tone, BlendMode.srcIn),
    );
    if (!badge) return icon;
    return Container(
      width: size * 1.8,
      height: size * 1.8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.14),
      ),
      child: icon,
    );
  }
}
