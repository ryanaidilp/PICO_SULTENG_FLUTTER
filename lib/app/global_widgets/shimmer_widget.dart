import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  const ShimmerWidget(
      {Key? key,
      required this.width,
      required this.height,
      this.highlightColor,})
      : super(key: key);
  final double width;
  final double height;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: highlightColor ?? Colors.grey.shade200,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.0),
        ),
        height: height,
        width: width,
      ),
    );
  }
}
