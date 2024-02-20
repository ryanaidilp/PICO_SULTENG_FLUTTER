import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoUpdatedAtPlaceholder extends StatelessWidget {
  const PicoUpdatedAtPlaceholder({
    required this.label,
    required this.date,
    super.key,
  });

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.keep(
            child: Text(
              label,
              style: PicoTextStyle.headingXs(),
            ),
          ),
          4.verticalSpace,
          Row(
            children: [
              Skeleton.keep(
                child: Text(
                  context.translations.general.updatedAt,
                  style: PicoTextStyle.bodySm(
                    color: context.picoColors.text.neutral.subtle,
                  ),
                ),
              ),
              4.horizontalSpace,
              Text(
                date,
                style: PicoTextStyle.bodySm(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      );
}
