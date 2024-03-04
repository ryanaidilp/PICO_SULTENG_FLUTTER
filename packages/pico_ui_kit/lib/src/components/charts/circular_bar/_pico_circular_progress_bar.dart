part of 'circular_bar.dart';

class _PicoCircularProgressBar extends StatelessWidget {
  const _PicoCircularProgressBar({
    required this.logo,
    required this.value,
    required this.barHeight,
  });

  final String logo;
  final double value;
  final double barHeight;

  Color? _valueColor(BuildContext context) => switch (value) {
        > 0 => context.picoColors.icon.semantic.error,
        < 0 => context.picoColors.icon.semantic.success,
        _ => null,
      };

  Alignment get _valueAlignment => switch (value) {
        > 0 => Alignment.topCenter,
        < 0 => Alignment.bottomCenter,
        _ => Alignment.center,
      };

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: 300.milliseconds,
        width: _logoSize.w,
        height: barHeight.h,
        child: Stack(
          children: [
            Align(
              child: AnimatedContainer(
                width: 24.w,
                margin: EdgeInsets.only(
                  top: value > 0 ? 2.h : 0,
                  bottom: value < 0 ? 2.h : 0,
                ),
                height: barHeight.h,
                duration: 300.milliseconds,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(100.r),
                    bottom: Radius.circular(100.r),
                  ),
                  color: _valueColor(context),
                ),
              ),
            ),
            Align(
              child: AnimatedContainer(
                duration: 300.milliseconds,
                alignment: _valueAlignment,
                child: Container(
                  width: _logoSize.w,
                  height: _logoSize.h,
                  padding: EdgeInsets.all(2.r),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: PicoNetworkImage(
                    url: logo,
                    fit: BoxFit.contain,
                    border: Border.all(
                      width: 0,
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
