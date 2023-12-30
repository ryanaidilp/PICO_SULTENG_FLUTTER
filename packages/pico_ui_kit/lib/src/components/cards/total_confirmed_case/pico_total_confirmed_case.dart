import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTotalConfirmedCase extends StatelessWidget {
  const PicoTotalConfirmedCase({
    required this.total,
    required this.newCase,
    super.key,
  });

  final int total;
  final int newCase;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            width: 1.sw,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: context.picoColors.semantic.info.shade200
                      .withOpacity(0.3),
                  blurRadius: 10.r,
                  spreadRadius: 5.r,
                  offset: Offset.fromDirection(-30, 5),
                ),
              ],
              borderRadius: BorderRadius.circular(8.r),
              gradient: LinearGradient(
                colors: [
                  context.picoColors.semantic.info,
                  context.picoColors.semantic.info.shade100.withOpacity(0.5),
                ],
              ),
            ),
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.keep(
                  child: Text(
                    context.i10n.card_case_label.confirmed,
                    style: PicoTextStyle.labelSm(
                      color: Colors.white,
                    ),
                  ),
                ),
                16.verticalSpace,
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      NumberHelper.numberFormat(total),
                      style: PicoTextStyle.headingXl(
                        color: Colors.white,
                      ),
                    ),
                    8.horizontalSpace,
                    Text(
                      StringHelper.formatNewCase(newCase),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
              ],
            ),
          ),
          Positioned(
            width: 0.15.sw,
            right: 0,
            bottom: 0,
            top: 0,
            child: Skeleton.keep(
              child: PicoAsset.images(
                image: PicoImages.covid,
                width: 0.15.sw,
              ),
            ),
          ),
        ],
      );
}
