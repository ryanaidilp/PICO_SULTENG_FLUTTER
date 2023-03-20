import 'package:flutter/material.dart';

class LineContainer extends StatelessWidget {
  const LineContainer({super.key, this.height = 8.0});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(top: 8.0),
      color: Colors.grey.shade50,
    );
  }
}
