import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';

class InfographicCard extends StatelessWidget {
  const InfographicCard({Key? key, required this.infographic})
      : super(key: key);

  final Infographic infographic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 250.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: ExtendedImage.network(
                infographic.images.first as String,
                fit: BoxFit.fill,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                gradient: const LinearGradient(
                  colors: [
                    Colors.black87,
                    Colors.black54,
                    Colors.black12,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 8.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateWithDayFormat(infographic.publishedAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: Get.width * 0.9,
                    child: Text(
                      infographic.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 24.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8.0,
              right: 8.0,
              child: Opacity(
                opacity: 0.8,
                child: Chip(
                  backgroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  label: Text('1/${infographic.images.length}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
