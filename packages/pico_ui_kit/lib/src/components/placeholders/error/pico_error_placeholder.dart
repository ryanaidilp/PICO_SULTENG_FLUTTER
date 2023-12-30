import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_animations.dart';
import 'package:pico_ui_kit/src/components/asset/pico_asset.dart';

class PicoErrorPlaceholder extends StatelessWidget {
  const PicoErrorPlaceholder({
    required this.label,
    required this.onRetry,
    super.key,
    this.child = const Placeholder(),
  });

  final String label;
  final Widget child;
  final GestureTapCallback onRetry;

  @override
  Widget build(BuildContext context) {
    var childData = child;
    if (childData is Placeholder) {
      childData = PicoAsset.animation(
        animation: PicoAnimations.error,
        height: 60.h,
        width: 120.w,
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            childData,
            8.verticalSpace,
            Text(label),
            8.verticalSpace,
            TextButton(
              onPressed: onRetry,
              child: Text(
                context.i10n.buttons.try_again,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
