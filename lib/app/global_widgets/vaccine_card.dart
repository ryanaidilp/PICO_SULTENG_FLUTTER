import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class VaccineCard extends StatelessWidget {
  const VaccineCard({
    Key? key,
    required this.title,
    required this.color,
    required this.progress,
    required this.total,
    required this.newCase,
  }) : super(key: key);

  final String title;
  final Color color;
  final int progress;
  final int total;
  final int newCase;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              formatNewCase(newCase),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4.0),
            Center(
              child: Text(
                numberFormat(progress),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 46.0,
                  color: color,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                LocaleKeys.vaccine_card_dose_given.tr,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            FAProgressBar(
              progressColor: color,
              backgroundColor: Colors.grey.shade300,
              currentValue: calculatePercentage(progress, total),
              displayText: '%',
              animatedDuration: const Duration(seconds: 2),
            ),
            const SizedBox(height: 8.0),
            RichText(
              text: TextSpan(
                text: percentageFormat(
                  calculatePercentage(progress, total) / 100,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0,
                ),
                children: [
                  TextSpan(
                    text: LocaleKeys.vaccine_card_from.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: numberFormat(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: LocaleKeys.vaccine_card_vaccinated.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
