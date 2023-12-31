import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoUpdatedAtPlaceholder extends StatelessWidget {
  const PicoUpdatedAtPlaceholder({
    required this.date,
    super.key,
  });

  final String date;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Skeleton.keep(
            child: Text(
              context.i10n.updated_at,
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
      );
}
