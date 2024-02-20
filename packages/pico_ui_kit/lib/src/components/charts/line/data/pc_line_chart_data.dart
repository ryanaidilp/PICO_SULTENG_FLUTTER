import 'dart:math';

class PCLineChartData {
  PCLineChartData({
    required this.data,
  }) {
    minX = 0;
    maxX = data.length.toDouble();
    if (data.isNotEmpty) {
      minY = data.reduce(min);
      maxY = data.reduce(max);
    } else {
      minY = 0;
      maxY = 0;
    }
  }

  final List<double> data;

  late final double minX;
  late final double maxX;
  late final double minY;
  late final double maxY;

  int get minYIndex => data.indexOf(minY);
  int get maxYIndex => data.indexOf(maxY);
  double get maxYOffset => maxY + ((maxY - minY) * 0.15);
  double get minYOffset => minY - ((maxY - minY) * 0.05);
  int get dataLength => data.length;
  double get medY => maxY - minY / 2;
  bool get showZeroLineLabel {
    return (minY != 0 && maxY != 0) && (maxY.sign != minY.sign);
  }

  PCLineChartData copyWith({
    List<double>? data,
  }) =>
      PCLineChartData(
        data: data ?? this.data,
      );
}
