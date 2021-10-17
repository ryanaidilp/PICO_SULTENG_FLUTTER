import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class CardConfirmed extends StatelessWidget {
  const CardConfirmed({
    Key? key,
    required this.total,
    required this.newCase,
    required this.startColor,
    required this.endColor,
    required this.shadowColor,
  }) : super(key: key);
  final int total;
  final int newCase;
  final Color startColor;
  final Color endColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            margin: const EdgeInsets.symmetric(
              vertical: 16.0,
            ),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10.0,
                  spreadRadius: 5.0,
                  offset: Offset.fromDirection(-30.0, 5.0),
                )
              ],
              borderRadius: BorderRadius.circular(10.0),
              gradient: LinearGradient(colors: [
                startColor,
                endColor,
              ]),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.card_case_label_confirmed.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        numberFormat(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 30.0,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        formatNewCase(newCase),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
          width: Get.width * 0.15,
          right: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: Image.asset('assets/images/covid.png'),
        ),
      ],
    );
  }
}
