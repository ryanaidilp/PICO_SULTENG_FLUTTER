import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/charts/painter/pico_dot_painter.dart';

class PCLineChart extends StatefulWidget {
  const PCLineChart({
    required this.data,
    required this.hoverLabelResolver,
    required this.valueFormatter,
    super.key,
    this.dotRadius = 4,
    this.lineWidth = 2,
    this.showDot = true,
    this.showVerticalLine = true,
    this.showGradient = true,
    this.lineColor,
    this.dotColor,
    this.positiveColor,
    this.negativeColor,
    this.controller,
    this.onHoverCallback,
  });

  final bool showDot;
  final bool showVerticalLine;
  final bool showGradient;
  final double dotRadius;
  final Color? lineColor;
  final Color? dotColor;
  final Color? positiveColor;
  final Color? negativeColor;
  final double lineWidth;
  final PCLineChartData data;
  final PCLineChartController? controller;
  final void Function(
    int index, {
    required bool hoverState,
  })? onHoverCallback;
  final String Function(int? index) hoverLabelResolver;
  final String Function(double value) valueFormatter;

  @override
  State<PCLineChart> createState() => _PCLineChartState();
}

class _PCLineChartState extends State<PCLineChart>
    with TickerProviderStateMixin {
  late final AnimationController _barsAnimationCtl;
  late final Animation<double> _barsAnimation;

  late final AnimationController _blinkAnimationCtl;
  late final Animation<double> _blinkAnimation;

  late final ValueNotifier<PCLineChartData> _chartDataNotifier;
  late final ValueNotifier<bool> _hoverStateNotifier;

  double _hoveredIndex = 0;
  bool _isChanging = false;
  PCChartState _state = PCChartState.success;

  @override
  void initState() {
    super.initState();
    _chartDataNotifier = ValueNotifier(widget.data);
    _hoverStateNotifier = ValueNotifier(false);

    _initializeBarsAnimation();
    _initializeBlinkAnimation();

    widget.controller?.data = widget.data.data;
    widget.controller?.addListener(_controllerListener);
  }

  Future<void> _controllerListener() async {
    switch (widget.controller?.event) {
      case PCChartEvent.changeState:
        setState(() => _state = widget.controller?.state ?? _state);
      case PCChartEvent.updateData:
      case PCChartEvent.appendData:
        _chartDataNotifier.value = _chartDataNotifier.value.copyWith(
          data: widget.controller?.data,
        );
      case PCChartEvent.changeData:
        await _barsAnimationCtl.reverse();
        _chartDataNotifier.value = _chartDataNotifier.value.copyWith(
          data: widget.controller?.data,
        );
        await _barsAnimationCtl.forward();
      case null:
        break;
    }

    widget.controller?.event = null;
  }

  Future<void> _barsAnimationStatusListener(AnimationStatus status) async {
    var changing = _checkStatus(status);
    switch (status) {
      case AnimationStatus.completed:
      case AnimationStatus.dismissed:
        changing = false;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        changing = true;
    }

    setState(() => _isChanging = changing);
  }

  bool _checkStatus(AnimationStatus status) => switch (status) {
        AnimationStatus.completed => false,
        _ => true,
      };

  void _initializeBarsAnimation() {
    _barsAnimationCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: Duration.zero,
    )
      ..forward()
      ..addStatusListener(_barsAnimationStatusListener);
    _barsAnimation = CurvedAnimation(
      parent: _barsAnimationCtl,
      curve: Curves.easeInCubic,
    );
  }

  void _initializeBlinkAnimation() {
    _blinkAnimationCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _blinkAnimation = CurvedAnimation(
      parent: _blinkAnimationCtl,
      curve: Curves.easeOutCubic,
    );
  }

  void _setHoverState(bool state) {
    if (state != _hoverStateNotifier.value) {
      _hoverStateNotifier.value = state;
    }
  }

  @override
  void dispose() {
    _blinkAnimationCtl.dispose();
    _barsAnimationCtl
      ..removeStatusListener(_barsAnimationStatusListener)
      ..dispose();
    widget.controller?.removeListener(_controllerListener);
    _chartDataNotifier.dispose();
    super.dispose();
  }

  FlDotPainter _getDotPainter(spot, xPercentage, bar, index) => PicoDotPainter(
        color: _state.dotColor(
          context,
          dotColor: widget.dotColor,
        ),
        radius: widget.dotRadius.r,
        strokeColor: _state
            .dotColor(
              context,
              dotColor: widget.dotColor,
            )
            .withOpacity(
              0.5 - (0.5 * _blinkAnimationCtl.value / 1),
            ),
        strokeWidth: _blinkAnimation.value * 8.w,
      );

  FlDotPainter _hoveredDotPainter(spot, xPercentage, bar, index) =>
      PicoDotPainter(
        color: _state.dotColor(
          context,
          dotColor: widget.dotColor,
        ),
        radius: widget.dotRadius.r,
        strokeColor: Colors.white,
        strokeWidth: 2.w,
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _barsAnimation,
        builder: (_, __) => AnimatedPadding(
          duration: 300.milliseconds,
          padding: _state.padding,
          child: AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (_, __) => ValueListenableBuilder<PCLineChartData>(
              valueListenable: _chartDataNotifier,
              builder: (_, chartData, __) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _hoverStateNotifier,
                  builder: (_, isHovered, __) {
                    if (chartData.data.isEmpty) {
                      return LineChart(_emptyChartData);
                    }

                    return LineChart(
                      LineChartData(
                        maxX: chartData.maxX,
                        minX: chartData.minX,
                        maxY: chartData.maxYOffset,
                        minY: chartData.minYOffset,
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: const FlGridData(
                          show: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: const AxisTitles(),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 12.w,
                              showTitles: chartData.showZeroLineLabel,
                              getTitlesWidget: (value, meta) => value == 0
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                        left: PCSpacing.s8.w,
                                      ),
                                      child: Text(
                                        meta.formattedValue,
                                        style: PicoTextStyle.bodySm(
                                          color: context
                                              .picoColors.text.neutral.subtle,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          extraLinesOnTop: false,
                          horizontalLines: [
                            HorizontalLine(
                              y: 0,
                              color: context.picoColors.outline.neutral.main,
                              strokeWidth: 1.w,
                              strokeCap: StrokeCap.round,
                            ),
                          ],
                          verticalLines: [
                            if (widget.showVerticalLine)
                              if (!isHovered) ...[
                                VerticalLine(
                                  x: chartData.maxYIndex.toDouble(),
                                  strokeWidth: 0,
                                  color: Colors.transparent,
                                  label: VerticalLineLabel(
                                    show: true,
                                    alignment: Alignment.topCenter,
                                    style: PicoTextStyle.bodySm(
                                      fontWeight: FontWeight.w600,
                                      color: context
                                          .picoColors.text.neutral.subtle,
                                    ),
                                    labelResolver: (line) =>
                                        widget.valueFormatter(chartData.maxY),
                                  ),
                                ),
                                VerticalLine(
                                  x: chartData.minYIndex.toDouble(),
                                  strokeWidth: 0,
                                  color: Colors.transparent,
                                  label: VerticalLineLabel(
                                    show: true,
                                    alignment: Alignment.bottomCenter,
                                    style: PicoTextStyle.bodySm(
                                      fontWeight: FontWeight.w600,
                                      color: context
                                          .picoColors.text.neutral.subtle,
                                    ),
                                    labelResolver: (line) =>
                                        widget.valueFormatter(chartData.minY),
                                  ),
                                ),
                              ],
                            if (isHovered)
                              VerticalLine(
                                x: _hoveredIndex,
                                dashArray: [6, 6],
                                strokeWidth: 2.w,
                                color:
                                    context.picoColors.outline.neutral.strong,
                                label: VerticalLineLabel(
                                  show: true,
                                  alignment: Alignment.bottomCenter,
                                  padding: const EdgeInsets.only(
                                    top: PCSpacing.s32,
                                  ),
                                  style: PicoTextStyle.bodySm(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        context.picoColors.text.neutral.subtle,
                                  ),
                                  labelResolver: (_) =>
                                      widget.hoverLabelResolver.call(
                                    _hoveredIndex.toInt(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          getTouchLineStart: (_, __) => 0,
                          getTouchLineEnd: (_, __) => chartData.maxY,
                          getTouchedSpotIndicator: (barData, spotIndexes) =>
                              spotIndexes
                                  .map(
                                    (e) => TouchedSpotIndicatorData(
                                      const FlLine(strokeWidth: 0),
                                      FlDotData(
                                        show: widget.showDot,
                                        getDotPainter: _hoveredDotPainter,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.transparent,
                            showOnTopOfTheChartBoxArea: true,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            maxContentWidth: double.infinity,
                            tooltipMargin: 0,
                            getTooltipItems: (touchedSpots) =>
                                touchedSpots.map((e) => null).toList(),
                          ),
                          touchCallback: (event, response) {
                            _setHoverState(event.isInterestedForInteractions);

                            setState(() {
                              _hoveredIndex = event.isInterestedForInteractions
                                  ? response?.lineBarSpots?.first.x ?? 0
                                  : 0;
                            });
                            widget.onHoverCallback?.call(
                              _hoveredIndex.toInt(),
                              hoverState: event.isInterestedForInteractions,
                            );
                          },
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isStrokeJoinRound: true,
                            belowBarData: BarAreaData(
                              show: widget.showGradient,
                              applyCutOffY: true,
                              gradient: LinearGradient(
                                colors: [
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.2),
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.1),
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            aboveBarData: BarAreaData(
                              show: widget.showGradient,
                              applyCutOffY: true,
                              gradient: LinearGradient(
                                colors: [
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.05),
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.1),
                                  _state
                                      .lineColor(
                                        context,
                                        lineColor: widget.lineColor,
                                      )
                                      .withOpacity(0.2),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            barWidth: widget.lineWidth,
                            color: _state.lineColor(
                              context,
                              lineColor: widget.lineColor,
                            ),
                            isCurved: true,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              getDotPainter: _getDotPainter,
                              show: widget.showDot && !isHovered,
                              checkToShowDot: (spot, barData) =>
                                  barData.spots.last == spot,
                            ),
                            spots: List.generate(
                              (chartData.dataLength * _barsAnimationCtl.value)
                                  .toInt(),
                              (index) => FlSpot(
                                index.toDouble(),
                                chartData.data[index],
                              ),
                            ),
                          ),
                        ],
                      ),
                      curve: Curves.easeOut,
                      duration: _isChanging ? Duration.zero : 500.milliseconds,
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

  LineChartData get _emptyChartData => LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: 10,
        minY: 5,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 5),
              const FlSpot(5, 5),
            ],
          ),
        ],
      );
}
