import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// The PICO logo (the original question-mark cube) with the app name "PICO
/// SulTeng". It is the app bar title of the tab roots. The logo is the same in
/// light and dark: its blues have enough contrast on both grounds.
class PicoWordmark extends StatelessWidget {
  /// Creates the logo and name at [height]. [semanticLabel] names it for
  /// screen readers.
  const PicoWordmark({
    this.height = 32,
    this.semanticLabel = 'PICO SulTeng',
    super.key,
  });

  /// Logo height in logical pixels.
  final double height;

  /// Screen reader label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    header: true,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logo/pico-logo.svg',
            package: 'pico_ui_kit',
            height: height,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'PICO SulTeng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.heading.h4.copyWith(
                color: context.colors.foreground.main,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
