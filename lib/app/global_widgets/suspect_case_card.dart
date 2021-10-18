import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class SuspectCaseCard extends StatelessWidget {
  const SuspectCaseCard({
    Key? key,
    required this.title,
    required this.total,
    required this.newCase,
    required this.newFinishedCase,
    required this.activeCase,
    required this.finishedCase,
    this.onTap,
  }) : super(key: key);

  final String title;
  final int total;
  final int newCase;
  final int newFinishedCase;
  final int activeCase;
  final int finishedCase;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Text(title),
              const SizedBox(width: 4.0),
              InkWell(
                onTap: onTap,
                child: Icon(
                  LineIcons.questionCircle,
                  size: 16.0,
                  color: Colors.grey.shade600,
                ),
              )
            ]),
            const SizedBox(height: 6.0),
            Row(
              children: [
                Text(
                  numberFormat(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 26.0,
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  formatNewCase(newCase),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            const Divider(thickness: 2.0),
            const SizedBox(height: 6.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocaleKeys.card_case_label_active.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          Text(
                            numberFormat(activeCase),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22.0,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            formatNewCase(newCase - newFinishedCase),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                    ],
                  ),
                ),
                SizedBox(width: Get.width * 0.2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocaleKeys.card_case_label_finish.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          Text(
                            numberFormat(finishedCase),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22.0,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            formatNewCase(newFinishedCase),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
