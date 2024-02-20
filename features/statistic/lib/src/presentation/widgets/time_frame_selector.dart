import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/enums.dart';

class TimeFrameSelector extends StatelessWidget {
  const TimeFrameSelector({
    required this.value,
    required this.onSelected,
    super.key,
  });

  final DataTimeFrame value;
  final void Function(DataTimeFrame value) onSelected;

  @override
  Widget build(BuildContext context) => StaggeredGrid.count(
        crossAxisCount: 4,
        crossAxisSpacing: PCSpacing.s4,
        children: List.generate(
          DataTimeFrame.values.length,
          (index) {
            final timeFrame = DataTimeFrame.values[index];
            final isSelected = value == timeFrame;
            return IntrinsicWidth(
              child: FilterChip(
                label: Text(
                  timeFrame.label(context),
                ),
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    PCRadius.xs,
                  ),
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : context.picoColors.outline.neutral.main,
                ),
                backgroundColor: context.picoColors.background.card.main,
                selectedColor: context.picoColors.semantic.primary,
                labelStyle: PicoTextStyle.bodySm(
                  color: isSelected
                      ? context.picoColors.text.neutral.onImageStrong
                      : context.picoColors.text.neutral.main,
                ),
                selected: isSelected,
                onSelected: (isSelected) {
                  if (isSelected) {
                    onSelected(timeFrame);
                  }
                },
              ),
            );
          },
        ),
      );
}
