import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoCard extends StatelessWidget {
  const PicoCard({
    required this.child,
    super.key,
    this.borderColor,
    this.padding,
    this.borderWidth = 1,
    this.borderRadius = PCRadius.md,
    this.gradient,
    this.bgColor,
    this.width,
    this.height,
    this.shadow,
  }) : assert(
          (gradient == null && bgColor != null) ||
              (bgColor == null && gradient != null) ||
              (bgColor == null && gradient == null),
          'You must set either gradient or bgColor but not both!',
        );

  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets? padding;
  final Widget child;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final Color? bgColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: 300.milliseconds,
        width: width?.w,
        height: height?.h,
        padding: padding ??
            EdgeInsets.all(
              PCSpacing.s16.r,
            ),
        decoration: BoxDecoration(
          boxShadow: shadow,
          color: bgColor == null && gradient == null
              ? context.picoColors.background.card.main
              : bgColor,
          gradient: bgColor == null && gradient == null ? null : gradient,
          borderRadius: BorderRadius.circular(
            borderRadius.r,
          ),
          border: Border.all(
            width: borderWidth.w,
            color: context.picoColors.outline.neutral.main,
          ),
        ),
        child: child,
      );
}
