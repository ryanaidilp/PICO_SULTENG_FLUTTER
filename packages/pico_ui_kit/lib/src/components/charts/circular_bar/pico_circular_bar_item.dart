part of 'circular_bar.dart';

class PicoCircularBarItem extends StatelessWidget {
  const PicoCircularBarItem({
    required this.value,
    required this.maxValue,
    required this.scale,
    required this.logo,
    required this.label,
    this.onTap,
    this.valueFormatter,
    super.key,
  });

  final String logo;
  final String label;
  final double value;
  final double maxValue;
  final PCChartScale scale;
  final GestureTapCallback? onTap;
  final String Function(num value)? valueFormatter;

  double get _calculateLinearValue {
    final formattedValue = value.abs();

    if (formattedValue == 0) return 0;

    if (formattedValue >= _specialLineBottom &&
        formattedValue <= _specialLineTop) {
      return _specialLineBottom / maxValue;
    }

    return formattedValue / maxValue;
  }

  double get _calculateLogValue {
    final formattedValue = value.abs();

    if (formattedValue == 0) {
      return 0;
    } else if (formattedValue < 1) {
      final logScale = NumberHelper.logBase(value: 1, base: _base);
      const logAdjuster = 1 + (1 / _denom);
      final logScaleFinal = logScale + logAdjuster;
      final result = formattedValue * logScaleFinal;
      return result / maxValue;
    }

    final logScale = NumberHelper.logBase(value: formattedValue, base: _base);
    const logAdjuster = 1 + (1 / _denom);
    final result = logScale + logAdjuster;
    return result / maxValue;
  }

  double get _finalValue => switch (scale) {
        PCChartScale.log => _calculateLogValue,
        PCChartScale.linear => _calculateLinearValue,
      };

  double get _pureBarHeight => _finalValue * _maxBarHeight;
  double get _barHeight => _pureBarHeight + _logoSize;
  double get _finalBarHeight => _pureBarHeight == 0
      ? _logoSize
      : _pureBarHeight < _minItemSize
          ? _barHeight + 2.4 * 1.h
          : _barHeight;

  @override
  Widget build(BuildContext context) {
    final totalSizedBoxHeight = 8.h;
    var topSpace = 0.0;
    var bottomSpace = 0.0;

    if (value >= _anchorBound) {
      if (value.isNegative) {
        /// Give some space to put the percentage label to top of the container
        topSpace = _maxBarHeight - _finalBarHeight + _logoSize;
      } else {
        /// Give some space to stick the percentage bar on top of the container
        bottomSpace = _maxBarHeight - _finalBarHeight + _logoSize;
      }
    } else {
      if (value == 0) {
        // Center the value bar
        bottomSpace = _maxBarHeight * _zeroAnchorPercent + (_logoSize / 2);

        /// Reduce by the total height of sized box in _CoinChartItem
        bottomSpace -= totalSizedBoxHeight;
      } else {
        if (value.isNegative) {
          /// Set space by the negative anchor size
          bottomSpace = _maxBarHeight * _negativeBottomAnchorPercent +
              (_logoSize / 2) +
              totalSizedBoxHeight;
        } else {
          /// Set space by the positive anchor size
          bottomSpace = _maxBarHeight * _positiveBottomAnchorPercent;
        }

        /// Reduce by the total height of sized box in _CoinChartItem
        bottomSpace -= totalSizedBoxHeight;

        /// Set the bottom space to middle of anchor
        bottomSpace = bottomSpace - (_finalBarHeight / 2) + (_logoSize / 2);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 700.milliseconds,
        constraints: BoxConstraints(
          minWidth: _itemWidth,
          minHeight: _itemHeight,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _PicoCircularBarLabel(
              value: value,
              valueFormatter: valueFormatter,
            ),
            (totalSizedBoxHeight / 2).verticalSpace,
            AnimatedContainer(
              duration: 300.milliseconds,
              height: topSpace,
            ),
            _PicoCircularProgressBar(
              logo: logo,
              value: value,
              barHeight: _finalBarHeight,
            ),
            AnimatedContainer(
              duration: 300.milliseconds,
              height: bottomSpace,
            ),
            (totalSizedBoxHeight / 2).verticalSpace,
            Text(
              label,
              style: PicoTextStyle.bodySm(
                fontWeight: FontWeight.w600,
                color: context.picoColors.text.neutral.main,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
