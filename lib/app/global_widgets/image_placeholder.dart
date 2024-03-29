import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, 
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: Get.width,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            child,
            const SizedBox(height: 5.0),
            Text(
              label,
              style: const TextStyle(color: Colors.grey),
            )
          ],
        ),);
  }
}
