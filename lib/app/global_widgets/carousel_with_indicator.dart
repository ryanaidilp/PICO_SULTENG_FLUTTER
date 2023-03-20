import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarouselWithIndicator extends StatelessWidget {
  const CarouselWithIndicator({
    super.key,
    required this.items,
    required this.options,
    required this.controller,
    required this.currentIndex,
  });

  final List<Widget> items;
  final CarouselOptions options;
  final CarouselController controller;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider(
          items: items,
          carouselController: controller,
          options: options,
        ),
        const SizedBox(height: 6.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => controller.animateToPage(entry.key),
              child: Container(
                width: currentIndex == entry.key ? 26.0 : 10.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: currentIndex == entry.key
                      ? BorderRadius.circular(8.0)
                      : null,
                  shape: currentIndex == entry.key
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade100
                          : Colors.blueAccent)
                      .withOpacity(currentIndex == entry.key ? 0.9 : 0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
