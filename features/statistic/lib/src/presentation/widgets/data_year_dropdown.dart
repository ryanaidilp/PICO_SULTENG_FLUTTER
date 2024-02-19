import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class DataYearDropdown extends StatelessWidget {
  const DataYearDropdown({
    required this.data,
    required this.onChanged,
    required this.value,
    super.key,
  });

  final int? value;
  final List<int> data;
  final void Function(int? value) onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton2<int?>(
        underline: const SizedBox.shrink(),
        value: value,
        customButton: Icon(
          Icons.calendar_month_rounded,
          color: context.picoColors.icon.neutral.main,
          size: 24.sp,
        ),
        items: List.generate(
          data.length,
          (index) => DropdownMenuItem(
            value: data[index],
            child: Text(data[index].toString()),
          ),
        ).followedBy([
          DropdownMenuItem(
            child: Text(context.translations.chart.line_chart.filter_label.all),
          ),
        ]).toList(),
        isDense: true,
        onChanged: onChanged,
        style: PicoTextStyle.bodySm(
          color: context.picoColors.text.neutral.subtle,
        ),
        buttonStyleData: ButtonStyleData(
          width: 36.w,
          height: 36.h,
          padding: EdgeInsets.symmetric(
            vertical: PCSpacing.s4.h,
            horizontal: PCSpacing.s8.w,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(PCRadius.sm),
            border: Border.all(
              color: context.picoColors.outline.neutral.strong,
            ),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          width: 80.w,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.picoColors.background.card.main,
            border: Border.all(
              color: context.picoColors.outline.neutral.main,
            ),
            borderRadius: BorderRadius.circular(PCRadius.sm),
          ),
          offset: Offset(
            -PCSpacing.s36.w,
            -PCSpacing.s8.h,
          ),
        ),
        iconStyleData: IconStyleData(
          icon: Transform.rotate(
            angle: -pi / 2,
            child: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          padding: EdgeInsets.symmetric(
            horizontal: PCSpacing.s8.w,
            vertical: PCSpacing.s2.h,
          ),
          height: 32,
          selectedMenuItemBuilder: (context, child) => ColoredBox(
            color: context.picoColors.semantic.primary,
            child: AnimatedDefaultTextStyle(
              style: PicoTextStyle.bodySm(
                color: context.picoColors.text.neutral.onImageStrong,
                fontWeight: FontWeight.w600,
              ),
              duration: 300.milliseconds,
              child: child,
            ),
          ),
        ),
      );
}
