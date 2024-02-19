// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoSwitch extends StatelessWidget {
  const PicoSwitch({
    required this.value,
    required this.onToggle,
    this.label,
    this.labelPosition = PicoSwitchLabelPosition.leading,
    this.width = 32,
    this.height = 16,
    this.toggleSize = 16,
    this.padding = 2,
    this.showOnOff = false,
    this.labelStyle,
    this.onLabel,
    this.offLabel,
    super.key,
  });

  final bool value;
  final bool showOnOff;
  final double width;
  final double height;
  final double toggleSize;
  final double padding;
  final String? label;
  final String? onLabel;
  final String? offLabel;
  final TextStyle? labelStyle;
  final PicoSwitchLabelPosition labelPosition;
  final void Function(bool value) onToggle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (label != null &&
              labelPosition == PicoSwitchLabelPosition.leading) ...[
            Text(
              label!,
              style: PicoTextStyle.bodySm(
                fontWeight: FontWeight.w600,
                color: context.picoColors.text.neutral.subtle,
              ),
            ),
            PCSpacing.s4.w.horizontalSpace,
          ],
          FlutterSwitch(
            value: value,
            onToggle: onToggle,
            showOnOff: showOnOff,
            activeText: onLabel,
            inactiveText: offLabel,
            activeColor: context.picoColors.semantic.primary,
            height: height.h,
            width: width.w,
            toggleSize: toggleSize.sp,
            padding: padding.r,
            activeToggleColor: context.picoColors.icon.neutral.onImageStrong,
            borderRadius: PCRadius.sm,
            inactiveToggleColor: context.picoColors.icon.neutral.disabled,
            inactiveColor: context.picoColors.background.neutral.strong,
          ),
          if (label != null &&
              labelPosition == PicoSwitchLabelPosition.trailing) ...[
            PCSpacing.s4.w.horizontalSpace,
            Text(
              label!,
              style: labelStyle ??
                  PicoTextStyle.bodySm(
                    fontWeight: FontWeight.w600,
                    color: context.picoColors.text.neutral.subtle,
                  ),
            ),
          ],
        ],
      );
}
