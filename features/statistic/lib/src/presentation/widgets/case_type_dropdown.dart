import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/case_type.dart';

class CaseTypeDropdown extends StatefulWidget {
  const CaseTypeDropdown({
    required this.data,
    required this.onChanged,
    required this.value,
    super.key,
  });

  final CaseType value;
  final List<CaseType> data;
  final void Function(CaseType value) onChanged;

  @override
  State<CaseTypeDropdown> createState() => _CaseTypeDropdownState();
}

class _CaseTypeDropdownState extends State<CaseTypeDropdown> {
  late final ValueNotifier<double> _rotationFactorNotifier;

  @override
  void initState() {
    super.initState();
    _rotationFactorNotifier = ValueNotifier(-0.25);
  }

  @override
  void dispose() {
    _rotationFactorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DropdownButton2<CaseType>(
        underline: const SizedBox.shrink(),
        value: widget.value,
        items: List.generate(
          widget.data.length,
          (index) => DropdownMenuItem(
            value: widget.data[index],
            child: Text(widget.data[index].label(context)),
          ),
        ),
        isDense: true,
        onChanged: (value) => widget.onChanged(value!),
        style: PicoTextStyle.bodySm(
          color: context.picoColors.text.neutral.main,
        ),
        buttonStyleData: ButtonStyleData(
          height: 32.h,
          width: 100.w,
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
        menuItemStyleData: MenuItemStyleData(
          height: 32,
          padding: EdgeInsets.symmetric(
            vertical: PCSpacing.s2.h,
            horizontal: PCSpacing.s8.w,
          ),
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
        dropdownStyleData: DropdownStyleData(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.picoColors.background.card.main,
            border: Border.all(
              color: context.picoColors.outline.neutral.main,
            ),
            borderRadius: BorderRadius.circular(PCRadius.sm),
          ),
          offset: const Offset(0, -PCSpacing.s4),
        ),
        iconStyleData: IconStyleData(
          icon: ValueListenableBuilder(
            valueListenable: _rotationFactorNotifier,
            builder: (_, value, __) {
              return AnimatedRotation(
                duration: 300.milliseconds,
                turns: value,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 16.sp,
                  color: context.picoColors.icon.neutral.subtle,
                ),
              );
            },
          ),
        ),
        onMenuStateChange: (isOpen) {
          if (isOpen) {
            _rotationFactorNotifier.value = 0.25;
          } else {
            _rotationFactorNotifier.value = -0.25;
          }
        },
      );
}
